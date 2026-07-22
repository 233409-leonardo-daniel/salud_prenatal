import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/subscription_status.dart';
import '../providers/subscriptions_provider.dart';
import 'subscription_state.dart';

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 2);
  static const _pollTimeout = Duration(seconds: 15);
  static const _sharedPlanFeatures = [
    'Pacientes y expedientes clínicos ilimitados',
    'Predicción de riesgo de preeclampsia con IA',
    'Agenda y recordatorios de citas',
    'Chat directo con tus pacientes',
    'Bitácora de embarazo en tiempo real',
  ];

  String _selectedPlan = 'basic';
  // 'recurring' -> tarjeta con renovación automática.
  // 'one_time'  -> pago de un mes; en Stripe habilita OXXO/SPEI (asíncronos).
  String _paymentMode = 'recurring';
  // Modo del checkout que estamos esperando confirmar; distingue la UI de
  // "confirmando..." (tarjeta) de la de instrucciones de ficha (OXXO/SPEI).
  String? _awaitingPaymentMode;
  bool _awaitingConfirmation = false;
  bool _confirmationTimedOut = false;
  // El doctor salió al Portal de Stripe (cambiar plan / tarjeta / cancelar);
  // al volver a la app hay que recargar el estado para reflejar el cambio.
  bool _awaitingPortalReturn = false;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionsProvider>().loadStatus();
    });
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleIncomingLink);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (_awaitingConfirmation || _awaitingPortalReturn)) {
      _awaitingPortalReturn = false;
      context.read<SubscriptionsProvider>().loadStatus();
    }
  }

  /// Stripe redirige aquí (esquema `saludprenatal://`, ver FRONTEND_URL del
  /// backend) al terminar el checkout. Esto trae la app al frente de forma
  /// automática (Android cierra la pestaña del navegador in-app) y dispara
  /// una verificación inmediata en vez de esperar a que el usuario regrese
  /// manualmente.
  void _handleIncomingLink(Uri uri) {
    if (uri.scheme != 'saludprenatal' || uri.host != 'payment-callback') return;
    if (!mounted) return;

    // Regreso del Portal de Stripe (gestión de suscripción): no es un checkout,
    // solo recargamos el estado para reflejar el plan/tarjeta actualizados.
    if (_awaitingPortalReturn) {
      _awaitingPortalReturn = false;
      context.read<SubscriptionsProvider>().loadStatus();
      return;
    }

    if (uri.path.toLowerCase().contains('cancel')) {
      _pollTimer?.cancel();
      setState(() {
        _awaitingConfirmation = false;
        _confirmationTimedOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago cancelado. Puedes intentarlo de nuevo cuando quieras.')),
      );
      return;
    }

    if (_awaitingConfirmation) {
      _checkStatus();
    } else {
      _startPolling();
    }
  }

  Future<void> _pay() async {
    setState(() => _confirmationTimedOut = false);

    final provider = context.read<SubscriptionsProvider>();
    final checkoutUrl = await provider.startCheckout(_selectedPlan, _paymentMode);
    if (!mounted) return;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      // El error real del backend ya se muestra inline en _buildPlanPicker
      // (provider.checkoutError); no duplicar con un SnackBar.
      return;
    }

    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la página de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _startPolling();
  }

  /// Abre el Portal de Cliente de Stripe (cambiar de plan, actualizar tarjeta,
  /// cancelar). Mismo patrón que [_pay]: pide la URL al backend y la abre en el
  /// navegador in-app. Al volver, [didChangeAppLifecycleState] recarga el estado.
  Future<void> _openPortal() async {
    final provider = context.read<SubscriptionsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final portalUrl = await provider.openPortal();
    if (!mounted) return;

    if (portalUrl == null || portalUrl.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.portalError ?? 'No se pudo abrir la gestión de la suscripción'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(portalUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la página de gestión'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _awaitingPortalReturn = true;
  }

  void _startPolling() {
    setState(() {
      _awaitingPaymentMode = _paymentMode;
      _awaitingConfirmation = true;
      _confirmationTimedOut = false;
    });
    _pollStartedAt = DateTime.now();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final provider = context.read<SubscriptionsProvider>();
    await provider.loadStatus();
    if (!mounted) return;

    if (provider.subscription?.isActive == true) {
      _pollTimer?.cancel();
      // El gating lee subscription_status del JWT; hay que reemplazar el token
      // por uno fresco antes de navegar o el doctor seguiría gateado.
      await provider.refreshSessionToken();
      if (!mounted) return;
      // El pago se confirmó mientras esperábamos: entra directo al dashboard
      // en vez de dejar al doctor parado en esta pantalla de confirmación.
      _goToDoctorDashboard();
      return;
    }

    if (_pollStartedAt != null && DateTime.now().difference(_pollStartedAt!) >= _pollTimeout) {
      _pollTimer?.cancel();
      // OXXO/SPEI son asíncronos: el polling SIEMPRE expira porque el doctor
      // aún no paga (tiene ficha/CLABE). No es error: se mantiene la pantalla
      // de instrucciones con el botón "Ya pagué" en vez de volver al picker.
      if (_awaitingPaymentMode == 'one_time') return;
      setState(() {
        _awaitingConfirmation = false;
        _confirmationTimedOut = true;
      });
    }
  }

  void _goToDoctorDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false, arguments: 'doctor');
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _noticeBox({required MaterialColor color, required String text}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color.shade800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SubscriptionsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadStatus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _buildContent(theme, provider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, SubscriptionsProvider provider) {
    if (provider.fetchStatus == SubscriptionFetchStatus.loading && provider.subscription == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (provider.fetchStatus == SubscriptionFetchStatus.error && provider.subscription == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            provider.fetchError ?? 'No se pudo obtener el estado de tu suscripción',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadStatus(),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_awaitingConfirmation) {
      return _buildAwaitingConfirmation(theme);
    }

    final subscription = provider.subscription;
    if (subscription != null && subscription.isActive) {
      return _buildActiveState(theme, subscription);
    }

    return _buildPlanPicker(theme, provider);
  }

  Widget _buildAwaitingConfirmation(ThemeData theme) {
    if (_awaitingPaymentMode == 'one_time') {
      return _buildAsyncPaymentInstructions(theme);
    }
    return Column(
      children: [
        const SizedBox(height: 100),
        CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'Confirmando tu pago...',
          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto puede tardar unos segundos.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  /// Pantalla para OXXO/SPEI: el pago es asíncrono (ficha en efectivo o
  /// transferencia), así que NO afirmamos "confirmando pago" — instruimos al
  /// doctor a pagar su ficha/CLABE y le dejamos un botón para reverificar.
  Widget _buildAsyncPaymentInstructions(ThemeData theme) {
    final provider = context.watch<SubscriptionsProvider>();
    final isChecking = provider.fetchStatus == SubscriptionFetchStatus.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 48),
        const SizedBox(height: 16),
        Text(
          'Completa tu pago',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        Text(
          'Genera y paga tu ficha OXXO en tienda, o realiza tu transferencia SPEI '
          'con la CLABE que te dio Stripe. Tu acceso se activa en cuanto se '
          'registre el pago: puede tardar hasta 72 h en OXXO y unos minutos en SPEI.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: isChecking ? null : _checkStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: isChecking
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : const Text('Ya pagué, verificar de nuevo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _pollTimer?.cancel();
            setState(() {
              _awaitingConfirmation = false;
              _awaitingPaymentMode = null;
              _confirmationTimedOut = false;
            });
          },
          child: const Text('Volver a los planes'),
        ),
      ],
    );
  }

  Widget _buildActiveState(ThemeData theme, SubscriptionStatus subscription) {
    final planLabel = subscription.planType == 'premium' ? 'Premium' : 'Básico';
    final periodEnd = subscription.currentPeriodEnd;
    final isOpeningPortal = context.watch<SubscriptionsProvider>().portalStatus == PortalStatus.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.verified_outlined, color: AppColors.primary, size: 48),
        const SizedBox(height: 16),
        Text(
          'Tu suscripción está activa',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          'Plan $planLabel',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        ),
        if (periodEnd != null) ...[
          const SizedBox(height: 4),
          Text(
            subscription.autoRenewal ? 'Se renueva el ${_formatDate(periodEnd)}' : 'Vence el ${_formatDate(periodEnd)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
        // Pago único (OXXO/SPEI o tarjeta suelta): no se renueva solo, hay que
        // avisar del vencimiento para que el doctor renueve a tiempo.
        if (subscription.isOneTimeActive && periodEnd != null)
          _noticeBox(
            color: Colors.orange,
            text: 'Pago único: tu acceso vence el ${_formatDate(periodEnd)}. '
                'Renueva antes de esa fecha para no perder acceso.',
          ),
        // Recurrente marcada para cancelarse al final del periodo.
        if (subscription.autoRenewal && subscription.cancelAtPeriodEnd && periodEnd != null)
          _noticeBox(
            color: Colors.orange,
            text: 'Tu plan se cancelará el ${_formatDate(periodEnd)}. '
                'Después de esa fecha perderás el acceso.',
          ),
        const SizedBox(height: 32),
        // Gestión de la suscripción vía el Portal de Cliente de Stripe: cambiar
        // de plan, actualizar tarjeta o cancelar. Solo aplica al plan recurrente
        // (el pago único no se "gestiona": se vuelve a pagar para renovar).
        if (subscription.autoRenewal) ...[
          OutlinedButton.icon(
            onPressed: isOpeningPortal ? null : _openPortal,
            icon: isOpeningPortal
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : Icon(Icons.settings_outlined, color: AppColors.primary),
            label: Text(
              'Cambiar plan o gestionar suscripción',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              _goToDoctorDashboard();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildPlanPicker(ThemeData theme, SubscriptionsProvider provider) {
    final isCheckingOut = provider.checkoutStatus == CheckoutStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 48),
        const SizedBox(height: 16),
        Text(
          'Activa tu consultorio digital',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          'Elige tu plan para empezar a atender pacientes. El monto se confirma en la página de pago. '
          'Por ahora ambos planes incluyen el mismo acceso al sistema.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        if (_confirmationTimedOut)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Tu pago se está procesando, te avisaremos cuando se confirme. Puedes verificar de nuevo con el botón "Ya pagué".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        if (provider.checkoutStatus == CheckoutStatus.error && provider.checkoutError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              provider.checkoutError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _planCard(
          planType: 'basic',
          label: 'Básico',
          features: _sharedPlanFeatures,
        ),
        const SizedBox(height: 16),
        _planCard(
          planType: 'premium',
          label: 'Premium',
          features: _sharedPlanFeatures,
        ),
        const SizedBox(height: 24),
        Text(
          'Forma de pago',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        _paymentModeCard(
          mode: 'recurring',
          icon: Icons.credit_card,
          label: 'Tarjeta',
          description: 'Renovación automática cada mes.',
        ),
        const SizedBox(height: 12),
        _paymentModeCard(
          mode: 'one_time',
          icon: Icons.storefront_outlined,
          label: 'Efectivo o transferencia',
          description: 'Pago único de 1 mes con OXXO o SPEI. No se renueva solo.',
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: isCheckingOut ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: isCheckingOut
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Pagar y continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
        ),
        if (_confirmationTimedOut) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => provider.loadStatus(),
            child: const Text('Ya pagué, verificar de nuevo'),
          ),
        ],
      ],
    );
  }

  Widget _planCard({
    required String planType,
    required String label,
    required List<String> features,
  }) {
    final isSelected = _selectedPlan == planType;
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => setState(() => _selectedPlan = planType),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f, style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentModeCard({
    required String mode,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _paymentMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

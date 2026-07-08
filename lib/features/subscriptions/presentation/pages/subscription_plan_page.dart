import 'dart:async';
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

  String _selectedPlan = 'basic';
  bool _awaitingConfirmation = false;
  bool _confirmationTimedOut = false;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionsProvider>().loadStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingConfirmation) {
      context.read<SubscriptionsProvider>().loadStatus();
    }
  }

  Future<void> _pay() async {
    final provider = context.read<SubscriptionsProvider>();
    final checkoutUrl = await provider.startCheckout(_selectedPlan);
    if (!mounted) return;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.checkoutError ?? 'No se pudo iniciar el proceso de pago'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _startPolling() {
    setState(() {
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
      setState(() => _awaitingConfirmation = false);
      return;
    }

    if (_pollStartedAt != null && DateTime.now().difference(_pollStartedAt!) >= _pollTimeout) {
      _pollTimer?.cancel();
      setState(() {
        _awaitingConfirmation = false;
        _confirmationTimedOut = true;
      });
    }
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

  Widget _buildActiveState(ThemeData theme, SubscriptionStatus subscription) {
    final planLabel = subscription.planType == 'premium' ? 'Premium' : 'Básico';
    final periodEnd = subscription.currentPeriodEnd;
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
            'Vence el ${periodEnd.day}/${periodEnd.month}/${periodEnd.year}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).maybePop(),
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
          'Elige tu plan para empezar a atender pacientes. El monto se confirma en la página de pago.',
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
          features: const [
            'Pacientes y expedientes clínicos ilimitados',
            'Predicción de riesgo de preeclampsia con IA',
            'Agenda y recordatorios de citas',
          ],
        ),
        const SizedBox(height: 16),
        _planCard(
          planType: 'premium',
          label: 'Premium',
          features: const [
            'Todo lo incluido en el plan Básico',
            'Chat directo con tus pacientes',
            'Bitácora de embarazo en tiempo real',
            'Soporte prioritario',
          ],
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
}

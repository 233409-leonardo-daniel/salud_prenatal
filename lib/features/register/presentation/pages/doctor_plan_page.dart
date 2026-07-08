import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';

/// Pantalla de selección de plan que se muestra al doctor justo después de
/// registrarse, antes de entrar al dashboard.
///
/// El botón de pagar NO está conectado a ningún procesador de pagos real
/// (Stripe, etc.) — por instrucción explícita, aquí solo se simula el pago
/// exitoso reutilizando el login real del doctor recién registrado para
/// obtener su sesión y llevarlo al dashboard.
class DoctorPlanPage extends StatefulWidget {
  final String email;
  final String password;

  const DoctorPlanPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<DoctorPlanPage> createState() => _DoctorPlanPageState();
}

class _DoctorPlanPageState extends State<DoctorPlanPage> {
  bool _isProcessing = false;

  Future<void> _confirmPlan() async {
    setState(() => _isProcessing = true);
    final loginProvider = context.read<LoginProvider>();
    final success = await loginProvider.login(widget.email, widget.password);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      // DashboardPage decide qué tablero mostrar según el argumento de ruta
      // (ver DashboardPage._userRole); sin esto cae al valor por defecto
      // 'patient' y manda al doctor recién registrado al dashboard equivocado.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
        arguments: 'doctor',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginProvider.errorMessage ?? 'No se pudo iniciar tu sesión. Intenta iniciar sesión manualmente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final features = <String>[
      'Pacientes y expedientes clínicos ilimitados',
      'Predicción de riesgo de preeclampsia con IA',
      'Chat directo con tus pacientes',
      'Agenda y recordatorios de citas',
      'Bitácora de embarazo en tiempo real',
      'Soporte prioritario',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 48),
              SizedBox(height: 16),
              Text(
                '¡Ya casi terminamos!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Elige tu plan para activar tu consultorio digital y empezar a atender pacientes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'PLAN MÉDICO',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$399',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            ' MXN/mes',
                            style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                            SizedBox(width: 10),
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
              SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isProcessing ? null : _confirmPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Pagar y continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
              ),
              SizedBox(height: 12),
              Text(
                'Se cobrará mensualmente. Puedes cancelar cuando quieras.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

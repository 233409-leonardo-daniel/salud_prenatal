import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../../core/services/qr_service.dart';
import '../providers/invitation_provider.dart';
import 'patient_state.dart';

class InvitationCodePage extends StatefulWidget {
  const InvitationCodePage({super.key});

  @override
  State<InvitationCodePage> createState() => _InvitationCodePageState();
}

class _InvitationCodePageState extends State<InvitationCodePage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = context.read<LoginProvider>();
      final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';
      final invitationProvider = context.read<InvitationProvider>();
      invitationProvider.reset();

      if (isDoctor && loginProvider.doctorId != null) {
        invitationProvider.generateInvitationCode(loginProvider.doctorId!);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();
    final isDoctor = loginProvider.role == 'doctor' || loginProvider.role == 'doctor(a)';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isDoctor ? 'Invitar Paciente' : 'Vincularme con Médico',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isDoctor ? _buildDoctorView() : _buildPatientView(),
    );
  }

  // ─── DOCTOR VIEW: Generate code / QR ───
  Widget _buildDoctorView() {
    final invitationProvider = context.watch<InvitationProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 16),

          // Header icon
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.primary),
          ),
          SizedBox(height: 24),

          Text(
            'Código de Invitación',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 8),
          Text(
            'Comparte este código con tu paciente para vincularla a tu cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 32),

          // Code card & buttons
          ...switch (invitationProvider.generateStatus) {
            InvitationCodeStatus.initial => [
                SizedBox(height: 40),
              ],
            InvitationCodeStatus.loading => [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ],
            InvitationCodeStatus.error => [
                _buildErrorCard(invitationProvider.error ?? 'Error al generar código', () {
                  final doctorId = context.read<LoginProvider>().doctorId;
                  if (doctorId != null) {
                    invitationProvider.generateInvitationCode(doctorId);
                  }
                }),
              ],
            InvitationCodeStatus.success => [
                if (invitationProvider.generatedCode != null)
                  _buildCodeCard(invitationProvider.generatedCode!, invitationProvider.expiresAt),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final doctorId = context.read<LoginProvider>().doctorId;
                      if (doctorId != null) {
                        invitationProvider.generateInvitationCode(doctorId);
                      }
                    },
                    icon: Icon(Icons.refresh_rounded),
                    label: Text('Generar nuevo código'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
          },
        ],
      ),
    );
  }

  Widget _buildCodeCard(String code, String? expiresAt) {
    String expiresText = '';
    if (expiresAt != null) {
      try {
        final dt = DateTime.parse(expiresAt);
        expiresText = 'Expira: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        expiresText = 'Expira: $expiresAt';
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // The QR code: fondo SIEMPRE blanco (a propósito) — el QR se dibuja
          // en negro y necesita contraste claro para poder escanearse bien,
          // sin importar el tema de la app.
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink.shade50, width: 2),
            ),
            child: context.read<QrService>().buildQrCode(code, size: 180),
          ),
          SizedBox(height: 24),

          // The code as big styled text
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SelectableText(
                code,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Copy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Código copiado al portapapeles'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: Icon(Icons.copy_rounded, size: 18),
              label: Text('Copiar código', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          if (expiresText.isNotEmpty) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text(expiresText, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── PATIENT VIEW: Enter code ───
  Widget _buildPatientView() {
    final invitationProvider = context.watch<InvitationProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 16),

          // Header icon
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.link_rounded, size: 48, color: AppColors.primary),
          ),
          SizedBox(height: 24),

          Text(
            'Vincularme con mi Médico',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresa el código que te proporcionó tu médico para vincularte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 32),

          // Code input
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.textMuted.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final scannedCode = await context.read<QrService>().scanQrCode(context);
                      if (scannedCode != null && scannedCode.isNotEmpty) {
                        _codeController.text = scannedCode;
                      }
                    },
                    icon: Icon(Icons.qr_code_scanner_rounded),
                    label: Text('Escanear QR del médico'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: invitationProvider.redeemStatus == InvitationCodeStatus.loading
                        ? null
                        : () async {
                            final code = _codeController.text.trim();
                            if (code.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ingresa un código'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            final loginProvider = context.read<LoginProvider>();
                            final patientId = loginProvider.patientId;
                            if (patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('No se pudo identificar tu sesión de paciente.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            final success = await invitationProvider.redeemCode(patientId, code);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡Vinculación exitosa!'),
                                  backgroundColor: Colors.teal,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              Navigator.pop(context, true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    ),
                    child: invitationProvider.redeemStatus == InvitationCodeStatus.loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Vincular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),

          // Error or success messages
          ...switch (invitationProvider.redeemStatus) {
            InvitationCodeStatus.initial || InvitationCodeStatus.loading => [],
            InvitationCodeStatus.error => [
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          invitationProvider.error ?? 'Error al vincular',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            InvitationCodeStatus.success => [
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.teal.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Te has vinculado exitosamente con tu médico!',
                          style: TextStyle(color: Colors.teal.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          },
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
          SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors_ext.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../chat/presentation/pages/chat_room_page.dart';

/// Perfil (solo lectura) del médico asignado a la paciente.
///
/// Se abre desde la tarjeta del doctor en el dashboard de la paciente. Recibe el
/// [UserProfile] emparejado contra la lista de usuarios ya cargada (puede venir
/// `null` si no hubo coincidencia); en ese caso se apoya en [fallbackName] y
/// [fallbackSpecialty], que provienen de `current_doctor` /
/// `current_doctor_specialty` del dashboard, para que la vista siempre muestre
/// al menos el nombre y la especialidad del médico.
///
/// Código nuevo: lee colores y tipografías de `Theme.of(context)` (no de
/// `AppColors`), por lo que reacciona en vivo al cambio claro/oscuro del SO.
class DoctorProfilePage extends StatelessWidget {
  final UserProfile? doctor;
  final String fallbackName;
  final String fallbackSpecialty;

  const DoctorProfilePage({
    super.key,
    this.doctor,
    required this.fallbackName,
    required this.fallbackSpecialty,
  });

  String get _displayName {
    final d = doctor;
    if (d != null) {
      final full = '${d.name} ${d.lastName}'.trim();
      if (full.isNotEmpty) return full;
    }
    return fallbackName.trim().isNotEmpty ? fallbackName.trim() : 'Tu médico';
  }

  String get _displaySpecialty {
    final s = doctor?.specialty;
    if (s != null && s.trim().isNotEmpty) return s.trim();
    return fallbackSpecialty.trim().isNotEmpty
        ? fallbackSpecialty.trim()
        : 'Especialidad no especificada';
  }

  /// Inicial para el avatar, ignorando el prefijo "Dr./Dra.".
  String get _initial {
    final clean = _displayName
        .replaceAll(RegExp(r'^(Dr\.|Dra\.)\s*', caseSensitive: false), '')
        .trim();
    return clean.isNotEmpty ? clean[0].toUpperCase() : 'D';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ext = theme.extension<AppColorsExt>()!;
    final topInset = MediaQuery.of(context).padding.top;

    final email = doctor?.email.trim() ?? '';
    final phone = doctor?.phone.trim() ?? '';
    final license = doctor?.professionalLicense?.trim() ?? '';
    final office = doctor?.office?.trim() ?? '';
    final imageUrl = doctor?.imageUrl.trim() ?? '';

    final infoRows = <Widget>[];
    void addRow(IconData icon, String label, String value) {
      if (value.isEmpty) return;
      if (infoRows.isNotEmpty) infoRows.add(const SizedBox(height: 12));
      infoRows.add(_InfoCard(icon: icon, label: label, value: value));
    }

    addRow(Icons.medical_services_outlined, 'Especialidad', _displaySpecialty);
    addRow(Icons.badge_outlined, 'Cédula profesional', license);
    addRow(Icons.email_outlined, 'Correo electrónico', email);
    addRow(Icons.phone_outlined, 'Teléfono', phone);
    addRow(Icons.meeting_room_outlined, 'Consultorio', office);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header a sangre completa (llega hasta la barra de notificaciones) ---
            Container(
              padding: EdgeInsets.only(top: topInset + 8, bottom: 28),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Avatar(imageUrl: imageUrl, initial: _initial, primary: scheme.primary),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _displaySpecialty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Cuerpo desplazable ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Información del médico',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ext.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...infoRows,
                    if (email.isEmpty && phone.isEmpty && license.isEmpty && office.isEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tu médico aún no ha completado más datos de contacto en su perfil.',
                        style: theme.textTheme.bodySmall?.copyWith(color: ext.textMuted),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (doctor?.userId != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(
                                  otherUserId: doctor!.userId!,
                                  otherUserName: _displayName,
                                  otherUserRole: 'doctor',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Enviar mensaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

/// Avatar circular: usa la foto del médico si está disponible; si no (o si falla
/// la carga), cae a la inicial sobre un círculo blanco.
class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String initial;
  final Color primary;

  const _Avatar({required this.imageUrl, required this.initial, required this.primary});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(
        initial,
        style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 34),
      ),
    );

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withAlpha(153), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return fallback;
                },
              ),
      ),
    );
  }
}

/// Fila de información con ícono, etiqueta y valor. Theme-aware.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ext = theme.extension<AppColorsExt>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ext.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: ext.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ext.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

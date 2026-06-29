import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../privacy_policy/presentation/providers/privacy_policy_provider.dart';
import '../../../privacy_policy/data/models/accepted_policy_model.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();
    final initial = loginProvider.name.isNotEmpty ? loginProvider.name[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFFFE0EF),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mi Perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gestiona tu cuenta y privacidad',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // User Information details card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Nombre completo',
                  value: '${loginProvider.userProfile?.name} ${loginProvider.userProfile?.lastName}'.trim().isNotEmpty
                      ? '${loginProvider.userProfile?.name} ${loginProvider.userProfile?.lastName}'
                      : 'No especificado',
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  value: loginProvider.userProfile?.email.isNotEmpty == true
                      ? loginProvider.userProfile!.email
                      : 'No especificado',
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: loginProvider.userProfile?.phone.isNotEmpty == true
                      ? loginProvider.userProfile!.phone
                      : 'No especificado',
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Rol',
                  value: loginProvider.userProfile?.role.toLowerCase() == 'doctor'
                      ? 'Médico / Especialista'
                      : 'Paciente',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                  label: const Text(
                    'Editar Perfil',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accepted policies section
          const _AcceptedPoliciesTile(),
          const SizedBox(height: 16),

          // Account deletion section (expandable)
          _AccountDeletionTile(),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              final loginProvider = context.read<LoginProvider>();
              loginProvider.reset();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade200,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcceptedPoliciesTile extends StatefulWidget {
  const _AcceptedPoliciesTile();

  @override
  State<_AcceptedPoliciesTile> createState() => _AcceptedPoliciesTileState();
}

class _AcceptedPoliciesTileState extends State<_AcceptedPoliciesTile> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadPolicies();
    }
  }

  void _loadPolicies() {
    final loginProvider = context.read<LoginProvider>();
    final email = loginProvider.userProfile?.email ?? '';
    if (email.isNotEmpty) {
      context.read<PrivacyPolicyProvider>().loadAcceptedPolicies(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.policy_outlined, color: AppColors.primary, size: 20),
          ),
          title: const Text(
            'Políticas Aceptadas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 14,
            ),
          ),
          subtitle: const Text(
            'Consulta las políticas que aceptaste al registrarte',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Consumer<PrivacyPolicyProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      ),
                    );
                  }

                  if (provider.acceptedPolicies.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'No se encontraron políticas aceptadas para esta cuenta.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FFF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${provider.acceptedPolicies.length} política(s) aceptada(s)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...provider.acceptedPolicies.map((policy) => _buildPolicyCard(policy)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(AcceptedPolicyModel policy) {
    final date = DateTime.tryParse(policy.acceptedAt);
    String formattedDate = policy.acceptedAt;
    if (date != null) {
      final months = [
        '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
      ];
      formattedDate = '${date.day} de ${months[date.month]} de ${date.year}, '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    final bool isSensitive = policy.policyId.contains('sensitive');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSensitive ? const Color(0xFFFFF8E1) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSensitive ? const Color(0xFFFFCC80) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSensitive ? Icons.health_and_safety_outlined : Icons.shield_outlined,
                color: isSensitive ? const Color(0xFFE65100) : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  policy.policyTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSensitive ? const Color(0xFFE65100) : AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aceptada',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                policy.userEmail,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountDeletionTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 20),
          ),
          title: const Text(
            'Eliminar mi cuenta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD32F2F),
              fontSize: 14,
            ),
          ),
          subtitle: const Text(
            'Conoce cómo solicitar la eliminación de tus datos',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoText(
                    'En Salud Prenatal respetamos tu privacidad y tu derecho a controlar tus datos personales. Si deseas eliminar tu cuenta y todos los datos asociados, puedes solicitarlo siguiendo estos pasos:',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pasos para solicitar la eliminación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStep('1', 'Abre tu correo electrónico (preferiblemente el mismo con el que te registraste).'),
                  _buildStep('2', 'Redacta un correo dirigido a: fitnesspro.soporte@gmail.com'),
                  _buildStep('3', 'En el asunto escribe: "Solicitud de eliminación de cuenta - Salud Prenatal".'),
                  _buildStep('4', 'Incluye tu nombre completo y el correo asociado a tu cuenta.'),
                  _buildStep('5', '(Opcional) Cuéntanos brevemente el motivo de tu baja.'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 13, color: AppColors.textDark),
                              children: [
                                TextSpan(text: 'Tiempo de respuesta: '),
                                TextSpan(
                                  text: '10 días hábiles',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                TextSpan(text: ' a partir de recibir tu solicitud.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Qué datos se eliminan y cuáles se conservan?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDataRow(
                    icon: Icons.delete_forever_outlined,
                    color: const Color(0xFFD32F2F),
                    bgColor: const Color(0xFFFFEBEA),
                    label: 'Se eliminan',
                    description:
                        'Cuenta de usuario, contraseñas, datos de contacto (nombre, correo) e historial médico personal (datos ginecobstétricos, signos vitales, notas de consulta y riesgos calculados).',
                  ),
                  const SizedBox(height: 10),
                  _buildDataRow(
                    icon: Icons.lock_outline,
                    color: const Color(0xFF00796B),
                    bgColor: const Color(0xFFE0F2F1),
                    label: 'Se conservan',
                    description:
                        'Únicamente información disociada o anonimizada (estadísticas sin identidad) para fines de investigación, o datos que por ley debamos resguardar temporalmente ante auditorías sanitarias.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '¿Dudas? Contáctanos en fitnesspro.soporte@gmail.com',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.6),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

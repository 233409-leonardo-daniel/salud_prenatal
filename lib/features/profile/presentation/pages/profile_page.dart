import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../privacy_policy/presentation/providers/privacy_policy_provider.dart';
import '../../../privacy_policy/data/models/accepted_policy_model.dart';
import '../../../register/presentation/providers/register_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();
    final initial = loginProvider.name.isNotEmpty ? loginProvider.name[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          SizedBox(height: 28),

          // User Information details card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
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
                Divider(height: 24, color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  value: loginProvider.userProfile?.email.isNotEmpty == true
                      ? loginProvider.userProfile!.email
                      : 'No especificado',
                ),
                Divider(height: 24, color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: loginProvider.userProfile?.phone.isNotEmpty == true
                      ? loginProvider.userProfile!.phone
                      : 'No especificado',
                ),
                Divider(height: 24, color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Rol',
                  value: loginProvider.userProfile?.role.toLowerCase() == 'doctor'
                      ? 'Médico / Especialista'
                      : 'Paciente',
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  },
                  icon: Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                  label: Text(
                    'Editar Perfil',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
                if (loginProvider.userProfile?.role.toLowerCase() == 'doctor') ...[
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateReceptionistDialog(context);
                    },
                    icon: Icon(Icons.person_add_alt_1_outlined, size: 18, color: Colors.white),
                    label: Text(
                      'Mi Recepcionista',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5ACD),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),

          // Accepted policies section
          const _AcceptedPoliciesTile(),
          SizedBox(height: 16),

          // Account deletion section (expandable)
          _AccountDeletionTile(),
          SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              final loginProvider = context.read<LoginProvider>();
              loginProvider.reset();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: Icon(Icons.logout_rounded, size: 18, color: Colors.white),
            label: Text(
              'Cerrar Sesión',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade200,
              padding: EdgeInsets.symmetric(vertical: 14),
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
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
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
  void _showCreateReceptionistDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreateReceptionistBottomSheet(),
      ),
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
        color: AppColors.cardBackground,
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
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          shape: Border(),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.policy_outlined, color: AppColors.primary, size: 20),
          ),
          title: Text(
            'Políticas Aceptadas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Consulta las políticas que aceptaste al registrarte',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0))),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Consumer<PrivacyPolicyProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      ),
                    );
                  }

                  if (provider.acceptedPolicies.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                          SizedBox(width: 10),
                          Expanded(
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
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.isDarkMode ? const Color(0xFF1A3320) : const Color(0xFFF0FFF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.isDarkMode ? const Color(0xFF3D6B45) : const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${provider.acceptedPolicies.length} política(s) aceptada(s)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
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
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSensitive
            ? (AppColors.isDarkMode ? const Color(0xFF3A2E10) : const Color(0xFFFFF8E1))
            : (AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSensitive
              ? (AppColors.isDarkMode ? const Color(0xFF8A6A2C) : const Color(0xFFFFCC80))
              : (AppColors.isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0)),
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
              SizedBox(width: 8),
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
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
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 12, color: AppColors.textMuted),
              SizedBox(width: 6),
              Text(
                policy.userEmail,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
        color: AppColors.cardBackground,
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
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          shape: Border(),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.riskHighBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline, color: AppColors.riskHighText, size: 20),
          ),
          title: Text(
            'Eliminar mi cuenta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.riskHighText,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Conoce cómo solicitar la eliminación de tus datos',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0))),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoText(
                    'En Salud Prenatal respetamos tu privacidad y tu derecho a controlar tus datos personales. Si deseas eliminar tu cuenta y todos los datos asociados, puedes solicitarlo siguiendo estos pasos:',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pasos para solicitar la eliminación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildStep('1', 'Abre tu correo electrónico (preferiblemente el mismo con el que te registraste).'),
                  _buildStep('2', 'Redacta un correo dirigido a: fitnesspro.soporte@gmail.com'),
                  _buildStep('3', 'En el asunto escribe: "Solicitud de eliminación de cuenta - Salud Prenatal".'),
                  _buildStep('4', 'Incluye tu nombre completo y el correo asociado a tu cuenta.'),
                  _buildStep('5', '(Opcional) Cuéntanos brevemente el motivo de tu baja.'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
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
                  SizedBox(height: 16),
                  Text(
                    '¿Qué datos se eliminan y cuáles se conservan?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildDataRow(
                    icon: Icons.delete_forever_outlined,
                    color: AppColors.riskHighText,
                    bgColor: AppColors.riskHighBg,
                    label: 'Se eliminan',
                    description:
                        'Cuenta de usuario, contraseñas, datos de contacto (nombre, correo) e historial médico personal (datos ginecobstétricos, signos vitales, notas de consulta y riesgos calculados).',
                  ),
                  SizedBox(height: 10),
                  _buildDataRow(
                    icon: Icons.lock_outline,
                    color: AppColors.riskLowText,
                    bgColor: AppColors.riskLowBg,
                    label: 'Se conservan',
                    description:
                        'Únicamente información disociada o anonimizada (estadísticas sin identidad) para fines de investigación, o datos que por ley debamos resguardar temporalmente ante auditorías sanitarias.',
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: AppColors.textMuted, size: 16),
                      SizedBox(width: 6),
                      Expanded(
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
      style: TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.6),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.5),
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateReceptionistBottomSheet extends StatefulWidget {
  const _CreateReceptionistBottomSheet();

  @override
  State<_CreateReceptionistBottomSheet> createState() => _CreateReceptionistBottomSheetState();
}

class _CreateReceptionistBottomSheetState extends State<_CreateReceptionistBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.read<LoginProvider>();
    final registerProvider = context.watch<RegisterProvider>();
    
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A5ACD).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add_alt_1_outlined, color: const Color(0xFF6A5ACD)),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Crear Recepcionista',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  if (!val.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              SizedBox(height: 32),

              ElevatedButton(
                onPressed: registerProvider.isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    final doctorId = loginProvider.doctorId ?? 0;
                    if (doctorId == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: No se pudo obtener el ID del médico.'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    
                    final success = await registerProvider.registerReceptionist(
                      name: _nameController.text.trim(),
                      lastName: _lastNameController.text.trim(),
                      email: _emailController.text.trim(),
                      phone: _phoneController.text.trim(),
                      password: _passwordController.text.trim(),
                      doctorId: doctorId,
                    );

                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Recepcionista creado exitosamente.'), backgroundColor: Colors.green),
                      );
                    } else if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(registerProvider.errorMessage ?? 'Error al crear recepcionista.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5ACD),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: registerProvider.isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Crear Cuenta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

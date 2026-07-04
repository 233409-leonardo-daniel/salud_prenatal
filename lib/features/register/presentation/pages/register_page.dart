import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../providers/register_provider.dart';
import 'package:provider/provider.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../privacy_policy/presentation/pages/privacy_policy_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Patient fields
  final _birthdateController = TextEditingController();
  String _selectedBloodType = 'O+';
  final _weeksController = TextEditingController(text: '0');
  final _lmpController = TextEditingController();

  // Doctor fields
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _officeController = TextEditingController();

  // Receptionist fields
  final _doctorIdController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _birthdateController.dispose();
    _lmpController.dispose();
    _weeksController.dispose();
    _licenseController.dispose();
    _specialtyController.dispose();
    _officeController.dispose();
    _doctorIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _showPrivacyPolicy() async {
    final email = _emailController.text.trim();
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage(userEmail: email)),
    );
    if (accepted == true) {
      setState(() => _privacyAccepted = true);
      _submitForm();
    }
  }

  void _submitForm() async {
    if (!_privacyAccepted) {
      _showPrivacyPolicy();
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      bool success = false;
      final registerProvider = context.read<RegisterProvider>();
      final role = registerProvider.selectedRole;

      if (role == 'patient') {
        success = await registerProvider.registerPatient(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          birthdate: _birthdateController.text,
          bloodType: _selectedBloodType,
          weeksAtRegistration: int.tryParse(_weeksController.text) ?? 0,
          lastMenstrualPeriod: _lmpController.text,
          residence: "",
        );
      } else if (role == 'doctor') {
        success = await registerProvider.registerDoctor(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          professionalLicense: _licenseController.text.trim(),
          specialty: _specialtyController.text.trim(),
          office: _officeController.text.trim(),
        );
      } else if (role == 'receptionist') {
        final doctorId = int.tryParse(_doctorIdController.text.trim());
        if (doctorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresa un ID de médico válido'), backgroundColor: Colors.red),
          );
          return;
        }
        success = await registerProvider.registerReceptionist(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          doctorId: doctorId,
        );
      } else {
        // admin fallback
        success = await registerProvider.registerAdmin(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        if (success) {
          // Si se registró como paciente, guardar el patient_id para usarlo después
          if (role == 'patient') {
            final registeredPatientId = registerProvider.lastRegisteredPatientId;
            if (registeredPatientId != null) {
              context.read<LoginProvider>().setPatientId(registeredPatientId);
            }
          }
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(registerProvider.errorMessage ?? 'Error al registrar')),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildRoleCard(String role, String title, IconData icon, Color activeColor) {
    final registerProvider = context.watch<RegisterProvider>();
    final isSelected = registerProvider.selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<RegisterProvider>().setRole(role),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
              ? (AppColors.isDarkMode ? AppColors.primaryLight : activeColor.withOpacity(0.08))
              : (AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? activeColor : AppColors.textMuted,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : AppColors.textDark,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background, // Soft pinkish-white background from mockup
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Builder(
            builder: (context) {
              final registerProvider = context.watch<RegisterProvider>();
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Help Icon / App Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 48), // Spacer to balance
                        Row(
                          children: [
                            Image.asset(
                              'assets/logo_integrador-removebg-preview.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Salud Prenatal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline, color: AppColors.primary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    Text(
                      'Comienza con nosotros',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Únete a nuestra comunidad para recibir acompañamiento experto, monitoreo en tiempo real y paz mental durante tu embarazo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Main Info Card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(AppColors.isDarkMode ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Base Form fields
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Apellido',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu apellido' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo Electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                                return 'Ingresa un correo válido';
                              }
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
                            validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu teléfono' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                          SizedBox(height: 24),

                          // Role selection
                          Text(
                            '¿Quién eres?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              _buildRoleCard('patient', 'Paciente', Icons.pregnant_woman, AppColors.primary),
                              SizedBox(width: 8),
                              _buildRoleCard('doctor', 'Doctor(a)', Icons.badge_outlined, AppColors.primary),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Dynamic fields based on role
                          if (registerProvider.selectedRole == 'patient') ...[
                            Text(
                              'Información de Paciente',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _birthdateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Nacimiento',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              onTap: () => _selectDate(context, _birthdateController),
                              validator: (value) => value == null || value.isEmpty ? 'Selecciona tu fecha de nacimiento' : null,
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedBloodType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Sangre',
                                prefixIcon: Icon(Icons.bloodtype_outlined),
                              ),
                              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedBloodType = val);
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _weeksController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Semanas de Embarazo al Registro',
                                prefixIcon: Icon(Icons.trending_up_outlined),
                              ),
                              validator: (value) => value == null || int.tryParse(value) == null ? 'Ingresa un número válido' : null,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _lmpController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Fecha Última Regla (FUM)',
                                prefixIcon: Icon(Icons.date_range_outlined),
                              ),
                              onTap: () => _selectDate(context, _lmpController),
                              validator: (value) => value == null || value.isEmpty ? 'Selecciona la fecha FUM' : null,
                            ),
                          ] else if (registerProvider.selectedRole == 'doctor') ...[
                            Text(
                              'Información Médica',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _licenseController,
                              decoration: const InputDecoration(
                                labelText: 'Cédula Profesional',
                                prefixIcon: Icon(Icons.card_membership_outlined),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Ingresa tu cédula profesional' : null,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _specialtyController,
                              decoration: const InputDecoration(
                                labelText: 'Especialidad',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Ingresa tu especialidad' : null,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _officeController,
                              decoration: const InputDecoration(
                                labelText: 'Consultorio',
                                prefixIcon: Icon(Icons.local_hospital_outlined),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Ingresa tu consultorio' : null,
                            ),
                          ],
                          SizedBox(height: 32),

                          // Submit button
                          ElevatedButton(
                            onPressed: registerProvider.isLoading
                                ? null
                                : (_privacyAccepted ? _submitForm : _showPrivacyPolicy),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: registerProvider.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Crear Cuenta',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward),
                                    ],
                                  ),
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: _showPrivacyPolicy,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                children: const [
                                  TextSpan(text: 'Al unirte, aceptas nuestra '),
                                  TextSpan(
                                    text: 'Política de Privacidad',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' y consientes el tratamiento de tus datos.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Feature Information Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.pink.shade50,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 18),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Atención Expert',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Conexión directa con especialistas en obstetricia.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.pink.shade50,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Progreso',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Seguimiento semanal detallado de tu bebé.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),

                    // Back to login prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes una cuenta?',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Inicia Sesión',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

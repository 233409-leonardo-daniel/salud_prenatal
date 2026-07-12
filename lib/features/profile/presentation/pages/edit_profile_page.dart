import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/session/session_manager.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;
  late TextEditingController _licenseController;
  late TextEditingController _officeController;
  late String _email;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final session = context.read<SessionManager>();
      final profile = session.userProfile;
      _nameController = TextEditingController(text: profile?.name ?? '');
      _lastNameController = TextEditingController(text: profile?.lastName ?? '');
      _phoneController = TextEditingController(text: profile?.phone ?? '');
      _specialtyController = TextEditingController(text: profile?.specialty ?? '');
      _licenseController = TextEditingController(text: profile?.professionalLicense ?? '');
      _officeController = TextEditingController(text: profile?.office ?? '');
      _email = profile?.email ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final isDoc = context.read<SessionManager>().isDoctor;
    final profileProvider = context.read<ProfileProvider>();

    final success = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      specialty: isDoc ? _specialtyController.text.trim() : null,
      professionalLicense: isDoc ? _licenseController.text.trim() : null,
      office: isDoc ? _officeController.text.trim() : null,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Description
                Text(
                  'Modifica tus datos de contacto y personales a continuación.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                SizedBox(height: 24),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Last Name Input
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Apellidos',
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tus apellidos';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu teléfono';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email (Read Only)
                TextFormField(
                  initialValue: _email,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico (No editable)',
                    filled: true,
                    fillColor: AppColors.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
                if (session.isDoctor) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _specialtyController,
                    decoration: InputDecoration(
                      labelText: 'Especialidad médica',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      labelText: 'Cédula profesional',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _officeController,
                    decoration: InputDecoration(
                      labelText: 'Consultorio / Dirección de oficina',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFFFE0EF)),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

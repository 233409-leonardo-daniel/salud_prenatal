import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/social_profile.dart';
import '../providers/forums_provider.dart';
import 'forums_state.dart';

class SocialProfilePage extends StatefulWidget {
  const SocialProfilePage({super.key});

  @override
  State<SocialProfilePage> createState() => _SocialProfilePageState();
}

class _SocialProfilePageState extends State<SocialProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _bioController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _picker = ImagePicker();
  String _selectedAvatar = 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
  // true si ya existía un perfil social al cargar la página: determina si al
  // guardar se llama PATCH /forums/profiles/me (actualizar) o POST
  // /forums/profiles (crear por primera vez).
  bool _hasExistingProfile = false;

  final List<String> _avatars = [
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
    'https://cdn-icons-png.flaticon.com/512/219/219969.png',
    'https://cdn-icons-png.flaticon.com/512/219/219970.png',
    'https://cdn-icons-png.flaticon.com/512/1154/1154448.png',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = context.read<SessionManager>();
      final currentUserId = session.userId;
      if (currentUserId != null) {
        final forumsProvider = context.read<ForumsProvider>();
        await forumsProvider.loadSocialProfile(currentUserId);
        
        final profile = forumsProvider.socialProfile;
        if (profile != null) {
          setState(() {
            _hasExistingProfile = true;
            _aliasController.text = profile.alias;
            _bioController.text = profile.bio ?? '';
            _officeAddressController.text = profile.officeAddress ?? '';
            if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
              _selectedAvatar = profile.avatarUrl!;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _bioController.dispose();
    _officeAddressController.dispose();
    super.dispose();
  }

  /// Elige una foto del dispositivo (galería/cámara), la sube al bucket
  /// (POST /forums/profiles/upload-avatar) y usa la URL devuelta como avatar.
  /// Se persiste al pulsar "Guardar Perfil" (PATCH /forums/profiles/me).
  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('Galería', style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: Text('Cámara', style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 90);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la imagen.')),
      );
      return;
    }
    if (picked == null) return;

    final forumsProvider = context.read<ForumsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final url = await forumsProvider.uploadAvatar(File(picked.path));
    if (!mounted) return;
    if (url != null) {
      setState(() => _selectedAvatar = url);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(forumsProvider.saveError ?? 'No se pudo subir la foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();
    final session = context.read<SessionManager>();
    final currentUserId = session.userId;
    final isDoctor = session.role?.toLowerCase().contains('doctor') ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil de Comunidad', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: switch (forumsProvider.profileStatus) {
          ProfileStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ProfileStatus.error => Center(
              child: Text(
                'Error: ${forumsProvider.profileError ?? "No se pudo cargar el perfil"}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _ => Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: forumsProvider.isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: NetworkImage(_selectedAvatar),
                          ),
                          if (forumsProvider.isUploadingAvatar)
                            Positioned.fill(
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.black.withOpacity(0.45),
                                child: const CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary,
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: forumsProvider.isUploadingAvatar ? null : _pickAndUploadAvatar,
                      icon: Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
                      label: Text(
                        'Subir foto desde el dispositivo',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'O elige un avatar de la Comunidad:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatars[index];
                        final isSelected = _selectedAvatar == avatar;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatar = avatar;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(avatar),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _aliasController,
                    decoration: InputDecoration(
                      labelText: 'Alias / Nombre Público',
                      hintText: 'Ej. MamáFeliz99 o DrGomez',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa un alias';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Biografía',
                      hintText: 'Cuéntanos un poco sobre ti...',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                      ),
                    ),
                  ),
                  if (isDoctor) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _officeAddressController,
                      decoration: InputDecoration(
                        labelText: 'Dirección del consultorio',
                        hintText: 'Ej. Av. Reforma 123, Consultorio 4',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: forumsProvider.isSaving
                        ? null
                        : () async {
                            if (currentUserId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se pudo identificar tu sesión.')),
                              );
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              final profile = SocialProfile(
                                userId: currentUserId,
                                alias: _aliasController.text.trim(),
                                bio: _bioController.text.trim(),
                                avatarUrl: _selectedAvatar,
                                officeAddress: isDoctor ? _officeAddressController.text.trim() : null,
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              final success = _hasExistingProfile
                                  ? await forumsProvider.updateSocialProfile(profile)
                                  : await forumsProvider.saveSocialProfile(profile);
                              if (success) {
                                navigator.pop(true);
                              } else if (forumsProvider.sessionExpired) {
                                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${forumsProvider.saveError ?? "No se pudo guardar"}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: forumsProvider.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar Perfil',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}

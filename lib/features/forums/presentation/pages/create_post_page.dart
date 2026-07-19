import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/session/session_manager.dart';
import '../providers/forums_provider.dart';
import 'forums_state.dart';

class CreatePostPage extends StatefulWidget {
  final int? groupId;

  const CreatePostPage({super.key, this.groupId});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  /// Imagen elegida localmente (aún sin subir). Se sube al backend recién al
  /// pulsar "Publicar" para obtener la `image_url` y no gastar almacenamiento
  /// si el usuario cancela.
  File? _pickedImage;

  /// Selección del médico premium: false = publicación normal, true = aviso
  /// (is_ad). El backend igual valida por token que solo un doctor con
  /// suscripción activa pueda enviar is_ad=true.
  bool _isAd = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la imagen.')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Galería', style: TextStyle(color: AppColors.textDark)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: Text('Cámara', style: TextStyle(color: AppColors.textDark)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();
    final session = context.read<SessionManager>();
    final currentUserId = session.userId;
    // Solo un médico con suscripción premium activa puede elegir publicar
    // como aviso. El resto solo crea publicaciones normales.
    final canPostAd = session.isPremiumDoctor;
    final busy = forumsProvider.isSaving || forumsProvider.isUploadingImage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nueva Publicación', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título de la Publicación',
                  hintText: 'Ej. ¿Dudas sobre vitaminas prenatal?',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Contenido / Pregunta',
                  hintText: 'Escribe detalladamente tu duda o experiencia...',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor escribe el contenido de tu post';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Selector de imagen. La imagen se sube al backend al publicar
              // (POST /forums/posts/upload-image) y su URL se manda en image_url.
              _buildImagePicker(),
              // Selector de tipo de publicación: visible solo para médicos con
              // suscripción activa (premium). El backend valida por token que
              // solo ellos puedan enviar is_ad=true.
              if (canPostAd) ...[
                const SizedBox(height: 24),
                Text(
                  'Tipo de publicación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Publicación'),
                      icon: Icon(Icons.forum_outlined),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Aviso'),
                      icon: Icon(Icons.campaign_outlined),
                    ),
                  ],
                  selected: {_isAd},
                  onSelectionChanged: (selection) {
                    setState(() => _isAd = selection.first);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isAd ? Icons.campaign_outlined : Icons.info_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isAd
                            ? 'Aviso destacado. Sugerencia: usa una imagen vertical (4:5 o 9:16), tipo Instagram.'
                            : 'Publicación normal, visible en el feed general.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: busy ? null : () => _submit(context, currentUserId, canPostAd),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            forumsProvider.isUploadingImage ? 'Subiendo imagen...' : 'Publicando...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ],
                      )
                    : const Text(
                        'Publicar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_pickedImage == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: _showImageSourceSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 1.2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Agregar imagen (opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Formato vertical recomendado (4:5)',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(
            _pickedImage!,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _circleIconButton(Icons.swap_horiz, 'Cambiar', _showImageSourceSheet),
              const SizedBox(width: 8),
              _circleIconButton(Icons.close, 'Quitar', () {
                setState(() => _pickedImage = null);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        iconSize: 20,
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Future<void> _submit(BuildContext context, int? currentUserId, bool canPostAd) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final forumsProvider = context.read<ForumsProvider>();

    if (currentUserId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo identificar tu sesión.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Paso 1: subir la imagen (si hay) para obtener su URL pública.
    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await forumsProvider.uploadPostImage(_pickedImage!);
      if (imageUrl == null) {
        if (!mounted) return;
        if (forumsProvider.sessionExpired) {
          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
          return;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(forumsProvider.saveError ?? 'No se pudo subir la imagen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Paso 2: crear el post con la URL obtenida.
    final success = await forumsProvider.createPost(
      currentUserId,
      widget.groupId,
      _titleController.text.trim(),
      _contentController.text.trim(),
      isAd: canPostAd && _isAd,
      imageUrl: imageUrl,
    );

    if (!mounted) return;
    if (success) {
      navigator.pop(true);
      return;
    }
    if (forumsProvider.sessionExpired) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(forumsProvider.saveError ?? 'No se pudo publicar'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
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
                    borderSide: BorderSide(color: Colors.pink.shade50),
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
                    borderSide: BorderSide(color: Colors.pink.shade50),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor escribe el contenido de tu post';
                  }
                  return null;
                },
              ),
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
                          final success = await forumsProvider.createPost(
                            currentUserId,
                            widget.groupId,
                            _titleController.text.trim(),
                            _contentController.text.trim(),
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Publicación creada con éxito!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${forumsProvider.saveError ?? "No se pudo publicar"}'),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../domain/entities/forum_post.dart';
import '../providers/forums_provider.dart';
import 'forums_state.dart';

class PostDetailPage extends StatefulWidget {
  final ForumPost post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumsProvider>().loadComments(widget.post.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;

    final isAd = widget.post.isAd;
    final authorName = widget.post.authorAlias ?? (isAd ? 'Consultorio' : 'Usuario');
    final isDoctor = widget.post.authorRole?.toLowerCase().contains('doctor') ?? false;
    final displayName = isDoctor ? 'Dr. $authorName' : authorName;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';
    final accentColor = isAd ? const Color(0xFFB07C1F) : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Publicación', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.flag_outlined, color: AppColors.textMuted),
            onPressed: () => _showReportDialog(context, widget.post.postId, null),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: isAd
                          ? (AppColors.isDarkMode ? const Color(0xFF2A2410) : const Color(0xFFFFF8E8))
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: isAd ? Border.all(color: const Color(0xFFF0C36D).withOpacity(0.6), width: 1.2) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isAd ? const Color(0xFFF0C36D).withOpacity(0.3) : AppColors.primaryLight,
                              backgroundImage: widget.post.authorAvatarUrl != null ? NetworkImage(widget.post.authorAvatarUrl!) : null,
                              child: widget.post.authorAvatarUrl == null
                                  ? Text(initials, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                      ),
                                      if (isDoctor && !isAd) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Doctor',
                                            style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  if (isAd)
                                    Row(
                                      children: [
                                        Icon(Icons.campaign_outlined, size: 12, color: accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'De un doctor',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      formatRelativeTime(widget.post.createdAt),
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Text(
                          widget.post.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.post.content,
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Comentarios',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  switch (forumsProvider.commentsStatus) {
                    CommentsStatus.loading => const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      )),
                    CommentsStatus.error => Center(
                        child: Text(
                          'Error al cargar comentarios: ${forumsProvider.commentsError}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    _ => _buildCommentsList(),
                  },
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Añadir un comentario...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: AppColors.primary),
                    onPressed: () async {
                      final text = _commentController.text.trim();
                      if (text.isNotEmpty && currentUserId != null) {
                        _commentController.clear();
                        final focus = FocusScope.of(context);
                        final success = await forumsProvider.createComment(
                          widget.post.postId,
                          currentUserId,
                          text,
                        );
                        if (success) {
                          focus.unfocus();
                          forumsProvider.loadComments(widget.post.postId);
                        } else if (mounted && forumsProvider.sessionExpired) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(forumsProvider.saveError ?? 'No se pudo enviar el comentario'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    final forumsProvider = context.watch<ForumsProvider>();
    final comments = forumsProvider.comments;

    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Sin comentarios aún. ¡Escribe el primero!',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final authorName = comment.authorAlias ?? 'Usuario';
        final initials = authorName.isNotEmpty ? authorName.substring(0, 1).toUpperCase() : 'U';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: comment.authorAvatarUrl != null ? NetworkImage(comment.authorAvatarUrl!) : null,
                        child: comment.authorAvatarUrl == null
                            ? Text(initials, style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        authorName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.flag_outlined, size: 16, color: AppColors.textMuted),
                    onPressed: () => _showReportDialog(context, null, comment.commentId),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, int? postId, int? commentId) {
    final reasonController = TextEditingController();
    final forumsProvider = context.read<ForumsProvider>();
    final loginProvider = context.read<LoginProvider>();
    final currentUserId = loginProvider.userId;
    if (currentUserId == null) return; // Sesión no disponible.

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reportar Contenido', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Por qué deseas reportar esta publicación?', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Spam, información médica falsa, agresión...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  Navigator.pop(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final success = await forumsProvider.createReport(
                    currentUserId,
                    postId,
                    commentId,
                    reason,
                  );
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('¡Reporte enviado! Los administradores revisarán el contenido.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (forumsProvider.sessionExpired) {
                    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(forumsProvider.saveError ?? 'No se pudo enviar el reporte'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reportar'),
            ),
          ],
        );
      },
    );
  }
}

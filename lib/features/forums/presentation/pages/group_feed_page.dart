import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/community_group.dart';
import '../providers/forums_provider.dart';
import 'forums_state.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

class GroupFeedPage extends StatefulWidget {
  final CommunityGroup group;

  const GroupFeedPage({super.key, required this.group});

  @override
  State<GroupFeedPage> createState() => _GroupFeedPageState();
}

class _GroupFeedPageState extends State<GroupFeedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumsProvider>().loadGroupFeed(widget.group.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.group.description, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: switch (forumsProvider.forumsStatus) {
          ForumsStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ForumsStatus.error => Center(
              child: Text(
                'Error: ${forumsProvider.forumsError ?? "Error al cargar la comunidad"}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _ => _buildPostsList(),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePostPage(groupId: widget.group.groupId),
            ),
          );
          if (created == true) {
            forumsProvider.loadGroupFeed(widget.group.groupId);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostsList() {
    final forumsProvider = context.watch<ForumsProvider>();
    final posts = forumsProvider.posts;

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 64, color: Colors.pink.shade100),
              const SizedBox(height: 16),
              Text(
                'Aún no hay publicaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Sé la primera en escribir algo o hacer una pregunta en este foro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final authorName = post.authorAlias ?? 'Usuario';
        final isDoctor = post.authorRole?.toLowerCase().contains('doctor') ?? false;
        final displayName = isDoctor ? 'Dr. $authorName' : authorName;
        final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(post: post),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: post.authorAvatarUrl != null ? NetworkImage(post.authorAvatarUrl!) : null,
                        child: post.authorAvatarUrl == null 
                            ? Text(initials, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                                if (isDoctor) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0F6),
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
                            Text(
                              'Hace un momento',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Ver comentarios',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

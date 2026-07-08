import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/community_group.dart';
import '../providers/forums_provider.dart';
import '../widgets/forum_post_card.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            Text(widget.group.description, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
              Icon(Icons.article_outlined, size: 64, color: AppColors.primary.withOpacity(0.3)),
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
        return ForumPostCard(
          post: post,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailPage(post: post),
              ),
            );
          },
        );
      },
    );
  }
}

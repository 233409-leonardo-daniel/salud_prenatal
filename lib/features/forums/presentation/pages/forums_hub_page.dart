import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../domain/entities/community_group.dart';
import '../providers/forums_provider.dart';
import '../widgets/forum_post_card.dart';
import 'forums_state.dart';
import 'group_feed_page.dart';
import 'social_profile_page.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';
import 'forums_groups_page.dart';

class ForumsHubPage extends StatefulWidget {
  const ForumsHubPage({super.key});

  @override
  State<ForumsHubPage> createState() => _ForumsHubPageState();
}

class _ForumsHubPageState extends State<ForumsHubPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loginProvider = context.read<LoginProvider>();
      final currentUserId = loginProvider.userId;
      if (currentUserId != null) {
        final forumsProvider = context.read<ForumsProvider>();
        await forumsProvider.loadSocialProfile(currentUserId);
        if (forumsProvider.socialProfile != null) {
          forumsProvider.loadRecommendedFeed();
          forumsProvider.loadRecommendedGroups();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshFeed() {
    context.read<ForumsProvider>().loadRecommendedFeed();
  }

  void _refreshGroups() {
    context.read<ForumsProvider>().loadRecommendedGroups();
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();
    final hasProfile = forumsProvider.socialProfile != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Comunidad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          if (hasProfile) ...[
            IconButton(
              icon: Icon(Icons.add_box_outlined, color: AppColors.primary),
              tooltip: 'Nueva publicación',
              onPressed: _showCreatePost,
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.textMuted),
              onPressed: () {
                _refreshFeed();
                _refreshGroups();
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: switch (forumsProvider.profileStatus) {
          ProfileStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          _ => !hasProfile
              ? _buildProfileOnboarding()
              : _buildFeedTab(),
        },
      ),
      floatingActionButton: hasProfile
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForumsGroupsPage()),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.group_outlined, color: Colors.white),
              label: const Text(
                'Grupos',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileOnboarding() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade100,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline, color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Únete a la Comunidad!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Text(
                  'Para participar en los foros, publicar dudas y chatear con otras mamás y doctores, primero debes crear tu perfil social de la comunidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () async {
                    final loginProvider = context.read<LoginProvider>();
                    final forumsProvider = context.read<ForumsProvider>();
                    final created = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SocialProfilePage()),
                    );
                    if (created == true) {
                      final currentUserId = loginProvider.userId;
                      if (currentUserId != null) {
                        await forumsProvider.loadSocialProfile(currentUserId);
                        if (forumsProvider.socialProfile != null) {
                          forumsProvider.loadRecommendedFeed();
                          forumsProvider.loadRecommendedGroups();
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Configurar mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Tab "Para ti": feed recomendado por cluster, con publicidad ----

  Widget _buildFeedTab() {
    final forumsProvider = context.watch<ForumsProvider>();

    return switch (forumsProvider.feedStatus) {
      ForumsStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ForumsStatus.error => _buildErrorView(
          message: forumsProvider.feedError ?? 'Error al cargar el feed',
          sessionExpired: forumsProvider.sessionExpired,
          onRetry: _refreshFeed,
        ),
      _ => _buildFeedList(),
    };
  }

  Widget _buildFeedList() {
    final forumsProvider = context.watch<ForumsProvider>();
    final posts = forumsProvider.recommendedFeed;

    if (posts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.dynamic_feed_outlined,
        title: 'Nada por aquí todavía',
        description: 'Cuando tú u otras mamás publiquen, lo verás aquí.',
        action: ElevatedButton.icon(
          onPressed: _showCreatePost,
          icon: const Icon(Icons.add),
          label: const Text('Crear publicación'),
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
              MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
            );
          },
        );
      },
    );
  }

  void _showCreatePost() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
    if (created == true && mounted) {
      _refreshFeed();
    }
  }

  // ---- Tab "Grupos": recomendados por cluster (o todos, con fallback del backend) ----



  Widget _buildErrorView({
    required String message,
    required bool sessionExpired,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sessionExpired ? 'Tu sesión expiró. Vuelve a iniciar sesión.' : 'Error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: sessionExpired ? _goToLogin : onRetry,
              child: Text(sessionExpired ? 'Ir a iniciar sesión' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

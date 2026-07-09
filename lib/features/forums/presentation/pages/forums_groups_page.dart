import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../domain/entities/community_group.dart';
import '../providers/forums_provider.dart';
import 'forums_state.dart';
import 'group_feed_page.dart';

class ForumsGroupsPage extends StatefulWidget {
  const ForumsGroupsPage({super.key});

  @override
  State<ForumsGroupsPage> createState() => _ForumsGroupsPageState();
}

class _ForumsGroupsPageState extends State<ForumsGroupsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Trigger refresh to filter search query correctly
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumsProvider>().loadRecommendedGroups();
      context.read<ForumsProvider>().loadGroups();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshGroups() {
    context.read<ForumsProvider>().loadRecommendedGroups();
    context.read<ForumsProvider>().loadGroups();
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Foros y Grupos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: _refreshGroups,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Recomendados'),
            Tab(text: 'Explorar'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar foros o temas...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Recomendados
                  Consumer<ForumsProvider>(
                    builder: (context, provider, child) {
                      return switch (provider.recommendedGroupsStatus) {
                        ForumsStatus.loading => const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ForumsStatus.error => _buildErrorView(
                            message: provider.recommendedGroupsError ?? 'Error al cargar grupos recomendados',
                            sessionExpired: provider.sessionExpired,
                            onRetry: _refreshGroups,
                          ),
                        _ => _buildGroupsList(isDark, isRecommended: true),
                      };
                    },
                  ),
                  // Tab 2: Explorar (Todos)
                  Consumer<ForumsProvider>(
                    builder: (context, provider, child) {
                      return switch (provider.forumsStatus) {
                        ForumsStatus.loading => const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ForumsStatus.error => _buildErrorView(
                            message: provider.forumsError ?? 'Error al cargar todos los grupos',
                            sessionExpired: provider.sessionExpired,
                            onRetry: _refreshGroups,
                          ),
                        _ => _buildGroupsList(isDark, isRecommended: false),
                      };
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Foro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGroupsList(bool isDark, {required bool isRecommended}) {
    final forumsProvider = context.watch<ForumsProvider>();
    final groups = isRecommended ? forumsProvider.recommendedGroups : forumsProvider.groups;

    final filtered = groups.where((g) {
      return g.name.toLowerCase().contains(_searchQuery) ||
          g.description.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off_outlined,
          title: 'Sin resultados',
          description: 'No se encontraron foros que coincidan con tu búsqueda.',
        );
      } else {
        return _buildEmptyState(
          icon: Icons.group_work_outlined,
          title: isRecommended ? 'No hay foros recomendados' : 'No hay foros aún',
          description: isRecommended
              ? 'No tienes foros recomendados en este momento.'
              : 'Crea el primer foro para iniciar la conversación en comunidad.',
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            isRecommended ? 'Recomendados para ti' : 'Todos los foros',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final group = filtered[index];
              return _buildGroupTile(group, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTile(CommunityGroup group, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.forum_outlined, color: AppColors.primary),
        ),
        title: Text(
          group.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            group.description,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupFeedPage(group: group),
            ),
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final loginProvider = context.read<LoginProvider>();
    final forumsProvider = context.read<ForumsProvider>();
    final currentUserId = loginProvider.userId;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nuevo Foro de Discusión', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Foro',
                  hintText: 'Ej. Primer Trimestre de Embarazo',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Consejos, dudas y experiencias sobre...',
                ),
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
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isNotEmpty && desc.isNotEmpty) {
                  Navigator.pop(context);
                  final success = await forumsProvider.createGroup(name, desc, currentUserId);
                  if (success && mounted) {
                    _refreshGroups();
                  } else if (mounted && forumsProvider.sessionExpired) {
                    _goToLogin();
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

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
          ],
        ),
      ),
    );
  }
}

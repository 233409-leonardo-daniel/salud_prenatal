import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../providers/forums_provider.dart';
import 'forums_state.dart';
import 'group_feed_page.dart';
import 'social_profile_page.dart';

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
          forumsProvider.loadGroups();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    context.read<ForumsProvider>().loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final forumsProvider = context.watch<ForumsProvider>();
    final hasProfile = forumsProvider.socialProfile != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Foros de Comunidad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FB),
        actions: [
          if (hasProfile)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _refreshData,
            ),
        ],
      ),
      body: SafeArea(
        child: switch (forumsProvider.profileStatus) {
          ProfileStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          _ => !hasProfile
              ? _buildProfileOnboarding()
              : Column(
                  children: [
                    // Barra de búsqueda
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
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    // Cuerpo de listado
                    Expanded(
                      child: switch (forumsProvider.forumsStatus) {
                        ForumsStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ForumsStatus.error => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: ${forumsProvider.forumsError ?? "Error al cargar grupos"}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _refreshData,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        _ => _buildForumsView(),
                      },
                    ),
                  ],
                ),
        },
      ),
      floatingActionButton: hasProfile
          ? FloatingActionButton(
              onPressed: _showCreateGroupDialog,
              backgroundColor: AppColors.primary,
              tooltip: 'Crear Nuevo Foro',
              child: const Icon(Icons.add, color: Colors.white),
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
              color: const Color(0xFFFFF0F6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.pink.shade100, width: 1.5),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline, color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Únete a la Comunidad!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para participar en los foros, publicar dudas y chatear con otras mamás y doctores, primero debes crear tu perfil social de la comunidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.4),
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
                          forumsProvider.loadGroups();
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

  Widget _buildForumsView() {
    final forumsProvider = context.watch<ForumsProvider>();
    final groups = forumsProvider.groups;

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
          title: 'No hay foros aún',
          description: 'Crea el primer foro para iniciar la conversación en comunidad.',
          action: ElevatedButton.icon(
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.add),
            label: const Text('Crear Foro'),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Foros y Grupos de Discusión',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1C1C1E)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final group = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(4),
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
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
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
            },
          ),
        ),
      ],
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final loginProvider = context.read<LoginProvider>();
    final forumsProvider = context.read<ForumsProvider>();
    final currentUserId = loginProvider.userId;
    if (currentUserId == null) return; // Sesión no disponible.

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
                    _refreshData();
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
            Icon(icon, size: 64, color: Colors.pink.shade100),
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

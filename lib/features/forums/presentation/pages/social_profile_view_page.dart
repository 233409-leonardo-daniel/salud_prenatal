import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../domain/entities/social_profile.dart';
import '../../domain/entities/forum_post.dart';
import '../providers/forums_provider.dart';
import 'post_detail_page.dart';

enum SocialProfileViewStatus { loading, success, error }

class SocialProfileViewPage extends StatefulWidget {
  final int userId;

  const SocialProfileViewPage({super.key, required this.userId});

  @override
  State<SocialProfileViewPage> createState() => _SocialProfileViewPageState();
}

class _SocialProfileViewPageState extends State<SocialProfileViewPage> {
  SocialProfile? _profile;
  UserEntity? _user;
  SocialProfileViewStatus _status = SocialProfileViewStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _status = SocialProfileViewStatus.loading;
      _error = null;
    });

    try {
      final forumsProvider = context.read<ForumsProvider>();
      final userProvider = context.read<UserProvider>();

      // Fetch general user profile (required)
      final user = await userProvider.fetchUserById(widget.userId);

      // Fetch forums social profile (optional, might not exist yet)
      SocialProfile? profile;
      try {
        profile = await forumsProvider.getProfileById(widget.userId);
      } catch (e) {
        debugPrint('Forums profile not found or failed to load for user ${widget.userId}: $e');
      }

      if (mounted) {
        setState(() {
          _user = user;
          _profile = profile;
          _status = SocialProfileViewStatus.success;
        });
      }

      // Timeline público: todas las publicaciones del usuario (incluye
      // grupo/anuncios). No bloquea la carga del perfil si falla.
      unawaited(forumsProvider.loadProfileTimeline(widget.userId));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _status = SocialProfileViewStatus.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final forumsProvider = context.watch<ForumsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Perfil de la Comunidad',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(isDark, forumsProvider),
      ),
    );
  }

  Widget _buildBody(bool isDark, ForumsProvider forumsProvider) {
    return switch (_status) {
      SocialProfileViewStatus.loading => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      SocialProfileViewStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar el perfil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      SocialProfileViewStatus.success => _buildContent(isDark, forumsProvider),
    };
  }

  Widget _buildContent(bool isDark, ForumsProvider forumsProvider) {
    if (_user == null) {
      return Center(
        child: Text(
          'Usuario no encontrado',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final isDoctor = _user!.role.toLowerCase() == 'doctor' || _user!.role.toLowerCase() == 'doctor(a)';
    final String roleLabel = isDoctor ? 'Médico / Especialista' : 'Paciente';
    final String nameToDisplay = _user!.fullName;
    final String aliasToDisplay = _profile?.alias ?? _user!.fullName;
    final String initial = nameToDisplay.isNotEmpty ? nameToDisplay[0].toUpperCase() : 'U';
    final String? officeAddress = (_profile?.officeAddress != null && _profile!.officeAddress!.trim().isNotEmpty)
        ? _profile!.officeAddress
        : _user!.office;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
                      ? NetworkImage(_profile!.avatarUrl!)
                      : null,
                  child: _profile?.avatarUrl == null || _profile!.avatarUrl!.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                // Alias / Nickname
                Text(
                  aliasToDisplay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDoctor ? const Color(0xFF6A5ACD).withOpacity(0.12) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDoctor ? const Color(0xFF6A5ACD) : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Biography Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Biografía',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _profile?.bio != null && _profile!.bio!.trim().isNotEmpty
                      ? _profile!.bio!
                      : 'Este usuario aún no ha escrito una biografía.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                    fontStyle: _profile?.bio == null || _profile!.bio!.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // General Info Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos Personales',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Nombre completo',
                  value: nameToDisplay,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  value: _user!.email,
                ),
                if (_user!.phoneNumber != null && _user!.phoneNumber!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono de contacto',
                    value: _user!.phoneNumber!,
                  ),
                ],
              ],
            ),
          ),

          // Doctor Specific Details (Office & Specialty)
          if (isDoctor) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Profesional',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_user!.specialty != null && _user!.specialty!.trim().isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.medical_services_outlined,
                      label: 'Especialidad médica',
                      value: _user!.specialty!,
                    ),
                    const Divider(height: 24),
                  ],
                  if (_user!.professionalLicense != null && _user!.professionalLicense!.trim().isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Cédula profesional',
                      value: _user!.professionalLicense!,
                    ),
                    const Divider(height: 24),
                  ],
                  if (officeAddress != null && officeAddress.trim().isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Dirección del consultorio',
                      value: officeAddress,
                    ),
                ],
              ),
            ),
          ],

          // Publicaciones del usuario (GET /forums/profiles/{user_id}/timeline).
          const SizedBox(height: 20),
          _buildPostsSection(isDark, forumsProvider, isDoctor),
        ],
      ),
    );
  }

  Widget _buildPostsSection(bool isDark, ForumsProvider forumsProvider, bool isDoctor) {
    final posts = forumsProvider.timeline?.posts ?? [];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Publicaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (forumsProvider.isTimelineLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (posts.isEmpty)
            Text(
              'Este usuario aún no tiene publicaciones.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            ...posts.map((post) => _buildPostRow(post, isDoctor)),
        ],
      ),
    );
  }

  Widget _buildPostRow(ForumPost post, bool isDoctor) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDoctor)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Anuncio',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              post.content,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

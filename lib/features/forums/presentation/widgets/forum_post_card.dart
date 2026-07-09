import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/relative_time.dart';
import '../../domain/entities/forum_post.dart';

/// Tarjeta de publicación reutilizada en el feed "Para ti" y en el feed de
/// un grupo. Si `post.isAd` es true (siempre que el autor sea doctor, se
/// asigna automático al crear el post) se renderiza como tarjeta "De un
/// doctor" (estilo distinto, sello), igual que un post patrocinado en
/// Facebook: mismo layout, pero con acento ámbar y la etiqueta en vez de la
/// fecha. No se usa la palabra "Publicidad": es contenido propio de un
/// doctor, no un anuncio de terceros.
class ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;

  const ForumPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAd = post.isAd;
    final authorName = post.authorAlias ?? (isAd ? 'Consultorio' : 'Usuario');
    final isDoctor = post.authorRole?.toLowerCase().contains('doctor') ?? false;
    final displayName = isDoctor ? 'Dr. $authorName' : authorName;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    final accentColor = isAd ? const Color(0xFFB07C1F) : AppColors.primary;
    final cardColor = isAd
        ? (AppColors.isDarkMode ? const Color(0xFF2A2410) : const Color(0xFFFFF8E8))
        : AppColors.cardBackground;
    final borderColor = isAd ? const Color(0xFFF0C36D).withOpacity(0.6) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAd ? const Color(0xFFF0C36D).withOpacity(0.3) : AppColors.primaryLight,
                    backgroundImage: post.authorAvatarUrl != null ? NetworkImage(post.authorAvatarUrl!) : null,
                    child: post.authorAvatarUrl == null
                        ? Text(initials, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                              ),
                            ),
                            if (isDoctor && !isAd) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Doctor',
                                  style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
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
                            formatRelativeTime(post.createdAt),
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
              if (isAd)
                Row(
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      'Ver más',
                      style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Ver comentarios',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

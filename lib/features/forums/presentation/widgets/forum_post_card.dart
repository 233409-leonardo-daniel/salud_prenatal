import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/relative_time.dart';
import '../../domain/entities/forum_post.dart';

/// Tarjeta de publicación reutilizada en el feed "Para ti", el feed de un
/// grupo y el feed global. El estilo "De un doctor" (acento rosa, sello e
/// icono de altavoz en vez de la fecha) se aplica a TODAS las publicaciones
/// cuyo autor sea doctor, sin importar el valor guardado de `post.isAd`
/// (ese campo se fija solo al crear el post — publicaciones antiguas
/// creadas antes de esta regla podían quedar con `is_ad = false` aunque su
/// autor sea doctor, lo que hacía que se vieran inconsistentes entre sí).
/// Al derivar el estilo del rol del autor en vez de leer `is_ad`, todas las
/// publicaciones de un mismo doctor se ven igual.
class ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;

  const ForumPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDoctor = post.authorRole?.toLowerCase().contains('doctor') ?? false;
    final isAd = isDoctor;
    final authorName = post.authorAlias ?? (isAd ? 'Consultorio' : 'Usuario');
    final displayName = isDoctor ? 'Dr. $authorName' : authorName;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    final accentColor = AppColors.primary;
    final cardColor = isAd ? AppColors.primaryLight : AppColors.cardBackground;
    final borderColor = isAd ? AppColors.primary.withOpacity(0.35) : Colors.transparent;

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
                    backgroundColor: AppColors.primaryLight,
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

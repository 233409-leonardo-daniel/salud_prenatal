import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/relative_time.dart';
import '../../domain/entities/forum_post.dart';

/// Tarjeta de publicación reutilizada en el feed "Para ti", el feed de un
/// grupo y el feed global. TODA publicación cuyo autor sea médico se muestra
/// con el estilo rosa y el sello "De un doctor" (según el rol del autor). Las
/// que además son anuncios (`post.isAd == true`, solo activable por un médico
/// premium) llevan encima la etiqueta "Anuncio" y el pie "Ver más".
class ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;

  const ForumPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDoctor = post.authorRole?.toLowerCase().contains('doctor') ?? false;
    // TODA publicación de un médico se muestra en rosa con el sello "De un
    // doctor". Las que además son anuncios (is_ad) llevan la etiqueta
    // "Anuncio" y el pie "Ver más".
    final isDoctorPost = isDoctor;
    final isAdPost = post.isAd;
    final authorName = post.authorAlias ?? (isDoctorPost ? 'Consultorio' : 'Usuario');
    final displayName = isDoctor ? 'Dr. $authorName' : authorName;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    final accentColor = AppColors.primary;
    final cardColor = isDoctorPost ? AppColors.primaryLight : AppColors.cardBackground;
    final borderColor = isDoctorPost ? AppColors.primary.withOpacity(0.35) : Colors.transparent;

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
                        if (isDoctorPost)
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
                  // Etiqueta pequeña "Anuncio" para posts marcados como aviso
                  // (is_ad real, no derivado del rol del autor).
                  if (post.isAd) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.campaign, size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Anuncio',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              if (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post.imageUrl!.trim(),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 180,
                            alignment: Alignment.center,
                            color: AppColors.primaryLight,
                            child: const CircularProgressIndicator(),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (isAdPost)
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

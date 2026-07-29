import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Tarjeta que muestra la recepcionista asignada al doctor (o un estado
/// vacío si aún no tiene una).
class ReceptionistInfoCard extends StatelessWidget {
  final List<dynamic> receptionists;

  const ReceptionistInfoCard({super.key, required this.receptionists});

  @override
  Widget build(BuildContext context) {
    final bool has = receptionists.isNotEmpty;
    final Map<String, dynamic>? r =
        has ? Map<String, dynamic>.from(receptionists.first as Map) : null;
    final String name = r == null
        ? ''
        : '${r['name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
    final String email = r?['email']?.toString() ?? '';
    final String initials = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    final String extra =
        receptionists.length > 1 ? ' (+${receptionists.length - 1} más)' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: has
                ? Text(
                    initials,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  )
                : Icon(Icons.support_agent_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Mi Recepcionista$extra',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  has ? name : 'Aún no tienes recepcionista asignada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (has && email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

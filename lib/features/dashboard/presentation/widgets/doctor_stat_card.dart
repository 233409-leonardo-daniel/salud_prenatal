import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Tarjeta de estadística corta del dashboard del doctor (ícono + título +
/// número grande).
class DoctorStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const DoctorStatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

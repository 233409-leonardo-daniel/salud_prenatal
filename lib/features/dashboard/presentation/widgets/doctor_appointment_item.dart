import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Fila de una cita en la lista de "Citas de hoy" del dashboard del doctor.
class DoctorAppointmentItem extends StatelessWidget {
  final String time;
  final String name;
  final String subtitle;
  final bool isUrgent;
  final VoidCallback? onTap;

  const DoctorAppointmentItem({
    super.key,
    required this.time,
    required this.name,
    required this.subtitle,
    required this.isUrgent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        color: AppColors.cardBackground,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time.split(' ')[0],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    time.split(' ')[1],
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: AppColors.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.pink.shade50,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUrgent ? Colors.red.shade700 : AppColors.textMuted,
                      fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

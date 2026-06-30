import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_status_chip.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDate(appointment.dateTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                AppointmentStatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Paciente: ${appointment.patientName}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Médico: ${appointment.doctorName}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
            if (appointment.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appointment.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

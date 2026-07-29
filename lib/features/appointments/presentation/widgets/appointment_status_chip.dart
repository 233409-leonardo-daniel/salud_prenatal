import 'package:flutter/material.dart';
import '../../domain/entities/appointment.dart';

class AppointmentStatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const AppointmentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case AppointmentStatus.pending:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case AppointmentStatus.confirmed:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case AppointmentStatus.cancelled:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

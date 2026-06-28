enum AppointmentStatus {
  pending,
  confirmed,
  in_progress,
  completed,
  cancelled
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.in_progress:
        return 'in_progress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
    }
  }

  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'in_progress':
        return AppointmentStatus.in_progress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'pending':
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.in_progress:
        return 'En curso';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
    }
  }
}

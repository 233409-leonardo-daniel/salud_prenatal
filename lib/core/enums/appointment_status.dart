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
        return 'pendiente';
      case AppointmentStatus.confirmed:
        return 'confirmada';
      case AppointmentStatus.in_progress:
        return 'en_curso';
      case AppointmentStatus.completed:
        return 'completada';
      case AppointmentStatus.cancelled:
        return 'cancelada';
    }
  }

  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada':
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'en_curso':
      case 'in_progress':
        return AppointmentStatus.in_progress;
      case 'completada':
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelada':
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'pendiente':
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

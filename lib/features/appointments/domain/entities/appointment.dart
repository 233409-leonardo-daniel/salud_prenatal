// Estados soportados por el backend (app/core/enums.py -> AppointmentStatusEnum).
// No incluye "en curso" ni "completada": el backend no los acepta y rechaza
// el PUT con 422 si se envían.
enum AppointmentStatus {
  pending,
  confirmed,
  cancelled
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pendiente';
      case AppointmentStatus.confirmed:
        return 'confirmada';
      case AppointmentStatus.cancelled:
        return 'cancelada';
    }
  }

  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada':
      case 'confirmed':
        return AppointmentStatus.confirmed;
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
      case AppointmentStatus.cancelled:
        return 'Cancelada';
    }
  }
}

class Appointment {
  final int id;
  final int doctorId;
  final int patientId;
  final String doctorName;
  final String patientName;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String reason;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.doctorName = '',
    this.patientName = '',
    required this.dateTime,
    this.status = AppointmentStatus.pending,
    required this.reason,
  });
}

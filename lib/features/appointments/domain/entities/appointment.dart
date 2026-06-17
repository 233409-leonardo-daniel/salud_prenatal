enum AppointmentStatus { pending, completed, cancelled }

class Appointment {
  final String id;
  final String doctorName;
  final String patientName;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String reason;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.patientName,
    required this.dateTime,
    this.status = AppointmentStatus.pending,
    required this.reason,
  });
}

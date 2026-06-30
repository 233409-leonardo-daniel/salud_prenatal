import '../../../../core/enums/appointment_status.dart';

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

import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  AppointmentModel({
    required super.id,
    required super.doctorName,
    required super.patientName,
    required super.dateTime,
    super.status = AppointmentStatus.pending,
    required super.reason,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();
    AppointmentStatus statusVal = AppointmentStatus.pending;
    if (rawStatus == 'completada' || rawStatus == 'completed') {
      statusVal = AppointmentStatus.completed;
    } else if (rawStatus == 'cancelada' || rawStatus == 'cancelled') {
      statusVal = AppointmentStatus.cancelled;
    }

    return AppointmentModel(
      id: (json['appointment_id'] ?? json['id'] ?? '').toString(),
      doctorName: (json['doctorName'] ?? json['doctor_id'] ?? '').toString(),
      patientName: (json['patientName'] ?? json['patient_id'] ?? '').toString(),
      dateTime: DateTime.parse(json['appointment_date'] ?? json['dateTime'] ?? DateTime.now().toIso8601String()),
      status: statusVal,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr = 'pendiente';
    if (status == AppointmentStatus.completed) {
      statusStr = 'completada';
    } else if (status == AppointmentStatus.cancelled) {
      statusStr = 'cancelada';
    }

    return {
      'appointment_id': int.tryParse(id) ?? 0,
      'status': statusStr,
      'reason': reason,
      'appointment_date': dateTime.toIso8601String(),
    };
  }
}

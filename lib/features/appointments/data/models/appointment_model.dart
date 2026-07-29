import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  AppointmentModel({
    required super.id,
    required super.doctorId,
    required super.patientId,
    super.doctorName = '',
    super.patientName = '',
    required super.dateTime,
    super.status = AppointmentStatus.pending,
    required super.reason,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();
    final statusVal = AppointmentStatusExtension.fromString(rawStatus);

    return AppointmentModel(
      id: (json['appointment_id'] ?? json['id'] ?? 0) is int
          ? (json['appointment_id'] ?? json['id'] ?? 0) as int
          : int.tryParse((json['appointment_id'] ?? json['id'] ?? '0').toString()) ?? 0,
      doctorId: (json['doctor_id'] ?? 0) is int
          ? json['doctor_id'] ?? 0
          : int.tryParse(json['doctor_id'].toString()) ?? 0,
      patientId: (json['patient_id'] ?? 0) is int
          ? json['patient_id'] ?? 0
          : int.tryParse(json['patient_id'].toString()) ?? 0,
      doctorName: (json['doctorName'] ?? json['doctor_name'] ?? '').toString(),
      patientName: (json['patientName'] ?? json['patient_name'] ?? '').toString(),
      dateTime: DateTime.tryParse(json['appointment_date'] ?? json['dateTime'] ?? '') ?? DateTime.now(),
      status: statusVal,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'status': status.value,
      'reason': reason,
      'appointment_date': dateTime.toIso8601String(),
    };
  }
}

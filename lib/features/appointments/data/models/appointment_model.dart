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
    return AppointmentModel(
      id: json['id'],
      doctorName: json['doctorName'],
      patientName: json['patientName'],
      dateTime: DateTime.parse(json['dateTime']),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'patientName': patientName,
      'dateTime': dateTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'reason': reason,
    };
  }
}

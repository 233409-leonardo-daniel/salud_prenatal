class AppointmentDto {
  final int id;
  final int doctorId;
  final int patientId;
  final String date;
  final String status;
  final String reason;

  const AppointmentDto({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.date,
    required this.status,
    required this.reason,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: json['appointment_id'] ?? json['id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      date: json['appointment_date'] ?? json['dateTime'] ?? DateTime.now().toIso8601String(),
      status: json['status'] ?? 'pending',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'appointment_date': date,
      'status': status,
      'reason': reason,
    };
  }
}

class StatusUpdateDto {
  final String status;

  const StatusUpdateDto({required this.status});

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}

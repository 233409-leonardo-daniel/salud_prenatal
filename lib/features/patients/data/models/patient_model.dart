import '../../domain/entities/patient.dart';

class PatientModel extends PatientEntity {
  PatientModel({
    required super.patientId,
    required super.userId,
    required super.dateOfBirth,
    required super.age,
    super.currentGestationalWeeks,
    required super.bloodType,
    super.risk,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    // Some basic parsing. The risk might be returned by API or calculated. We default to 'Bajo Riesgo' and calculate later if needed.
    return PatientModel(
      patientId: json['patient_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      age: json['age'] ?? 0,
      currentGestationalWeeks: json['current_gestational_weeks'],
      bloodType: json['blood_type']?.toString() ?? 'No especificado',
      risk: json['risk']?.toString() ?? 'Bajo Riesgo', // Optional, will be overridden by UI mock logic if missing
    );
  }
}

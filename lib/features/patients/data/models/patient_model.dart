import '../../domain/entities/patient.dart';

class PatientModel extends PatientEntity {
  PatientModel({
    required super.patientId,
    required super.userId,
    super.doctorId,
    required super.birthdate,
    super.age,
    super.fullName,
    super.currentGestationalWeeks,
  });

  // GET /doctors/{id}/patients vuelve a traer full_name y
  // current_gestational_weeks (resuelto por el backend contra el expediente
  // del doctor). /patients/search sigue sin estos campos (no los manda), por
  // eso son opcionales aquí.
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patient_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      doctorId: json['doctor_id'] is int
          ? json['doctor_id'] as int
          : (json['doctor_id'] != null ? int.tryParse(json['doctor_id'].toString()) : null),
      birthdate: json['birthdate']?.toString() ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
      fullName: json['full_name']?.toString(),
      currentGestationalWeeks: json['current_gestational_weeks'] is int
          ? json['current_gestational_weeks'] as int
          : (json['current_gestational_weeks'] != null ? int.tryParse(json['current_gestational_weeks'].toString()) : null),
    );
  }
}

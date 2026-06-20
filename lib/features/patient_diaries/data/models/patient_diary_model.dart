import '../../domain/entities/patient_diary.dart';

class PatientDiaryModel extends PatientDiary {
  PatientDiaryModel({
    required super.patientDiaryId,
    required super.medicalRecordId,
    required super.weightKg,
    required super.systolic,
    required super.diastolic,
    required super.symptoms,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PatientDiaryModel.fromJson(Map<String, dynamic> json) {
    return PatientDiaryModel(
      patientDiaryId: json['patient_diary_id'] ?? 0,
      medicalRecordId: json['medical_record_id'] ?? 0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      systolic: json['systolic'] ?? 0,
      diastolic: json['diastolic'] ?? 0,
      symptoms: json['symptoms'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medical_record_id': medicalRecordId,
      'weight_kg': weightKg,
      'systolic': systolic,
      'diastolic': diastolic,
      'symptoms': symptoms,
      'notes': notes,
    };
  }
}

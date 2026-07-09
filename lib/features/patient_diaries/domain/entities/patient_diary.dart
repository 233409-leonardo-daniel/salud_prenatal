class PatientDiary {
  final int patientDiaryId;
  final int medicalRecordId;
  final double weightKg;
  final int systolic;
  final int diastolic;
  final String symptoms;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientDiary({
    required this.patientDiaryId,
    required this.medicalRecordId,
    required this.weightKg,
    required this.systolic,
    required this.diastolic,
    required this.symptoms,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

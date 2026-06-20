class PatientEntity {
  final int patientId;
  final int userId;
  final String dateOfBirth;
  final int age;
  final int? currentGestationalWeeks;
  final String bloodType;
  final String risk;

  PatientEntity({
    required this.patientId,
    required this.userId,
    required this.dateOfBirth,
    required this.age,
    this.currentGestationalWeeks,
    required this.bloodType,
    this.risk = 'Bajo Riesgo',
  });
}

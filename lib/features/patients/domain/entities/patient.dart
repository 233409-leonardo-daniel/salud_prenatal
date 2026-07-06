class PatientEntity {
  final int patientId;
  final int userId;
  final int? doctorId;
  final String birthdate;
  final int? age;
  final String? fullName;
  final int? currentGestationalWeeks;

  PatientEntity({
    required this.patientId,
    required this.userId,
    this.doctorId,
    required this.birthdate,
    this.age,
    this.fullName,
    this.currentGestationalWeeks,
  });
}

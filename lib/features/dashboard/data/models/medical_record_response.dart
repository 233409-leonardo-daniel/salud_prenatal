class MedicalRecordResponse {
  final int medicalRecordId;
  final int patientId;
  final int doctorId;
  final bool previousHypertension;
  final bool diabetes;
  final bool familyHistoryHypertension;
  final int previousPregnancies;
  final int previousDeliveries;
  final int previousMiscarriages;
  final int previousCesareans;
  final bool previousPreeclampsia;
  final bool chronicKidneyDisease;
  final bool chronicHypertension;
  final bool multiplePregnancy;
  final bool fetalDeath;
  final bool fetalGrowthRestriction;
  final bool familyHistoryHeartDisease;
  final bool activeSmoking;

  MedicalRecordResponse({
    required this.medicalRecordId,
    required this.patientId,
    required this.doctorId,
    required this.previousHypertension,
    required this.diabetes,
    required this.familyHistoryHypertension,
    required this.previousPregnancies,
    required this.previousDeliveries,
    required this.previousMiscarriages,
    required this.previousCesareans,
    required this.previousPreeclampsia,
    required this.chronicKidneyDisease,
    required this.chronicHypertension,
    required this.multiplePregnancy,
    required this.fetalDeath,
    required this.fetalGrowthRestriction,
    required this.familyHistoryHeartDisease,
    required this.activeSmoking,
  });

  factory MedicalRecordResponse.fromJson(Map<String, dynamic> json) {
    final recordJson = json['medical_record'] is Map<String, dynamic>
        ? json['medical_record'] as Map<String, dynamic>
        : json;

    return MedicalRecordResponse(
      medicalRecordId: recordJson['medical_record_id'] ?? 0,
      patientId: recordJson['patient_id'] ?? 0,
      doctorId: recordJson['doctor_id'] ?? 0,
      previousHypertension: recordJson['previous_hypertension'] ?? false,
      diabetes: recordJson['diabetes'] ?? false,
      familyHistoryHypertension: recordJson['family_history_hypertension'] ?? false,
      previousPregnancies: recordJson['previous_pregnancies'] is int
          ? recordJson['previous_pregnancies'] as int
          : (recordJson['previous_pregnancies'] == true ? 1 : 0),
      previousDeliveries: recordJson['previous_deliveries'] is int
          ? recordJson['previous_deliveries'] as int
          : (recordJson['previous_deliveries'] == true ? 1 : 0),
      previousMiscarriages: recordJson['previous_miscarriages'] is int
          ? recordJson['previous_miscarriages'] as int
          : (recordJson['previous_miscarriages'] == true ? 1 : 0),
      previousCesareans: recordJson['previous_cesareans'] is int
          ? recordJson['previous_cesareans'] as int
          : (recordJson['previous_cesareans'] == true ? 1 : 0),
      previousPreeclampsia: recordJson['previous_preeclampsia'] ?? false,
      chronicKidneyDisease: recordJson['chronic_kidney_disease'] ?? false,
      chronicHypertension: recordJson['chronic_hypertension'] ?? false,
      multiplePregnancy: recordJson['multiple_pregnancy'] ?? false,
      fetalDeath: recordJson['fetal_death'] ?? false,
      fetalGrowthRestriction: recordJson['fetal_growth_restriction'] ?? false,
      familyHistoryHeartDisease: recordJson['family_history_heart_disease'] ?? false,
      activeSmoking: recordJson['active_smoking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medical_record_id': medicalRecordId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'previous_hypertension': previousHypertension,
      'diabetes': diabetes,
      'family_history_hypertension': familyHistoryHypertension,
      'previous_pregnancies': previousPregnancies,
      'previous_deliveries': previousDeliveries,
      'previous_miscarriages': previousMiscarriages,
      'previous_cesareans': previousCesareans,
      'previous_preeclampsia': previousPreeclampsia,
      'chronic_kidney_disease': chronicKidneyDisease,
      'chronic_hypertension': chronicHypertension,
      'multiple_pregnancy': multiplePregnancy,
      'fetal_death': fetalDeath,
      'fetal_growth_restriction': fetalGrowthRestriction,
      'family_history_heart_disease': familyHistoryHeartDisease,
      'active_smoking': activeSmoking,
    };
  }
}

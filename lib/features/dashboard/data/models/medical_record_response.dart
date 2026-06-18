class MedicalRecordResponse {
  final int medicalRecordId;
  final int patientId;
  final bool previousHypertension;
  final bool diabetes;
  final bool familyHistoryHypertension;
  final bool previousPregnancies;
  final bool previousDeliveries;
  final bool previousMiscarriages;
  final bool previousCesareans;
  final bool previousPreeclampsia;
  final bool chronicKidneyDisease;
  final bool chronicHypertension;
  final bool multiplePregnancy;
  final bool fetalDeath;
  final bool fetalGrowthRestriction;
  final bool familyHistoryHeartDisease;

  MedicalRecordResponse({
    required this.medicalRecordId,
    required this.patientId,
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
  });

  factory MedicalRecordResponse.fromJson(Map<String, dynamic> json) {
    final recordJson = json['medical_record'] is Map<String, dynamic>
        ? json['medical_record'] as Map<String, dynamic>
        : json;

    return MedicalRecordResponse(
      medicalRecordId: recordJson['medical_record_id'] ?? 0,
      patientId: recordJson['patient_id'] ?? 0,
      previousHypertension: recordJson['previous_hypertension'] ?? false,
      diabetes: recordJson['diabetes'] ?? false,
      familyHistoryHypertension: recordJson['family_history_hypertension'] ?? false,
      previousPregnancies: recordJson['previous_pregnancies'] ?? false,
      previousDeliveries: recordJson['previous_deliveries'] ?? false,
      previousMiscarriages: recordJson['previous_miscarriages'] ?? false,
      previousCesareans: recordJson['previous_cesareans'] ?? false,
      previousPreeclampsia: recordJson['previous_preeclampsia'] ?? false,
      chronicKidneyDisease: recordJson['chronic_kidney_disease'] ?? false,
      chronicHypertension: recordJson['chronic_hypertension'] ?? false,
      multiplePregnancy: recordJson['multiple_pregnancy'] ?? false,
      fetalDeath: recordJson['fetal_death'] ?? false,
      fetalGrowthRestriction: recordJson['fetal_growth_restriction'] ?? false,
      familyHistoryHeartDisease: recordJson['family_history_heart_disease'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medical_record_id': medicalRecordId,
      'patient_id': patientId,
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
    };
  }
}

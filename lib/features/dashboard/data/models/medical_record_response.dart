import '../../../patient_diaries/domain/entities/aggregated_symptom.dart';
import '../../../patient_diaries/data/models/aggregated_symptom_model.dart';

/// Predicción de riesgo (preeclampsia) tal como la devuelve el expediente médico
/// (GET /medical-records/patient/{patient_id}) o la evaluación manual
/// (POST /medical-records/{id}/risk-evaluation).
///
/// OJO: las dos rutas usan una llave distinta para la versión del modelo:
/// el GET manda `model_version`, el POST manda `ml_model_version`. Aquí se
/// aceptan ambas para poder reusar esta misma clase en los dos casos.
class RiskPrediction {
  final String status; // ok | insufficient_data | ml_unavailable
  final Map<String, dynamic>? prediction;
  final List<String>? missingFields;
  final String? modelVersion;
  final DateTime? predictedAt;
  final bool stale;

  RiskPrediction({
    required this.status,
    this.prediction,
    this.missingFields,
    this.modelVersion,
    this.predictedAt,
    this.stale = false,
  });

  bool get isOk => status == 'ok';
  bool get isInsufficientData => status == 'insufficient_data';
  bool get isMlUnavailable => status == 'ml_unavailable';

  // Campos del payload crudo del ML (dentro de `prediction`). El modelo real
  // usa `diagnosis` / `risk_cluster` (no `cluster_name` / `cluster` como
  // sugería el ejemplo ilustrativo de la guía del backend).
  String? get diagnosis => prediction?['diagnosis']?.toString();
  int? get riskCluster {
    final v = prediction?['risk_cluster'];
    return v is int ? v : (v != null ? int.tryParse(v.toString()) : null);
  }

  String? get interpretation => prediction?['interpretation']?.toString();
  String? get explicacion => prediction?['explicacion']?.toString();
  bool get casoLimitrofe => prediction?['caso_limitrofe'] == true;

  /// Afinidad a cada perfil clínico, ej. {"Alto Riesgo Hipertensivo": 73.3}
  Map<String, double> get afinidad {
    final raw = prediction?['afinidad'];
    if (raw is! Map) return {};
    final result = <String, double>{};
    raw.forEach((key, value) {
      final parsed = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (parsed != null) result[key.toString()] = parsed;
    });
    return result;
  }

  /// Variables clínicas que más influyeron en la clasificación.
  List<Map<String, dynamic>> get factoresDeterminantes {
    final raw = prediction?['factores_determinantes'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Pacientes con perfil clínico similar usados de referencia por el modelo.
  List<Map<String, dynamic>> get pacientesSimilares {
    final raw = prediction?['pacientes_similares'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Recomendaciones clínicas SOMANZ — solo viene cuando el perfil calculado
  /// es "Alto Riesgo Hipertensivo / Preeclampsia" (risk_cluster: 1). Para
  /// cualquier otro perfil este campo es null; siempre tratarlo como
  /// opcional. Se expone como Map crudo (igual que `afinidad`/
  /// `factoresDeterminantes`) porque su forma ya viene lista para pintar
  /// directamente desde el backend.
  Map<String, dynamic>? get recomendaciones {
    final raw = prediction?['recomendaciones'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  factory RiskPrediction.fromJson(Map<String, dynamic> json) {
    final predictionMap = json['prediction'] is Map<String, dynamic> ? json['prediction'] as Map<String, dynamic> : null;
    return RiskPrediction(
      status: json['status']?.toString() ?? 'ok',
      prediction: predictionMap,
      missingFields: json['missing_fields'] is List
          ? (json['missing_fields'] as List).map((e) => e.toString()).toList()
          : null,
      modelVersion: (json['model_version'] ?? json['ml_model_version'] ?? predictionMap?['model_version'])?.toString(),
      predictedAt: json['predicted_at'] != null ? DateTime.tryParse(json['predicted_at'].toString()) : null,
      stale: json['stale'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'prediction': prediction,
      'missing_fields': missingFields,
      'model_version': modelVersion,
      'predicted_at': predictedAt?.toIso8601String(),
      'stale': stale,
    };
  }
}

class MedicalRecordResponse {
  final int medicalRecordId;
  final int patientId;
  final int doctorId;

  // Perfil clínico
  final String? bloodType;
  final int? weeksAtRegistration;
  final DateTime? lastMenstrualPeriod;
  final String? residence;
  final String? educationLevel;
  final String? maritalStatus;
  final int? heightCm;
  final double? initialWeight;
  final int? initialSystolic;
  final int? initialDiastolic;

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

  // Campos que vienen del endpoint de expediente por paciente
  // (GET /medical-records/patient/{patient_id})
  final int? userId;
  final String? name;
  final String? lastName;
  final int? currentGestationalWeeks;
  final int? age;
  final RiskPrediction? riskPrediction;

  /// Síntomas nuevos desde la última consulta registrada (misma forma que
  /// GET /patient-diaries/medical-record/{id}/symptoms). Si el expediente
  /// no tiene ninguna consulta todavía, trae TODO el historial. Lista
  /// vacía = nada nuevo que mostrar.
  final List<AggregatedSymptom> symptomAlert;

  MedicalRecordResponse({
    required this.medicalRecordId,
    required this.patientId,
    required this.doctorId,
    this.bloodType,
    this.weeksAtRegistration,
    this.lastMenstrualPeriod,
    this.residence,
    this.educationLevel,
    this.maritalStatus,
    this.heightCm,
    this.initialWeight,
    this.initialSystolic,
    this.initialDiastolic,
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
    this.userId,
    this.name,
    this.lastName,
    this.currentGestationalWeeks,
    this.age,
    this.riskPrediction,
    this.symptomAlert = const [],
  });

  factory MedicalRecordResponse.fromJson(Map<String, dynamic> json) {
    final recordJson = json['medical_record'] is Map<String, dynamic>
        ? json['medical_record'] as Map<String, dynamic>
        : json;

    final riskPredJson = json['risk_prediction'];
    final riskPrediction = riskPredJson is Map<String, dynamic>
        ? RiskPrediction.fromJson(riskPredJson)
        : null;

    final symptomAlertJson = json['symptom_alert'];
    final symptomAlert = symptomAlertJson is List
        ? symptomAlertJson
            .whereType<Map>()
            .map((e) => AggregatedSymptomModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AggregatedSymptom>[];

    int? parseInt(dynamic v) => v is int ? v : (v != null ? int.tryParse(v.toString()) : null);
    double? parseDouble(dynamic v) => v is num ? v.toDouble() : (v != null ? double.tryParse(v.toString()) : null);

    return MedicalRecordResponse(
      medicalRecordId: recordJson['medical_record_id'] ?? 0,
      patientId: recordJson['patient_id'] ?? 0,
      doctorId: recordJson['doctor_id'] ?? 0,
      bloodType: recordJson['blood_type']?.toString(),
      weeksAtRegistration: parseInt(recordJson['weeks_at_registration']),
      lastMenstrualPeriod: recordJson['last_menstrual_period'] != null
          ? DateTime.tryParse(recordJson['last_menstrual_period'].toString())
          : null,
      residence: recordJson['residence']?.toString(),
      educationLevel: recordJson['education_level']?.toString(),
      maritalStatus: recordJson['marital_status']?.toString(),
      heightCm: parseInt(recordJson['height_cm']),
      initialWeight: parseDouble(recordJson['initial_weight']),
      initialSystolic: parseInt(recordJson['initial_systolic']),
      initialDiastolic: parseInt(recordJson['initial_diastolic']),
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
      userId: parseInt(json['user_id']),
      name: json['name']?.toString(),
      lastName: json['last_name']?.toString(),
      currentGestationalWeeks: parseInt(json['current_gestational_weeks']),
      age: parseInt(json['age']),
      riskPrediction: riskPrediction,
      symptomAlert: symptomAlert,
    );
  }

  /// Devuelve una copia de este expediente con una nueva predicción de riesgo
  /// (usado tras llamar a POST /medical-records/{id}/risk-evaluation, para no
  /// tener que recargar todo el expediente solo para refrescar este campo).
  MedicalRecordResponse copyWithRiskPrediction(RiskPrediction riskPrediction) {
    return MedicalRecordResponse(
      medicalRecordId: medicalRecordId,
      patientId: patientId,
      doctorId: doctorId,
      bloodType: bloodType,
      weeksAtRegistration: weeksAtRegistration,
      lastMenstrualPeriod: lastMenstrualPeriod,
      residence: residence,
      educationLevel: educationLevel,
      maritalStatus: maritalStatus,
      heightCm: heightCm,
      initialWeight: initialWeight,
      initialSystolic: initialSystolic,
      initialDiastolic: initialDiastolic,
      previousHypertension: previousHypertension,
      diabetes: diabetes,
      familyHistoryHypertension: familyHistoryHypertension,
      previousPregnancies: previousPregnancies,
      previousDeliveries: previousDeliveries,
      previousMiscarriages: previousMiscarriages,
      previousCesareans: previousCesareans,
      previousPreeclampsia: previousPreeclampsia,
      chronicKidneyDisease: chronicKidneyDisease,
      chronicHypertension: chronicHypertension,
      multiplePregnancy: multiplePregnancy,
      fetalDeath: fetalDeath,
      fetalGrowthRestriction: fetalGrowthRestriction,
      familyHistoryHeartDisease: familyHistoryHeartDisease,
      activeSmoking: activeSmoking,
      userId: userId,
      name: name,
      lastName: lastName,
      currentGestationalWeeks: currentGestationalWeeks,
      age: age,
      riskPrediction: riskPrediction,
      symptomAlert: symptomAlert,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medical_record_id': medicalRecordId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'blood_type': bloodType,
      'weeks_at_registration': weeksAtRegistration,
      'last_menstrual_period': lastMenstrualPeriod?.toIso8601String(),
      'residence': residence,
      'education_level': educationLevel,
      'marital_status': maritalStatus,
      'height_cm': heightCm,
      'initial_weight': initialWeight,
      'initial_systolic': initialSystolic,
      'initial_diastolic': initialDiastolic,
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
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (lastName != null) 'last_name': lastName,
      if (currentGestationalWeeks != null) 'current_gestational_weeks': currentGestationalWeeks,
      if (age != null) 'age': age,
      if (riskPrediction != null) 'risk_prediction': riskPrediction!.toJson(),
    };
  }
}

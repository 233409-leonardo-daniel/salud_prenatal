/// Síntoma agregado por concepto clínico a lo largo del embarazo. Misma
/// forma usada en dos endpoints:
/// - GET /patient-diaries/medical-record/{medical_record_id}/symptoms
///   (historial completo)
/// - `symptom_alert` dentro de GET /medical-records/patient/{patient_id}
///   (solo lo nuevo desde la última consulta)
///
/// A diferencia de [ExtractedSymptom] (una sola bitácora), aquí `zones` es
/// una lista de códigos (String), no de objetos, y los síntomas negados ya
/// vienen excluidos por el backend.
class AggregatedSymptom {
  final String code;
  final String label;
  final int occurrences;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final bool alarm;
  final List<String> zones;

  AggregatedSymptom({
    required this.code,
    required this.label,
    required this.occurrences,
    this.firstSeen,
    this.lastSeen,
    this.alarm = false,
    this.zones = const [],
  });
}

import 'symptom_zone.dart';

/// Síntoma detectado por el NLP en UNA bitácora específica
/// (GET /patient-diaries/{patient_diary_id}/symptoms). Incluye detalle
/// crudo (raw_text, score) y negación — a diferencia de [AggregatedSymptom],
/// que ya viene resumido por el backend.
class ExtractedSymptom {
  final String code;
  final String label;
  final String? rawText;
  final bool negated;
  final double? score;
  final bool alarm;
  final List<SymptomZone> zones;

  ExtractedSymptom({
    required this.code,
    required this.label,
    this.rawText,
    this.negated = false,
    this.score,
    this.alarm = false,
    this.zones = const [],
  });
}

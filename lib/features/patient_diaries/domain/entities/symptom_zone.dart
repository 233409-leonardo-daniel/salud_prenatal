/// Zona corporal ligada a un síntoma detectado por el NLP dentro de UNA
/// bitácora (GET /patient-diaries/{id}/symptoms). Objeto completo, a
/// diferencia de [AggregatedSymptom.zones] que solo trae códigos (strings).
class SymptomZone {
  final String code;
  final String label;
  final String? rawText;
  final bool negated;
  final double? score;

  SymptomZone({
    required this.code,
    required this.label,
    this.rawText,
    this.negated = false,
    this.score,
  });
}

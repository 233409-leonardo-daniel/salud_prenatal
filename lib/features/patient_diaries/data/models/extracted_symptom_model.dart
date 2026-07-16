import '../../domain/entities/extracted_symptom.dart';
import '../../domain/entities/symptom_zone.dart';

class SymptomZoneModel extends SymptomZone {
  SymptomZoneModel({
    required super.code,
    required super.label,
    super.rawText,
    super.negated,
    super.score,
  });

  factory SymptomZoneModel.fromJson(Map<String, dynamic> json) {
    return SymptomZoneModel(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? json['code']?.toString() ?? '',
      rawText: json['raw_text']?.toString(),
      negated: json['negated'] == true,
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}

class ExtractedSymptomModel extends ExtractedSymptom {
  ExtractedSymptomModel({
    required super.code,
    required super.label,
    super.rawText,
    super.negated,
    super.score,
    super.alarm,
    super.zones,
  });

  factory ExtractedSymptomModel.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as List<dynamic>? ?? [];
    return ExtractedSymptomModel(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? json['code']?.toString() ?? '',
      rawText: json['raw_text']?.toString(),
      negated: json['negated'] == true,
      score: (json['score'] as num?)?.toDouble(),
      alarm: json['alarm'] == true,
      zones: zonesJson
          .whereType<Map>()
          .map((z) => SymptomZoneModel.fromJson(Map<String, dynamic>.from(z)))
          .toList(),
    );
  }
}

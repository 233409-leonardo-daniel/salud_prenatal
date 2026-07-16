import '../../domain/entities/aggregated_symptom.dart';

class AggregatedSymptomModel extends AggregatedSymptom {
  AggregatedSymptomModel({
    required super.code,
    required super.label,
    required super.occurrences,
    super.firstSeen,
    super.lastSeen,
    super.alarm,
    super.zones,
  });

  factory AggregatedSymptomModel.fromJson(Map<String, dynamic> json) {
    return AggregatedSymptomModel(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? json['code']?.toString() ?? '',
      occurrences: json['occurrences'] is int
          ? json['occurrences'] as int
          : int.tryParse(json['occurrences']?.toString() ?? '') ?? 0,
      firstSeen: json['first_seen'] != null ? DateTime.tryParse(json['first_seen'].toString()) : null,
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'].toString()) : null,
      alarm: json['alarm'] == true,
      zones: (json['zones'] as List<dynamic>? ?? []).map((z) => z.toString()).toList(),
    );
  }
}

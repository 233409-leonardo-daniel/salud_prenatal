class ConsultationResponse {
  final int consultationId;
  final int patientId;
  final String notes;
  final String objective;
  final String plan;
  final String reportedFacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConsultationResponse({
    required this.consultationId,
    required this.patientId,
    required this.notes,
    required this.objective,
    required this.plan,
    required this.reportedFacts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsultationResponse.fromJson(Map<String, dynamic> json) {
    return ConsultationResponse(
      consultationId: json['consultation_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      notes: json['notes'] ?? '',
      objective: json['objective'] ?? '',
      plan: json['plan'] ?? '',
      reportedFacts: json['reported_facts'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_id': consultationId,
      'patient_id': patientId,
      'notes': notes,
      'objective': objective,
      'plan': plan,
      'reported_facts': reportedFacts,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

import '../../domain/entities/unlink_request.dart';

class UnlinkRequestModel extends UnlinkRequestEntity {
  const UnlinkRequestModel({
    required super.unlinkRequestId,
    required super.patientId,
    required super.doctorId,
    required super.status,
    super.reason,
    super.createdAt,
    super.resolvedAt,
    super.patientFullName,
  });

  factory UnlinkRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return UnlinkRequestModel(
      unlinkRequestId: json['unlink_request_id'] as int,
      patientId: json['patient_id'] as int,
      doctorId: json['doctor_id'] as int,
      status: json['status']?.toString() ?? 'pending',
      reason: json['reason']?.toString(),
      createdAt: parseDate(json['created_at']),
      resolvedAt: parseDate(json['resolved_at']),
      patientFullName: json['patient_full_name']?.toString(),
    );
  }
}

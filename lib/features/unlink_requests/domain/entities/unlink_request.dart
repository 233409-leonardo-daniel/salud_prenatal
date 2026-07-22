/// Solicitud de una paciente para desvincularse de su doctor. El backend la
/// crea en estado 'pending' y el doctor la resuelve ('approved'/'rejected').
/// Solo al aprobarse se ejecuta la desvinculación real.
class UnlinkRequestEntity {
  final int unlinkRequestId;
  final int patientId;
  final int doctorId;
  final String status; // pending | approved | rejected | cancelled
  final String? reason;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? patientFullName; // solo viene resuelto en la bandeja del doctor

  const UnlinkRequestEntity({
    required this.unlinkRequestId,
    required this.patientId,
    required this.doctorId,
    required this.status,
    this.reason,
    this.createdAt,
    this.resolvedAt,
    this.patientFullName,
  });

  bool get isPending => status == 'pending';
}

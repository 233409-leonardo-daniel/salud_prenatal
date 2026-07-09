/// Entidad de dominio que representa una política aceptada por el usuario.
///
/// Vive en `domain/` para que tanto la capa de presentación de esta feature
/// como la de otras features (p. ej. `profile`) puedan depender de ella sin
/// tener que importar el modelo de la capa `data` (`AcceptedPolicyModel`),
/// que incluye detalles de serialización (`toJson`/`fromJson`) que no le
/// incumben a la UI.
class AcceptedPolicy {
  final String policyId;
  final String policyTitle;
  final String userEmail;
  final String acceptedAt;

  const AcceptedPolicy({
    required this.policyId,
    required this.policyTitle,
    required this.userEmail,
    required this.acceptedAt,
  });
}

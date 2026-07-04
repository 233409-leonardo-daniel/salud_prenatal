/// Representa a alguien con quien el usuario actual puede tener una
/// conversación (un paciente para un doctor/recepcionista, o el doctor
/// asignado para un paciente). El backend no expone un endpoint de "inbox",
/// así que la lista de conversaciones se construye a partir de contactos
/// reales conocidos (pacientes del doctor, doctor asignado del paciente),
/// nunca de datos inventados.
class ChatContact {
  final int userId;
  final String name;
  final String role;

  const ChatContact({
    required this.userId,
    required this.name,
    required this.role,
  });
}

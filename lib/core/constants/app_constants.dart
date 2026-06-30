class AppConstants {
  static const String rolePatient = 'paciente';
  static const String roleDoctor = 'doctor';
  static const String roleReceptionist = 'recepcionist';

  static const List<String> availableRoles = [
    rolePatient,
    roleDoctor,
    roleReceptionist,
  ];

  static const String apiUsersDoctors = '/users/doctors';
  static const String apiUsersPatients = '/users/patients';
  static const String apiAppointments = '/appointments';
  static const String apiChatConversations = '/chat/conversations';
  static const String apiChatMessage = '/chat/message';
  static const String apiChatHistory = '/chat/history';
  static const String apiChatWs = '/chat/ws';
}

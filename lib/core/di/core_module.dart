import '../services/qr_service.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';

class CoreModule {
  late final SessionManager sessionManager;
  late final ApiClient apiClient;
  late final QrService qrService;

  CoreModule() {
    // Orden de creación: SessionManager primero; ApiClient lo jala vía closure.
    sessionManager = SessionManager();
    apiClient = ApiClient(tokenProvider: () => sessionManager.token);
    qrService = QrServiceImpl();
  }
}

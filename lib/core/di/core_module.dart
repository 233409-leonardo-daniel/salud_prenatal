import '../services/qr_service.dart';
import '../network/api_client.dart';
import '../network/certificate_pinning.dart';
import '../session/session_manager.dart';

class CoreModule {
  late final SessionManager sessionManager;
  late final ApiClient apiClient;
  late final QrService qrService;

  CoreModule() {
    // Orden de creación: SessionManager primero; ApiClient lo jala vía closure.
    sessionManager = SessionManager();
    // Cliente HTTP con SSL/TLS pinning: solo confía en el certificado del
    // servidor de Salud Prenatal (ver certificate_pinning.dart).
    apiClient = ApiClient(
      client: createPinnedClient(),
      tokenProvider: () => sessionManager.token,
    );
    qrService = QrServiceImpl();
  }
}

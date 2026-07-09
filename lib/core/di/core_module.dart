import '../services/qr_service.dart';
import '../network/api_client.dart';

class CoreModule {
  late final QrService qrService;
  late final ApiClient apiClient;

  CoreModule() {
    qrService = QrServiceImpl();
    apiClient = ApiClient();
  }
}

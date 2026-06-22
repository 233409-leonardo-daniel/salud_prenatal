import '../services/qr_service.dart';

class CoreModule {
  late final QrService qrService;

  CoreModule() {
    qrService = QrServiceImpl();
  }
}

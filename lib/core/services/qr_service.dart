import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../presentation/pages/qr_scanner_page.dart';

abstract class QrService {
  Widget buildQrCode(String data, {double size = 200});
  Future<String?> scanQrCode(BuildContext context);
}

class QrServiceImpl implements QrService {
  @override
  Widget buildQrCode(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black87,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black87,
      ),
    );
  }

  @override
  Future<String?> scanQrCode(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerPage(),
      ),
    );
    return result;
  }
}

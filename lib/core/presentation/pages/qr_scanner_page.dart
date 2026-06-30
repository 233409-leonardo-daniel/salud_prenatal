import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/theme.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear QR de Vinculación', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  setState(() {
                    _isScanned = true;
                  });
                  Navigator.pop(context, barcode.rawValue);
                }
              }
            },
          ),
          // Overlay UI
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Apunta la cámara al código QR de tu médico',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanAreaSize = size.width * 0.7;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final innerPath = Path()..addRect(scanAreaRect);
    
    // Create a path that has a hole in the middle
    final finalPath = Path.combine(PathOperation.difference, path, innerPath);
    
    canvas.drawPath(finalPath, paint);
    
    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
      
    final cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(scanAreaRect.topLeft, scanAreaRect.topLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanAreaRect.topLeft, scanAreaRect.topLeft + Offset(0, cornerLength), cornerPaint);
    
    // Top Right
    canvas.drawLine(scanAreaRect.topRight, scanAreaRect.topRight - Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanAreaRect.topRight, scanAreaRect.topRight + Offset(0, cornerLength), cornerPaint);
    
    // Bottom Left
    canvas.drawLine(scanAreaRect.bottomLeft, scanAreaRect.bottomLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanAreaRect.bottomLeft, scanAreaRect.bottomLeft - Offset(0, cornerLength), cornerPaint);
    
    // Bottom Right
    canvas.drawLine(scanAreaRect.bottomRight, scanAreaRect.bottomRight - Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanAreaRect.bottomRight, scanAreaRect.bottomRight - Offset(0, cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

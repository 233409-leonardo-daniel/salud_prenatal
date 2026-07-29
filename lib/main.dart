import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.contains('Using AnnounceSemanticsEvent for accessibility is deprecated on Android')) {
      return;
    }
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  runApp(
    DevicePreview(
      enabled: kIsWeb, // Solo en web
      builder: (context) => const MyApp(),
    ),
  );
}


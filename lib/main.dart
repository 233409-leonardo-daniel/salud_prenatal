import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.contains('Using AnnounceSemanticsEvent for accessibility is deprecated on Android')) {
      return;
    }
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  runApp(const MyApp());
}

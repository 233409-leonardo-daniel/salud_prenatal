// Versión para WEB - sin dart:io
import 'package:http/http.dart' as http;

/// En web, no hay pinning (dart:io no existe)
dynamic createPinnedHttpClient() => null;

/// En web, retorna cliente HTTP normal
http.Client createPinnedClient() => http.Client();

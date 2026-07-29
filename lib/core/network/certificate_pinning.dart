// Import condicional: usa la versión correcta según la plataforma
export 'certificate_pinning_native.dart' if (dart.library.html) 'certificate_pinning_web.dart';

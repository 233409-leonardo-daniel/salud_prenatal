import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SSL/TLS pinning de Salud Prenatal.
///
/// Estrategia: se construye un [SecurityContext] que NO confía en las CAs del
/// sistema (`withTrustedRoots: false`) y al que se le agrega, como ÚNICA ancla
/// de confianza, el certificado del servidor (o su CA intermedia). Con esto,
/// cualquier certificado distinto —por ejemplo el que inyecta un proxy en un
/// ataque Man-in-the-Middle— hace fallar el handshake TLS y la petición se
/// aborta con una [HandshakeException].
///
/// Como todas las peticiones de la app pasan por un único `ApiClient`, este
/// cliente pineado se inyecta una sola vez desde `CoreModule` y protege TODA
/// la app (incluido el WebSocket del chat, que usa `createPinnedHttpClient`).
///
/// -------------------------------------------------------------------------
///  CÓMO OBTENER EL CERTIFICADO (pegar el resultado en [kPinnedServerCertPem]):
///
///  # 1) Descargar la cadena del servidor en formato PEM:
///  openssl s_client -connect saludprenatal.sytes.net:443 \
///    -servername saludprenatal.sytes.net -showcerts </dev/null \
///    2>/dev/null | openssl x509 -outform pem
///
///  # 2) (para el reporte) Huella SHA-256 del certificado:
///  openssl s_client -connect saludprenatal.sytes.net:443 \
///    -servername saludprenatal.sytes.net </dev/null 2>/dev/null \
///    | openssl x509 -noout -fingerprint -sha256
/// -------------------------------------------------------------------------

/// Certificado del servidor (o de su CA intermedia) contra el que se pinea.
/// Pega aquí la salida del comando (1). Puedes pegar la cadena completa
/// (hoja + intermedio); todos los bloques BEGIN/END CERTIFICATE se usan como
/// anclas de confianza.
/// Cadena pineada: certificado HOJA (saludprenatal.sytes.net) + intermedio
/// "Let's Encrypt YE2". Ambos son anclas de confianza, así que cuando la hoja
/// se renueve (~cada 90 días) el nuevo certificado seguirá validando contra el
/// intermedio (válido hasta 2028) y la app NO se romperá.
const String kPinnedServerCertPem = '''
-----BEGIN CERTIFICATE-----
MIIDnTCCAyOgAwIBAgISBd2umcP9DTCgy2WbFDXeXXKVMAoGCCqGSM49BAMDMDMx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQwwCgYDVQQDEwNZ
RTIwHhcNMjYwNjI2MDUzNjI1WhcNMjYwOTI0MDUzNjI0WjAiMSAwHgYDVQQDExdz
YWx1ZHByZW5hdGFsLnN5dGVzLm5ldDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IA
BIBUDRo8Psk5xG2c3+Ld/rPr9pJO+dS2bXWwYnhP43j6dJMHB1j1ElrgZ34TC2Du
tstMHo0vgfFUqNidYdCBe4SjggImMIICIjAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0l
BAwwCgYIKwYBBQUHAwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUXlRrahVrR+TK
9FmQBnp92k9Ks3swHwYDVR0jBBgwFoAUuVnyjs8i8IbTN0j/dhQYuoLYVYcwMwYI
KwYBBQUHAQEEJzAlMCMGCCsGAQUFBzAChhdodHRwOi8veWUyLmkubGVuY3Iub3Jn
LzAiBgNVHREEGzAZghdzYWx1ZHByZW5hdGFsLnN5dGVzLm5ldDATBgNVHSAEDDAK
MAgGBmeBDAECATAuBgNVHR8EJzAlMCOgIaAfhh1odHRwOi8veWUyLmMubGVuY3Iu
b3JnLzIyLmNybDCCAQ0GCisGAQQB1nkCBAIEgf4EgfsA+QB2ANdtfRDRp/V3wsfp
X9cAv/mCyTNaZeHQswFzF8DIxWl3AAABnwKjePUAAAQDAEcwRQIhAKPlKwlp2GsB
2psbnEZJAujPTOVWKNgAnSUE5UviP6C8AiATZakW5Wgb8eARmVm91919kfVb0/pu
DWFBZqiz+49AngB/ACbjZG5YaSEjvDQ/RyQ1mzeSzSRaiNgV05Mz/ZkYq0cjAAAB
nwKjd24ACAAABQAiS/39BAMASDBGAiEAiKGhcyCrEVwg/yxf8Ww6mOEAcDHbOKPa
GFSF2LcAglICIQCRQHuzVlDTZFjTwk4CHOcy2oZ32kOCW82NI+21Nk3ZvTAKBggq
hkjOPQQDAwNoADBlAjEA00dfCWTBOq12WytycvZaRdGX8xX6zIy7ev3Mzifehr9A
L2nAzIEy4KLFl5pbYrxCAjA+bIBps6fh2cMaFZ/qWcp2Cd31zB/Wzb0j4vRF5eSB
u/2G7ll8hVjA00hu2HrSoiE=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIICjDCCAhGgAwIBAgIQTfOxXdbAeExQfNN7WObxFTAKBggqhkjOPQQDAzAuMQsw
CQYDVQQGEwJVUzENMAsGA1UEChMESVNSRzEQMA4GA1UEAxMHUm9vdCBZRTAeFw0y
NTA5MDMwMDAwMDBaFw0yODA5MDIyMzU5NTlaMDMxCzAJBgNVBAYTAlVTMRYwFAYD
VQQKEw1MZXQncyBFbmNyeXB0MQwwCgYDVQQDEwNZRTIwdjAQBgcqhkjOPQIBBgUr
gQQAIgNiAARxmrQzkdbEEL3MqXt3dJQttYc47axkdDTHud5TPqM2z5uSD5cmk0Wr
HlWXvnlvqBLqiB34kluxIbmMyAiq3/YD6e80/vV259K8XQIdjFXloYOa0mIU71f7
HQ09PvYDlw+jge4wgeswDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUF
BwMBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLlZ8o7PIvCG0zdI/3YU
GLqC2FWHMB8GA1UdIwQYMBaAFKPIJlqOoUzQNWP8myPIOq5W809WMDIGCCsGAQUF
BwEBBCYwJDAiBggrBgEFBQcwAoYWaHR0cDovL3llLmkubGVuY3Iub3JnLzATBgNV
HSAEDDAKMAgGBmeBDAECATAnBgNVHR8EIDAeMBygGqAYhhZodHRwOi8veWUuYy5s
ZW5jci5vcmcvMAoGCCqGSM49BAMDA2kAMGYCMQDIcnw5dcZLN9ffynXnnkLD/itS
JEycJPb3sRkzeqBowup7vOsAwaqoCnNn/jh9wycCMQCJM6CPlaOC4pQYYbJtVPYb
DKrIb2EKk5NpOpE6/XttQYZV/3gilB9l+Cc/DOVwmyg=
-----END CERTIFICATE-----
''';

/// Huella SHA-256 del certificado hoja (para el reporte).
///   Obtenida con: openssl x509 -in chain.pem -noout -fingerprint -sha256
const String kPinnedSha256Fingerprint =
    'C9:14:E3:DB:93:C9:39:B0:12:D5:67:1D:8D:0C:61:38:11:11:63:FA:B3:1B:33:0E:C4:F8:FD:7C:30:2D:74:26';

/// `true` cuando ya se pegó un certificado real (no el placeholder).
bool get isPinningConfigured =>
    kPinnedServerCertPem.contains('BEGIN CERTIFICATE') &&
    !kPinnedServerCertPem.contains('PEGA_AQUI');

/// Crea un [HttpClient] (dart:io) que SOLO confía en el certificado pineado.
/// Se usa tanto para el cliente HTTP como para el WebSocket del chat.
HttpClient createPinnedHttpClient() {
  if (!isPinningConfigured) {
    // Fallback de desarrollo: mientras no se pegue el certificado real, la app
    // sigue funcionando con un cliente normal (sin pinning). Al pegar el PEM
    // en [kPinnedServerCertPem], el pinning se activa automáticamente.
    debugPrint(
      '[PINNING] Certificado no configurado: usando cliente SIN pinning. '
      'Pega el PEM real en kPinnedServerCertPem para activarlo.',
    );
    return HttpClient();
  }

  final context = SecurityContext(withTrustedRoots: false)
    ..setTrustedCertificatesBytes(utf8.encode(kPinnedServerCertPem));

  final client = HttpClient(context: context);

  // Solo se invoca cuando la validación contra el ancla pineada FALLA
  // (p. ej. un proxy presenta su propio certificado). Se registra la huella
  // del intruso —útil como evidencia en la PoC— y se RECHAZA la conexión.
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    debugPrint(
      '[PINNING] Certificado NO confiable en $host:$port. '
      'Sujeto: ${cert.subject}. SHA1: ${cert.sha1}. Conexión RECHAZADA.',
    );
    return false;
  };

  return client;
}

/// Cliente de `package:http` con pinning, listo para inyectar en `ApiClient`.
http.Client createPinnedClient() => IOClient(createPinnedHttpClient());

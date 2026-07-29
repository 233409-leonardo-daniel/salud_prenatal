// Versión para PLATAFORMAS NATIVAS (iOS, Android, Windows, macOS)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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

bool _isPinningConfigured() =>
    kPinnedServerCertPem.contains('BEGIN CERTIFICATE') &&
    !kPinnedServerCertPem.contains('PEGA_AQUI');

dynamic createPinnedHttpClient() {
  if (!_isPinningConfigured()) {
    debugPrint('[PINNING] Certificado no configurado: usando cliente SIN pinning.');
    return HttpClient();
  }
  final context = SecurityContext(withTrustedRoots: false)
    ..setTrustedCertificatesBytes(utf8.encode(kPinnedServerCertPem));
  final client = HttpClient(context: context);
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    debugPrint('[PINNING] Certificado rechazado en $host:$port');
    return false;
  };
  return client;
}

http.Client createPinnedClient() => IOClient(createPinnedHttpClient() as dynamic);

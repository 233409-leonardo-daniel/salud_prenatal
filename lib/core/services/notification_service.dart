import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';
import '../../app.dart';

/// Corre en un isolate propio: los `static` de [NotificationService] NO se
/// comparten con el isolate principal, por eso hay que re-inicializar Firebase
/// y el plugin local aquí dentro.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notificación recibida en segundo plano: ${message.messageId}");
  // Si el mensaje trae bloque `notification`, Android ya lo dibuja solo en
  // background; mostrarlo aquí lo duplicaría. Los data-only, en cambio, no
  // muestran NADA salvo que los dibujemos a mano.
  if (message.notification != null) return;
  await NotificationService.showNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'salud_prenatal_notifications', // id (debe coincidir con el default del manifest)
    'Notificaciones de Salud Prenatal', // name
    description: 'Canal para alertas de citas y avisos médicos.',
    importance: Importance.max,
  );

  static ApiClient? _apiClient;
  static String? _cachedToken;
  static bool _localPluginReady = false;

  /// Future de la inicialización en curso/completada. Se asigna de forma
  /// SÍNCRONA en [initialize], así que quien llame después puede hacer
  /// `await _initFuture` y tener la garantía de que `Firebase.initializeApp()`
  /// ya terminó. Antes esto no existía y [registerDevice] llamaba a
  /// `getToken()` mientras Firebase seguía inicializando: fallaba de forma
  /// intermitente y el dispositivo quedaba sin registrar.
  static Future<void>? _initFuture;

  /// Inicializa Firebase y los canales de notificación locales.
  /// Idempotente: llamadas repetidas devuelven el mismo Future.
  static Future<void> initialize(ApiClient apiClient) {
    _apiClient = apiClient;
    return _initFuture ??= _doInitialize();
  }

  static Future<void> _doInitialize() async {
    try {
      // 1. Inicializar Firebase Core
      await Firebase.initializeApp();

      // 2. Configurar manejador en segundo plano
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Plugin de notificaciones locales + canal
      await _ensureLocalPluginReady();

      // 4. Escuchar mensajes en primer plano (foreground).
      // En foreground Android NUNCA dibuja la notificación por su cuenta (ni
      // siquiera las que traen bloque `notification`), así que aquí se muestra
      // siempre.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Mensaje recibido en primer plano: ${message.messageId}");
        showNotification(message);
      });

      // 6. Escuchar clics en notificaciones cuando la app está abierta en segundo plano
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Notificación cliqueada (segundo plano): ${message.messageId}");
        _handleNotificationClick(jsonEncode(message.data));
      });

      // 6b. Cubre el caso en que la app estaba completamente cerrada y el
      // usuario la abrió tocando la notificación (onMessageOpenedApp no
      // cubre este caso, solo background).
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(jsonEncode(initialMessage.data));
      }

      // 7. Escuchar refresco del token
      FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
        debugPrint("FCM Token refrescado: $token");
        _cachedToken = token;
        _registerTokenOnServer(token);
      });

      debugPrint("NotificationService inicializado exitosamente.");
    } catch (e) {
      debugPrint("Error inicializando NotificationService: $e");
      // Se limpia para que un arranque fallido (ej. sin red) pueda reintentarse
      // en la siguiente llamada en vez de quedar cacheado como "ya inicializado".
      _initFuture = null;
      rethrow;
    }
  }

  /// Inicializa el plugin local + el canal. Idempotente y seguro de llamar
  /// desde el isolate de background (donde los `static` arrancan en cero).
  static Future<void> _ensureLocalPluginReady() async {
    if (_localPluginReady) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Clic en notificación local: ${response.payload}");
        _handleNotificationClick(response.payload);
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _localPluginReady = true;
  }

  /// Dibuja una notificación local a partir de un [RemoteMessage].
  ///
  /// Toma el título/cuerpo del bloque `notification` cuando viene, y si no
  /// (mensajes data-only, que Android no muestra por su cuenta) cae a los
  /// campos equivalentes de `data`.
  static Future<void> showNotification(RemoteMessage message) async {
    try {
      await _ensureLocalPluginReady();

      final data = message.data;
      final title = message.notification?.title ?? data['title'] ?? 'Salud Prenatal';
      final body = message.notification?.body ?? data['body'] ?? data['message'] ?? '';
      if (body.isEmpty) {
        debugPrint('Notificación sin cuerpo mostrable, se ignora: ${message.messageId}');
        return;
      }

      await _localNotificationsPlugin.show(
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error mostrando notificación local: $e');
    }
  }

  /// Solicita permisos de notificación al usuario (crucial en Android 13+).
  static Future<void> requestPermissions() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('Estado de permisos del usuario: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error solicitando permisos de notificación: $e');
    }
  }

  /// Obtiene el token de Firebase e intenta registrarlo en el backend.
  ///
  /// Espera a que [initialize] haya terminado: llamarlo antes hacía que
  /// `getToken()` corriera con Firebase a medio inicializar y lanzara, dejando
  /// el dispositivo sin registrar hasta el siguiente login.
  static Future<void> registerDevice() async {
    try {
      final init = _initFuture;
      if (init == null) {
        debugPrint('registerDevice() llamado antes de initialize(); se omite.');
        return;
      }
      await init;

      await requestPermissions();
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _cachedToken = token;
        debugPrint("FCM Token obtenido: $token");
        await _registerTokenOnServer(token);
      }
    } catch (e) {
      debugPrint("Error al registrar dispositivo para push: $e");
    }
  }

  /// Elimina el token del servidor al cerrar sesión.
  static Future<void> unregisterDevice() async {
    try {
      String? token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && _apiClient != null) {
        debugPrint("Desregistrando dispositivo del backend...");
        final response = await _apiClient!.post(
          '/notifications/unregister',
          {'token': token},
        );
        if (response.statusCode == 200) {
          debugPrint("FCM Token desregistrado del backend exitosamente.");
        } else {
          debugPrint("Error al desregistrar token en el backend: ${response.statusCode}");
        }
      }
      await FirebaseMessaging.instance.deleteToken();
      _cachedToken = null;
    } catch (e) {
      debugPrint("Error al desregistrar dispositivo: $e");
    }
  }

  /// Envía el token al backend FastAPI.
  static Future<void> _registerTokenOnServer(String token) async {
    if (_apiClient == null) return;
    try {
      debugPrint("Registrando token en el backend...");
      final response = await _apiClient!.post(
        '/notifications/register',
        {
          'token': token,
          'device_type': 'android',
        },
      );
      if (response.statusCode == 201) {
        debugPrint("FCM Token registrado en el backend exitosamente.");
      } else {
        debugPrint("Error al registrar token en el backend (Status: ${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Error de red registrando token en backend: $e");
    }
  }

  /// Maneja la acción al presionar una notificación. El payload es el
  /// `data` del mensaje FCM (ver `type` enviado por el backend: por ahora
  /// `chat_message` o `daily_reminder`).
  static void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    try {
      final context = MyApp.navigatorKey.currentContext;
      if (context == null) return;

      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (data['type'] == 'chat_message') {
        // Antes se hacía pushNamedAndRemoveUntil('/home') + push(ChatListPage):
        // eso dejaba la bandeja de chat como una ruta suelta ENCIMA del /home,
        // sin la barra de navegación inferior (el footer vive dentro del
        // Scaffold de DashboardPage). Ahora entramos a /home pidiéndole que abra
        // la pestaña de Mensajes, así el footer se conserva y el DashboardPage
        // resuelve el índice correcto según el rol.
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
          arguments: {'openChat': true},
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      debugPrint("Error manejando click de notificación: $e");
    }
  }
}

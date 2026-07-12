import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';
import '../../app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notificación recibida en segundo plano: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static ApiClient? _apiClient;
  static bool _initialized = false;
  static String? _cachedToken;

  /// Inicializa Firebase y los canales de notificación locales.
  static Future<void> initialize(ApiClient apiClient) async {
    if (_initialized) return;
    _apiClient = apiClient;

    try {
      // 1. Inicializar Firebase Core
      await Firebase.initializeApp();

      // 2. Configurar manejador en segundo plano
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Inicializar Notificaciones Locales (para foreground)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Clic en notificación local: ${response.payload}");
          _handleNotificationClick(response.payload);
        },
      );

      // 4. Crear canal por defecto para Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'salud_prenatal_notifications', // id
        'Notificaciones de Salud Prenatal', // name
        description: 'Canal para alertas de citas y avisos médicos.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Escuchar mensajes en primer plano (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Mensaje recibido en primer plano: ${message.notification?.title}");
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 6. Escuchar clics en notificaciones cuando la app está abierta en segundo plano
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Notificación cliqueada (segundo plano): ${message.messageId}");
        _handleNotificationClick(jsonEncode(message.data));
      });

      // 7. Escuchar refresco del token
      FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
        debugPrint("FCM Token refrescado: $token");
        _cachedToken = token;
        _registerTokenOnServer(token);
      });

      _initialized = true;
      debugPrint("NotificationService inicializado exitosamente.");
    } catch (e) {
      debugPrint("Error inicializando NotificationService: $e");
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
  static Future<void> registerDevice() async {
    try {
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

  /// Maneja la acción al presionar una notificación.
  static void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    try {
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      debugPrint("Error manejando click de notificación: $e");
    }
  }
}

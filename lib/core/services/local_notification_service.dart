// lib/core/services/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Para RemoteMessage

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Configuración de inicialización para Android
    // Reemplaza '@mipmap/ic_launcher' con el nombre de tu ícono de app si es diferente
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración de inicialización para iOS
    // Solicitar permisos en iOS se hace por separado con firebase_messaging
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // FCM se encarga de esto
      requestBadgePermission: false,
      requestSoundPermission: false,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Para iOS < 10
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // Para manejar taps en la notificación
    );
    print("LocalNotificationService: Inicializado.");
  }

  // static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  //   final String? payload = notificationResponse.payload;
  //   if (notificationResponse.payload != null) {
  //     print('notification payload: $payload');
  //     // Aquí puedes navegar a una pantalla específica basada en el payload
  //   }
  //   // Ejemplo: Navegar a una pantalla específica
  //   // await MyApp.navigatorKey.currentState?.pushNamed('/notification_details', arguments: payload);
  // }

  static Future<void> showNotificationFromFcm(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    AppleNotification? apple = message.notification?.apple; // Para iOS

    if (notification != null) {
      // Crear detalles de notificación específicos para cada plataforma
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'mediremind_dose_channel', // ID del canal (debe ser único)
        'Recordatorios de Dosis', // Nombre del canal visible al usuario
        channelDescription: 'Canal para recordatorios de dosis de medicamentos.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        // icon: android?.smallIcon, // Puedes usar el ícono de FCM o uno local
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true, // Mostrar alerta
        presentBadge: true, // Actualizar badge
        presentSound: true, // Reproducir sonido
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      print("LocalNotificationService: Mostrando notificación local: ${notification.title}");
      await _notificationsPlugin.show(
        notification.hashCode, // ID único para la notificación
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data['payload'] as String?, // Ejemplo de payload si lo envías
      );
    } else {
      print("LocalNotificationService: El mensaje FCM no contenía un objeto 'notification'.");
    }
  }
}

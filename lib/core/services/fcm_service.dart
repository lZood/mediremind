// lib/core/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mediremind/core/services/profile_service.dart';
import 'package:mediremind/core/services/local_notification_service.dart'; // Importar servicio local
import 'package:mediremind/core/models/user_profile.dart'; // Importa la clase UserProfile

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ProfileService _profileService = ProfileService();

  Future<void> initializeAndRequestPermission() async {
    print("FcmService: Inicializando y solicitando permisos FCM...");
    // Solicitar permisos (iOS y Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false, // false para pedir permiso explícito
      sound: true,
    );

    print('FcmService: Permiso FCM otorgado por el usuario: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FcmService: Permiso concedido. Obteniendo token...');
      await _getTokenAndSave();

      // Listener para cuando el token se actualiza
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print("FcmService: Token FCM actualizado: $newToken");
        await _saveTokenToSupabase(newToken);
      });

      // Listener para mensajes recibidos mientras la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('FcmService: Mensaje FCM recibido en primer plano!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print('Message notification: ${message.notification!.title} - ${message.notification!.body}');
          // Mostrar notificación local usando el servicio
          LocalNotificationService.showNotificationFromFcm(message);
        }
      });

      // Listener para cuando se toca una notificación y la app se abre desde segundo plano (no terminada)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('FcmService: Mensaje FCM abierto (app desde background): ${message.messageId}');
        // Aquí puedes navegar a una pantalla específica basada en message.data
        // Ejemplo: String? screen = message.data['screen_to_open'];
        // if (screen != null) { MyApp.navigatorKey.currentState?.pushNamed(screen); }
      });

    } else {
      print('FcmService: Usuario denegó o no ha aceptado permisos FCM.');
      // Aquí podrías mostrar un mensaje al usuario explicando por qué las notificaciones son importantes.
    }
  }

  Future<void> _getTokenAndSave() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("FcmService: Token FCM obtenido: $token");
        await _saveTokenToSupabase(token);
      } else {
        print("FcmService: No se pudo obtener el token FCM (es null).");
      }
    } catch (e) {
      print("FcmService: Error obteniendo token FCM: $e");
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      // Obtener el perfil actual para no sobrescribir otros datos
      UserProfile? currentProfile = await _profileService.getMyProfile();
      if (currentProfile != null && currentProfile.fcmToken == token) {
        print("FcmService: Token FCM ya está actualizado en Supabase.");
        return;
      }
      
      await _profileService.updateMyProfile({'fcm_token': token});
      print("FcmService: Token FCM guardado/actualizado en Supabase.");
    } catch (e) {
      print("FcmService: Error guardando token FCM en Supabase: $e");
    }
  }
}

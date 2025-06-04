// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/features/auth/screens/auth_gate.dart'; // Asegúrate que el path sea correcto
import 'package:flutter_localizations/flutter_localizations.dart';

// Importaciones de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Para el background handler
import 'firebase_options.dart'; // Archivo generado por FlutterFire CLI

// NUEVA IMPORTACIÓN para el servicio de notificaciones locales
import 'package:mediremind/core/services/local_notification_service.dart';


// Este handler DEBE ser una función de nivel superior (no dentro de una clase).
// También necesita la anotación @pragma('vm:entry-point') para asegurar que funcione
// correctamente cuando la app está terminada o en segundo plano.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Si estás usando otras dependencias de Firebase en el background,
  // puedes necesitar inicializar Firebase aquí también, aunque usualmente
  // la inicialización principal en main() es suficiente si se hace antes de runApp.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Descomentar si es necesario

  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}');
  }
  // Aquí puedes realizar tareas como actualizar un badge, guardar datos localmente, etc.
  // No interactúes con la UI directamente desde aquí ya que la app podría no estar activa.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para operaciones async antes de runApp

  // Inicializar Firebase ANTES que cualquier otra cosa que dependa de él
  try {
    print("Main: Inicializando Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Usa el archivo generado por FlutterFire
    );
    print("Main: Firebase inicializado correctamente.");

    // Configurar el handler para mensajes en segundo plano/terminado
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // NUEVO: Inicializar LocalNotificationService (para notificaciones en foreground)
    await LocalNotificationService.initialize();
    print("Main: LocalNotificationService inicializado.");

  } catch (e) {
    print('************************************************************');
    print('Error FATAL durante la inicialización de Firebase/LocalNotif en main.dart: $e');
    print('************************************************************');
    // Decide cómo manejar este error. Podría impedir que las notificaciones funcionen.
  }

  String? initialRouteError;
  try {
    print("Main: Cargando variables de entorno...");
    await dotenv.load(fileName: ".env");
    print("Main: Variables de entorno cargadas.");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception("SUPABASE_URL no encontrada en .env");
    }
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception("SUPABASE_ANON_KEY no encontrada en .env");
    }

    print("Main: Inicializando Supabase con URL: $supabaseUrl");
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print("Main: Supabase inicializado correctamente.");
  } catch (e) {
    print('************************************************************');
    print('Error FATAL durante la inicialización de Supabase en main.dart: $e');
    print('************************************************************');
    initialRouteError = "Error de inicialización: $e. Revise las credenciales de Supabase y el archivo .env.";
  }

  runApp(MyApp(initialError: initialRouteError));
}

// Helper para acceder al cliente de Supabase globalmente (opcional pero conveniente)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final String? initialError;
  const MyApp({super.key, this.initialError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRemind Paciente',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), // Para Material 3
        // useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), 
        Locale('es', 'MX'), 
      ],
      // locale: const Locale('es', 'MX'), // Opcional: establecer un locale por defecto
      home: initialError != null
          ? ErrorScreen(message: initialError!)
          : const AuthGate(),
    );
  }
}

// Widget simple para mostrar errores de inicialización
class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error al iniciar la aplicación:\n\n$message\n\nPor favor, verifica la consola de depuración para más detalles y reinicia la aplicación.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[900], fontSize: 16),
          ),
        ),
      ),
    );
  }
}

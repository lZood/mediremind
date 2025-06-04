// lib/features/auth/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'package:mediremind/features/auth/screens/initial_setup_check_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    print("AuthGate: Construyendo AuthGate...");
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print(
            'AuthGate Snapshot: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, error=${snapshot.error}, data=${snapshot.data}');

        // 1. Manejo de errores del Stream
        if (snapshot.hasError) {
          print('AuthGate Stream Error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error en el servicio de autenticación: ${snapshot.error}. Intenta reiniciar la app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        // 2. Estado de espera mientras se obtiene el primer evento del stream
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          print("AuthGate: Stream esperando datos iniciales...");
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Verificando sesión..."),
                ],
              ),
            ),
          );
        }

        // 3. Procesar el estado de autenticación una vez que tenemos datos
        final session = snapshot.data?.session;
        print("AuthGate: Sesión actual desde Stream: ${session?.user.id}");

        if (session != null) {
          print(
              "AuthGate: Sesión activa. Navegando a InitialSetupCheckScreen.");
          // Usuario autenticado, verificar si necesita configuración inicial
          return const InitialSetupCheckScreen(); // <--- Redirige aquí
        } else {
          print(
              "AuthGate: No hay sesión activa o sesión es null. Mostrando LoginScreen.");
          // Usuario no autenticado o sesión es null
          return const LoginScreen();
        }
      },
    );
  }
}

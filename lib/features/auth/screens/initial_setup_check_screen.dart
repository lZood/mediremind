// lib/features/auth/screens/initial_setup_check_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Para el signOut en caso de error

// import 'package:mediremind/core/models/user_profile.dart'; // Asegúrate que el path sea correcto
import 'package:mediremind/core/services/profile_service.dart'; // Asegúrate que el path sea correcto
import 'package:mediremind/features/home/screens/home_screen.dart'; // Asegúrate que el path sea correcto
import 'change_password_screen.dart'; // Asegúrate que el path sea correcto

class InitialSetupCheckScreen extends StatefulWidget {
  const InitialSetupCheckScreen({super.key});

  @override
  State<InitialSetupCheckScreen> createState() => _InitialSetupCheckScreenState();
}

class _InitialSetupCheckScreenState extends State<InitialSetupCheckScreen> {
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _checkInitialSetup();
  }

  Future<void> _checkInitialSetup() async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("InitialSetupCheckScreen: _checkInitialSetup - Iniciando obtención de perfil...");

    final profile = await _profileService.getMyProfile();
    if (!mounted) {
      print("InitialSetupCheckScreen: _checkInitialSetup - Widget desmontado antes de procesar perfil.");
      return;
    }

    if (profile != null) {
      print("InitialSetupCheckScreen: _checkInitialSetup - Perfil obtenido: ${profile.toJson()}"); // Imprime todo el perfil
      print("InitialSetupCheckScreen: _checkInitialSetup - Valor de profile.needsInitialSetup: ${profile.needsInitialSetup}");

      if (profile.needsInitialSetup == true) {
        print("InitialSetupCheckScreen: El usuario NECESITA configuración inicial. Navegando a ChangePasswordScreen.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
      } else { // Esto cubre needsInitialSetup == false y needsInitialSetup == null (si prefieres tratar null como "ya configurado")
        print("InitialSetupCheckScreen: El usuario NO necesita configuración inicial (o es null). Navegando a HomeScreen.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      print("InitialSetupCheckScreen: _checkInitialSetup - ERROR: Perfil es null después de llamar a _profileService.getMyProfile().");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error crítico: No se pudo cargar el perfil del usuario. Por favor, intenta iniciar sesión de nuevo.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      try {
        await Supabase.instance.client.auth.signOut();
        print("InitialSetupCheckScreen: _checkInitialSetup - Logout forzado debido a perfil nulo.");
      } catch (e) {
        print("InitialSetupCheckScreen: _checkInitialSetup - Error durante el logout forzado: $e");
      }
      // AuthGate debería recoger este cambio de estado y mostrar LoginScreen, no necesitas navegar explícitamente aquí.
    }
  }

  @override
  Widget build(BuildContext context) {
    print("InitialSetupCheckScreen: Construyendo UI de carga...");
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Verificando configuración de tu cuenta...",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// lib/core/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> signUpPatient({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final AuthResponse res = await _auth.signUp(
        email: email,
        password: password,
        data: { // raw_user_meta_data
          'name': name,
          'role': 'patient',
          'needs_initial_setup': true, // Asegurar que se pase o que el trigger lo ponga
        },
      );
      return res;
    } catch (e) {
      // ...
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res;
    } catch (e) {
      print('Error en signInWithPassword: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
      rethrow;
    }
  }

  // Podrías añadir una función para obtener el UserProfile de la tabla `profiles`
  // después del login/signup si no usas un gestor de estado global para ello.
}
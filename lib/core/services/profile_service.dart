// lib/core/services/profile_service.dart (Flutter)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/core/models/user_profile.dart'; // Asegúrate que el path sea correcto

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfile?> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("ProfileService: getMyProfile - Usuario no autenticado.");
      return null;
    }

    try {
      print("ProfileService: getMyProfile - Buscando perfil para usuario ID: ${user.id}");
      final response = await _supabase
          .from('profiles') // Nombre exacto de tu tabla de perfiles
          .select() // Selecciona todas las columnas, incluyendo 'needs_initial_setup'
          .eq('id', user.id)
          .maybeSingle(); // Usa maybeSingle() para manejar el caso de que no exista el perfil sin lanzar un error PostgrestException por "0 rows"

      if (response == null) {
        print("ProfileService: getMyProfile - No se encontró perfil para el usuario ID: ${user.id}");
        return null;
      }

      print("ProfileService: getMyProfile - Perfil encontrado: $response");
      return UserProfile.fromJson(response);
    } catch (e) {
      print('ProfileService: getMyProfile - Error buscando perfil: $e');
      // Puedes lanzar una excepción más específica o devolver null según prefieras
      // throw Exception('Error al obtener el perfil: ${e.toString()}');
      return null;
    }
  }

  Future<UserProfile?> updateMyProfile(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("ProfileService: updateMyProfile - Usuario no autenticado.");
      return null;
    }

    try {
      print("ProfileService: updateMyProfile - Actualizando perfil para ID: ${user.id} con datos: $data");
      final response = await _supabase
          .from('profiles')
          .update(data)
          .eq('id', user.id)
          .select() // Para obtener el registro actualizado
          .single(); // Asume que siempre se actualiza un solo registro

      print("ProfileService: updateMyProfile - Perfil actualizado: $response");
      return UserProfile.fromJson(response);
    } catch (e) {
      print('ProfileService: updateMyProfile - Error actualizando perfil: $e');
      return null;
    }
  }
}
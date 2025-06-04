// lib/core/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/core/models/user_profile.dart'; // Asegúrate que el path sea correcto

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _profilesTable = 'profiles';

  Future<UserProfile?> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("ProfileService: getMyProfile - Usuario no autenticado.");
      return null;
    }
    try {
      print("ProfileService: getMyProfile - Buscando perfil para usuario ID: ${user.id}");
      final response = await _supabase
          .from(_profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        print("ProfileService: getMyProfile - No se encontró perfil para el usuario ID: ${user.id}");
        return null;
      }
      print("ProfileService: getMyProfile - Perfil encontrado: $response");
      return UserProfile.fromJson(response);
    } catch (e) {
      print('ProfileService: getMyProfile - Error buscando perfil: $e');
      return null;
    }
  }

  Future<UserProfile?> updateMyProfile(Map<String, dynamic> dataToUpdate) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("ProfileService: updateMyProfile - Usuario no autenticado.");
      return null;
    }
    if (dataToUpdate.isEmpty) {
      print("ProfileService: updateMyProfile - No hay datos para actualizar.");
      return await getMyProfile(); // Devuelve el perfil actual si no hay nada que actualizar
    }

    // Asegurarse de que 'updated_at' se actualice si no está ya en dataToUpdate
    final Map<String, dynamic> updatePayload = {
      ...dataToUpdate,
      'updated_at': DateTime.now().toIso8601String(),
    };


    try {
      print("ProfileService: updateMyProfile - Actualizando perfil para ID: ${user.id} con datos: $updatePayload");
      final response = await _supabase
          .from(_profilesTable)
          .update(updatePayload) // Usar el payload con updated_at
          .eq('id', user.id)
          .select()
          .single();

      print("ProfileService: updateMyProfile - Perfil actualizado: $response");
      return UserProfile.fromJson(response);
    } catch (e) {
      print('ProfileService: updateMyProfile - Error actualizando perfil: $e');
      // Considera relanzar o manejar el error de forma más específica
      throw Exception("Error al actualizar el perfil: ${e.toString()}");
    }
  }
}

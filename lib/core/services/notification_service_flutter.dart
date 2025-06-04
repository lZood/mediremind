// lib/core/services/notification_service_flutter.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/core/models/notification_model_flutter.dart'; // Asegúrate que el path sea correcto

class NotificationServiceFlutter {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _notificationsTable = 'notifications';
  final String _patientsTable = 'patients'; // Para la vinculación

  Future<List<NotificationModel>> getMyNotificationsHistory() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print("NotificationServiceFlutter: Usuario no autenticado.");
      return [];
    }
    final String userAuthId = currentUser.id;

    try {
      // Asumimos que notifications.patient_id es el auth.uid del paciente
      // Si notifications.patient_id es el patients.id, necesitarás la lógica de 2 pasos
      print("NotificationServiceFlutter: Obteniendo historial de notificaciones para patient_id (auth.uid): $userAuthId");
      
      // Lógica de 2 pasos si notifications.patient_id es el patients.id
      final patientRecordResponse = await _supabase
          .from(_patientsTable)
          .select('id')
          .eq('user_id', userAuthId)
          .maybeSingle();

      if (patientRecordResponse == null || patientRecordResponse['id'] == null) {
        print("NotificationServiceFlutter: No se encontró registro en '$_patientsTable' para user_id: $userAuthId.");
        return [];
      }
      final String patientTableId = patientRecordResponse['id'] as String;
      print("NotificationServiceFlutter: '$_patientsTable.id' (patientTableId) encontrado: $patientTableId.");


      final response = await _supabase
          .from(_notificationsTable)
          .select() // Selecciona todas las columnas de notifications
          // MODIFICACIÓN: Filtrar por el patientTableId si notifications.patient_id es FK a patients.id
          .eq('patient_id', patientTableId) 
          // O, si notifications.patient_id es directamente el auth.uid:
          // .eq('patient_id', userAuthId) 
          .order('created_at', ascending: false) // Más recientes primero
          .limit(50); // Limitar para no cargar demasiadas

      final List<dynamic> responseData = response as List<dynamic>;
      print("NotificationServiceFlutter: Respuesta cruda de notificaciones (longitud: ${responseData.length}): $responseData");

      final notifications = responseData.map((data) {
        try {
          return NotificationModel.fromJson(data as Map<String, dynamic>);
        } catch (e, s) {
          print("NotificationServiceFlutter: Error parseando una notificación: $data, error: $e, stacktrace: $s");
          return null;
        }
      }).where((n) => n != null).cast<NotificationModel>().toList();

      print("NotificationServiceFlutter: Notificaciones obtenidas y parseadas: ${notifications.length}");
      return notifications;

    } catch (e, s) {
      print('NotificationServiceFlutter: Error GENERAL obteniendo historial de notificaciones: $e, stacktrace: $s');
      throw Exception('Error al obtener el historial de notificaciones: ${e.toString()}');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
     final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print("NotificationServiceFlutter: markNotificationAsRead - Usuario no autenticado.");
      throw Exception("Usuario no autenticado.");
    }
    try {
       await _supabase
        .from(_notificationsTable)
        .update({'status': 'read', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
        // Podrías añadir .eq('patient_id', currentUser.id) si patient_id en notifications es auth.uid
        // o una lógica más compleja si es patients.id, pero RLS debería manejar esto.
       print("NotificationServiceFlutter: Notificación $notificationId marcada como leída.");
    } catch (e) {
      print("NotificationServiceFlutter: Error marcando notificación como leída: $e");
      throw Exception("Error al actualizar notificación: ${e.toString()}");
    }
  }
}

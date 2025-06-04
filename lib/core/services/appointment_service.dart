// lib/core/services/appointment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/core/models/appointment.dart'; // Asegúrate que el path y el modelo sean correctos
import 'package:mediremind/core/models/user_profile.dart'; // Asegúrate que el path sea correcto para UserProfile
// Asumimos que tu modelo Appointment.dart puede parsear los datos del paciente y doctor anidados
// si los seleccionas en tus queries.

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _appointmentsTable = 'appointments';
  final String _patientsTable = 'patients';
  final String _profilesTable = 'profiles'; // Para los datos del doctor

  // Obtener todas las citas del paciente logueado
  Future<List<Appointment>> getMyAppointments() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print("AppointmentService: getMyAppointments - Usuario no autenticado.");
      return [];
    }
    final String userAuthId = currentUser.id;
    try {
      final patientRecordResponse = await _supabase
          .from(_patientsTable)
          .select('id')
          .eq('user_id', userAuthId)
          .maybeSingle();

      if (patientRecordResponse == null ||
          patientRecordResponse['id'] == null) {
        print(
          "AppointmentService: getMyAppointments - No se encontró registro en '$_patientsTable' para user_id: $userAuthId.",
        );
        return [];
      }
      final String patientTableId = patientRecordResponse['id'] as String;

      final response = await _supabase
          .from(_appointmentsTable)
          .select(
            // Selecciona todos los campos de appointments (*),
            // y explícitamente los campos necesarios de patients y profiles (doctores)
            '*, '
            'patients!inner(id, name, email, phone, address, created_at, doctor_id, user_id), ' // Asegúrate de incluir todos los campos que Patient.fromJson necesita
            'profiles!inner(id, name, specialty, email, role)',
          ) // Asumiendo que doctor_id en appointments referencia profiles.id
          .eq('patient_id', patientTableId)
          .order('date', ascending: false)
          .order('time', ascending: false);

      final List<dynamic> responseData = response as List<dynamic>;
      final appointments = responseData
          .map((data) {
            try {
              return Appointment.fromJson(data as Map<String, dynamic>);
            } catch (e, s) {
              print(
                "AppointmentService: getMyAppointments - Error parseando una cita: $data, error: $e, stacktrace: $s",
              );
              return null;
            }
          })
          .where((appt) => appt != null)
          .cast<Appointment>()
          .toList();
      return appointments;
    } catch (e, s) {
      print(
        'AppointmentService: getMyAppointments - Error GENERAL: $e, stacktrace: $s',
      );
      throw Exception('Error al obtener las citas: ${e.toString()}');
    }
  }

  Future<Appointment?> requestAppointment({
    required String doctorId,
    required String specialty,
    required String requestedDate,
    required String requestedTime,
    required String reasonForRequest,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print("AppointmentService: requestAppointment - Usuario no autenticado.");
      throw Exception("Usuario no autenticado para solicitar cita.");
    }
    final String userAuthId = currentUser.id;
    try {
      final patientRecordResponse = await _supabase
          .from(_patientsTable)
          .select('id')
          .eq('user_id', userAuthId)
          .maybeSingle();

      if (patientRecordResponse == null ||
          patientRecordResponse['id'] == null) {
        print(
          "AppointmentService: requestAppointment - No se encontró registro en '$_patientsTable' para user_id: $userAuthId.",
        );
        throw Exception(
          "Registro de paciente no encontrado para solicitar cita.",
        );
      }
      final String patientTableId = patientRecordResponse['id'];

      final Map<String, dynamic> dataToInsert = {
        'patient_id': patientTableId,
        'doctor_id': doctorId,
        'specialty': specialty,
        'requested_date': requestedDate,
        'requested_time': requestedTime,
        'date': requestedDate,
        'time': requestedTime,
        'reason_for_request': reasonForRequest,
        'status': 'requested_by_patient',
        'notificacion_recordatorio_24h_enviada': false,
      };
      print(
        "AppointmentService: requestAppointment - Intentando insertar solicitud: $dataToInsert",
      );

      final response = await _supabase
          .from(_appointmentsTable)
          .insert(dataToInsert)
          .select(
            // MODIFICACIÓN AQUÍ para asegurar que todos los campos de patients se traigan
            '*, '
            'patients!inner(id, name, email, phone, address, created_at, doctor_id, user_id), ' // Selecciona todos los campos necesarios de patients
            'profiles!inner(id, name, specialty, email, role)',
          ) // Asumiendo doctor_id referencia profiles.id
          .single();

      print(
        "AppointmentService: requestAppointment - Solicitud creada (respuesta cruda): $response",
      );
      // El error ocurre aquí si 'response' no tiene los campos que Patient.fromJson espera
      return Appointment.fromJson(response);
    } catch (e, s) {
      print(
        'AppointmentService: requestAppointment - Error: $e, stacktrace: $s',
      );
      if (e is PostgrestException) {
        print(
          'PostgrestException Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}',
        );
      }
      // No relanzar la excepción aquí permite que el flujo en RequestAppointmentScreen continúe
      // y muestre el SnackBar de error, pero no se devolverá una cita.
      // Si quieres que el error se propague para un manejo más global, usa: rethrow;
      return null; // Devuelve null en caso de error para que la UI lo maneje
    }
  }
  
  Future<List<UserProfile>> getAvailableDoctors() async {
      print("AppointmentService: getAvailableDoctors() - Iniciando...");
      try {
        final response = await _supabase
            .from('profiles') // Nombre exacto de tu tabla de perfiles
            .select() // Selecciona todas las columnas
            .eq('role', 'doctor'); // Filtra por rol 'doctor'

        // response es List<dynamic> que contiene Map<String, dynamic>
        final List<dynamic> responseData = response as List<dynamic>;
        print(
          "AppointmentService: getAvailableDoctors() - Respuesta cruda de Supabase (longitud: ${responseData.length}): $responseData",
        );

        if (responseData.isEmpty) {
          print(
            "AppointmentService: getAvailableDoctors() - No se encontraron perfiles con role='doctor'.",
          );
          return [];
        }

        final doctors = responseData
            .map((data) {
              try {
                print(
                  "AppointmentService: getAvailableDoctors() - Parseando doctor: $data",
                );
                return UserProfile.fromJson(data as Map<String, dynamic>);
              } catch (e, s) {
                print(
                  "AppointmentService: getAvailableDoctors() - ERROR parseando un perfil de doctor: $data, error: $e, stacktrace: $s",
                );
                return null; // Devuelve null si hay error de parseo para un doctor específico
              }
            })
            .where((doctor) => doctor != null)
            .cast<UserProfile>()
            .toList(); // Filtra los nulos y castea

        print(
          "AppointmentService: getAvailableDoctors() - Doctores parseados exitosamente: ${doctors.length}",
        );
        return doctors;
      } catch (e, s) {
        print(
          'AppointmentService: getAvailableDoctors() - Error GENERAL obteniendo doctores: $e',
        );
        print('Stacktrace: $s');
        if (e is PostgrestException) {
          print(
            'PostgrestException Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}',
          );
        }
        return []; // Devuelve lista vacía en caso de error
      }
    }

  // NUEVO MÉTODO PARA ELIMINAR FÍSICAMENTE UNA SOLICITUD DE CITA
      Future<void> deleteRequestedAppointment(String appointmentId) async {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) {
          print("AppointmentService: deleteRequestedAppointment - Usuario no autenticado.");
          throw Exception("Usuario no autenticado para eliminar solicitud de cita.");
        }

        try {
          print("AppointmentService: deleteRequestedAppointment - Intentando eliminar cita ID: $appointmentId");
          // La RLS se encargará de verificar si el paciente puede eliminar esta cita específica
          // (basado en que le pertenezca y el estado actual sea 'requested_by_patient').
          await _supabase
              .from(_appointmentsTable)
              .delete()
              .eq('id', appointmentId);
          
          print("AppointmentService: deleteRequestedAppointment - Solicitud de cita eliminada: $appointmentId");
          // No se devuelve nada porque la fila ya no existe.
        } catch (e, s) {
          print('AppointmentService: deleteRequestedAppointment - Error: $e, stacktrace: $s');
          if (e is PostgrestException) {
            print('PostgrestException Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}');
          }
          throw Exception('Error al eliminar la solicitud de cita: ${e.toString()}');
        }
      }
      
  Future<Appointment?> cancelAppointmentByPatient(String appointmentId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print(
        "AppointmentService: cancelAppointmentByPatient - Usuario no autenticado.",
      );
      throw Exception("Usuario no autenticado para cancelar cita.");
    }
    try {
      print(
        "AppointmentService: cancelAppointmentByPatient - Intentando cancelar cita ID: $appointmentId",
      );
      final response = await _supabase
          .from(_appointmentsTable)
          .update({'status': 'cancelled_by_patient'})
          .eq('id', appointmentId)
          .select(
            '*, '
            'patients!inner(id, name, email, phone, address, created_at, doctor_id, user_id), '
            'profiles!inner(id, name, specialty, email, role)',
          )
          .single();

      print(
        "AppointmentService: cancelAppointmentByPatient - Cita cancelada: $response",
      );
      return Appointment.fromJson(response);
    } catch (e, s) {
      print(
        'AppointmentService: cancelAppointmentByPatient - Error: $e, stacktrace: $s',
      );
      if (e is PostgrestException) {
        print(
          'PostgrestException Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}',
        );
      }
      return null;
    }

    
  }
}

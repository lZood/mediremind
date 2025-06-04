// lib/core/services/vital_sign_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/core/models/vital_sign.dart'; // Asegúrate que el path sea correcto

class VitalSignService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Ya no necesitamos _vitalSignsTable o _patientsTable para esta función específica

  Future<List<VitalSign>> getMyVitalSigns() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("VitalSignService: getMyVitalSigns - Usuario no autenticado.");
      return [];
    }

    final String userAuthId = user.id;
    print("VitalSignService: getMyVitalSigns - Llamando a RPC 'get_patient_vital_signs' con user_auth_id: $userAuthId");

    try {
      // Llama a la función de base de datos
      final response = await _supabase.rpc(
        'get_patient_vital_signs', // Nombre exacto de tu función PostgreSQL
        params: {'p_user_auth_id': userAuthId}, // Parámetros de la función
      );

      // El resultado de rpc() puede ser una List<dynamic> directamente si la función devuelve SETOF
      // o puede estar anidado dependiendo de la configuración.
      // Con SETOF, usualmente es una List<Map<String, dynamic>>.
      if (response == null) {
        print("VitalSignService: getMyVitalSigns - RPC devolvió null.");
        return [];
      }
      
      final List<dynamic> responseData = response as List<dynamic>;
      print("VitalSignService: getMyVitalSigns - Respuesta cruda de RPC (longitud: ${responseData.length}): $responseData");

      if (responseData.isEmpty) {
        print("VitalSignService: getMyVitalSigns - No se encontraron signos vitales para el usuario (vía RPC).");
      }

      final vitalSigns = responseData
          .map((data) {
            try {
              return VitalSign.fromJson(data as Map<String, dynamic>);
            } catch (e, s) {
              print("VitalSignService: getMyVitalSigns - Error parseando un signo vital desde RPC: $data, error: $e, stacktrace: $s");
              return null;
            }
          })
          .where((vs) => vs != null)
          .cast<VitalSign>()
          .toList();

      print("VitalSignService: getMyVitalSigns - Signos vitales obtenidos y parseados vía RPC: ${vitalSigns.length}");
      return vitalSigns;
    } catch (e, s) {
      print('VitalSignService: getMyVitalSigns - Error GENERAL llamando a RPC: $e, stacktrace: $s');
      if (e is PostgrestException) {
        print('PostgrestException Details: ${e.details}');
        print('PostgrestException Hint: ${e.hint}');
        print('PostgrestException Code: ${e.code}');
      }
      throw Exception('Error al obtener los signos vitales (RPC): ${e.toString()}');
    }
  }

  // Tu función recordVitalSign puede permanecer igual,
  // ya que para INSERTAR, la política RLS que creaste anteriormente (la que verifica el rol
  // y el enlace con la tabla patients) es la forma correcta de manejar la seguridad.
  // El SECURITY DEFINER es más común para lecturas controladas o lógicas complejas
  // que necesitan saltarse RLS de forma segura.

  Future<VitalSign?> recordVitalSign(Map<String, dynamic> vitalSignDataFromForm) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("VitalSignService: Usuario no autenticado.");
      throw Exception("Usuario no autenticado");
    }

    final String userAuthId = user.id;

    try {
      print("VitalSignService: Buscando patient record en 'patients' para user_id: $userAuthId");
      final patientRecordResponse = await _supabase
          .from('patients') // Usar el nombre de tabla directamente
          .select('id')
          .eq('user_id', userAuthId)
          .maybeSingle();

      if (patientRecordResponse == null) {
        print("VitalSignService: No se encontró un registro de paciente vinculado (user_id: $userAuthId). No se puede registrar el signo vital.");
        throw Exception("Registro de paciente no encontrado para el usuario actual.");
      }
      
      if (patientRecordResponse['id'] == null) {
         print("VitalSignService: Se encontró registro en 'patients' para user_id: $userAuthId, pero la columna 'id' es null. Respuesta: $patientRecordResponse");
         throw Exception("ID del paciente en la tabla 'patients' es nulo.");
      }

      final String patientTableId = patientRecordResponse['id'] as String;
      print("VitalSignService: 'patients.id' (patientTableId) encontrado: $patientTableId");

      final dataToInsert = {
        ...vitalSignDataFromForm,
        'patient_id': patientTableId,
      };

      print("VitalSignService: Intentando insertar signo vital: $dataToInsert");
      final response = await _supabase
          .from('vital_signs') // Usar el nombre de tabla directamente
          .insert(dataToInsert)
          .select()
          .single();

      print("VitalSignService: Signo vital insertado: $response");
      return VitalSign.fromJson(response);
    } catch (e) {
      print('VitalSignService: Error registrando signo vital: $e');
      rethrow;
    }
  }
}
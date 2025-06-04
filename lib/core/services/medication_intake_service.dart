// lib/core/services/medication_intake_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mediremind/core/models/medication_intake.dart'; // Ajusta el path
// Asumimos que tienes un modelo Patient similar a este para obtener el id
// import 'package:mediremind/core/models/patient.dart';

class MedicationIntakeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _medicationIntakesTable = 'medication_intakes';
  final String _patientsTable = 'patients'; // Nombre de tu tabla de pacientes

  Future<List<MedicationIntake>> getMyMedicationIntakes() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print("MedicationIntakeService: Usuario no autenticado.");
      return [];
    }

    final String userAuthId = currentUser.id;
    print("MedicationIntakeService: auth.currentUser.id (userAuthId): $userAuthId");

    try {
      print("MedicationIntakeService: Paso 1 - Buscando registro en '$_patientsTable' donde 'user_id' = '$userAuthId'");
      final patientRecordResponse = await _supabase
          .from(_patientsTable)
          .select('id') // Solo necesitamos el ID de la tabla patients
          .eq('user_id', userAuthId)
          .maybeSingle();

      if (patientRecordResponse == null) {
        print("MedicationIntakeService: Paso 1 - FALLIDO. No se encontró registro en '$_patientsTable' para user_id: $userAuthId. El paciente necesita vincular su cuenta o no tiene ficha creada por el doctor con este user_id.");
        return [];
      }

      // Verifica que 'id' exista en la respuesta y no sea null
      if (patientRecordResponse['id'] == null) {
        print("MedicationIntakeService: Paso 1 - ERROR. Se encontró registro en '$_patientsTable' para user_id: $userAuthId, pero la columna 'id' es null. Respuesta: $patientRecordResponse");
        return [];
      }

      final String patientTableId = patientRecordResponse['id'] as String;
      print("MedicationIntakeService: Paso 1 - ÉXITO. '$_patientsTable.id' (patientTableId) encontrado: $patientTableId");

      print("MedicationIntakeService: Paso 2 - Buscando en '$_medicationIntakesTable' donde 'patient_id' = '$patientTableId'");
      final response = await _supabase
          .from(_medicationIntakesTable)
          .select('*, medications(id, name, active_ingredient, expiration_date, doctor_id)') // <--- AÑADE LOS CAMPOS FALTANTES
          .eq('patient_id', patientTableId)
          .order('date', ascending: false)
          .order('time', ascending: false);

      // La respuesta de Supabase, incluso si no hay filas, es una lista.
      // No es null si la consulta es válida.
      final List<dynamic> responseData = response as List<dynamic>;
      print("MedicationIntakeService: Paso 2 - Respuesta cruda de '$_medicationIntakesTable' (longitud: ${responseData.length}): $responseData");


      if (responseData.isEmpty) {
        print("MedicationIntakeService: Paso 2 - No se encontraron tomas en '$_medicationIntakesTable' para patient_id (de tabla patients): $patientTableId");
      }

      final intakes = responseData
          .map((data) {
            try {
              print("MedicationIntakeService: Parseando toma: $data");
              return MedicationIntake.fromJson(data as Map<String, dynamic>);
            } catch (e, s) {
              print("MedicationIntakeService: Error parseando una toma: $data, error: $e, stacktrace: $s");
              return null;
            }
          })
          .where((intake) => intake != null)
          .cast<MedicationIntake>()
          .toList();

      print("MedicationIntakeService: Tomas obtenidas y parseadas: ${intakes.length}");
      return intakes;
    } catch (e, s) {
      print('MedicationIntakeService: Error GENERAL al obtener medication intakes: $e, stacktrace: $s');
      throw Exception('Error al obtener el historial de tomas: ${e.toString()}');
    }
  }

  Future<MedicationIntake?> updateIntakeStatus(String intakeId, bool isTaken) async {
     final currentUser = _supabase.auth.currentUser;
     if (currentUser == null) {
        print("MedicationIntakeService: Usuario no autenticado al intentar actualizar toma.");
        throw Exception("Usuario no autenticado");
     }
    try {
      print("MedicationIntakeService: Actualizando estado de toma ID: $intakeId a $isTaken");
      final response = await _supabase
          .from(_medicationIntakesTable)
          .update({'taken': isTaken})
          .eq('id', intakeId)
          .select('*, medications(id, name, active_ingredient)')
          .single();

      final updatedIntake = MedicationIntake.fromJson(response);
      print("MedicationIntakeService: Toma actualizada: ${updatedIntake.id}");
      return updatedIntake;
    } catch (e) {
      print('Error updating intake status: $e');
      throw Exception('Error al actualizar el estado de la toma: ${e.toString()}');
    }
  }
}

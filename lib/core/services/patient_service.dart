import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart'; // Ajusta el path

class PatientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // El paciente generalmente no creará "otros" pacientes.
  // Esta app es para el paciente, así que las funciones serían sobre "mi" perfil/datos.
  // Podrías tener un servicio `ProfileService` para manejar el perfil del paciente logueado.

  Future<Patient?> getMyPatientProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('patients') // O 'profiles' si los pacientes están ahí
          .select()
          .eq('id', user.id) // Asumiendo que el ID de paciente coincide con el auth.uid()
                             // o tienes un campo user_id en la tabla patients
          .single();

      return Patient.fromJson(response);
    } catch (e) {
      print('Error fetching patient profile: $e');
      return null;
    }
  }
  // ... otras funciones relevantes para el paciente ...
}
// lib/core/models/medication_intake.dart
import 'medication.dart'; // Asumiendo que medication.dart está en la misma carpeta

class MedicationIntake {
  final String id;
  final String patientId;       // patient_id en DB
  final String medicationId;    // medication_id en DB
  final String date;            // YYYY-MM-DD
  final String time;            // HH:MM
  final bool taken;
  final DateTime? createdAt;    // created_at en DB
  final DateTime? updatedAt;    // updated_at en DB
  final Medication? medication; // Para datos anidados del medicamento
  

  MedicationIntake({
    required this.id,
    required this.patientId,
    required this.medicationId,
    required this.date,
    required this.time,
    required this.taken,
    this.createdAt,
    this.updatedAt,
    this.medication,
  });

  factory MedicationIntake.fromJson(Map<String, dynamic> json) {
    print("MedicationIntake.fromJson - Recibiendo JSON: $json"); // MANTÉN ESTE DEBUG
    Medication? parsedMedication;
    if (json['medications'] != null && (json['medications'] is Map<String, dynamic>)) {
      try {
        parsedMedication = Medication.fromJson(json['medications'] as Map<String, dynamic>);
        print("MedicationIntake.fromJson - Medicamento parseado: ${parsedMedication.name}"); // DEBUG
      } catch (e) {
        print("MedicationIntake.fromJson - ERROR parseando 'medications': ${json['medications']}, Error: $e");
      }
    } else {
      print("MedicationIntake.fromJson - No se encontró 'medications' o no es un Map: ${json['medications']}");
    }

    // ... (parseo de otros campos de MedicationIntake) ...
    return MedicationIntake(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      medicationId: json['medication_id'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      taken: json['taken'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      medication: parsedMedication, // Usa la variable parseada
    );
  }

   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'medication_id': medicationId,
      'date': date,
      'time': time,
      'taken': taken,
      // No incluimos createdAt ni updatedAt, son manejados por DB
      // No incluimos medication anidado al enviar JSON a Supabase para esta tabla
    };
  }
}
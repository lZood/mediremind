// lib/core/models/appointment.dart
import 'package:mediremind/core/models/patient.dart'; // Asumiendo que tienes patient.dart
import 'package:mediremind/core/models/user_profile.dart'; // Asumiendo que tienes user_profile.dart para el Doctor

class Appointment {
  final String id;
  final String patientId; // FK a patients.id
  final String doctorId;  // FK a profiles.id (del doctor)
  final String specialty;
  final String date; // YYYY-MM-DD
  final String time; // HH:MM
  final String? diagnosis;
  final String status; // 'requested_by_patient', 'scheduled', 'completed', 'cancelled_by_doctor', etc.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? notificacionRecordatorio24hEnviada;

  // Campos para datos anidados
  final Patient? patient;
  final UserProfile? doctor; // UserProfile es tu modelo para perfiles (incluyendo doctores)

  // Nuevos campos opcionales para la solicitud
  final String? requestedDate;
  final String? requestedTime;
  final String? reasonForRequest;
  final String? rejectionReason;


  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.specialty,
    required this.date,
    required this.time,
    this.diagnosis,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.notificacionRecordatorio24hEnviada,
    this.patient,
    this.doctor,
    this.requestedDate,
    this.requestedTime,
    this.reasonForRequest,
    this.rejectionReason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    print("Appointment.fromJson - Recibiendo JSON: $json");
    return Appointment(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      specialty: json['specialty'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      diagnosis: json['diagnosis'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      notificacionRecordatorio24hEnviada: json['notificacion_recordatorio_24h_enviada'] as bool?,
      // Parsear datos anidados
      patient: json['patients'] != null && (json['patients'] is Map<String, dynamic>)
          ? Patient.fromJson(json['patients'] as Map<String, dynamic>)
          : null,
      // La clave para el doctor dependerá de cómo Supabase nombre el join (profiles, doctor, o el nombre de la FK)
      // Ajusta 'profiles' si es diferente en la respuesta JSON
      doctor: json['profiles'] != null && (json['profiles'] is Map<String, dynamic>)
          ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>)
          : (json['doctor'] != null && (json['doctor'] is Map<String, dynamic>) // Intento alternativo por si el alias es 'doctor'
              ? UserProfile.fromJson(json['doctor'] as Map<String, dynamic>)
              : null),
      requestedDate: json['requested_date'] as String?,
      requestedTime: json['requested_time'] as String?,
      reasonForRequest: json['reason_for_request'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Para enviar a Supabase
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'specialty': specialty,
      'date': date,
      'time': time,
      'diagnosis': diagnosis,
      'status': status,
      'requested_date': requestedDate,
      'requested_time': requestedTime,
      'reason_for_request': reasonForRequest,
      'rejection_reason': rejectionReason,
      'notificacion_recordatorio_24h_enviada': notificacionRecordatorio24hEnviada,
      // No enviar patient, doctor, createdAt, updatedAt al crear/actualizar
    };
  }
}
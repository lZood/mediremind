// lib/core/models/notification_model_flutter.dart
// Adaptado de tu tipo Notification en TypeScript

class NotificationModel {
  final String id;
  final String? patientId; // auth.uid del paciente (o el ID de profiles del paciente)
  final String? doctorId;  // auth.uid del doctor (o el ID de profiles del doctor)
  final String? appointmentId;
  final String? medicationIntakeId;
  final String message;
  final String type;
  final String status; // 'pending' | 'sent' | 'read' | 'archived' | 'error'
  final DateTime? sendAt; // Para programar envíos
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Opcional: Para anidar info del paciente o cita si la obtienes con joins
  // final Patient? patient;
  // final Appointment? appointment;

  NotificationModel({
    required this.id,
    this.patientId,
    this.doctorId,
    this.appointmentId,
    this.medicationIntakeId,
    required this.message,
    required this.type,
    required this.status,
    this.sendAt,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String?, // Nota: en tu TS era patient_id
      doctorId: json['doctor_id'] as String?,   // Nota: en tu TS era doctor_id
      appointmentId: json['appointment_id'] as String?,
      medicationIntakeId: json['medication_intake_id'] as String?,
      message: json['message'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      sendAt: json['send_at'] != null ? DateTime.tryParse(json['send_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }
}
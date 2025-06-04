// lib/core/models/vital_sign.dart

class VitalSign {
  final String id;
  final String patientId; // Corresponde a 'patient_id' en la base de datos
  final String type;      // Tipo de signo vital, ej: "Presión Arterial Sistólica"
  final double value;     // El valor numérico del signo vital
  final String unit;      // Unidad de medida, ej: "mmHg", "bpm", "°C"
  final String date;      // Fecha en formato YYYY-MM-DD
  final String time;      // Hora en formato HH:MM o HH:MM:SS
  final DateTime? createdAt; // Corresponde a 'created_at' en la base de datos
  final DateTime? updatedAt; // Corresponde a 'updated_at' en la base de datos

  VitalSign({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.unit,
    required this.date,
    required this.time,
    this.createdAt,
    this.updatedAt,
  });

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      type: json['type'] as String,
      // El campo 'value' en la DB es NUMERIC, así que puede venir como int o double.
      // Lo convertimos a double para consistencia en Dart.
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      date: json['date'] as String, // Asumimos que viene como String YYYY-MM-DD
      time: json['time'] as String, // Asumimos que viene como String HH:MM:SS o HH:MM
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Este método se usaría principalmente para crear o actualizar un signo vital.
    // 'id', 'created_at', y 'updated_at' usualmente son manejados por la base de datos.
    return {
      // 'id': id, // No se envía al crear, Supabase lo genera
      'patient_id': patientId,
      'type': type,
      'value': value,
      'unit': unit,
      'date': date,
      'time': time,
      // 'created_at': createdAt?.toIso8601String(), // Manejado por DB
      // 'updated_at': updatedAt?.toIso8601String(), // Manejado por DB
    };
  }

  // Método para crear una copia con algunas propiedades actualizadas (útil para UI)
  VitalSign copyWith({
    String? id,
    String? patientId,
    String? type,
    double? value,
    String? unit,
    String? date,
    String? time,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VitalSign(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
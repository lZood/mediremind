class Patient {
  final String id;
  final String name;
  final String? phone;     // Hacer nullable si puede ser null en DB
  final String? address;   // Hacer nullable si puede ser null en DB
  final String email;     // Asumimos que email es requerido
  final DateTime? createdAt; // Hacer nullable si puede ser null o si no siempre lo seleccionas
  final String? doctorId;
  final String? userId;    // El auth.uid del paciente, si lo almacenas aquí

  Patient({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.email,
    this.createdAt,
    this.doctorId,
    this.userId,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    print("Patient.fromJson - Recibiendo JSON para paciente: $json");
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Nombre Desconocido',
      phone: json['phone'] as String?, // Casteo seguro a nullable
      address: json['address'] as String?, // Casteo seguro a nullable
      email: json['email'] as String? ?? 'Email Desconocido',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null, // Usar tryParse
      doctorId: json['doctor_id'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'doctor_id': doctorId,
    };
  }
}
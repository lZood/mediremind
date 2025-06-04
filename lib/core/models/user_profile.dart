// lib/core/models/user_profile.dart

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? specialty;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? needsInitialSetup;
  final String? fcmToken; // NUEVO CAMPO para el token FCM

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.specialty,
    this.createdAt,
    this.updatedAt,
    this.needsInitialSetup,
    this.fcmToken, // Añadir al constructor
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Nombre no disponible',
      email: json['email'] as String? ?? 'Email no disponible',
      role: json['role'] as String? ?? 'patient',
      specialty: json['specialty'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      needsInitialSetup: json['needs_initial_setup'] as bool?,
      fcmToken: json['fcm_token'] as String?, // Mapear desde snake_case
    );
  }

  Map<String, dynamic> toJson() {
    // Solo para los campos que quieres actualizar.
    // No incluyas id, createdAt, updatedAt si no los estás modificando.
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'role': role,
    };
    if (specialty != null) data['specialty'] = specialty;
    if (needsInitialSetup != null) data['needs_initial_setup'] = needsInitialSetup;
    if (fcmToken != null) data['fcm_token'] = fcmToken; // Incluir para actualizar
    return data;
  }
}

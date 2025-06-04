// lib/core/models/user_profile.dart
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role; // 'doctor', 'patient', etc.
  final String? specialty; // Opcional para pacientes
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? needsInitialSetup;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.specialty,
    this.createdAt,
    this.updatedAt,
    this.needsInitialSetup,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'], // Asumiendo que el email también está en la tabla profiles
      role: json['role'],
      specialty: json['specialty'],
      needsInitialSetup: json['needs_initial_setup'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'specialty': specialty,
      'needs_initial_setup': needsInitialSetup,
      // No incluimos createdAt ni updatedAt al enviar, Supabase los maneja
    };
  }
}
class Medication {
  final String id;
  final String name;
  final String activeIngredient; // active_ingredient en DB
  final String? expirationDate;   // expiration_date en DB (YYYY-MM-DD)
  final String? description;
  final String? doctorId;        // doctor_id en DB
  final DateTime? createdAt;     // created_at en DB
  final DateTime? updatedAt;     // updated_at en DB
  // final bool? notificacionStockExpirandoEnviada; // notificacion_stock_expirando_enviada en DB

  Medication({
    required this.id,
    required this.name,
    required this.activeIngredient,
    this.expirationDate,
    this.description,
    this.doctorId,
    this.createdAt,
    this.updatedAt,
    // this.notificacionStockExpirandoEnviada,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    print("Medication.fromJson - Recibiendo JSON para medicamento: $json");
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Medicamento Desconocido', // Manejo de nulos por si acaso
      activeIngredient: json['active_ingredient'] as String? ?? 'Principio Activo Desconocido', // Manejo de nulos
      // Campos que podrían no venir de la consulta anidada, por lo tanto, deben ser opcionales
      // o tener un valor por defecto si se leen, y ser casteados como String?
      expirationDate: json['expiration_date'] as String?,
      description: json['description'] as String?,
      doctorId: json['doctor_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      // notificacionStockExpirandoEnviada: json['notificacion_stock_expirando_enviada'] as bool?,
    );
  }

   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'active_ingredient': activeIngredient,
      'expiration_date': expirationDate,
      'description': description,
      'doctor_id': doctorId,
      // No incluimos createdAt ni updatedAt, son manejados por DB
      // 'notificacion_stock_expirando_enviada': notificacionStockExpirandoEnviada,
    };
  }
}
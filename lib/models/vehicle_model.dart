/// Modelo de veículo para aluguer.
class VehicleModel {
  final String? vehicleId;
  final String ownerId;
  final String brand;
  final String model;
  final int year;
  final String category;
  final List<String> eventTypes;
  final String description;
  final List<String> features;
  final List<String> images;
  final double pricePerDay;
  final Map<String, dynamic> location;
  final Map<String, dynamic> availability;
  final ValidationStatus validation;
  final VehicleStats stats;
  final DateTime createdAt;
  final String transmission;
  final int seats;
  final String engineType;

  VehicleModel({
    this.vehicleId,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.year,
    required this.category,
    required this.eventTypes,
    required this.description,
    required this.features,
    required this.images,
    required this.pricePerDay,
    required this.location,
    required this.availability,
    required this.validation,
    required this.stats,
    required this.createdAt,
    this.transmission = 'Manual',
    this.seats = 4,
    this.engineType = 'Gasolina',
  });

  /// Cria um VehicleModel a partir de um Map da base de dados.
  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      vehicleId: map['id'],
      ownerId: map['owner_id'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      category: map['category'] ?? 'classic',
      eventTypes: List<String>.from(map['event_types'] ?? []),
      description: map['description'] ?? '',
      features: List<String>.from(map['features'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      pricePerDay: (map['price_per_day'] ?? 0).toDouble(),
      location: map['location'] ?? {},
      availability: map['availability'] ?? {'is_available': true, 'blocked_dates': []},
      validation: ValidationStatus.fromMap(map['validation'] ?? {}),
      stats: VehicleStats.fromMap(map['stats'] ?? {}),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      transmission: map['transmission'] ?? 'Manual',
      seats: map['seats'] ?? 4,
      engineType: map['engine_type'] ?? 'Gasolina',
    );
  }

  /// Converte o modelo para Map para guardar na base de dados.
  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'brand': brand,
      'model': model,
      'year': year,
      'category': category,
      'event_types': eventTypes,
      'description': description,
      'features': features,
      'images': images,
      'price_per_day': pricePerDay,
      'location': location,
      'availability': availability,
      'validation': validation.toMap(),
      'validation_status': validation.status,
      'stats': stats.toMap(),
      'created_at': createdAt.toIso8601String(),
      'transmission': transmission,
      'seats': seats,
      'engine_type': engineType,
      'is_available': isAvailable,
    };
  }

  String get fullName => '$brand $model ($year)';
  bool get isAvailable =>
      availability['is_available'] ?? availability['isAvailable'] ?? true;
  bool get isApproved => validation.status == 'approved';
  double get latitude => (location['latitude'] ?? 38.7223).toDouble();
  double get longitude => (location['longitude'] ?? -9.1393).toDouble();
}

/// Estado de validação de um veículo.
class ValidationStatus {
  final String status;
  final DateTime? validatedAt;
  final String? validatedBy;
  final Map<String, String>? documents;

  ValidationStatus({
    required this.status,
    this.validatedAt,
    this.validatedBy,
    this.documents,
  });

  factory ValidationStatus.fromMap(Map<String, dynamic> map) {
    return ValidationStatus(
      status: map['status'] ?? 'pending',
      validatedAt: map['validated_at'] != null
          ? DateTime.parse(map['validated_at'])
          : null,
      validatedBy: map['validated_by'],
      documents: map['documents'] != null
          ? Map<String, String>.from(map['documents'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'validated_at': validatedAt?.toIso8601String(),
      'validated_by': validatedBy,
      'documents': documents,
    };
  }
}

/// Estatísticas de um veículo.
class VehicleStats {
  final int totalBookings;
  final double rating;
  final int views;
  final int totalReviews;

  VehicleStats({
    required this.totalBookings,
    required this.rating,
    required this.views,
    this.totalReviews = 0,
  });

  factory VehicleStats.fromMap(Map<String, dynamic> map) {
    return VehicleStats(
      totalBookings: map['total_bookings'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      views: (map['views'] ?? 0).toInt(),
      totalReviews: map['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_bookings': totalBookings,
      'rating': rating,
      'views': views,
      'total_reviews': totalReviews,
    };
  }
}

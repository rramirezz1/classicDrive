import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      vehicleId: id,
      ownerId: map['ownerId'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      category: map['category'] ?? 'classic',
      eventTypes: List<String>.from(map['eventTypes'] ?? []),
      description: map['description'] ?? '',
      features: List<String>.from(map['features'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      location: map['location'] ?? {},
      availability:
          map['availability'] ?? {'isAvailable': true, 'blockedDates': []},
      validation: ValidationStatus.fromMap(map['validation'] ?? {}),
      stats: VehicleStats.fromMap(map['stats'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'brand': brand,
      'model': model,
      'year': year,
      'category': category,
      'eventTypes': eventTypes,
      'description': description,
      'features': features,
      'images': images,
      'pricePerDay': pricePerDay,
      'location': location,
      'availability': availability,
      'validation': validation.toMap(),
      'stats': stats.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get fullName => '$brand $model ($year)';
  bool get isAvailable => availability['isAvailable'] ?? true;
  bool get isApproved => validation.status == 'approved';
}

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
      validatedAt: map['validatedAt'] != null
          ? (map['validatedAt'] as Timestamp).toDate()
          : null,
      validatedBy: map['validatedBy'],
      documents: map['documents'] != null
          ? Map<String, String>.from(map['documents'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'validatedAt':
          validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'validatedBy': validatedBy,
      'documents': documents,
    };
  }
}

class VehicleStats {
  final int totalBookings;
  final double rating;
  final int views;

  VehicleStats({
    required this.totalBookings,
    required this.rating,
    required this.views,
  });

  factory VehicleStats.fromMap(Map<String, dynamic> map) {
    return VehicleStats(
      totalBookings: map['totalBookings'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      views: map['views'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBookings': totalBookings,
      'rating': rating,
      'views': views,
    };
  }
}

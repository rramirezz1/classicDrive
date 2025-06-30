import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String userType; // 'owner' ou 'renter'
  final DateTime createdAt;
  final bool isVerified;

  // Campos de verificação
  final String?
      verificationStatus; // 'pending', 'verified', 'rejected', 'in_review'
  final DateTime? verificationSubmittedAt;
  final DateTime? verifiedAt;
  final String? verificationLevel; // 'basic', 'full'
  final Map<String, dynamic>? verificationDocuments;

  // Campos de confiabilidade
  final double trustScore;
  final int completedBookings;
  final int cancelledBookings;
  final double averageRating;
  final int totalReviews;

  // Preferências
  final Map<String, dynamic> preferences;
  final List<String> favoriteVehicles;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    required this.createdAt,
    required this.isVerified,
    this.verificationStatus,
    this.verificationSubmittedAt,
    this.verifiedAt,
    this.verificationLevel,
    this.verificationDocuments,
    this.trustScore = 0.0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    Map<String, dynamic>? preferences,
    List<String>? favoriteVehicles,
    List<String>? blockedUsers,
  })  : preferences = preferences ?? {},
        favoriteVehicles = favoriteVehicles ?? [],
        blockedUsers = blockedUsers ?? [];

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? 'renter',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      verificationStatus: map['verificationStatus'],
      verificationSubmittedAt: map['verificationSubmittedAt'] != null
          ? (map['verificationSubmittedAt'] as Timestamp).toDate()
          : null,
      verifiedAt: map['verifiedAt'] != null
          ? (map['verifiedAt'] as Timestamp).toDate()
          : null,
      verificationLevel: map['verificationLevel'],
      verificationDocuments: map['verificationDocuments'],
      trustScore: (map['trustScore'] ?? 0).toDouble(),
      completedBookings: map['completedBookings'] ?? 0,
      cancelledBookings: map['cancelledBookings'] ?? 0,
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      favoriteVehicles: List<String>.from(map['favoriteVehicles'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationSubmittedAt': verificationSubmittedAt != null
          ? Timestamp.fromDate(verificationSubmittedAt!)
          : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verificationLevel': verificationLevel,
      'verificationDocuments': verificationDocuments,
      'trustScore': trustScore,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'preferences': preferences,
      'favoriteVehicles': favoriteVehicles,
      'blockedUsers': blockedUsers,
    };
  }

  // Métodos auxiliares
  bool get hasKYC => verificationStatus == 'verified';
  bool get isFullyVerified => hasKYC && verificationLevel == 'full';
  bool get isPendingVerification => verificationStatus == 'in_review';

  double get reliabilityScore {
    if (completedBookings == 0) return 0.0;

    // Calcular score baseado em vários fatores
    double completionRate =
        completedBookings / (completedBookings + cancelledBookings);
    double ratingScore = averageRating / 5;
    double verificationScore = hasKYC ? 1.0 : 0.5;

    return (completionRate * 0.4 + ratingScore * 0.4 + verificationScore * 0.2)
        .clamp(0.0, 1.0);
  }

  String get trustLevel {
    if (trustScore >= 0.9) return 'Excelente';
    if (trustScore >= 0.7) return 'Muito Bom';
    if (trustScore >= 0.5) return 'Bom';
    if (trustScore >= 0.3) return 'Regular';
    return 'Novo';
  }
}

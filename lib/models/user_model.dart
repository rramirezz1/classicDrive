/// Modelo de utilizador da aplicação.
class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String userType;
  final DateTime createdAt;
  final bool isVerified;
  final String? verificationStatus;
  final DateTime? verificationSubmittedAt;
  final DateTime? verifiedAt;
  final String? verificationLevel;
  final Map<String, dynamic>? verificationDocuments;
  final double trustScore;
  final int completedBookings;
  final int cancelledBookings;
  final double averageRating;
  final int totalReviews;
  final Map<String, dynamic> preferences;
  final List<String> favoriteVehicles;
  final List<String> blockedUsers;
  final bool isAdmin;

  UserModel({
    required this.id,
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
    this.isAdmin = false,
  })  : preferences = preferences ?? {},
        favoriteVehicles = favoriteVehicles ?? [],
        blockedUsers = blockedUsers ?? [];

  String? get kycStatus => verificationStatus;
  DateTime? get kycSubmittedAt => verificationSubmittedAt;
  DateTime? get kycApprovedAt => verifiedAt;

  /// Cria um UserModel a partir de JSON (formato Supabase).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final status = json['kyc_status'] ?? json['verification_status'];

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['user_type'] ?? 'renter',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isVerified: json['is_verified'] ?? false,
      verificationStatus: status,
      verificationSubmittedAt: json['kyc_submitted_at'] != null
          ? DateTime.parse(json['kyc_submitted_at'])
          : (json['verification_submitted_at'] != null
              ? DateTime.parse(json['verification_submitted_at'])
              : null),
      verifiedAt: json['kyc_approved_at'] != null
          ? DateTime.parse(json['kyc_approved_at'])
          : (json['verified_at'] != null
              ? DateTime.parse(json['verified_at'])
              : null),
      verificationLevel: json['verification_level'],
      verificationDocuments: json['verification_documents'] != null
          ? Map<String, dynamic>.from(json['verification_documents'])
          : null,
      trustScore: (json['trust_score'] ?? 0).toDouble(),
      completedBookings: json['completed_bookings'] ?? 0,
      cancelledBookings: json['cancelled_bookings'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : {},
      favoriteVehicles: json['favorite_vehicles'] != null
          ? List<String>.from(json['favorite_vehicles'])
          : [],
      blockedUsers: json['blocked_users'] != null
          ? List<String>.from(json['blocked_users'])
          : [],
      isAdmin: json['is_admin'] ?? false,
    );
  }

  /// Cria um UserModel a partir de Map (formato Firebase).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? map['user_type'] ?? 'renter',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime ? map['createdAt'] : DateTime.now())
          : DateTime.now(),
      isVerified: map['isVerified'] ?? map['is_verified'] ?? false,
      verificationStatus:
          map['verificationStatus'] ?? map['verification_status'],
      verificationSubmittedAt: map['verificationSubmittedAt'] != null
          ? (map['verificationSubmittedAt'] is DateTime
              ? map['verificationSubmittedAt']
              : null)
          : null,
      verifiedAt: map['verifiedAt'] != null
          ? (map['verifiedAt'] is DateTime ? map['verifiedAt'] : null)
          : null,
      verificationLevel: map['verificationLevel'] ?? map['verification_level'],
      verificationDocuments: map['verificationDocuments'],
      trustScore: (map['trustScore'] ?? map['trust_score'] ?? 0).toDouble(),
      completedBookings:
          map['completedBookings'] ?? map['completed_bookings'] ?? 0,
      cancelledBookings:
          map['cancelledBookings'] ?? map['cancelled_bookings'] ?? 0,
      averageRating:
          (map['averageRating'] ?? map['average_rating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? map['total_reviews'] ?? 0,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      favoriteVehicles: List<String>.from(map['favoriteVehicles'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      isAdmin: map['isAdmin'] ?? map['is_admin'] ?? false,
    );
  }

  /// Converte para JSON (formato Supabase).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
      'is_verified': isVerified,
      'kyc_status': verificationStatus,
      'kyc_submitted_at': verificationSubmittedAt?.toIso8601String(),
      'kyc_approved_at': verifiedAt?.toIso8601String(),
      'verification_level': verificationLevel,
      'verification_documents': verificationDocuments,
      'trust_score': trustScore,
      'completed_bookings': completedBookings,
      'cancelled_bookings': cancelledBookings,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'preferences': preferences,
      'favorite_vehicles': favoriteVehicles,
      'blocked_users': blockedUsers,
      'is_admin': isAdmin,
    };
  }

  /// Converte para Map (formato Firebase).
  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType,
      'createdAt': createdAt,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationSubmittedAt': verificationSubmittedAt,
      'verifiedAt': verifiedAt,
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

  bool get hasKYC => verificationStatus == 'approved';
  bool get isFullyVerified => hasKYC && verificationLevel == 'full';
  bool get isPendingVerification => verificationStatus == 'pending';

  /// Calcula a pontuação de fiabilidade do utilizador.
  double get reliabilityScore {
    if (completedBookings == 0) return 0.0;

    double completionRate =
        completedBookings / (completedBookings + cancelledBookings);
    double ratingScore = averageRating / 5;
    double verificationScore = hasKYC ? 1.0 : 0.5;

    return (completionRate * 0.4 + ratingScore * 0.4 + verificationScore * 0.2)
        .clamp(0.0, 1.0);
  }

  /// Obtém o nível de confiança do utilizador.
  String get trustLevel {
    if (trustScore >= 0.9) return 'Excelente';
    if (trustScore >= 0.7) return 'Muito Bom';
    if (trustScore >= 0.5) return 'Bom';
    if (trustScore >= 0.3) return 'Regular';
    return 'Novo';
  }

  String get uid => id;
}

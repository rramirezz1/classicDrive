/// Modelo de avaliação de veículo.
class ReviewModel {
  final String? reviewId;
  final String bookingId;
  final String vehicleId;
  final String reviewerId;
  final String reviewerName;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final bool isVerifiedBooking;
  final bool isVerifiedReviewer;
  final Map<String, double> detailedRatings;
  final String? ownerResponse;
  final DateTime? ownerResponseAt;
  final int helpfulVotes;
  final List<String> helpfulVoters;

  ReviewModel({
    this.reviewId,
    required this.bookingId,
    required this.vehicleId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    List<String>? images,
    required this.createdAt,
    this.isVerifiedBooking = false,
    this.isVerifiedReviewer = false,
    Map<String, double>? detailedRatings,
    this.ownerResponse,
    this.ownerResponseAt,
    this.helpfulVotes = 0,
    List<String>? helpfulVoters,
  })  : images = images ?? [],
        detailedRatings = detailedRatings ?? {},
        helpfulVoters = helpfulVoters ?? [];

  /// Cria um ReviewModel a partir de um Map da base de dados.
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['id'],
      bookingId: map['booking_id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      reviewerId: map['reviewer_id'] ?? '',
      reviewerName: map['reviewer_name'] ?? 'Utilizador',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      isVerifiedBooking: map['is_verified_booking'] ?? false,
      isVerifiedReviewer: map['is_verified_reviewer'] ?? false,
      detailedRatings: map['detailed_ratings'] != null
          ? Map<String, double>.from(map['detailed_ratings'])
          : {},
      ownerResponse: map['owner_response'],
      ownerResponseAt: map['owner_response_at'] != null
          ? DateTime.parse(map['owner_response_at'])
          : null,
      helpfulVotes: map['helpful_votes'] ?? 0,
      helpfulVoters: List<String>.from(map['helpful_voters'] ?? []),
    );
  }

  /// Converte o modelo para Map para guardar na base de dados.
  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'vehicle_id': vehicleId,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'rating': rating,
      'comment': comment,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'is_verified_booking': isVerifiedBooking,
      'is_verified_reviewer': isVerifiedReviewer,
      'detailed_ratings': detailedRatings,
      'owner_response': ownerResponse,
      'owner_response_at': ownerResponseAt?.toIso8601String(),
      'helpful_votes': helpfulVotes,
      'helpful_voters': helpfulVoters,
    };
  }

  /// Obtém os ratings detalhados padrão.
  static Map<String, double> getDefaultDetailedRatings() {
    return {
      'cleanliness': 0.0,
      'communication': 0.0,
      'checkIn': 0.0,
      'accuracy': 0.0,
      'value': 0.0,
      'condition': 0.0,
    };
  }

  /// Calcula o rating geral a partir dos ratings detalhados.
  static double calculateOverallRating(Map<String, double> detailedRatings) {
    if (detailedRatings.isEmpty) return 0.0;

    double sum = detailedRatings.values.reduce((a, b) => a + b);
    return sum / detailedRatings.length;
  }
}

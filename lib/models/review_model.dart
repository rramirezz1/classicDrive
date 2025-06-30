import 'package:cloud_firestore/cloud_firestore.dart';

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

  final bool isVerifiedBooking; // Se a reserva foi verificada
  final bool isVerifiedReviewer; // Se o reviewer tem KYC
  final Map<String, double> detailedRatings; // Ratings detalhados
  final String? ownerResponse; // Resposta do proprietário
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

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      reviewId: id,
      bookingId: map['bookingId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Utilizador',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isVerifiedBooking: map['isVerifiedBooking'] ?? false,
      isVerifiedReviewer: map['isVerifiedReviewer'] ?? false,
      detailedRatings: map['detailedRatings'] != null
          ? Map<String, double>.from(map['detailedRatings'])
          : {},
      ownerResponse: map['ownerResponse'],
      ownerResponseAt: map['ownerResponseAt'] != null
          ? (map['ownerResponseAt'] as Timestamp).toDate()
          : null,
      helpfulVotes: map['helpfulVotes'] ?? 0,
      helpfulVoters: List<String>.from(map['helpfulVoters'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'vehicleId': vehicleId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerifiedBooking': isVerifiedBooking,
      'isVerifiedReviewer': isVerifiedReviewer,
      'detailedRatings': detailedRatings,
      'ownerResponse': ownerResponse,
      'ownerResponseAt':
          ownerResponseAt != null ? Timestamp.fromDate(ownerResponseAt!) : null,
      'helpfulVotes': helpfulVotes,
      'helpfulVoters': helpfulVoters,
    };
  }

  // Ratings detalhados padrão
  static Map<String, double> getDefaultDetailedRatings() {
    return {
      'cleanliness': 0.0, // Limpeza
      'communication': 0.0, // Comunicação
      'checkIn': 0.0, // Check-in
      'accuracy': 0.0, // Precisão do anúncio
      'value': 0.0, // Custo-benefício
      'condition': 0.0, // Estado do veículo
    };
  }

  // Calcular rating geral a partir dos detalhados
  static double calculateOverallRating(Map<String, double> detailedRatings) {
    if (detailedRatings.isEmpty) return 0.0;

    double sum = detailedRatings.values.reduce((a, b) => a + b);
    return sum / detailedRatings.length;
  }
}

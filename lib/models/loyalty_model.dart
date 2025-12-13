/// Modelo de fidelidade/pontos do utilizador.

enum LoyaltyTier { bronze, silver, gold }

class LoyaltyModel {
  final String oderId;
  final int totalPoints;
  final int lifetimePoints;
  final LoyaltyTier tier;
  final List<LoyaltyTransaction> transactions;
  final DateTime? lastActivityAt;
  final String? referralCode;
  final int referralCount;

  LoyaltyModel({
    required this.oderId,
    this.totalPoints = 0,
    this.lifetimePoints = 0,
    this.tier = LoyaltyTier.bronze,
    this.transactions = const [],
    this.lastActivityAt,
    this.referralCode,
    this.referralCount = 0,
  });

  /// Calcula o tier com base nos pontos totais.
  static LoyaltyTier calculateTier(int points) {
    if (points >= 2000) return LoyaltyTier.gold;
    if (points >= 500) return LoyaltyTier.silver;
    return LoyaltyTier.bronze;
  }

  /// Pontos necessários para o próximo tier.
  int get pointsToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 500 - totalPoints;
      case LoyaltyTier.silver:
        return 2000 - totalPoints;
      case LoyaltyTier.gold:
        return 0; // Já é gold
    }
  }

  /// Progresso percentual para o próximo tier (0.0 - 1.0).
  double get progressToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return totalPoints / 500;
      case LoyaltyTier.silver:
        return (totalPoints - 500) / 1500;
      case LoyaltyTier.gold:
        return 1.0;
    }
  }

  /// Desconto aplicável com base no tier.
  double get discountPercentage {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 0.0;
      case LoyaltyTier.silver:
        return 5.0;
      case LoyaltyTier.gold:
        return 10.0;
    }
  }

  /// Nome do tier em português.
  String get tierName {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Prata';
      case LoyaltyTier.gold:
        return 'Ouro';
    }
  }

  factory LoyaltyModel.fromMap(Map<String, dynamic> map) {
    final points = map['total_points'] ?? 0;
    return LoyaltyModel(
      oderId: map['user_id'] ?? '',
      totalPoints: points,
      lifetimePoints: map['lifetime_points'] ?? points,
      tier: calculateTier(points),
      transactions: (map['transactions'] as List?)
              ?.map((e) => LoyaltyTransaction.fromMap(e))
              .toList() ??
          [],
      lastActivityAt: map['last_activity_at'] != null
          ? DateTime.parse(map['last_activity_at'])
          : null,
      referralCode: map['referral_code'],
      referralCount: map['referral_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': oderId,
      'total_points': totalPoints,
      'lifetime_points': lifetimePoints,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'referral_code': referralCode,
      'referral_count': referralCount,
    };
  }
}

/// Transação de pontos.
class LoyaltyTransaction {
  final String? transactionId;
  final String oderId;
  final int points;
  final String type;
  final String description;
  final DateTime createdAt;

  LoyaltyTransaction({
    this.transactionId,
    required this.oderId,
    required this.points,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransaction(
      transactionId: map['id'],
      oderId: map['user_id'] ?? '',
      points: map['points'] ?? 0,
      type: map['type'] ?? 'other',
      description: map['description'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': oderId,
      'points': points,
      'type': type,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Tipos de transação.
class LoyaltyTypes {
  static const String booking = 'booking';
  static const String review = 'review';
  static const String referral = 'referral';
  static const String bonus = 'bonus';
  static const String redemption = 'redemption';
}

/// Pontos por ação.
class LoyaltyPoints {
  static const int booking = 50;
  static const int review = 25;
  static const int referral = 100;
  static const int firstBooking = 100;
}

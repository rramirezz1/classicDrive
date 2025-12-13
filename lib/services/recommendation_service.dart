import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_model.dart';
import '../models/booking_model.dart';

/// Serviço de recomendações personalizadas.
class RecommendationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const double WEIGHT_CATEGORY = 0.3;
  static const double WEIGHT_PRICE = 0.25;
  static const double WEIGHT_LOCATION = 0.2;
  static const double WEIGHT_RATING = 0.15;
  static const double WEIGHT_FEATURES = 0.1;

  /// Obtém recomendações personalizadas para um utilizador.
  Future<List<VehicleRecommendation>> getPersonalizedRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final userProfile = await _analyzeUserProfile(userId);

      final vehiclesData = await _supabase
          .from('vehicles')
          .select()
          .eq('validation_status', 'approved')
          .eq('is_available', true);

      final vehicles =
          vehiclesData.map((data) => VehicleModel.fromMap(data)).toList();

      List<VehicleRecommendation> recommendations = [];

      for (var vehicle in vehicles) {
        final score = _calculateRecommendationScore(vehicle, userProfile);
        recommendations.add(VehicleRecommendation(
          vehicle: vehicle,
          score: score,
          reasons: _generateReasons(vehicle, userProfile, score),
        ));
      }

      recommendations.sort((a, b) => b.score.compareTo(a.score));

      await _logRecommendations(userId, recommendations.take(limit).toList());

      return recommendations.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Analisa o perfil do utilizador com base no histórico.
  Future<UserProfile> _analyzeUserProfile(String userId) async {
    final viewsData = await _supabase
        .from('analytics')
        .select()
        .eq('user_id', userId)
        .eq('action', 'view')
        .order('timestamp', ascending: false)
        .limit(50);

    final bookingsData =
        await _supabase.from('bookings').select().eq('renter_id', userId);

    Map<String, int> categoryPreferences = {};
    Map<String, int> eventTypePreferences = {};
    List<double> priceHistory = [];
    Map<String, int> featurePreferences = {};

    for (var view in viewsData) {
      final vehicleId = view['vehicle_id'];
      if (vehicleId != null) {
        final vehicleData = await _supabase
            .from('vehicles')
            .select()
            .eq('id', vehicleId)
            .maybeSingle();

        if (vehicleData != null) {
          final vehicle = VehicleModel.fromMap(vehicleData);

          categoryPreferences[vehicle.category] =
              (categoryPreferences[vehicle.category] ?? 0) + 1;

          for (var eventType in vehicle.eventTypes) {
            eventTypePreferences[eventType] =
                (eventTypePreferences[eventType] ?? 0) + 1;
          }

          for (var feature in vehicle.features) {
            featurePreferences[feature] =
                (featurePreferences[feature] ?? 0) + 1;
          }
        }
      }
    }

    for (var bookingData in bookingsData) {
      final booking = BookingModel.fromMap(bookingData);
      priceHistory.add(booking.totalPrice / booking.numberOfDays);
    }

    double avgPrice = priceHistory.isNotEmpty
        ? priceHistory.reduce((a, b) => a + b) / priceHistory.length
        : 150.0;

    return UserProfile(
      userId: userId,
      preferredCategories: _sortByValue(categoryPreferences),
      preferredEventTypes: _sortByValue(eventTypePreferences),
      preferredFeatures: _sortByValue(featurePreferences),
      averagePrice: avgPrice,
      priceRange: priceHistory.isNotEmpty
          ? [
              priceHistory.reduce((a, b) => a < b ? a : b),
              priceHistory.reduce((a, b) => a > b ? a : b)
            ]
          : [50, 300],
    );
  }

  /// Calcula a pontuação de recomendação para um veículo.
  double _calculateRecommendationScore(
    VehicleModel vehicle,
    UserProfile profile,
  ) {
    double score = 0;

    if (profile.preferredCategories.contains(vehicle.category)) {
      final index = profile.preferredCategories.indexOf(vehicle.category);
      score += WEIGHT_CATEGORY * (1 - index * 0.1);
    }

    final priceDiff = (vehicle.pricePerDay - profile.averagePrice).abs();
    final priceScore = 1 - (priceDiff / profile.averagePrice).clamp(0, 1);
    score += WEIGHT_PRICE * priceScore;

    score += WEIGHT_LOCATION * 0.8;

    score += WEIGHT_RATING * (vehicle.stats.rating / 5);

    int matchingFeatures = 0;
    for (var feature in vehicle.features) {
      if (profile.preferredFeatures.contains(feature)) {
        matchingFeatures++;
      }
    }
    if (vehicle.features.isNotEmpty) {
      score += WEIGHT_FEATURES * (matchingFeatures / vehicle.features.length);
    }

    if (vehicle.stats.totalBookings > 10) {
      score *= 1.1;
    }

    return score.clamp(0, 1);
  }

  /// Gera razões para uma recomendação.
  List<String> _generateReasons(
    VehicleModel vehicle,
    UserProfile profile,
    double score,
  ) {
    List<String> reasons = [];

    if (profile.preferredCategories.contains(vehicle.category)) {
      reasons.add('Categoria que costuma procurar');
    }

    final priceDiff = (vehicle.pricePerDay - profile.averagePrice).abs();
    if (priceDiff < profile.averagePrice * 0.2) {
      reasons.add('Preço dentro do seu orçamento habitual');
    }

    if (vehicle.stats.rating >= 4.5) {
      reasons.add('Altamente avaliado');
    }

    if (vehicle.stats.totalBookings > 10) {
      reasons.add('Popular entre outros utilizadores');
    }

    final commonFeatures = vehicle.features
        .where((f) => profile.preferredFeatures.contains(f))
        .toList();
    if (commonFeatures.isNotEmpty) {
      reasons.add('Tem ${commonFeatures.join(", ")}');
    }

    return reasons;
  }

  /// Regista as recomendações para aprendizagem.
  Future<void> _logRecommendations(
    String userId,
    List<VehicleRecommendation> recommendations,
  ) async {
    try {
      List<Map<String, dynamic>> logs = [];

      for (int i = 0; i < recommendations.length; i++) {
        logs.add({
          'user_id': userId,
          'vehicle_id': recommendations[i].vehicle.vehicleId,
          'score': recommendations[i].score,
          'position': i + 1,
          'clicked': false,
          'booked': false,
        });
      }

      await _supabase.from('recommendation_logs').insert(logs);
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Regista um clique numa recomendação.
  Future<void> logRecommendationClick(String userId, String vehicleId) async {
    try {
      final logs = await _supabase
          .from('recommendation_logs')
          .select()
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (logs.isNotEmpty) {
        final logId = logs.first['id'];
        await _supabase
            .from('recommendation_logs')
            .update({'clicked': true}).eq('id', logId);
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Regista uma reserva de uma recomendação.
  Future<void> logRecommendationBooking(String userId, String vehicleId) async {
    try {
      final logs = await _supabase
          .from('recommendation_logs')
          .select()
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (logs.isNotEmpty) {
        final logId = logs.first['id'];
        await _supabase
            .from('recommendation_logs')
            .update({'booked': true}).eq('id', logId);
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Calcula o preço dinâmico baseado em procura e sazonalidade.
  Future<double> calculateDynamicPrice({
    required VehicleModel vehicle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final basePrice = vehicle.pricePerDay;
    double multiplier = 1.0;

    final demandMultiplier = await _calculateDemandMultiplier(
      vehicle.vehicleId!,
      startDate,
      endDate,
    );
    multiplier *= demandMultiplier;

    final seasonMultiplier = _calculateSeasonMultiplier(startDate);
    multiplier *= seasonMultiplier;

    final advanceMultiplier = _calculateAdvanceMultiplier(startDate);
    multiplier *= advanceMultiplier;

    final days = endDate.difference(startDate).inDays + 1;
    if (days >= 7) {
      multiplier *= 0.9;
    } else if (days >= 3) {
      multiplier *= 0.95;
    }

    return basePrice * multiplier;
  }

  Future<double> _calculateDemandMultiplier(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final bookingsData = await _supabase
        .from('bookings')
        .select()
        .eq('vehicle_id', vehicleId)
        .inFilter('status', ['confirmed', 'pending']);

    int overlappingDays = 0;
    final totalDays = 30;

    for (var bookingData in bookingsData) {
      final booking = BookingModel.fromMap(bookingData);

      if (booking.startDate.isBefore(endDate) &&
          booking.endDate.isAfter(startDate)) {
        overlappingDays += booking.numberOfDays;
      }
    }

    final occupancyRate = overlappingDays / totalDays;

    if (occupancyRate > 0.8) return 1.3;
    if (occupancyRate > 0.6) return 1.15;
    if (occupancyRate < 0.3) return 0.9;

    return 1.0;
  }

  double _calculateSeasonMultiplier(DateTime date) {
    final month = date.month;

    if (month >= 6 && month <= 8) return 1.2;
    if ((month >= 3 && month <= 5) || (month >= 9 && month <= 11)) return 1.1;

    return 0.9;
  }

  double _calculateAdvanceMultiplier(DateTime startDate) {
    final daysInAdvance = startDate.difference(DateTime.now()).inDays;

    if (daysInAdvance <= 2) return 1.2;
    if (daysInAdvance <= 7) return 1.1;
    if (daysInAdvance >= 30) return 0.95;

    return 1.0;
  }

  List<String> _sortByValue(Map<String, int> map) {
    var entries = map.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }
}

/// Perfil do utilizador para recomendações.
class UserProfile {
  final String userId;
  final List<String> preferredCategories;
  final List<String> preferredEventTypes;
  final List<String> preferredFeatures;
  final double averagePrice;
  final List<double> priceRange;

  UserProfile({
    required this.userId,
    required this.preferredCategories,
    required this.preferredEventTypes,
    required this.preferredFeatures,
    required this.averagePrice,
    required this.priceRange,
  });
}

/// Recomendação de veículo com pontuação e razões.
class VehicleRecommendation {
  final VehicleModel vehicle;
  final double score;
  final List<String> reasons;

  VehicleRecommendation({
    required this.vehicle,
    required this.score,
    required this.reasons,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';
import '../models/booking_model.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fatores de peso para o algoritmo
  static const double WEIGHT_CATEGORY = 0.3;
  static const double WEIGHT_PRICE = 0.25;
  static const double WEIGHT_LOCATION = 0.2;
  static const double WEIGHT_RATING = 0.15;
  static const double WEIGHT_FEATURES = 0.1;

  // Obter recomendações personalizadas
  Future<List<VehicleRecommendation>> getPersonalizedRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      // 1. Analisar histórico do utilizador
      final userProfile = await _analyzeUserProfile(userId);

      // 2. Obter veículos disponíveis
      final vehiclesSnapshot = await _firestore
          .collection('vehicles')
          .where('validation.status', isEqualTo: 'approved')
          .where('availability.isAvailable', isEqualTo: true)
          .get();

      final vehicles = vehiclesSnapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();

      // 3. Calcular pontuação para cada veículo
      List<VehicleRecommendation> recommendations = [];

      for (var vehicle in vehicles) {
        final score = _calculateRecommendationScore(vehicle, userProfile);
        recommendations.add(VehicleRecommendation(
          vehicle: vehicle,
          score: score,
          reasons: _generateReasons(vehicle, userProfile, score),
        ));
      }

      // 4. Ordenar por pontuação
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      // 5. Registar impressões para aprendizagem
      await _logRecommendations(userId, recommendations.take(limit).toList());

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Erro ao gerar recomendações: $e');
      return [];
    }
  }

  // Analisar perfil do utilizador
  Future<UserProfile> _analyzeUserProfile(String userId) async {
    // Obter histórico de visualizações
    final viewsSnapshot = await _firestore
        .collection('analytics')
        .where('userId', isEqualTo: userId)
        .where('action', isEqualTo: 'view')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    // Obter histórico de reservas
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('renterId', isEqualTo: userId)
        .get();

    // Analisar preferências
    Map<String, int> categoryPreferences = {};
    Map<String, int> eventTypePreferences = {};
    List<double> priceHistory = [];
    Map<String, int> featurePreferences = {};

    // Processar visualizações
    for (var doc in viewsSnapshot.docs) {
      final vehicleId = doc.data()['vehicleId'];
      if (vehicleId != null) {
        final vehicleDoc =
            await _firestore.collection('vehicles').doc(vehicleId).get();

        if (vehicleDoc.exists) {
          final vehicle =
              VehicleModel.fromMap(vehicleDoc.data()!, vehicleDoc.id);

          // Categorias
          categoryPreferences[vehicle.category] =
              (categoryPreferences[vehicle.category] ?? 0) + 1;

          // Tipos de evento
          for (var eventType in vehicle.eventTypes) {
            eventTypePreferences[eventType] =
                (eventTypePreferences[eventType] ?? 0) + 1;
          }

          // Features
          for (var feature in vehicle.features) {
            featurePreferences[feature] =
                (featurePreferences[feature] ?? 0) + 1;
          }
        }
      }
    }

    // Processar reservas
    for (var doc in bookingsSnapshot.docs) {
      final booking = BookingModel.fromMap(doc.data(), doc.id);
      priceHistory.add(booking.totalPrice / booking.numberOfDays);
    }

    // Calcular médias e preferências
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

  // Calcular pontuação de recomendação
  double _calculateRecommendationScore(
    VehicleModel vehicle,
    UserProfile profile,
  ) {
    double score = 0;

    // 1. Pontuação por categoria
    if (profile.preferredCategories.contains(vehicle.category)) {
      final index = profile.preferredCategories.indexOf(vehicle.category);
      score += WEIGHT_CATEGORY * (1 - index * 0.1);
    }

    // 2. Pontuação por preço
    final priceDiff = (vehicle.pricePerDay - profile.averagePrice).abs();
    final priceScore = 1 - (priceDiff / profile.averagePrice).clamp(0, 1);
    score += WEIGHT_PRICE * priceScore;

    // 3. Pontuação por localização (simplificado)
    score += WEIGHT_LOCATION * 0.8; // Por agora, assumir proximidade

    // 4. Pontuação por avaliação
    score += WEIGHT_RATING * (vehicle.stats.rating / 5);

    // 5. Pontuação por features
    int matchingFeatures = 0;
    for (var feature in vehicle.features) {
      if (profile.preferredFeatures.contains(feature)) {
        matchingFeatures++;
      }
    }
    if (vehicle.features.isNotEmpty) {
      score += WEIGHT_FEATURES * (matchingFeatures / vehicle.features.length);
    }

    // Bonus por popularidade
    if (vehicle.stats.totalBookings > 10) {
      score *= 1.1;
    }

    return score.clamp(0, 1);
  }

  // Gerar razões para recomendação
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

    // Features em comum
    final commonFeatures = vehicle.features
        .where((f) => profile.preferredFeatures.contains(f))
        .toList();
    if (commonFeatures.isNotEmpty) {
      reasons.add('Tem ${commonFeatures.join(", ")}');
    }

    return reasons;
  }

  // Registar recomendações para aprendizagem
  Future<void> _logRecommendations(
    String userId,
    List<VehicleRecommendation> recommendations,
  ) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < recommendations.length; i++) {
        final docRef = _firestore.collection('recommendation_logs').doc();
        batch.set(docRef, {
          'userId': userId,
          'vehicleId': recommendations[i].vehicle.vehicleId,
          'score': recommendations[i].score,
          'position': i + 1,
          'timestamp': FieldValue.serverTimestamp(),
          'clicked': false,
          'booked': false,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao registar recomendações: $e');
    }
  }

  // Registar clique em recomendação
  Future<void> logRecommendationClick(String userId, String vehicleId) async {
    try {
      final logs = await _firestore
          .collection('recommendation_logs')
          .where('userId', isEqualTo: userId)
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (logs.docs.isNotEmpty) {
        await logs.docs.first.reference.update({'clicked': true});
      }
    } catch (e) {
      print('Erro ao registar clique: $e');
    }
  }

  // Registar reserva de recomendação
  Future<void> logRecommendationBooking(String userId, String vehicleId) async {
    try {
      final logs = await _firestore
          .collection('recommendation_logs')
          .where('userId', isEqualTo: userId)
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (logs.docs.isNotEmpty) {
        await logs.docs.first.reference.update({'booked': true});
      }
    } catch (e) {
      print('Erro ao registar reserva: $e');
    }
  }

  // Preços dinâmicos
  Future<double> calculateDynamicPrice({
    required VehicleModel vehicle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final basePrice = vehicle.pricePerDay;
    double multiplier = 1.0;

    // 1. Fator de demanda
    final demandMultiplier = await _calculateDemandMultiplier(
      vehicle.vehicleId!,
      startDate,
      endDate,
    );
    multiplier *= demandMultiplier;

    // 2. Fator de sazonalidade
    final seasonMultiplier = _calculateSeasonMultiplier(startDate);
    multiplier *= seasonMultiplier;

    // 3. Fator de antecedência
    final advanceMultiplier = _calculateAdvanceMultiplier(startDate);
    multiplier *= advanceMultiplier;

    // 4. Fator de duração
    final days = endDate.difference(startDate).inDays + 1;
    if (days >= 7) {
      multiplier *= 0.9; // 10% desconto para alugueres longos
    } else if (days >= 3) {
      multiplier *= 0.95; // 5% desconto
    }

    return basePrice * multiplier;
  }

  // Calcular multiplicador de demanda
  Future<double> _calculateDemandMultiplier(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Verificar reservas existentes no período
    final bookings = await _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', whereIn: ['confirmed', 'pending']).get();

    int overlappingDays = 0;
    final totalDays = 30; // Janela de análise

    for (var doc in bookings.docs) {
      final booking = BookingModel.fromMap(doc.data(), doc.id);

      // Calcular sobreposição
      if (booking.startDate.isBefore(endDate) &&
          booking.endDate.isAfter(startDate)) {
        overlappingDays += booking.numberOfDays;
      }
    }

    final occupancyRate = overlappingDays / totalDays;

    if (occupancyRate > 0.8) return 1.3; // Alta demanda
    if (occupancyRate > 0.6) return 1.15; // Demanda moderada
    if (occupancyRate < 0.3) return 0.9; // Baixa demanda

    return 1.0;
  }

  // Calcular multiplicador de sazonalidade
  double _calculateSeasonMultiplier(DateTime date) {
    final month = date.month;

    // Verão (alta temporada)
    if (month >= 6 && month <= 8) return 1.2;

    // Primavera e Outono
    if ((month >= 3 && month <= 5) || (month >= 9 && month <= 11)) return 1.1;

    // Inverno (baixa temporada)
    return 0.9;
  }

  // Calcular multiplicador de antecedência
  double _calculateAdvanceMultiplier(DateTime startDate) {
    final daysInAdvance = startDate.difference(DateTime.now()).inDays;

    if (daysInAdvance <= 2) return 1.2; // Última hora
    if (daysInAdvance <= 7) return 1.1; // Uma semana
    if (daysInAdvance >= 30) return 0.95; // Reserva antecipada

    return 1.0;
  }

  // Métodos auxiliares
  List<String> _sortByValue(Map<String, int> map) {
    var entries = map.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }
}

// Modelos auxiliares
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

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

/// Serviço para gestão de avaliações.
class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtém avaliações de um veículo.
  Future<List<ReviewModel>> getVehicleReviews(String vehicleId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => ReviewModel.fromMap(e))
          .toList();
    } catch (e) {
      print('Erro ao obter avaliações: $e');
      return [];
    }
  }

  /// Obtém estatísticas de avaliações de um veículo.
  Future<Map<String, dynamic>> getVehicleRatingStats(String vehicleId) async {
    try {
      final reviews = await getVehicleReviews(vehicleId);
      
      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final totalRating = reviews.fold(0.0, (sum, r) => sum + r.rating);
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      for (final review in reviews) {
        final stars = review.rating.round().clamp(1, 5);
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }

      return {
        'averageRating': totalRating / reviews.length,
        'totalReviews': reviews.length,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Cria uma nova avaliação.
  Future<ReviewModel?> createReview(ReviewModel review) async {
    try {
      final response = await _supabase
          .from('reviews')
          .insert(review.toMap())
          .select()
          .single();

      // Atualizar rating médio do veículo
      await _updateVehicleRating(review.vehicleId);

      return ReviewModel.fromMap(response);
    } catch (e) {
      print('Erro ao criar avaliação: $e');
      return null;
    }
  }

  /// Adiciona resposta do proprietário.
  Future<bool> addOwnerResponse(String reviewId, String response) async {
    try {
      await _supabase
          .from('reviews')
          .update({
            'owner_response': response,
            'owner_response_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId);
      return true;
    } catch (e) {
      print('Erro ao responder: $e');
      return false;
    }
  }

  /// Marca avaliação como útil.
  Future<bool> markAsHelpful(String reviewId, String oderId) async {
    try {
      // Obter avaliação atual
      final current = await _supabase
          .from('reviews')
          .select()
          .eq('id', reviewId)
          .single();

      final voters = List<String>.from(current['helpful_voters'] ?? []);
      
      if (voters.contains(oderId)) {
        // Remover voto
        voters.remove(oderId);
      } else {
        // Adicionar voto
        voters.add(oderId);
      }

      await _supabase
          .from('reviews')
          .update({
            'helpful_voters': voters,
            'helpful_votes': voters.length,
          })
          .eq('id', reviewId);

      return true;
    } catch (e) {
      print('Erro ao votar: $e');
      return false;
    }
  }

  /// Verifica se utilizador pode avaliar (tem reserva concluída).
  Future<bool> canReview(String oderId, String vehicleId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', oderId)
          .eq('vehicle_id', vehicleId)
          .eq('status', 'completed');

      if ((response as List).isEmpty) return false;

      // Verificar se já avaliou
      final existing = await _supabase
          .from('reviews')
          .select()
          .eq('reviewer_id', oderId)
          .eq('vehicle_id', vehicleId);

      return (existing as List).isEmpty;
    } catch (e) {
      print('Erro: $e');
      return false;
    }
  }

  /// Atualiza rating médio do veículo.
  Future<void> _updateVehicleRating(String vehicleId) async {
    try {
      final stats = await getVehicleRatingStats(vehicleId);
      await _supabase
          .from('vehicles')
          .update({'rating': stats['averageRating']})
          .eq('id', vehicleId);
    } catch (e) {
      print('Erro ao atualizar rating: $e');
    }
  }
}

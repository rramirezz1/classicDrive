import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loyalty_model.dart';

/// Serviço para gestão do programa de fidelidade.
class LoyaltyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtém os dados de fidelidade do utilizador.
  Future<LoyaltyModel?> getUserLoyalty(String oderId) async {
    // Validar userId antes de fazer query
    if (oderId.isEmpty) {
      return null;
    }
    
    try {
      final response = await _supabase
          .from('user_loyalty')
          .select()
          .eq('user_id', oderId)
          .maybeSingle();

      if (response == null) {
        // Criar registo inicial
        return await _createInitialLoyalty(oderId);
      }

      return LoyaltyModel.fromMap(response);
    } catch (e) {
      print('Erro ao obter fidelidade: $e');
      return null;
    }
  }

  /// Cria registo inicial de fidelidade.
  Future<LoyaltyModel?> _createInitialLoyalty(String oderId) async {
    try {
      final referralCode = _generateReferralCode(oderId);
      
      final data = {
        'user_id': oderId,
        'total_points': 0,
        'lifetime_points': 0,
        'referral_code': referralCode,
        'referral_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_loyalty')
          .insert(data)
          .select()
          .single();

      return LoyaltyModel.fromMap(response);
    } catch (e) {
      print('Erro ao criar fidelidade: $e');
      return null;
    }
  }

  /// Gera código de referência único.
  String _generateReferralCode(String oderId) {
    final prefix = 'CD';
    final suffix = oderId.substring(0, 6).toUpperCase();
    return '$prefix$suffix';
  }

  /// Adiciona pontos ao utilizador.
  Future<bool> addPoints({
    required String oderId,
    required int points,
    required String type,
    required String description,
  }) async {
    try {
      // Registar transação
      await _supabase.from('loyalty_transactions').insert({
        'user_id': oderId,
        'points': points,
        'type': type,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Atualizar total de pontos
      final current = await getUserLoyalty(oderId);
      if (current == null) return false;

      final newTotal = current.totalPoints + points;
      final newLifetime = current.lifetimePoints + points;

      await _supabase.from('user_loyalty').update({
        'total_points': newTotal,
        'lifetime_points': newLifetime,
        'last_activity_at': DateTime.now().toIso8601String(),
      }).eq('user_id', oderId);

      return true;
    } catch (e) {
      print('Erro ao adicionar pontos: $e');
      return false;
    }
  }

  /// Adiciona pontos por reserva.
  Future<bool> addBookingPoints(String oderId, {bool isFirst = false}) async {
    final points = isFirst ? LoyaltyPoints.firstBooking : LoyaltyPoints.booking;
    final description = isFirst
        ? 'Bónus primeira reserva'
        : 'Pontos por reserva';
    
    return addPoints(
      oderId: oderId,
      points: points,
      type: LoyaltyTypes.booking,
      description: description,
    );
  }

  /// Adiciona pontos por review.
  Future<bool> addReviewPoints(String oderId, String vehicleName) async {
    return addPoints(
      oderId: oderId,
      points: LoyaltyPoints.review,
      type: LoyaltyTypes.review,
      description: 'Avaliação de $vehicleName',
    );
  }

  /// Adiciona pontos por referência.
  Future<bool> addReferralPoints(String oderId, String referredName) async {
    // Atualizar contagem de referências
    await _supabase
        .from('user_loyalty')
        .update({'referral_count': Supabase.instance.client.rpc('increment_referral', params: {'uid': oderId})})
        .eq('user_id', oderId);

    return addPoints(
      oderId: oderId,
      points: LoyaltyPoints.referral,
      type: LoyaltyTypes.referral,
      description: 'Referência: $referredName',
    );
  }

  /// Usa pontos para desconto.
  Future<bool> redeemPoints({
    required String oderId,
    required int points,
    required String description,
  }) async {
    try {
      final current = await getUserLoyalty(oderId);
      if (current == null || current.totalPoints < points) return false;

      // Registar transação negativa
      await _supabase.from('loyalty_transactions').insert({
        'user_id': oderId,
        'points': -points,
        'type': LoyaltyTypes.redemption,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Subtrair pontos
      await _supabase.from('user_loyalty').update({
        'total_points': current.totalPoints - points,
        'last_activity_at': DateTime.now().toIso8601String(),
      }).eq('user_id', oderId);

      return true;
    } catch (e) {
      print('Erro ao usar pontos: $e');
      return false;
    }
  }

  /// Obtém histórico de transações.
  Future<List<LoyaltyTransaction>> getTransactions(String oderId) async {
    try {
      final response = await _supabase
          .from('loyalty_transactions')
          .select()
          .eq('user_id', oderId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((e) => LoyaltyTransaction.fromMap(e))
          .toList();
    } catch (e) {
      print('Erro ao obter transações: $e');
      return [];
    }
  }

  /// Processa código de referência.
  Future<bool> processReferralCode(String code, String newoderId) async {
    try {
      // Encontrar dono do código
      final owner = await _supabase
          .from('user_loyalty')
          .select()
          .eq('referral_code', code.toUpperCase())
          .maybeSingle();

      if (owner == null || owner['user_id'] == newoderId) return false;

      // Dar pontos ao dono do código
      await addReferralPoints(owner['user_id'], 'Novo utilizador');

      // Dar bónus ao novo utilizador
      await addPoints(
        oderId: newoderId,
        points: 50,
        type: LoyaltyTypes.bonus,
        description: 'Bónus de boas-vindas (código de referência)',
      );

      return true;
    } catch (e) {
      print('Erro ao processar referência: $e');
      return false;
    }
  }
}

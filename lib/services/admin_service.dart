import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';

/// Serviço para gestão de funcionalidades administrativas.
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Verifica se o utilizador atual é administrador.
  Future<bool> isAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .single();

      return response['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se um utilizador específico é administrador.
  Future<bool> isUserAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .single();

      return response['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Obtém estatísticas gerais da plataforma.
  Future<Map<String, dynamic>?> getAdminStats() async {
    try {
      final response = await _supabase.from('admin_stats').select().single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Lista todos os utilizadores com filtros opcionais.
  Future<List<UserModel>> getAllUsers({
    String? searchQuery,
    String? userType,
    String? kycStatus,
    bool? isActive,
  }) async {
    try {
      var query = _supabase.from('users').select(
          'id, email, name, phone, user_type, created_at, is_verified, kyc_status, kyc_submitted_at, kyc_approved_at, kyc_rejected_at, verification_level, verification_documents, trust_score, completed_bookings, cancelled_bookings, average_rating, total_reviews, preferences, favorite_vehicles, blocked_users, is_admin');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query =
            query.or('name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }
      if (userType != null) {
        query = query.eq('user_type', userType);
      }
      if (kycStatus != null) {
        query = query.eq('kyc_status', kycStatus);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtém utilizadores com KYC pendente.
  Future<List<UserModel>> getPendingKYCUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select(
              'id, email, name, phone, user_type, created_at, is_verified, kyc_status, kyc_submitted_at, kyc_approved_at, kyc_rejected_at, verification_level, verification_documents, trust_score, completed_bookings, cancelled_bookings, average_rating, total_reviews, preferences, favorite_vehicles, blocked_users, is_admin')
          .eq('kyc_status', 'pending')
          .order('kyc_submitted_at', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ativa ou desativa um utilizador.
  Future<String?> toggleUserStatus(String userId, bool isActive) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) return 'Não autenticado';

      if (!await isAdmin()) {
        return 'Sem permissões de administrador';
      }

      await _supabase.rpc('toggle_user_status', params: {
        'p_admin_id': adminId,
        'p_user_id': userId,
        'p_is_active': isActive,
      });

      return null;
    } catch (e) {
      return 'Erro ao alterar status: $e';
    }
  }

  /// Aprova o KYC de um utilizador.
  Future<String?> approveKYC(String userId) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) return 'Não autenticado';

      if (!await isAdmin()) {
        return 'Sem permissões de administrador';
      }

      await _supabase.rpc('approve_kyc', params: {
        'p_admin_id': adminId,
        'p_user_id': userId,
      });

      return null;
    } catch (e) {
      return 'Erro ao aprovar KYC: $e';
    }
  }

  /// Rejeita o KYC de um utilizador.
  Future<String?> rejectKYC(String userId, String reason) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) return 'Não autenticado';

      if (!await isAdmin()) {
        return 'Sem permissões de administrador';
      }

      await _supabase.rpc('reject_kyc', params: {
        'p_admin_id': adminId,
        'p_user_id': userId,
        'p_reason': reason,
      });

      return null;
    } catch (e) {
      return 'Erro ao rejeitar KYC: $e';
    }
  }

  /// Lista todos os veículos como VehicleModel.
  Future<List<VehicleModel>> getAllVehiclesAsModels() async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((data) => VehicleModel.fromMap(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Lista todos os veículos com dados do proprietário.
  Future<List<Map<String, dynamic>>> getAllVehicles({
    String? searchQuery,
    String? category,
    bool? isAvailable,
  }) async {
    try {
      var query = _supabase.from('vehicles').select('''
        *,
        owner:owner_id (
          id,
          name,
          email
        )
      ''');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query =
            query.or('brand.ilike.%$searchQuery%,model.ilike.%$searchQuery%');
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Aprova um veículo.
  Future<void> approveVehicle(String vehicleId) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) throw Exception('Não autenticado');

      if (!await isAdmin()) {
        throw Exception('Sem permissões de administrador');
      }

      await _supabase.from('vehicles').update({
        'validation': {
          'status': 'approved',
          'validated_at': DateTime.now().toIso8601String(),
          'validated_by': adminId,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', vehicleId);

      await _logAction(
        action: 'approve_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
      );
    } catch (e) {
      throw Exception('Erro ao aprovar veículo: $e');
    }
  }

  /// Remove um veículo (soft delete).
  Future<String?> removeVehicle(String vehicleId, String reason) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) return 'Não autenticado';

      if (!await isAdmin()) {
        return 'Sem permissões de administrador';
      }

      await _supabase.from('vehicles').update({
        'is_available': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', vehicleId);

      await _logAction(
        action: 'remove_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {'reason': reason},
      );

      return null;
    } catch (e) {
      return 'Erro ao remover veículo: $e';
    }
  }

  /// Lista todas as reservas com filtros opcionais.
  Future<List<Map<String, dynamic>>> getAllBookings({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('bookings').select('''
        *,
        renter:renter_id (
          id,
          name,
          email
        ),
        vehicle:vehicle_id (
          id,
          brand,
          model,
          year
        )
      ''');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('end_date', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Cancela uma reserva como administrador.
  Future<String?> cancelBooking(String bookingId, String reason) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) return 'Não autenticado';

      if (!await isAdmin()) {
        return 'Sem permissões de administrador';
      }

      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      await _logAction(
        action: 'cancel_booking',
        targetType: 'booking',
        targetId: bookingId,
        details: {'reason': reason, 'cancelled_by': 'admin'},
      );

      return null;
    } catch (e) {
      return 'Erro ao cancelar reserva: $e';
    }
  }

  /// Regista uma ação administrativa.
  Future<void> _logAction({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId == null) return;

      await _supabase.rpc('log_admin_action', params: {
        'p_admin_id': adminId,
        'p_action': action,
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_details': details,
      });
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Obtém logs de ações administrativas.
  Future<List<Map<String, dynamic>>> getAdminLogs({
    int limit = 100,
    String? action,
    String? targetType,
  }) async {
    try {
      var query = _supabase.from('admin_logs').select('''
        *,
        admin:admin_id (
          id,
          name,
          email
        )
      ''');

      if (action != null) {
        query = query.eq('action', action);
      }
      if (targetType != null) {
        query = query.eq('target_type', targetType);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}

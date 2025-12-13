import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/vehicle_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';

/// Serviço de base de dados para gestão de veículos, reservas e avaliações.
class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtém stream de todos os veículos aprovados e disponíveis.
  Stream<List<VehicleModel>> getApprovedVehicles() {
    return _supabase.from('vehicles').stream(primaryKey: ['id']).order('created_at', ascending: false).map((data) {
      return data
          .where((item) =>
              item['validation_status'] == 'approved' &&
              item['is_available'] == true)
          .map((item) => VehicleModel.fromMap(item))
          .toList();
    });
  }

  /// Obtém stream de veículos filtrados por categoria.
  Stream<List<VehicleModel>> getVehiclesByCategory(String category) {
    return _supabase.from('vehicles').stream(primaryKey: ['id']).order('created_at', ascending: false).map((data) {
      return data
          .where((item) =>
              item['validation_status'] == 'approved' &&
              item['is_available'] == true &&
              item['category'] == category)
          .map((item) => VehicleModel.fromMap(item))
          .toList();
    });
  }

  /// Obtém stream de veículos de um proprietário específico.
  Stream<List<VehicleModel>> getVehiclesByOwner(String ownerId) {
    return _supabase
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .where((item) => item['owner_id'] == ownerId)
              .map((item) => VehicleModel.fromMap(item))
              .toList();
        });
  }

  /// Obtém um veículo pelo seu ID.
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final data = await _supabase
          .from('vehicles')
          .select()
          .eq('id', vehicleId)
          .single();

      return VehicleModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Adiciona um novo veículo à base de dados.
  Future<String?> addVehicle(VehicleModel vehicle) async {
    try {
      final data = await _supabase
          .from('vehicles')
          .insert(vehicle.toMap())
          .select()
          .single();

      return data['id'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Atualiza os dados de um veículo.
  Future<void> updateVehicle(
      String vehicleId, Map<String, dynamic> updates) async {
    try {
      final processedUpdates = <String, dynamic>{};

      updates.forEach((key, value) {
        if (value is DateTime) {
          processedUpdates[key] = value.toIso8601String();
        } else {
          processedUpdates[key] = value;
        }
      });

      await _supabase
          .from('vehicles')
          .update(processedUpdates)
          .eq('id', vehicleId);
    } catch (e) {
      throw Exception('Erro ao atualizar veículo: $e');
    }
  }

  /// Remove um veículo da base de dados.
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await _supabase.from('vehicles').delete().eq('id', vehicleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Faz upload de imagens de um veículo para o storage.
  Future<List<String>> uploadVehicleImages(
    String vehicleId,
    List<File> images,
  ) async {
    List<String> imageUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final fileName =
            '$vehicleId/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        await _supabase.storage
            .from('vehicle-images')
            .upload(fileName, images[i]);

        final url =
            _supabase.storage.from('vehicle-images').getPublicUrl(fileName);

        imageUrls.add(url);
      }
      return imageUrls;
    } catch (e) {
      return [];
    }
  }

  /// Pesquisa veículos com filtros opcionais.
  Future<List<VehicleModel>> searchVehicles({
    String? category,
    String? eventType,
    double? minPrice,
    double? maxPrice,
    String? city,
  }) async {
    try {
      var query = _supabase
          .from('vehicles')
          .select()
          .eq('validation_status', 'approved')
          .eq('is_available', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (eventType != null) {
        query = query.contains('event_types', [eventType]);
      }

      if (city != null) {
        query = query.eq('location_city', city);
      }

      if (minPrice != null) {
        query = query.gte('price_per_day', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price_per_day', maxPrice);
      }

      final data = await query.order('created_at', ascending: false);

      return data.map((item) => VehicleModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cria uma nova reserva.
  Future<String?> createBooking(BookingModel booking) async {
    try {
      final isAvailable = await checkVehicleAvailability(
        booking.vehicleId,
        booking.startDate,
        booking.endDate,
      );

      if (!isAvailable) {
        throw Exception('Veículo não disponível para estas datas');
      }

      final data = await _supabase
          .from('bookings')
          .insert(booking.toMap())
          .select()
          .single();

      await _registerAnalytics('book', booking.renterId, booking.vehicleId);

      return data['id'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Verifica a disponibilidade de um veículo para determinadas datas.
  Future<bool> checkVehicleAvailability(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _supabase.rpc(
        'check_vehicle_availability',
        params: {
          'p_vehicle_id': vehicleId,
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      return result as bool;
    } catch (e) {
      return false;
    }
  }

  /// Obtém stream das reservas de um utilizador.
  Stream<List<BookingModel>> getUserBookings(String userId,
      {bool asOwner = false}) {
    if (asOwner) {
      return _supabase
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('owner_id', userId)
          .order('created_at', ascending: false)
          .map((data) {
            return data.map((item) => BookingModel.fromMap(item)).toList();
          });
    } else {
      return _supabase
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('renter_id', userId)
          .order('created_at', ascending: false)
          .map((data) {
            return data.map((item) => BookingModel.fromMap(item)).toList();
          });
    }
  }

  /// Atualiza o estado de uma reserva.
  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _supabase.from('bookings').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtém as avaliações de um veículo.
  Future<List<ReviewModel>> getVehicleReviews(String vehicleId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);

      return data.map((item) => ReviewModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Adiciona uma nova avaliação.
  Future<String?> addReview(ReviewModel review) async {
    try {
      final data = await _supabase
          .from('reviews')
          .insert(review.toMap())
          .select()
          .single();

      await _updateVehicleRating(review.vehicleId);

      return data['id'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Atualiza o rating médio de um veículo.
  Future<void> _updateVehicleRating(String vehicleId) async {
    try {
      final reviews = await getVehicleReviews(vehicleId);

      if (reviews.isEmpty) return;

      final avgRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

      final vehicle = await getVehicleById(vehicleId);
      if (vehicle != null) {
        final newStats = {
          'total_bookings': vehicle.stats.totalBookings,
          'rating': avgRating,
          'views': vehicle.stats.views,
          'total_reviews': reviews.length,
        };

        await updateVehicle(vehicleId, {
          'stats': newStats,
        });
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Regista uma ação do utilizador para analytics.
  Future<void> _registerAnalytics(
    String action,
    String userId, [
    String? vehicleId,
  ]) async {
    try {
      await _supabase.from('analytics').insert({
        'user_id': userId,
        'action': action,
        'vehicle_id': vehicleId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Obtém recomendações personalizadas para um utilizador.
  Future<List<VehicleModel>> getRecommendations(String userId) async {
    try {
      final analytics = await _supabase
          .from('analytics')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(50);

      Map<String, int> categoryCount = {};
      double totalPrice = 0;
      int priceCount = 0;
      
      final Set<String> vehicleIdsToFetch = {};

      for (var record in analytics) {
        if (record['vehicle_id'] != null) {
          vehicleIdsToFetch.add(record['vehicle_id']);
        }
      }

      List<VehicleModel> historyVehicles = [];
      if (vehicleIdsToFetch.isNotEmpty) {
        final vehiclesData = await _supabase
            .from('vehicles')
            .select()
            .inFilter('id', vehicleIdsToFetch.toList());
            
        historyVehicles = vehiclesData
            .map((item) => VehicleModel.fromMap(item))
            .toList();
      }

      for (var vehicle in historyVehicles) {
        categoryCount[vehicle.category] =
            (categoryCount[vehicle.category] ?? 0) + 1;
        totalPrice += vehicle.pricePerDay;
        priceCount++;
      }

      String? preferredCategory;
      if (categoryCount.isNotEmpty) {
        preferredCategory = categoryCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      double avgPrice = priceCount > 0 ? totalPrice / priceCount : 100;

      var query = _supabase
          .from('vehicles')
          .select()
          .eq('validation_status', 'approved')
          .eq('is_available', true);

      if (preferredCategory != null) {
        query = query.eq('category', preferredCategory);
      }

      query = query
          .gte('price_per_day', avgPrice * 0.7)
          .lte('price_per_day', avgPrice * 1.3);

      final data = await query.order('rating', ascending: false).limit(10);

      return data.map((item) => VehicleModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Incrementa o contador de visualizações de um veículo.
  Future<void> incrementVehicleViews(String vehicleId, String userId) async {
    try {
      await _registerAnalytics('view', userId, vehicleId);

      final vehicle = await getVehicleById(vehicleId);
      if (vehicle != null) {
        await updateVehicle(vehicleId, {
          'views': vehicle.stats.views + 1,
        });
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Adiciona um veículo aos favoritos do utilizador.
  Future<bool> addToFavorites(String userId, String vehicleId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('favorite_vehicles')
          .eq('id', userId)
          .single();

      List<String> favorites =
          List<String>.from(user['favorite_vehicles'] ?? []);

      if (!favorites.contains(vehicleId)) {
        favorites.add(vehicleId);

        await _supabase
            .from('users')
            .update({'favorite_vehicles': favorites}).eq('id', userId);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove um veículo dos favoritos do utilizador.
  Future<bool> removeFromFavorites(String userId, String vehicleId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('favorite_vehicles')
          .eq('id', userId)
          .single();

      List<String> favorites =
          List<String>.from(user['favorite_vehicles'] ?? []);
      favorites.remove(vehicleId);

      await _supabase
          .from('users')
          .update({'favorite_vehicles': favorites}).eq('id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtém os veículos favoritos de um utilizador.
  Future<List<VehicleModel>> getFavoriteVehicles(String userId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('favorite_vehicles')
          .eq('id', userId)
          .single();

      List<String> favoriteIds =
          List<String>.from(user['favorite_vehicles'] ?? []);

      if (favoriteIds.isEmpty) return [];

      final data = await _supabase
          .from('vehicles')
          .select()
          .inFilter('id', favoriteIds);

      return data.map((item) => VehicleModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }
}

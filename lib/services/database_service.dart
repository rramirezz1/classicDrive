import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/vehicle_model.dart';
import '../models/booking_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== VEÍCULOS ==========

  // Obter todos os veículos aprovados
  Stream<List<VehicleModel>> getApprovedVehicles() {
    return _firestore
        .collection('vehicles')
        .where('validation.status', isEqualTo: 'approved')
        .where('availability.isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Buscar veículos por categoria
  Stream<List<VehicleModel>> getVehiclesByCategory(String category) {
    return _firestore
        .collection('vehicles')
        .where('validation.status', isEqualTo: 'approved')
        .where('availability.isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Obter veículos por proprietário
  Stream<List<VehicleModel>> getVehiclesByOwner(String ownerId) {
    return _firestore
        .collection('vehicles')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Obter veículo por ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _firestore.collection('vehicles').doc(vehicleId).get();
      if (doc.exists) {
        return VehicleModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao obter veículo: $e');
      return null;
    }
  }

  // Adicionar novo veículo
  Future<String?> addVehicle(VehicleModel vehicle) async {
    try {
      final docRef =
          await _firestore.collection('vehicles').add(vehicle.toMap());
      return docRef.id;
    } catch (e) {
      print('Erro ao adicionar veículo: $e');
      return null;
    }
  }

  // Atualizar veículo
  Future<bool> updateVehicle(
    String vehicleId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).update(updates);
      return true;
    } catch (e) {
      print('Erro ao atualizar veículo: $e');
      return false;
    }
  }

  // Upload de imagens
  Future<List<String>> uploadVehicleImages(
    String vehicleId,
    List<File> images,
  ) async {
    List<String> imageUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('vehicles/$vehicleId/image_$i.jpg');
        final uploadTask = await ref.putFile(images[i]);
        final url = await uploadTask.ref.getDownloadURL();
        imageUrls.add(url);
      }
      return imageUrls;
    } catch (e) {
      print('Erro ao fazer upload de imagens: $e');
      return [];
    }
  }

  // Pesquisar veículos com filtros
  Future<List<VehicleModel>> searchVehicles({
    String? category,
    String? eventType,
    double? minPrice,
    double? maxPrice,
    String? city,
  }) async {
    Query query = _firestore
        .collection('vehicles')
        .where('validation.status', isEqualTo: 'approved')
        .where('availability.isAvailable', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (eventType != null) {
      query = query.where('eventTypes', arrayContains: eventType);
    }

    if (city != null) {
      query = query.where('location.city', isEqualTo: city);
    }

    final snapshot = await query.get();
    var vehicles = snapshot.docs
        .map(
          (doc) => VehicleModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();

    // Filtrar por preço localmente (Firestore não suporta range queries em campos diferentes)
    if (minPrice != null || maxPrice != null) {
      vehicles = vehicles.where((vehicle) {
        if (minPrice != null && vehicle.pricePerDay < minPrice) return false;
        if (maxPrice != null && vehicle.pricePerDay > maxPrice) return false;
        return true;
      }).toList();
    }

    return vehicles;
  }

  // ========== RESERVAS ==========

  // Criar reserva
  Future<String?> createBooking(BookingModel booking) async {
    try {
      print("=== CRIANDO RESERVA ===");
      print("Vehicle ID: ${booking.vehicleId}");
      print("Renter ID: ${booking.renterId}");
      print("Owner ID: ${booking.ownerId}");
      // Verificar disponibilidade
      final isAvailable = await checkVehicleAvailability(
        booking.vehicleId,
        booking.startDate,
        booking.endDate,
      );

      if (!isAvailable) {
        throw Exception('Veículo não disponível para estas datas');
      }

      // Criar reserva
      final docRef =
          await _firestore.collection('bookings').add(booking.toMap());

      // Atualizar datas bloqueadas no veículo
      await _updateBlockedDates(
        booking.vehicleId,
        booking.startDate,
        booking.endDate,
      );

      // Registar análise
      await _registerAnalytics('book', booking.renterId, booking.vehicleId);

      return docRef.id;
    } catch (e) {
      print('Erro ao criar reserva: $e');
      return null;
    }
  }

  // Verificar disponibilidade
  Future<bool> checkVehicleAvailability(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      for (var doc in bookings.docs) {
        final booking = BookingModel.fromMap(doc.data(), doc.id);

        // Verificar sobreposição de datas
        if (!(endDate.isBefore(booking.startDate) ||
            startDate.isAfter(booking.endDate))) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // Obter reservas do utilizador
  Stream<List<BookingModel>> getUserBookings(String userId,
      {bool asOwner = false}) {
    print("=== getUserBookings ===");
    print("Looking for userId: $userId");
    print("As owner: $asOwner");

    // Query mais simples sem ordenação
    if (asOwner) {
      return _firestore
          .collection('bookings')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        print("Found ${snapshot.docs.length} bookings for owner");
        return snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } else {
      return _firestore
          .collection('bookings')
          .where('renterId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        print("Found ${snapshot.docs.length} bookings for renter");
        return snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
  }

  // Atualizar estado da reserva
  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erro ao atualizar reserva: $e');
      return false;
    }
  }

  // ========== ANÁLISE E RECOMENDAÇÕES ==========

  // Registar ação do utilizador
  Future<void> _registerAnalytics(
    String action,
    String userId, [
    String? vehicleId,
  ]) async {
    try {
      await _firestore.collection('analytics').add({
        'userId': userId,
        'action': action,
        'vehicleId': vehicleId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao registar análise: $e');
    }
  }

  // Obter recomendações para o utilizador
  Future<List<VehicleModel>> getRecommendations(String userId) async {
    try {
      // Obter histórico do utilizador
      final analytics = await _firestore
          .collection('analytics')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      // Analisar categorias e preços mais vistos
      Map<String, int> categoryCount = {};
      double totalPrice = 0;
      int priceCount = 0;

      for (var doc in analytics.docs) {
        if (doc.data()['vehicleId'] != null) {
          final vehicle = await getVehicleById(doc.data()['vehicleId']);
          if (vehicle != null) {
            categoryCount[vehicle.category] =
                (categoryCount[vehicle.category] ?? 0) + 1;
            totalPrice += vehicle.pricePerDay;
            priceCount++;
          }
        }
      }

      // Determinar categoria preferida e preço médio
      String? preferredCategory;
      if (categoryCount.isNotEmpty) {
        preferredCategory = categoryCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      double avgPrice = priceCount > 0 ? totalPrice / priceCount : 100;

      // Buscar veículos recomendados
      Query query = _firestore
          .collection('vehicles')
          .where('validation.status', isEqualTo: 'approved')
          .where('availability.isAvailable', isEqualTo: true);

      if (preferredCategory != null) {
        query = query.where('category', isEqualTo: preferredCategory);
      }

      final snapshot = await query.limit(10).get();
      var recommendations = snapshot.docs
          .map(
            (doc) => VehicleModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Ordenar por proximidade de preço
      recommendations.sort((a, b) {
        final diffA = (a.pricePerDay - avgPrice).abs();
        final diffB = (b.pricePerDay - avgPrice).abs();
        return diffA.compareTo(diffB);
      });

      return recommendations.take(5).toList();
    } catch (e) {
      print('Erro ao obter recomendações: $e');
      return [];
    }
  }

  // ========== AVALIAÇÕES ==========

  // Adicionar avaliação
  Future<bool> addReview({
    required String bookingId,
    required String vehicleId,
    required String reviewerId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'bookingId': bookingId,
        'vehicleId': vehicleId,
        'reviewerId': reviewerId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Atualizar rating médio do veículo
      await _updateVehicleRating(vehicleId);

      return true;
    } catch (e) {
      print('Erro ao adicionar avaliação: $e');
      return false;
    }
  }

  // Obter avaliações de um veículo
  Stream<List<Map<String, dynamic>>> getVehicleReviews(String vehicleId) {
    return _firestore
        .collection('reviews')
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // ========== MÉTODOS AUXILIARES ==========

  // Atualizar datas bloqueadas
  Future<void> _updateBlockedDates(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final vehicle = await getVehicleById(vehicleId);
      if (vehicle == null) return;

      List<String> blockedDates = List<String>.from(
        vehicle.availability['blockedDates'] ?? [],
      );

      // Adicionar todas as datas entre início e fim
      for (var date = startDate;
          date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
          date = date.add(const Duration(days: 1))) {
        final dateStr = date.toIso8601String().split('T')[0];
        if (!blockedDates.contains(dateStr)) {
          blockedDates.add(dateStr);
        }
      }

      await updateVehicle(vehicleId, {
        'availability.blockedDates': blockedDates,
      });
    } catch (e) {
      print('Erro ao atualizar datas bloqueadas: $e');
    }
  }

  // Atualizar rating do veículo
  Future<void> _updateVehicleRating(String vehicleId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += doc.data()['rating'];
      }

      final avgRating = totalRating / reviews.docs.length;

      await updateVehicle(vehicleId, {'stats.rating': avgRating});
    } catch (e) {
      print('Erro ao atualizar rating: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de analytics para proprietários.
class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtém estatísticas gerais do proprietário.
  Future<OwnerStats> getOwnerStats(String ownerId) async {
    try {
      // Total de veículos
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('id')
          .eq('owner_id', ownerId);
      final totalVehicles = (vehiclesResponse as List).length;

      // Reservas
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('id, total_price, status, created_at')
          .inFilter('vehicle_id', 
            (vehiclesResponse as List).map((v) => v['id']).toList()
          );
      
      final bookings = bookingsResponse as List;
      final totalBookings = bookings.length;
      final completedBookings = bookings.where((b) => b['status'] == 'completed').length;
      
      // Receita total
      double totalRevenue = 0;
      for (final booking in bookings) {
        if (booking['status'] == 'completed' || booking['status'] == 'confirmed') {
          totalRevenue += (booking['total_price'] ?? 0).toDouble();
        }
      }

      // Receita este mês
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      double monthlyRevenue = 0;
      for (final booking in bookings) {
        final createdAt = DateTime.parse(booking['created_at']);
        if (createdAt.isAfter(startOfMonth) &&
            (booking['status'] == 'completed' || booking['status'] == 'confirmed')) {
          monthlyRevenue += (booking['total_price'] ?? 0).toDouble();
        }
      }

      // Rating médio
      double averageRating = 0;
      if (totalVehicles > 0) {
        final ratingsResponse = await _supabase
            .from('vehicles')
            .select('stats')
            .eq('owner_id', ownerId);
        
        double totalRating = 0;
        int ratingCount = 0;
        for (final v in ratingsResponse) {
          final stats = v['stats'];
          if (stats != null && stats['rating'] != null) {
            totalRating += (stats['rating'] as num).toDouble();
            ratingCount++;
          }
        }
        if (ratingCount > 0) {
          averageRating = totalRating / ratingCount;
        }
      }

      return OwnerStats(
        totalVehicles: totalVehicles,
        totalBookings: totalBookings,
        completedBookings: completedBookings,
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        averageRating: averageRating,
        occupancyRate: totalBookings > 0 
            ? (completedBookings / totalBookings * 100) 
            : 0,
      );
    } catch (e) {
      print('Erro ao obter stats: $e');
      return OwnerStats.empty();
    }
  }

  /// Obtém receita por mês (últimos 6 meses).
  Future<List<MonthlyRevenue>> getMonthlyRevenue(String ownerId) async {
    try {
      // Obter veículos do proprietário
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('id')
          .eq('owner_id', ownerId);
      
      if ((vehiclesResponse as List).isEmpty) return [];

      final vehicleIds = vehiclesResponse.map((v) => v['id']).toList();

      // Obter reservas dos últimos 6 meses
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('total_price, created_at, status')
          .inFilter('vehicle_id', vehicleIds)
          .gte('created_at', sixMonthsAgo.toIso8601String())
          .inFilter('status', ['completed', 'confirmed']);

      // Agrupar por mês
      final Map<String, double> revenueByMonth = {};
      for (final booking in bookingsResponse) {
        final date = DateTime.parse(booking['created_at']);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        revenueByMonth[key] = (revenueByMonth[key] ?? 0) + 
            (booking['total_price'] ?? 0).toDouble();
      }

      // Gerar lista dos últimos 6 meses
      final result = <MonthlyRevenue>[];
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        result.add(MonthlyRevenue(
          month: month,
          revenue: revenueByMonth[key] ?? 0,
        ));
      }

      return result;
    } catch (e) {
      print('Erro ao obter receita mensal: $e');
      return [];
    }
  }

  /// Obtém performance por veículo.
  Future<List<VehiclePerformance>> getVehiclePerformance(String ownerId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select('id, brand, model, year, stats, images')
          .eq('owner_id', ownerId);

      final vehicles = response as List;
      final result = <VehiclePerformance>[];

      for (final v in vehicles) {
        // Contar reservas deste veículo
        final bookingsResponse = await _supabase
            .from('bookings')
            .select('id, total_price, status')
            .eq('vehicle_id', v['id']);
        
        final bookings = bookingsResponse as List;
        final totalBookings = bookings.length;
        double revenue = 0;
        for (final b in bookings) {
          if (b['status'] == 'completed' || b['status'] == 'confirmed') {
            revenue += (b['total_price'] ?? 0).toDouble();
          }
        }

        final stats = v['stats'] ?? {};
        final images = v['images'] as List? ?? [];

        result.add(VehiclePerformance(
          vehicleId: v['id'],
          name: '${v['brand']} ${v['model']}',
          year: v['year'] ?? 0,
          imageUrl: images.isNotEmpty ? images.first : null,
          totalBookings: totalBookings,
          revenue: revenue,
          rating: (stats['rating'] ?? 0).toDouble(),
          views: (stats['views'] ?? 0).toInt(),
        ));
      }

      // Ordenar por receita
      result.sort((a, b) => b.revenue.compareTo(a.revenue));
      return result;
    } catch (e) {
      print('Erro ao obter performance: $e');
      return [];
    }
  }
}

/// Estatísticas gerais do proprietário.
class OwnerStats {
  final int totalVehicles;
  final int totalBookings;
  final int completedBookings;
  final double totalRevenue;
  final double monthlyRevenue;
  final double averageRating;
  final double occupancyRate;

  OwnerStats({
    required this.totalVehicles,
    required this.totalBookings,
    required this.completedBookings,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.averageRating,
    required this.occupancyRate,
  });

  factory OwnerStats.empty() {
    return OwnerStats(
      totalVehicles: 0,
      totalBookings: 0,
      completedBookings: 0,
      totalRevenue: 0,
      monthlyRevenue: 0,
      averageRating: 0,
      occupancyRate: 0,
    );
  }
}

/// Receita mensal.
class MonthlyRevenue {
  final DateTime month;
  final double revenue;

  MonthlyRevenue({
    required this.month,
    required this.revenue,
  });

  String get monthName {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return months[month.month - 1];
  }
}

/// Performance de um veículo.
class VehiclePerformance {
  final String vehicleId;
  final String name;
  final int year;
  final String? imageUrl;
  final int totalBookings;
  final double revenue;
  final double rating;
  final int views;

  VehiclePerformance({
    required this.vehicleId,
    required this.name,
    required this.year,
    this.imageUrl,
    required this.totalBookings,
    required this.revenue,
    required this.rating,
    required this.views,
  });
}

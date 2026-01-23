import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/analytics_widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Dashboard do proprietário com estatísticas de ganhos e veículos.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isLoading = true;
  List<VehicleModel> _vehicles = [];
  List<BookingModel> _bookings = [];
  
  double _totalEarnings = 0;
  double _monthlyEarnings = 0;
  int _totalBookings = 0;
  int _activeBookings = 0;
  double _averageRating = 0;
  List<MonthlyRevenue> _monthlyRevenueData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      if (authService.currentUser == null) return;

      final userId = authService.currentUser!.id;

      // Carregar veículos do proprietário
      final vehiclesStream = databaseService.getVehiclesByOwner(userId);
      vehiclesStream.listen((vehicles) {
        if (mounted) {
          setState(() {
            _vehicles = vehicles;
            _calculateAverageRating();
          });
        }
      });

      // Carregar reservas como proprietário
      final bookingsStream = databaseService.getUserBookings(userId, asOwner: true);
      bookingsStream.listen((bookings) {
        if (mounted) {
          setState(() {
            _bookings = bookings;
            _calculateStatistics();
          });
        }
      });

      // Carregar dados de analytics
      final analyticsService = AnalyticsService();
      final monthlyData = await analyticsService.getMonthlyRevenue(userId);
      if (mounted) {
        setState(() => _monthlyRevenueData = monthlyData);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStatistics() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    _totalBookings = _bookings.length;
    _activeBookings = _bookings
        .where((b) => b.status == 'confirmed' || b.status == 'pending')
        .length;

    _totalEarnings = _bookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.totalPrice);

    _monthlyEarnings = _bookings
        .where((b) =>
            b.status == 'completed' &&
            b.createdAt.isAfter(startOfMonth))
        .fold(0.0, (sum, b) => sum + b.totalPrice);
  }

  void _calculateAverageRating() {
    if (_vehicles.isEmpty) {
      _averageRating = 0;
      return;
    }

    final totalRating = _vehicles.fold(0.0, (sum, v) => sum + v.stats.rating);
    _averageRating = totalRating / _vehicles.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Meu Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEarningsCard(isDark),
                    const SizedBox(height: 16),
                    _buildStatsGrid(isDark),
                    const SizedBox(height: 24),
                    // Gráfico de receita mensal
                    if (_monthlyRevenueData.isNotEmpty)
                      RevenueChart(data: _monthlyRevenueData),
                    const SizedBox(height: 24),
                    _buildVehiclesSection(isDark),
                    const SizedBox(height: 24),
                    _buildRecentBookings(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEarningsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOpacity30,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.whiteOpacity20,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ganhos Totais',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '€${_totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.whiteOpacity20,
              borderRadius: AppRadius.borderRadiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Este mês: €${_monthlyEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          isDark,
          icon: Icons.directions_car_rounded,
          label: 'Veículos',
          value: _vehicles.length.toString(),
          color: AppColors.info,
        ),
        _buildStatCard(
          isDark,
          icon: Icons.calendar_today_rounded,
          label: 'Total Reservas',
          value: _totalBookings.toString(),
          color: AppColors.success,
        ),
        _buildStatCard(
          isDark,
          icon: Icons.pending_actions_rounded,
          label: 'Reservas Ativas',
          value: _activeBookings.toString(),
          color: AppColors.warning,
        ),
        _buildStatCard(
          isDark,
          icon: Icons.star_rounded,
          label: 'Avaliação Média',
          value: _averageRating.toStringAsFixed(1),
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ModernCard(
      useGlass: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meus Veículos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_vehicles.isEmpty)
          ModernCard(
            useGlass: false,
            child: Center(
              child: Text(
                'Nenhum veículo registado',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ...List.generate(
            _vehicles.take(3).length,
            (index) => _buildVehicleItem(isDark, _vehicles[index]),
          ),
      ],
    );
  }

  Widget _buildVehicleItem(bool isDark, VehicleModel vehicle) {
    final vehicleBookings = _bookings
        .where((b) => b.vehicleId == vehicle.vehicleId)
        .length;
    final vehicleEarnings = _bookings
        .where((b) =>
            b.vehicleId == vehicle.vehicleId && b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.totalPrice);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ModernCard(
        useGlass: false,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardHover : Colors.grey[200],
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: isDark ? AppColors.darkTextTertiary : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fullName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$vehicleBookings reservas • €${vehicleEarnings.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: vehicle.isAvailable
                    ? AppColors.successOpacity10
                    : AppColors.errorOpacity10,
                borderRadius: AppRadius.borderRadiusFull,
              ),
              child: Text(
                vehicle.isAvailable ? 'Ativo' : 'Inativo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: vehicle.isAvailable ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings(bool isDark) {
    final recentBookings = _bookings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservas Recentes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (recentBookings.isEmpty)
          ModernCard(
            useGlass: false,
            child: Center(
              child: Text(
                'Nenhuma reserva',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ...List.generate(
            recentBookings.length,
            (index) => _buildBookingItem(isDark, recentBookings[index]),
          ),
      ],
    );
  }

  Widget _buildBookingItem(bool isDark, BookingModel booking) {
    Color statusColor;
    String statusLabel;

    switch (booking.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = 'Pendente';
        break;
      case 'confirmed':
        statusColor = AppColors.info;
        statusLabel = 'Confirmada';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Concluída';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Cancelada';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = booking.status;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ModernCard(
        useGlass: false,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Icon(
                Icons.event_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(booking.startDate)} - ${DateFormat('dd/MM/yyyy').format(booking.endDate)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${booking.numberOfDays} dias',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${booking.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

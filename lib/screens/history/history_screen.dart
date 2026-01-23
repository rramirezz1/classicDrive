import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de histórico de reservas com design moderno.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Histórico',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: databaseService.getUserBookings(
          authService.currentUser!.id,
          asOwner: false,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final historicBookings = snapshot.data!
              .where((booking) =>
                  booking.status == 'completed' ||
                  booking.status == 'cancelled')
              .toList();

          historicBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (historicBookings.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historicBookings.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                key: ValueKey('hist_anim_${historicBookings[index].bookingId}'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration:
                    Duration(milliseconds: 200 + (index * 50).clamp(0, 300)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: _HistoryCard(
                  booking: historicBookings[index],
                  databaseService: databaseService,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.infoOpacity10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sem histórico',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'As suas reservas anteriores aparecerão aqui',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BookingModel booking;
  final DatabaseService databaseService;

  const _HistoryCard({
    required this.booking,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = booking.status == 'completed';
    final statusColor = isCompleted ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<VehicleModel?>(
        future: databaseService.getVehicleById(booking.vehicleId),
        builder: (context, vehicleSnapshot) {
          final vehicle = vehicleSnapshot.data;

          return ModernCard(
            useGlass: false,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // Imagem
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: isDark ? AppColors.darkCardHover : Colors.grey[200],
                    child: vehicle != null && vehicle.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: vehicle.images.first,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.directions_car_rounded,
                            size: 32,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : Colors.grey,
                          ),
                  ),
                ),

                // Conteúdo
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle?.fullName ?? 'A carregar...',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(booking.startDate)} - ${DateFormat('dd/MM/yyyy').format(booking.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: AppRadius.borderRadiusFull,
                          ),
                          child: Text(
                            isCompleted ? 'Concluída' : 'Cancelada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Preço e data
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€${booking.totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yy').format(booking.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

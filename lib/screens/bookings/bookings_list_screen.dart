import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../reviews/add_review_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de lista de reservas com design moderno.
class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.isOwner;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authService.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reservas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: isOwner
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                tabs: const [
                  Tab(text: 'Dos Meus Veículos'),
                  Tab(text: 'Minhas Reservas'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilterChips(isDark),

          // Lista de reservas
          Expanded(
            child: isOwner
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(asOwner: true, isDark: isDark),
                      _buildBookingsList(asOwner: false, isDark: isDark),
                    ],
                  )
                : _buildBookingsList(asOwner: false, isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      ('all', 'Todas', null),
      ('pending', 'Pendentes', AppColors.warning),
      ('confirmed', 'Confirmadas', AppColors.success),
      ('completed', 'Concluídas', AppColors.info),
      ('cancelled', 'Canceladas', AppColors.error),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filterStatus == filter.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _filterStatus = filter.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (filter.$3 ?? AppColors.primary)
                        : (isDark
                            ? AppColors.darkCardHover
                            : AppColors.lightCardHover),
                    borderRadius: AppRadius.borderRadiusFull,
                    border: Border.all(
                      color: isSelected
                          ? (filter.$3 ?? AppColors.primary)
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    filter.$2,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingsList({required bool asOwner, required bool isDark}) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    final userId = authService.currentUser?.id;
    if (userId == null) {
      return const Center(child: Text('Erro: Utilizador não autenticado'));
    }

    return StreamBuilder<List<BookingModel>>(
      stream: databaseService.getUserBookings(userId, asOwner: asOwner),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(asOwner, isDark);
        }

        var bookings = snapshot.data!;
        if (_filterStatus != 'all') {
          bookings =
              bookings.where((b) => b.status == _filterStatus).toList();
        }

        if (bookings.isEmpty) {
          return _buildNoResultsState(isDark);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _ModernBookingCard(
                booking: bookings[index],
                isOwnerView: asOwner,
                isDark: isDark,
                index: index,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorOpacity10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ocorreu um erro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool asOwner, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryOpacity10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              asOwner
                  ? 'Sem reservas nos seus veículos'
                  : 'Ainda não fez nenhuma reserva',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              asOwner
                  ? 'As reservas aparecerão aqui quando alguém reservar os seus veículos'
                  : 'Explore os veículos disponíveis e faça a sua primeira reserva',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warningOpacity10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma reserva encontrada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhuma reserva com este filtro',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ModernButton.secondary(
              text: 'Limpar Filtro',
              icon: Icons.clear_all_rounded,
              onPressed: () => setState(() => _filterStatus = 'all'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernBookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isOwnerView;
  final bool isDark;
  final int index;

  const _ModernBookingCard({
    required this.booking,
    required this.isOwnerView,
    required this.isDark,
    required this.index,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    return TweenAnimationBuilder<double>(
      key: ValueKey('booking_anim_${booking.bookingId}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: FutureBuilder<VehicleModel?>(
        future: databaseService.getVehicleById(booking.vehicleId),
        builder: (context, snapshot) {
          final vehicle = snapshot.data;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ModernCard(
              useGlass: false,
              padding: EdgeInsets.zero,
              onTap: () => _showBookingDetails(context, booking, vehicle),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(booking.status),
                              color: _getStatusColor(booking.status),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Constants.bookingStatuses[booking.status] ??
                                  booking.status,
                              style: TextStyle(
                                color: _getStatusColor(booking.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius: AppRadius.borderRadiusFull,
                          ),
                          child: Text(
                            'ID: ${booking.bookingId?.substring(0, 8).toUpperCase() ?? ""}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Vehicle image
                        ClipRRect(
                          borderRadius: AppRadius.borderRadiusMd,
                          child: Container(
                            width: 80,
                            height: 80,
                            color: isDark
                                ? AppColors.darkCardHover
                                : AppColors.lightCardHover,
                            child: vehicle != null && vehicle.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: vehicle.images.first,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.directions_car_rounded,
                                            size: 32),
                                  )
                                : Icon(
                                    Icons.directions_car_rounded,
                                    size: 32,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle?.fullName ?? 'A carregar...',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${DateFormat('dd/MM').format(booking.startDate)} - ${DateFormat('dd/MM').format(booking.endDate)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.eventType == 'wedding'
                                        ? 'Casamento'
                                        : booking.eventType == 'party'
                                            ? 'Festa'
                                            : booking.eventType == 'photoshoot'
                                                ? 'Fotografia'
                                                : 'Tour',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${booking.totalPrice.toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${booking.numberOfDays} ${booking.numberOfDays == 1 ? "dia" : "dias"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (booking.status == 'pending' && isOwnerView)
                    _buildPendingActions(context),
                  if (booking.status == 'confirmed' && isOwnerView)
                    _buildCompleteAction(context),
                  if (booking.status == 'completed' && !isOwnerView)
                    _buildReviewAction(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => _handleBookingAction(context, 'cancelled'),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Rejeitar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: () => _handleBookingAction(context, 'confirmed'),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleBookingAction(context, 'completed'),
          icon: const Icon(Icons.done_all_rounded, size: 18),
          label: const Text('Concluir Reserva'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddReviewScreen(
                  bookingId: booking.bookingId!,
                ),
              ),
            );

            if (result == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Obrigado pela sua avaliação!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderRadiusMd),
                ),
              );
            }
          },
          icon: const Icon(Icons.star_rounded, size: 18),
          label: const Text('Avaliar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(
      BuildContext context, BookingModel booking, VehicleModel? vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Detalhes da Reserva',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID da Reserva',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          booking.bookingId?.substring(0, 8).toUpperCase() ??
                              "",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: AppRadius.borderRadiusFull,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(booking.status),
                            color: _getStatusColor(booking.status),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Constants.bookingStatuses[booking.status] ??
                                booking.status,
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Vehicle
                if (vehicle != null) ...[
                  Text(
                    'Veículo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    useGlass: false,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.borderRadiusMd,
                          child: Container(
                            width: 60,
                            height: 60,
                            color: isDark
                                ? AppColors.darkCardHover
                                : AppColors.lightCardHover,
                            child: vehicle.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: vehicle.images.first,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.directions_car_rounded),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.fullName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                vehicle.location['city'] ?? 'Porto',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Dates
                Text(
                  'Período',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ModernCard(
                  useGlass: false,
                  gradient: AppColors.primaryGradient,
                  showBorder: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check-in',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(booking.startDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white70),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Check-out',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(booking.endDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${booking.numberOfDays} ${booking.numberOfDays == 1 ? "dia" : "dias"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

                const SizedBox(height: 24),

                // Event type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tipo de Evento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentOpacity10,
                        borderRadius: AppRadius.borderRadiusFull,
                      ),
                      child: Text(
                        booking.eventType == 'wedding'
                            ? '💒 Casamento'
                            : booking.eventType == 'party'
                                ? '🎉 Festa'
                                : booking.eventType == 'photoshoot'
                                    ? '📸 Fotografia'
                                    : '🚗 Tour',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                if (booking.specialRequests != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Pedidos Especiais',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentOpacity10,
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(
                        color: AppColors.accentOpacity30,
                      ),
                    ),
                    child: Text(booking.specialRequests!),
                  ),
                ],

                const SizedBox(height: 24),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '€${booking.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBookingAction(BuildContext context, String newStatus) async {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (newStatus == 'confirmed'
                        ? AppColors.success
                        : newStatus == 'completed'
                            ? AppColors.info
                            : AppColors.error)
                    .withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Icon(
                newStatus == 'confirmed'
                    ? Icons.check_circle_rounded
                    : newStatus == 'completed'
                        ? Icons.done_all_rounded
                        : Icons.cancel_rounded,
                color: newStatus == 'confirmed'
                    ? AppColors.success
                    : newStatus == 'completed'
                        ? AppColors.info
                        : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                newStatus == 'confirmed'
                    ? 'Confirmar Reserva?'
                    : newStatus == 'completed'
                        ? 'Concluir Reserva?'
                        : 'Rejeitar Reserva?',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          newStatus == 'confirmed'
              ? 'Tem a certeza que deseja confirmar esta reserva?'
              : newStatus == 'completed'
                  ? 'Tem a certeza que deseja marcar esta reserva como concluída?'
                  : 'Tem a certeza que deseja rejeitar esta reserva?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'confirmed'
                  ? AppColors.success
                  : newStatus == 'completed'
                      ? AppColors.info
                      : AppColors.error,
            ),
            child: Text(newStatus == 'confirmed'
                ? 'Confirmar'
                : newStatus == 'completed'
                    ? 'Concluir'
                    : 'Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await databaseService.updateBookingStatus(
        booking.bookingId!,
        newStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  success
                      ? 'Reserva ${newStatus == "confirmed" ? "confirmada" : newStatus == "completed" ? "concluída" : "rejeitada"} com sucesso!'
                      : 'Erro ao atualizar reserva',
                ),
              ],
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
          ),
        );
      }
    }
  }
}

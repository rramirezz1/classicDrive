import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de gestão de reservas admin com design moderno.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final AdminService _adminService = AdminService();

  String _selectedStatus = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _adminService.getAllBookings();
      setState(() {
        _bookings = bookings;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showErrorSnackbar('Erro ao carregar reservas: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  void _applyFilters() {
    _filteredBookings = _bookings.where((booking) {
      if (_selectedStatus != 'all' && booking['status'] != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    _filteredBookings.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });
  }

  double _calculateTotalRevenue() {
    return _bookings
        .where((b) => b['status'] == 'completed')
        .fold(0.0, (sum, booking) => sum + (booking['total_price'] ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Gestão de Reservas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBookings,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: _buildFilterChips(isDark),
          ),

          // Stats
          _buildStatsSection(isDark),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                  milliseconds: 200 + (index * 50).clamp(0, 300)),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: _BookingCard(
                                booking: _filteredBookings[index],
                                onRefresh: _loadBookings,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final statusFilters = [
      ('all', 'Todas', null),
      ('pending', 'Pendentes', AppColors.warning),
      ('confirmed', 'Confirmadas', AppColors.info),
      ('completed', 'Concluídas', AppColors.success),
      ('cancelled', 'Canceladas', AppColors.error),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusFilters.map((filter) {
          final isSelected = _selectedStatus == filter.$1;
          final color = filter.$3 ?? AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = filter.$1;
                  _applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : (isDark
                          ? AppColors.darkCardHover
                          : AppColors.lightCardHover),
                  borderRadius: AppRadius.borderRadiusFull,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    color: isSelected
                        ? color
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
    );
  }

  Widget _buildStatsSection(bool isDark) {
    final total = _bookings.length;
    final pending = _bookings.where((b) => b['status'] == 'pending').length;
    final confirmed = _bookings.where((b) => b['status'] == 'confirmed').length;
    final revenue = _calculateTotalRevenue();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatChip('Total', total.toString(), AppColors.info, isDark),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Pendentes', pending.toString(), AppColors.warning, isDark),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Confirmadas', confirmed.toString(), AppColors.success, isDark),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.15),
                  AppColors.success.withOpacity(0.05),
                ],
              ),
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.euro_rounded, color: AppColors.success, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Receita: €${revenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, size: 48, color: AppColors.info),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma reserva encontrada',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros',
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

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefresh;

  const _BookingCard({required this.booking, required this.onRefresh});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
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
        return Icons.help_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(booking['status']);
    final startDate = DateTime.parse(booking['start_date']);
    final endDate = DateTime.parse(booking['end_date']);
    final numberOfDays = endDate.difference(startDate).inDays + 1;

    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final renter = booking['renter'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        useGlass: false,
        padding: EdgeInsets.zero,
        onTap: () => _showBookingDetails(context, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getStatusIcon(booking['status']),
                          color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusLabel(booking['status']),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ID: ${booking['id'].toString().substring(0, 8).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veículo
                  Row(
                    children: [
                      Icon(Icons.directions_car_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vehicle != null
                              ? '${vehicle['brand']} ${vehicle['model']} (${vehicle['year']})'
                              : 'Veículo não disponível',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Cliente
                  Row(
                    children: [
                      Icon(Icons.person_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          renter?['name'] ?? 'Cliente não disponível',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Datas
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: AppRadius.borderRadiusSm,
                        ),
                        child: Text(
                          '$numberOfDays ${numberOfDays == 1 ? "dia" : "dias"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preço
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '€${(booking['total_price'] ?? 0.0).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ações
            if (booking['status'] != 'cancelled' &&
                booking['status'] != 'completed')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showBookingDetails(context, isDark),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Detalhes'),
                    ),
                    if (booking['status'] == 'pending' ||
                        booking['status'] == 'confirmed')
                      TextButton.icon(
                        onPressed: () => _cancelBooking(context),
                        icon: const Icon(Icons.cancel_rounded, size: 16),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, bool isDark) {
    final startDate = DateTime.parse(booking['start_date']);
    final endDate = DateTime.parse(booking['end_date']);
    final createdAt = DateTime.parse(booking['created_at']);
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final renter = booking['renter'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                ),
              ),

              Text(
                'Detalhes da Reserva',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'ID: ${booking['id'].toString().substring(0, 8).toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              _buildSection(context, isDark, 'Veículo', Icons.directions_car_rounded, [
                Text(vehicle != null
                    ? '${vehicle['brand']} ${vehicle['model']} (${vehicle['year']})'
                    : 'Não disponível'),
              ]),

              _buildSection(context, isDark, 'Cliente', Icons.person_rounded, [
                if (renter != null) ...[
                  _buildInfoRow(context, isDark, 'Nome', renter['name']),
                  _buildInfoRow(context, isDark, 'Email', renter['email']),
                ],
              ]),

              _buildSection(context, isDark, 'Período', Icons.calendar_today_rounded, [
                _buildInfoRow(context, isDark, 'Início',
                    DateFormat('dd/MM/yyyy').format(startDate)),
                _buildInfoRow(context, isDark, 'Fim',
                    DateFormat('dd/MM/yyyy').format(endDate)),
                _buildInfoRow(context, isDark, 'Duração',
                    '${endDate.difference(startDate).inDays + 1} dias'),
              ]),

              _buildSection(context, isDark, 'Pagamento', Icons.euro_rounded, [
                _buildInfoRow(context, isDark, 'Total',
                    '€${(booking['total_price'] ?? 0.0).toStringAsFixed(2)}'),
                _buildInfoRow(
                    context, isDark, 'Status', _getStatusLabel(booking['status'])),
                _buildInfoRow(context, isDark, 'Criada em',
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt)),
              ]),

              if (booking['special_requests'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Pedidos Especiais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(booking['special_requests']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, bool isDark, String title,
      IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Cancelar Reserva'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem a certeza que deseja cancelar esta reserva?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
            child: const Text('Cancelar Reserva'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final adminService = AdminService();
        final error = await adminService.cancelBooking(
          booking['id'],
          reasonController.text.isEmpty
              ? 'Cancelado pelo admin'
              : reasonController.text,
        );

        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Reserva cancelada com sucesso!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd),
            ),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar reserva: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

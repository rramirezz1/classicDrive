import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_input.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de gestão de veículos admin com design moderno.
class AdminVehiclesScreen extends StatefulWidget {
  const AdminVehiclesScreen({super.key});

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  bool _isLoading = true;
  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _adminService.getAllVehiclesAsModels();
      setState(() {
        _vehicles = vehicles;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackbar('Erro ao carregar veículos: $e');
      }
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
    _filteredVehicles = _vehicles.where((vehicle) {
      if (_selectedCategory != 'all' && vehicle.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != 'all' &&
          vehicle.validation.status != _selectedStatus) {
        return false;
      }
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return vehicle.brand.toLowerCase().contains(query) ||
            vehicle.model.toLowerCase().contains(query) ||
            vehicle.fullName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    _filteredVehicles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Gestão de Veículos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadVehicles,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pesquisa e Filtros
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
            child: Column(
              children: [
                ModernSearchField(
                  controller: _searchController,
                  hintText: 'Pesquisar por marca ou modelo...',
                  onChanged: (_) {
                    setState(() => _applyFilters());
                  },
                ),
                const SizedBox(height: 12),
                _buildFilterChips(isDark),
              ],
            ),
          ),

          // Stats
          _buildStatsRow(isDark),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadVehicles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredVehicles.length,
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
                              child: _VehicleCard(
                                vehicle: _filteredVehicles[index],
                                onRefresh: _loadVehicles,
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
      ('all', 'Todos', null),
      ('approved', 'Aprovados', AppColors.success),
      ('pending', 'Pendentes', AppColors.warning),
      ('rejected', 'Rejeitados', AppColors.error),
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

  Widget _buildStatsRow(bool isDark) {
    final total = _vehicles.length;
    final approved =
        _vehicles.where((v) => v.validation.status == 'approved').length;
    final pending =
        _vehicles.where((v) => v.validation.status == 'pending').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatChip('Total', total.toString(), AppColors.info, isDark),
          const SizedBox(width: 10),
          _buildStatChip(
              'Aprovados', approved.toString(), AppColors.success, isDark),
          const SizedBox(width: 10),
          _buildStatChip(
              'Pendentes', pending.toString(), AppColors.warning, isDark),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: color),
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
              color: AppColors.infoOpacity10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum veículo encontrado',
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

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onRefresh;

  const _VehicleCard({required this.vehicle, required this.onRefresh});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(vehicle.validation.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        useGlass: false,
        padding: EdgeInsets.zero,
        onTap: () => _showVehicleDetails(context, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com status
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
                      Icon(_getStatusIcon(vehicle.validation.status),
                          color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusLabel(vehicle.validation.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (!vehicle.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.errorOpacity10,
                        borderRadius: AppRadius.borderRadiusSm,
                        border: Border.all(color: AppColors.error),
                      ),
                      child: const Text(
                        'Indisponível',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Imagem
                  ClipRRect(
                    borderRadius: AppRadius.borderRadiusMd,
                    child: Container(
                      width: 90,
                      height: 90,
                      color: isDark ? AppColors.darkCardHover : Colors.grey[200],
                      child: vehicle.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: vehicle.images.first,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.directions_car_rounded,
                                size: 36,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : Colors.grey,
                              ),
                            )
                          : Icon(
                              Icons.directions_car_rounded,
                              size: 36,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.fullName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle.category.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.stats.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.visibility_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.stats.views.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.event_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.stats.totalBookings.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Preço
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€${vehicle.pricePerDay.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      Text(
                        '/dia',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ações
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    onPressed: () => _showVehicleDetails(context, isDark),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Detalhes'),
                  ),
                  if (vehicle.validation.status == 'pending')
                    TextButton.icon(
                      onPressed: () => _approveVehicle(context),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Aprovar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
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

  void _showVehicleDetails(BuildContext context, bool isDark) {
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
          child: _buildDetailsContent(context, scrollController, isDark),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(
      BuildContext context, ScrollController controller, bool isDark) {
    return ListView(
      controller: controller,
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

        // Título
        Text(
          vehicle.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'ID: ${vehicle.vehicleId?.substring(0, 8).toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),

        // Imagens
        if (vehicle.images.isNotEmpty) ...[
          Text(
            'Imagens',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: vehicle.images.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: AppRadius.borderRadiusMd,
                  child: CachedNetworkImage(
                    imageUrl: vehicle.images[index],
                    width: 180,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Descrição
        Text(
          'Descrição',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(vehicle.description),
        const SizedBox(height: 24),

        // Características
        Text(
          'Características',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vehicle.features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryOpacity10,
                borderRadius: AppRadius.borderRadiusFull,
              ),
              child: Text(
                feature,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Info rows
        _buildInfoRow(context, isDark, 'Categoria',
            vehicle.category.toUpperCase()),
        _buildInfoRow(context, isDark, 'Preço/dia',
            '€${vehicle.pricePerDay.toStringAsFixed(2)}'),
        _buildInfoRow(context, isDark, 'Criado em',
            DateFormat('dd/MM/yyyy HH:mm').format(vehicle.createdAt)),
        if (vehicle.validation.validatedAt != null)
          _buildInfoRow(
            context,
            isDark,
            'Validado em',
            DateFormat('dd/MM/yyyy HH:mm')
                .format(vehicle.validation.validatedAt!),
          ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _approveVehicle(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        title: const Text('Aprovar Veículo'),
        content: Text('Deseja aprovar "${vehicle.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final adminService = AdminService();
        await adminService.approveVehicle(vehicle.vehicleId!);
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Veículo aprovado com sucesso!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

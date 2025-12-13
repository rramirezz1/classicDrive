import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_input.dart';
import '../../widgets/modern_button.dart';
import '../../providers/comparison_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de lista de veículos com design moderno.
class VehicleListScreen extends StatefulWidget {
  final bool showOnlyMine;
  final String? category;
  final String? categoryTitle;

  const VehicleListScreen({
    super.key,
    this.showOnlyMine = false,
    this.category,
    this.categoryTitle,
  });

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  String? _selectedCategory;
  String? _selectedEventType;
  double _minPrice = 0;
  double _maxPrice = 1000;
  String _sortBy = 'recent';
  bool _showFilters = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.isOwner;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context, isOwner, isDark),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Barra de pesquisa e filtros
              SliverToBoxAdapter(
                child: _buildSearchAndFilters(context, isDark),
              ),

              // Lista de veículos
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildVehicleList(isDark),
              ),
            ],
          ),

          // Botão de comparação flutuante
          _buildCompareButton(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isOwner,
    bool isDark,
  ) {
    return AppBar(
      title: Text(
        widget.showOnlyMine
            ? 'Meus Veículos'
            : widget.categoryTitle ?? 'Veículos',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        if (isOwner)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              onPressed: () => context.push('/add-vehicle'),
              tooltip: 'Adicionar Veículo',
            ),
          ),
        if (widget.category == null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_showFilters ? AppColors.primary : AppColors.info)
                      .withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Icon(
                  _showFilters
                      ? Icons.filter_list_off_rounded
                      : Icons.filter_list_rounded,
                  color: _showFilters ? AppColors.primary : AppColors.info,
                  size: 20,
                ),
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'Filtros',
            ),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Campo de pesquisa
          ModernSearchField(
            controller: _searchController,
            hintText: 'Pesquisar por marca, modelo...',
            onChanged: (value) => setState(() {}),
            onClear: () => setState(() => _searchController.clear()),
          ),

          // Filtros expandidos
          if (widget.category == null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showFilters
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildFilters(isDark),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categorias
          _buildFilterSection(
            'Categoria',
            Icons.category_rounded,
            AppColors.accent,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                'Todas',
                _selectedCategory == null,
                () => setState(() => _selectedCategory = null),
                isDark,
              ),
              ...Constants.vehicleCategories.map((category) {
                return _buildFilterChip(
                  category == 'classic'
                      ? 'Clássicos'
                      : category == 'vintage'
                          ? 'Vintage'
                          : 'Luxo',
                  _selectedCategory == category,
                  () => setState(() {
                    _selectedCategory =
                        _selectedCategory == category ? null : category;
                  }),
                  isDark,
                );
              }),
            ],
          ),

          const SizedBox(height: 20),

          // Tipo de evento
          _buildFilterSection(
            'Tipo de Evento',
            Icons.event_rounded,
            AppColors.info,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                'Todos',
                _selectedEventType == null,
                () => setState(() => _selectedEventType = null),
                isDark,
              ),
              ...Constants.eventTypes.map((type) {
                return _buildFilterChip(
                  type == 'wedding'
                      ? 'Casamento'
                      : type == 'party'
                          ? 'Festa'
                          : type == 'photoshoot'
                              ? 'Fotografia'
                              : 'Tour',
                  _selectedEventType == type,
                  () => setState(() {
                    _selectedEventType =
                        _selectedEventType == type ? null : type;
                  }),
                  isDark,
                );
              }),
            ],
          ),

          const SizedBox(height: 20),

          // Faixa de preço
          _buildFilterSection(
            'Preço por dia',
            Icons.euro_rounded,
            AppColors.success,
            trailing: Text(
              '€${_minPrice.toInt()} - €${_maxPrice.toInt()}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 1000,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
            labels: RangeLabels(
              '€${_minPrice.toInt()}',
              '€${_maxPrice.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),

          const SizedBox(height: 20),

          // Ordenar por
          _buildFilterSection(
            'Ordenar por',
            Icons.sort_rounded,
            AppColors.primaryEnd,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              items: const [
                DropdownMenuItem(
                    value: 'recent', child: Text('Mais recentes')),
                DropdownMenuItem(
                    value: 'price_low', child: Text('Preço: menor')),
                DropdownMenuItem(
                    value: 'price_high', child: Text('Preço: maior')),
                DropdownMenuItem(value: 'rating', child: Text('Avaliação')),
              ],
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Color color,
      {Widget? trailing}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.borderRadiusSm,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCardHover : AppColors.lightCardHover),
          borderRadius: AppRadius.borderRadiusFull,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCompareButton(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Consumer<ComparisonProvider>(
        builder: (context, provider, child) {
          if (provider.isEmpty) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              boxShadow: AppShadows.primaryGlow,
              borderRadius: AppRadius.borderRadiusFull,
            ),
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/compare'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
              label: Text(
                'Comparar (${provider.count})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleList(bool isDark) {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context);

    Stream<List<VehicleModel>> vehicleStream;

    if (widget.showOnlyMine && authService.isOwner) {
      vehicleStream =
          databaseService.getVehiclesByOwner(authService.currentUser!.id);
    } else {
      vehicleStream = databaseService.getApprovedVehicles();
    }

    return StreamBuilder<List<VehicleModel>>(
      stream: vehicleStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingWidgets.vehicleListShimmer();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(authService, isDark);
        }

        var vehicles = _filterAndSortVehicles(snapshot.data!);

        if (vehicles.isEmpty) {
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
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(vehicles[index], isDark, index);
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
                color: AppColors.error.withOpacity(0.1),
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
            const SizedBox(height: 24),
            ModernButton.primary(
              text: 'Tentar novamente',
              icon: Icons.refresh_rounded,
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AuthService authService, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.showOnlyMine
                  ? 'Ainda não tem veículos'
                  : 'Sem veículos disponíveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showOnlyMine
                  ? 'Adicione o seu primeiro veículo para começar'
                  : 'Volte mais tarde para ver novos veículos',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if ((widget.showOnlyMine || authService.isOwner) &&
                widget.categoryTitle == null) ...[
              const SizedBox(height: 24),
              ModernButton.primary(
                text: 'Adicionar Veículo',
                icon: Icons.add_rounded,
                onPressed: () => context.push('/add-vehicle'),
              ),
            ],
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
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum resultado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros de pesquisa',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ModernButton.secondary(
              text: 'Limpar Filtros',
              icon: Icons.filter_list_off_rounded,
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedEventType = null;
                  _minPrice = 0;
                  _maxPrice = 1000;
                  _searchController.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  List<VehicleModel> _filterAndSortVehicles(List<VehicleModel> vehicles) {
    var filtered = vehicles.where((vehicle) {
      if (_searchController.text.isNotEmpty) {
        final search = _searchController.text.toLowerCase();
        if (!vehicle.brand.toLowerCase().contains(search) &&
            !vehicle.model.toLowerCase().contains(search) &&
            !vehicle.description.toLowerCase().contains(search)) {
          return false;
        }
      }

      final effectiveCategory = widget.category ?? _selectedCategory;
      if (effectiveCategory != null && vehicle.category != effectiveCategory) {
        return false;
      }

      if (_selectedEventType != null &&
          !vehicle.eventTypes.contains(_selectedEventType)) {
        return false;
      }

      if (vehicle.pricePerDay < _minPrice || vehicle.pricePerDay > _maxPrice) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      case 'rating':
        filtered.sort((a, b) => b.stats.rating.compareTo(a.stats.rating));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  Widget _buildVehicleCard(VehicleModel vehicle, bool isDark, int index) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwnerOfVehicle = widget.showOnlyMine ||
        vehicle.ownerId == authService.currentUser?.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: isDark ? AppShadows.softShadowDark : AppShadows.softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildVehicleImage(vehicle, isDark),
                    _buildImageOverlay(),
                    _buildPriceBadge(vehicle),
                    if (isOwnerOfVehicle) _buildDeleteButton(vehicle),
                    _buildCompareButton2(vehicle),
                  ],
                ),
              ),

              // Informações
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehicleTitle(vehicle),
                    const SizedBox(height: 10),
                    _buildVehicleDetails(vehicle, isDark),
                    const SizedBox(height: 10),
                    _buildVehicleRating(vehicle, isDark),
                    if (authService.isOwner || widget.showOnlyMine)
                      _buildStatusBadge(vehicle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(VehicleModel vehicle, bool isDark) {
    if (vehicle.images.isNotEmpty) {
      return Hero(
        tag: 'vehicle-${vehicle.vehicleId}',
        child: CachedNetworkImage(
          imageUrl: vehicle.images.first,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
            child: const Icon(Icons.error),
          ),
        ),
      );
    }
    return Container(
      color: isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
      child: Icon(
        Icons.directions_car_rounded,
        size: 64,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 80,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBadge(VehicleModel vehicle) {
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.borderRadiusFull,
        ),
        child: Text(
          '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(VehicleModel vehicle) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => _confirmDelete(context, vehicle),
          tooltip: 'Apagar Veículo',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildCompareButton2(VehicleModel vehicle) {
    return Positioned(
      top: 12,
      right: 12,
      child: Consumer<ComparisonProvider>(
        builder: (context, provider, _) {
          final isSelected = provider.isSelected(vehicle);
          return Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.success.withOpacity(0.9)
                  : Colors.black.withOpacity(0.4),
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: IconButton(
              icon: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (!isSelected && !provider.canAdd) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Máximo de 3 veículos para comparação'),
                        ],
                      ),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadiusMd),
                    ),
                  );
                  return;
                }
                provider.toggleVehicle(vehicle);
              },
              tooltip: 'Comparar',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleTitle(VehicleModel vehicle) {
    return Text(
      vehicle.fullName,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildVehicleDetails(VehicleModel vehicle, bool isDark) {
    final tertiaryColor =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Row(
      children: [
        Icon(Icons.category_outlined, size: 14, color: tertiaryColor),
        const SizedBox(width: 4),
        Text(
          vehicle.category == 'classic'
              ? 'Clássico'
              : vehicle.category == 'vintage'
                  ? 'Vintage'
                  : 'Luxo',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 16),
        Icon(Icons.location_on_outlined, size: 14, color: tertiaryColor),
        const SizedBox(width: 4),
        Text(
          vehicle.location['city'] ?? 'Porto',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVehicleRating(VehicleModel vehicle, bool isDark) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < vehicle.stats.rating.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: 16,
            color: AppColors.accent,
          );
        }),
        const SizedBox(width: 6),
        Text(
          '${vehicle.stats.rating.toStringAsFixed(1)} (${vehicle.stats.totalReviews})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        if (vehicle.features.isNotEmpty)
          ...vehicle.features.take(3).map((feature) {
            IconData icon;
            switch (feature.toLowerCase()) {
              case 'ac':
                icon = Icons.ac_unit_rounded;
                break;
              case 'chauffeur':
                icon = Icons.person_rounded;
                break;
              case 'decorated':
                icon = Icons.auto_awesome_rounded;
                break;
              default:
                icon = Icons.check_rounded;
            }
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatusBadge(VehicleModel vehicle) {
    Color statusColor;
    String statusText;

    switch (vehicle.validation.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusText = 'Aprovado';
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'Pendente';
        break;
      default:
        statusColor = AppColors.error;
        statusText = 'Rejeitado';
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VehicleModel vehicle) async {
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
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Apagar Veículo'),
          ],
        ),
        content: Text(
          'Tem a certeza que deseja apagar o veículo "${vehicle.brand} ${vehicle.model}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('A apagar veículo...'),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
        ),
      );

      final success = await databaseService.deleteVehicle(vehicle.vehicleId!);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Veículo apagado com sucesso'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd),
            ),
          );
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Erro ao apagar veículo'),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd),
            ),
          );
        }
      }
    }
  }
}

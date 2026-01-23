import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_input.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de pesquisa de veículos com design moderno.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  RangeValues _priceRange = const RangeValues(0, 500);
  double _minRating = 0;
  bool _showFilters = false;

  List<VehicleModel> _allVehicles = [];
  List<VehicleModel> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() async {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    databaseService.getApprovedVehicles().listen((vehicles) {
      setState(() {
        _allVehicles = vehicles;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredVehicles = _allVehicles.where((vehicle) {
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          if (!vehicle.fullName.toLowerCase().contains(searchTerm) &&
              !vehicle.brand.toLowerCase().contains(searchTerm) &&
              !vehicle.model.toLowerCase().contains(searchTerm)) {
            return false;
          }
        }

        if (_selectedCategory != 'all' &&
            vehicle.category != _selectedCategory) {
          return false;
        }

        if (vehicle.pricePerDay < _priceRange.start ||
            vehicle.pricePerDay > _priceRange.end) {
          return false;
        }

        if (vehicle.stats.rating < _minRating) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Procurar Veículos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de pesquisa
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
                Row(
                  children: [
                    Expanded(
                      child: ModernSearchField(
                        controller: _searchController,
                        hintText: 'Pesquisar marca, modelo...',
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? AppColors.primaryOpacity15
                              : (isDark
                                  ? AppColors.darkCardHover
                                  : AppColors.lightCardHover),
                          borderRadius: AppRadius.borderRadiusMd,
                          border: Border.all(
                            color: _showFilters
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Icon(
                          _showFilters
                              ? Icons.filter_list_off_rounded
                              : Icons.filter_list_rounded,
                          color: _showFilters
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                // Filtros expandíveis
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildFilters(isDark),
                  crossFadeState: _showFilters
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),

          // Contador de resultados
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '${_filteredVehicles.length} veículo${_filteredVehicles.length != 1 ? 's' : ''} encontrado${_filteredVehicles.length != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Resultados
          Expanded(
            child: _filteredVehicles.isEmpty
                ? _buildEmptyState(isDark)
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredVehicles.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('search_anim_${_filteredVehicles[index].vehicleId}'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration:
                            Duration(milliseconds: 200 + (index * 30).clamp(0, 200)),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child:
                            _VehicleGridCard(vehicle: _filteredVehicles[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoria
          Text(
            'Categoria',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          _buildCategoryChips(isDark),
          const SizedBox(height: 18),

          // Preço
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preço por dia',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryOpacity10,
                  borderRadius: AppRadius.borderRadiusFull,
                ),
                child: Text(
                  '€${_priceRange.start.toInt()} - €${_priceRange.end.toInt()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryOpacity20,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primaryOpacity10,
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 500,
              divisions: 50,
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                  _applyFilters();
                });
              },
            ),
          ),

          // Avaliação mínima
          Row(
            children: [
              Text(
                'Avaliação mínima:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_minRating == index + 1) {
                          _minRating = 0;
                        } else {
                          _minRating = index + 1.0;
                        }
                        _applyFilters();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        index < _minRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.accent,
                        size: 26,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    final categories = [
      ('all', 'Todos'),
      ('classic', 'Clássicos'),
      ('vintage', 'Vintage'),
      ('luxury', 'Luxo'),
      ('sports', 'Desportivo'),
      ('exotic', 'Exótico'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat.$1;
                  _applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOpacity15
                      : (isDark
                          ? AppColors.darkCardHover
                          : AppColors.lightCardHover),
                  borderRadius: AppRadius.borderRadiusFull,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  cat.$2,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
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
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.primary,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _VehicleGridCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleGridCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                color: isDark ? AppColors.darkCardHover : Colors.grey[200],
                child: vehicle.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: vehicle.images.first,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.directions_car_rounded,
                        size: 40,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : Colors.grey,
                      ),
              ),
            ),
          ),
          // Informações
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          vehicle.stats.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

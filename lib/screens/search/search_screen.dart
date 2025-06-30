import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../models/vehicle_model.dart';

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
        // Filtro de pesquisa por texto
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          if (!vehicle.fullName.toLowerCase().contains(searchTerm) &&
              !vehicle.brand.toLowerCase().contains(searchTerm) &&
              !vehicle.model.toLowerCase().contains(searchTerm)) {
            return false;
          }
        }

        // Filtro de categoria
        if (_selectedCategory != 'all' &&
            vehicle.category != _selectedCategory) {
          return false;
        }

        // Filtro de preço
        if (vehicle.pricePerDay < _priceRange.start ||
            vehicle.pricePerDay > _priceRange.end) {
          return false;
        }

        // Filtro de avaliação
        if (vehicle.stats.rating < _minRating) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurar Veículos'),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar marca, modelo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                      ),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),

                // Filtros expandíveis
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showFilters ? null : 0,
                  child: _showFilters ? _buildFilters() : null,
                ),
              ],
            ),
          ),

          // Resultados
          Expanded(
            child: _filteredVehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum veículo encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente ajustar os filtros',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredVehicles.length,
                    itemBuilder: (context, index) {
                      return _VehicleGridCard(
                          vehicle: _filteredVehicles[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoria
          const Text(
            'Categoria',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _CategoryChip(
                label: 'Todos',
                value: 'all',
                groupValue: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _applyFilters();
                  });
                },
              ),
              _CategoryChip(
                label: 'Clássicos',
                value: 'classic',
                groupValue: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _applyFilters();
                  });
                },
              ),
              _CategoryChip(
                label: 'Vintage',
                value: 'vintage',
                groupValue: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _applyFilters();
                  });
                },
              ),
              _CategoryChip(
                label: 'Luxo',
                value: 'luxury',
                groupValue: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preço
          Text(
            'Preço por dia: €${_priceRange.start.toInt()} - €${_priceRange.end.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 500,
            divisions: 50,
            labels: RangeLabels(
              '€${_priceRange.start.toInt()}',
              '€${_priceRange.end.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
                _applyFilters();
              });
            },
          ),

          // Avaliação mínima
          Row(
            children: [
              const Text(
                'Avaliação mínima:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _minRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _minRating = index + 1.0;
                        if (_minRating == index + 1) {
                          _minRating = 0; // Reset se clicar na mesma estrela
                        }
                        _applyFilters();
                      });
                    },
                  );
                }),
              ),
            ],
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  const _CategoryChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _VehicleGridCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleGridCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[300],
                child: vehicle.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: vehicle.images.first,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.directions_car,
                        size: 48,
                        color: Colors.grey,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            vehicle.stats.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
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
      ),
    );
  }
}

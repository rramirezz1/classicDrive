import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/animated_widgets.dart';

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
  String _sortBy = 'recent'; // recent, price_low, price_high, rating
  bool _showFilters = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se veio com categoria pré-selecionada
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showOnlyMine
            ? 'Meus Veículos'
            : widget.categoryTitle ?? 'Veículos'),
        elevation: 0,
        actions: [
          if (isOwner && (widget.showOnlyMine || !widget.showOnlyMine))
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/add-vehicle'),
                tooltip: 'Adicionar Veículo',
              ),
            ),
          // Só mostra filtros se não for tela de categoria específica
          if (widget.category == null)
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 300),
              child: IconButton(
                icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                tooltip: 'Filtros',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa com animação
          AnimatedWidgets.fadeInContent(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Campo de pesquisa
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por marca, modelo...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) => setState(() {}),
                  ),

                  // Filtros expandidos com animação (só se não for categoria específica)
                  if (widget.category == null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _showFilters ? null : 0,
                      child: _showFilters
                          ? AnimatedWidgets.fadeInContent(
                              duration: const Duration(milliseconds: 200),
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _buildFilters(),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),

          // Lista de veículos
          Expanded(
            child: _buildVehicleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categorias
        const Text(
          'Categoria',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Todas'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                });
              },
            ),
            ...Constants.vehicleCategories.map((category) {
              return FilterChip(
                label: Text(category == 'classic'
                    ? 'Clássicos'
                    : category == 'vintage'
                        ? 'Vintage'
                        : 'Luxo'),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
              );
            }),
          ],
        ),

        const SizedBox(height: 16),

        // Tipo de evento
        const Text(
          'Tipo de Evento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Todos'),
              selected: _selectedEventType == null,
              onSelected: (selected) {
                setState(() {
                  _selectedEventType = null;
                });
              },
            ),
            ...Constants.eventTypes.map((type) {
              return FilterChip(
                label: Text(type == 'wedding'
                    ? 'Casamento'
                    : type == 'party'
                        ? 'Festa'
                        : type == 'photoshoot'
                            ? 'Fotografia'
                            : 'Tour'),
                selected: _selectedEventType == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedEventType = selected ? type : null;
                  });
                },
              );
            }),
          ],
        ),

        const SizedBox(height: 16),

        // Faixa de preço
        Row(
          children: [
            const Text(
              'Preço por dia: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '€${_minPrice.toInt()} - €${_maxPrice.toInt()}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: 0,
          max: 1000,
          divisions: 20,
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

        const SizedBox(height: 16),

        // Ordenar por
        Row(
          children: [
            const Text(
              'Ordenar por: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'recent', child: Text('Mais recentes')),
                DropdownMenuItem(
                    value: 'price_low', child: Text('Preço: menor')),
                DropdownMenuItem(
                    value: 'price_high', child: Text('Preço: maior')),
                DropdownMenuItem(value: 'rating', child: Text('Avaliação')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleList() {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context);

    // Determinar qual stream usar
    Stream<List<VehicleModel>> vehicleStream;

    if (widget.showOnlyMine && authService.isOwner) {
      // Mostrar apenas veículos do proprietário
      vehicleStream =
          databaseService.getVehiclesByOwner(authService.currentUser!.uid);
    } else {
      // Mostrar todos os veículos aprovados
      vehicleStream = databaseService.getApprovedVehicles();
    }

    return StreamBuilder<List<VehicleModel>>(
      stream: vehicleStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingWidgets.vehicleListShimmer();
        }

        if (snapshot.hasError) {
          return AnimatedWidgets.fadeInContent(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  AnimatedWidgets.animatedButton(
                    text: 'Tentar novamente',
                    icon: Icons.refresh,
                    onPressed: () => setState(() {}),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return AnimatedWidgets.fadeInContent(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.showOnlyMine
                        ? 'Ainda não tem veículos\nClique em + para adicionar'
                        : widget.categoryTitle != null
                            ? 'Nenhum veículo ${widget.categoryTitle!.toLowerCase()} disponível'
                            : authService.isOwner
                                ? 'Ainda não tem veículos\nClique em + para adicionar'
                                : 'Não há veículos disponíveis',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if ((widget.showOnlyMine || authService.isOwner) &&
                      widget.categoryTitle == null) ...[
                    const SizedBox(height: 24),
                    AnimatedWidgets.animatedButton(
                      text: 'Adicionar Veículo',
                      icon: Icons.add,
                      onPressed: () => context.push('/add-vehicle'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Filtrar e ordenar veículos
        var vehicles = _filterAndSortVehicles(snapshot.data!);

        if (vehicles.isEmpty) {
          return AnimatedWidgets.fadeInContent(
            child: const Center(
              child:
                  Text('Nenhum veículo encontrado com os filtros selecionados'),
            ),
          );
        }

        // Exibir lista de veículos
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            // Pequeno delay para mostrar a animação
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return AnimatedListItem(
                index: index,
                delay: const Duration(milliseconds: 50),
                child: _buildVehicleListItem(vehicles[index]),
              );
            },
          ),
        );
      },
    );
  }

  List<VehicleModel> _filterAndSortVehicles(List<VehicleModel> vehicles) {
    // Aplicar filtros
    var filtered = vehicles.where((vehicle) {
      // Filtro de pesquisa
      if (_searchController.text.isNotEmpty) {
        final search = _searchController.text.toLowerCase();
        if (!vehicle.brand.toLowerCase().contains(search) &&
            !vehicle.model.toLowerCase().contains(search) &&
            !vehicle.description.toLowerCase().contains(search)) {
          return false;
        }
      }

      // Filtro de categoria (considera categoria vinda por parâmetro)
      final effectiveCategory = widget.category ?? _selectedCategory;
      if (effectiveCategory != null && vehicle.category != effectiveCategory) {
        return false;
      }

      // Filtro de tipo de evento
      if (_selectedEventType != null &&
          !vehicle.eventTypes.contains(_selectedEventType)) {
        return false;
      }

      // Filtro de preço
      if (vehicle.pricePerDay < _minPrice || vehicle.pricePerDay > _maxPrice) {
        return false;
      }

      return true;
    }).toList();

    // Ordenar
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

  Widget _buildVehicleListItem(VehicleModel vehicle) {
    return AnimatedWidgets.animatedVehicleCard(
      // CARD ANIMADO
      onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO ANIMATION PARA IMAGEM
            AspectRatio(
              aspectRatio: 16 / 9,
              child: vehicle.images.isNotEmpty
                  ? AnimatedWidgets.heroVehicleImage(
                      vehicleId: vehicle.vehicleId!,
                      imageUrl: vehicle.images.first,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.directions_car,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // Informações
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e preço
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Categoria e localização
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.category == 'classic'
                            ? 'Clássico'
                            : vehicle.category == 'vintage'
                                ? 'Vintage'
                                : 'Luxo',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.location['city'] ?? 'Porto',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Avaliação e características
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < vehicle.stats.rating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '${vehicle.stats.rating.toStringAsFixed(1)} (${vehicle.stats.totalBookings})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (vehicle.features.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: vehicle.features.take(3).map((feature) {
                            IconData icon;
                            switch (feature.toLowerCase()) {
                              case 'ac':
                                icon = Icons.ac_unit;
                                break;
                              case 'chauffeur':
                                icon = Icons.person;
                                break;
                              case 'decorated':
                                icon = Icons.auto_awesome;
                                break;
                              default:
                                icon = Icons.check;
                            }
                            return Icon(icon,
                                size: 16, color: Colors.grey[600]);
                          }).toList(),
                        ),
                    ],
                  ),

                  // Status (para proprietários ou na tela "Meus Veículos")
                  if (Provider.of<AuthService>(context).isOwner ||
                      widget.showOnlyMine) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle.validation.status == 'approved'
                            ? Colors.green.withOpacity(0.1)
                            : vehicle.validation.status == 'pending'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vehicle.validation.status == 'approved'
                            ? 'Aprovado'
                            : vehicle.validation.status == 'pending'
                                ? 'Pendente'
                                : 'Rejeitado',
                        style: TextStyle(
                          fontSize: 12,
                          color: vehicle.validation.status == 'approved'
                              ? Colors.green
                              : vehicle.validation.status == 'pending'
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classe auxiliar para animação de itens da lista
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Duration delay;
  final Widget child;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.delay,
    required this.child,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Delay baseado no índice
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

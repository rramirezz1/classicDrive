import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/recommendation_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/rating_widget.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  List<VehicleRecommendation>? _recommendations;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, high_match, nearby, affordable

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final recommendations =
          await _recommendationService.getPersonalizedRecommendations(
        authService.currentUser!.id,
        limit: 50, // Carregar mais recomendações
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error logged silently
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<VehicleRecommendation> get _filteredRecommendations {
    if (_recommendations == null) return [];

    switch (_selectedFilter) {
      case 'high_match':
        return _recommendations!.where((r) => r.score >= 0.7).toList();
      case 'nearby':
        // Filtrar por proximidade (assumindo que há coordenadas)
        return _recommendations!;
      case 'affordable':
        return _recommendations!
          ..sort(
              (a, b) => a.vehicle.pricePerDay.compareTo(b.vehicle.pricePerDay));
      default:
        return _recommendations!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recomendações Personalizadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _recommendations == null || _recommendations!.isEmpty
              ? _buildEmptyState()
              : _buildRecommendationsList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: LoadingWidgets.vehicleCardShimmer(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ainda sem recomendações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete o seu perfil e explore veículos\npara receber recomendações personalizadas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.explore),
            label: const Text('Explorar Veículos'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    final filteredList = _filteredRecommendations;

    return Column(
      children: [
        // Filtros
        AnimatedWidgets.fadeInContent(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Todos', 'all', filteredList.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Alta Compatibilidade',
                  'high_match',
                  _recommendations!.where((r) => r.score >= 0.7).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Próximos', 'nearby', filteredList.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Económicos', 'affordable', filteredList.length),
              ],
            ),
          ),
        ),

        // Lista de recomendações
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              return AnimatedWidgets.fadeInContent(
                delay: Duration(milliseconds: index * 50),
                child: _RecommendationCard(
                  recommendation: filteredList[index],
                  onTap: () => _onVehicleTap(filteredList[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
    );
  }

  void _onVehicleTap(VehicleRecommendation recommendation) {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Registar clique
    _recommendationService.logRecommendationClick(
      authService.currentUser!.id,
      recommendation.vehicle.vehicleId!,
    );

    // Navegar para detalhes
    context.push('/vehicle/${recommendation.vehicle.vehicleId}');
  }
}

class _RecommendationCard extends StatelessWidget {
  final VehicleRecommendation recommendation;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = recommendation.vehicle;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com badge de match
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: vehicle.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vehicle.images.first,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.directions_car,
                            size: 64,
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchColor(recommendation.score),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(recommendation.score * 100).toInt()}% Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Informações
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e preço
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    vehicle.location['city'] ?? 'Porto',
                                    style: TextStyle(color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '€${vehicle.pricePerDay.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Text(
                            'por dia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Avaliação
                  RatingDisplay(
                    rating: vehicle.stats.rating,
                    totalReviews: vehicle.stats.totalBookings,
                  ),

                  const SizedBox(height: 12),

                  // Razões da recomendação
                  if (recommendation.reasons.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Porquê esta recomendação?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendation.reasons.take(3).map((reason) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.blue;
  }
}

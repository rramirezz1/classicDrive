import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../models/vehicle_model.dart';
import 'animated_widgets.dart';
import 'loading_widgets.dart';

class RecommendationsWidget extends StatefulWidget {
  final String title;
  final int limit;
  final bool showReasons;

  const RecommendationsWidget({
    super.key,
    this.title = 'Recomendados para Si',
    this.limit = 5,
    this.showReasons = true,
  });

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  final RecommendationService _recommendationService = RecommendationService();
  List<VehicleRecommendation>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    try {
      final recommendations =
          await _recommendationService.getPersonalizedRecommendations(
        authService.currentUser!.uid,
        limit: widget.limit,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar recomendações: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: LoadingWidgets.vehicleCardShimmer(),
              ),
            ),
          ),
        ],
      );
    }

    if (_recommendations == null || _recommendations!.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedWidgets.fadeInContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navegar para página de recomendações completa
                    context.push('/recommendations');
                  },
                  child: const Text('Ver mais'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.showReasons ? 320 : 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendations!.length,
              itemBuilder: (context, index) {
                final recommendation = _recommendations![index];
                return AnimatedWidgets.fadeInContent(
                  delay: Duration(milliseconds: index * 100),
                  child: _RecommendationCard(
                    recommendation: recommendation,
                    showReasons: widget.showReasons,
                    onTap: () => _onVehicleTap(recommendation),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onVehicleTap(VehicleRecommendation recommendation) {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Registar clique
    _recommendationService.logRecommendationClick(
      authService.currentUser!.uid,
      recommendation.vehicle.vehicleId!,
    );

    // Navegar para detalhes
    context.push('/vehicle/${recommendation.vehicle.vehicleId}');
  }
}

class _RecommendationCard extends StatelessWidget {
  final VehicleRecommendation recommendation;
  final bool showReasons;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.showReasons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = recommendation.vehicle;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
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
                              size: 48,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(recommendation.score * 100).toInt()}% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.location['city'] ?? 'Porto',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Avaliação
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < vehicle.stats.rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.stats.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Razões da recomendação
                    if (showReasons && recommendation.reasons.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          recommendation.reasons.first,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para preços dinâmicos
class DynamicPriceWidget extends StatefulWidget {
  final VehicleModel vehicle;
  final DateTime startDate;
  final DateTime endDate;

  const DynamicPriceWidget({
    super.key,
    required this.vehicle,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<DynamicPriceWidget> createState() => _DynamicPriceWidgetState();
}

class _DynamicPriceWidgetState extends State<DynamicPriceWidget> {
  final RecommendationService _recommendationService = RecommendationService();
  double? _dynamicPrice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  @override
  void didUpdateWidget(DynamicPriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _calculatePrice();
    }
  }

  Future<void> _calculatePrice() async {
    setState(() => _isLoading = true);

    try {
      final price = await _recommendationService.calculateDynamicPrice(
        vehicle: widget.vehicle,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (mounted) {
        setState(() {
          _dynamicPrice = price;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dynamicPrice = widget.vehicle.pricePerDay;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final difference = _dynamicPrice! - widget.vehicle.pricePerDay;
    final percentChange = (difference / widget.vehicle.pricePerDay * 100).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (difference != 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: difference > 0 ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${difference > 0 ? '+' : ''}${percentChange.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: difference > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '€${_dynamicPrice!.toStringAsFixed(0)}/dia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        if (difference != 0)
          Text(
            'Preço base: €${widget.vehicle.pricePerDay.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

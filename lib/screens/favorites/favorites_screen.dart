import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/modern_error_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de veículos favoritos com funcionalidade completa.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<VehicleModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      if (authService.currentUser == null) return;

      final favorites =
          await databaseService.getFavoriteVehicles(authService.currentUser!.id);

      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String vehicleId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    final success = await databaseService.removeFromFavorites(
      authService.currentUser!.id,
      vehicleId,
    );

    if (success) {
      setState(() {
        _favorites.removeWhere((v) => v.vehicleId == vehicleId);
      });
      _showSnackbar('Removido dos favoritos', AppColors.info);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Favoritos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadFavorites,
            ),
        ],
      ),
      body: _isLoading
          ? const VehicleListSkeleton(itemCount: 3)
          : _favorites.isEmpty
              ? _buildEmptyState(isDark)
              : _buildFavoritesList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ModernEmptyWidget(
      icon: Icons.favorite_border_rounded,
      title: 'Sem favoritos',
      message: 'Adicione veículos aos favoritos para acesso rápido',
      action: ElevatedButton.icon(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
        ),
        icon: const Icon(Icons.search_rounded, color: Colors.white),
        label: const Text(
          'Explorar Veículos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            key: ValueKey('fav_anim_${_favorites[index].vehicleId}'),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 50).clamp(0, 300)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _FavoriteCard(
              vehicle: _favorites[index],
              onRemove: () => _removeFavorite(_favorites[index].vehicleId!),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.vehicle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(vehicle.vehicleId!),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.borderRadiusLg,
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: ModernCard(
          useGlass: false,
          padding: EdgeInsets.zero,
          onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
          child: Row(
            children: [
              // Imagem
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 120,
                  height: 110,
                  color: isDark ? AppColors.darkCardHover : Colors.grey[200],
                  child: vehicle.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vehicle.images.first,
                          fit: BoxFit.cover,
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

              // Conteúdo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.fullName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.stats.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              vehicle.location['city'] ?? 'Portugal',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.errorOpacity10,
                                borderRadius: AppRadius.borderRadiusSm,
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

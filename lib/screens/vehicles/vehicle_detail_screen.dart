import 'dart:ui';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/user_model.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../reviews/vehicle_reviews_screen.dart';
import '../../widgets/loading_widgets.dart';
import 'edit_vehicle_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de detalhes do veículo com design moderno.
class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  VehicleModel? _vehicle;
  UserModel? _owner;
  bool _isLoading = true;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      final vehicle = await databaseService.getVehicleById(widget.vehicleId);

      if (vehicle != null) {
        UserModel? owner;
        try {
          final ownerData = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', vehicle.ownerId)
              .maybeSingle();

          if (ownerData != null) {
            owner = UserModel.fromMap(ownerData);
          }
        } catch (e) {
          // Ignora erro ao buscar proprietário
        }

        setState(() {
          _vehicle = vehicle;
          _owner = owner;
          _isLoading = false;
        });

        // Verificação e correção automática de stats
        _verifyAndFixStats(vehicle, databaseService);

        // Verificar se é favorito
        _checkIfFavorite();
      } else {
        if (mounted) {
          _showErrorSnackbar('Veículo não encontrado');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Erro ao carregar veículo: $e');
      }
    }
  }

  Future<void> _verifyAndFixStats(
      VehicleModel vehicle, DatabaseService databaseService) async {
    try {
      final reviews =
          await databaseService.getVehicleReviews(vehicle.vehicleId!);
      final realReviewCount = reviews.length;

      double realRating = 0.0;
      if (realReviewCount > 0) {
        realRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            realReviewCount;
      }

      if (vehicle.stats.totalReviews != realReviewCount ||
          (realReviewCount > 0 &&
              (vehicle.stats.rating - realRating).abs() > 0.01)) {
        final newStats = {
          'total_bookings': vehicle.stats.totalBookings,
          'rating': realRating,
          'views': vehicle.stats.views,
          'total_reviews': realReviewCount,
        };

        await databaseService.updateVehicle(vehicle.vehicleId!, {
          'stats': newStats,
        });

        if (mounted) {
          final updatedVehicle =
              await databaseService.getVehicleById(widget.vehicleId);
          if (updatedVehicle != null) {
            setState(() => _vehicle = updatedVehicle);
          }
        }
      }
    } catch (e) {
      // Ignora erro ao verificar stats
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(body: LoadingWidgets.vehicleDetailShimmer());
    }

    if (_vehicle == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.errorOpacity50,
              ),
              const SizedBox(height: 16),
              Text(
                'Veículo não encontrado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.currentUser?.id == _vehicle!.ownerId;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildImageHeader(context, isDark),
              SliverToBoxAdapter(
                child: _buildContent(context, isDark, isOwner),
              ),
            ],
          ),
          // Botão voltar
          _buildBackButton(context, isDark),
          // Botão favorito
          if (!isOwner) _buildFavoriteButton(context, isDark),
          // Botão partilhar
          _buildShareButton(context, isDark, isOwner),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, isDark, isOwner),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blackOpacity40,
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context, bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blackOpacity40,
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_isFavorite),
              color: _isFavorite ? AppColors.error : Colors.white,
            ),
          ),
          onPressed: _toggleFavorite,
        ),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, bool isDark, bool isOwner) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: isOwner ? 16 : 72,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blackOpacity40,
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: _shareVehicle,
        ),
      ),
    );
  }

  Future<void> _shareVehicle() async {
    if (_vehicle == null) return;

    final deepLink = 'classicdrive://vehicle/${_vehicle!.vehicleId}';
    final shareText = '''
🚗 ${_vehicle!.fullName}

📍 ${_vehicle!.location ?? 'Portugal'}
💰 €${_vehicle!.pricePerDay.toStringAsFixed(0)}/dia
⭐ ${_vehicle!.stats.rating.toStringAsFixed(1)}

Aluga este veículo clássico na ClassicDrive!

$deepLink
''';

    // Copiar para clipboard e mostrar opções
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareSheet(context, shareText, deepLink),
    );
  }

  Widget _buildShareSheet(BuildContext context, String shareText, String deepLink) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : Colors.grey[300],
              borderRadius: AppRadius.borderRadiusFull,
            ),
          ),
          Text(
            'Partilhar ${_vehicle!.fullName}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                context,
                icon: Icons.copy_rounded,
                label: 'Copiar Link',
                color: AppColors.primary,
                onTap: () async {
                  await _copyToClipboard(deepLink);
                  if (mounted) Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.message_rounded,
                label: 'Mensagem',
                color: AppColors.success,
                onTap: () async {
                  final uri = Uri.parse('sms:?body=${Uri.encodeComponent(shareText)}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.email_rounded,
                label: 'Email',
                color: AppColors.info,
                onTap: () async {
                  final uri = Uri.parse(
                    'mailto:?subject=${Uri.encodeComponent('Veículo Clássico: ${_vehicle!.fullName}')}&body=${Uri.encodeComponent(shareText)}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackbar('Link copiado!');
  }

  Future<void> _startConversation() async {
    if (_vehicle == null || _owner == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      _showErrorSnackbar('Faz login para enviar mensagens');
      return;
    }

    final chatService = ChatService();
    final conversation = await chatService.getOrCreateConversation(
      currentUserId: currentUser.id,
      otherUserId: _owner!.id,
      currentUserName: currentUser.userMetadata?['name'] ?? 'Utilizador',
      otherUserName: _owner!.name,
      vehicleId: _vehicle!.vehicleId,
      vehicleName: _vehicle!.fullName,
    );

    if (conversation != null && mounted) {
      context.push('/chat/${conversation.conversationId}');
    } else {
      _showErrorSnackbar('Erro ao iniciar conversa');
    }
  }

  Future<void> _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (authService.currentUser == null || _vehicle == null) return;

    setState(() => _isFavorite = !_isFavorite);

    bool success;
    if (_isFavorite) {
      success = await databaseService.addToFavorites(
        authService.currentUser!.id,
        _vehicle!.vehicleId!,
      );
    } else {
      success = await databaseService.removeFromFavorites(
        authService.currentUser!.id,
        _vehicle!.vehicleId!,
      );
    }

    if (!success && mounted) {
      setState(() => _isFavorite = !_isFavorite);
      _showErrorSnackbar('Erro ao atualizar favoritos');
    } else if (success && mounted) {
      _showSuccessSnackbar(_isFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos');
    }
  }

  Future<void> _checkIfFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (authService.currentUser == null || _vehicle == null) return;

    try {
      final favorites = await databaseService.getFavoriteVehicles(authService.currentUser!.id);
      if (mounted) {
        setState(() {
          _isFavorite = favorites.any((v) => v.vehicleId == _vehicle!.vehicleId);
        });
      }
    } catch (e) {
      // Ignore error
    }
  }


  Widget _buildImageHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Carrossel de imagens
            _vehicle!.images.isNotEmpty
                ? PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemCount: _vehicle!.images.length,
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: index == 0
                            ? 'vehicle-${_vehicle!.vehicleId}'
                            : 'vehicle-img-$index',
                        child: CachedNetworkImage(
                          imageUrl: _vehicle!.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? AppColors.darkCardHover
                                : AppColors.lightCardHover,
                            child:
                                const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color:
                        isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 80,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.blackOpacity70,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Indicadores de página
            if (_vehicle!.images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _vehicle!.images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderRadiusFull,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : AppColors.whiteOpacity40,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, bool isOwner) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e preço
          _buildTitleSection(context, isDark),
          const SizedBox(height: 20),

          // Categoria e avaliação
          _buildCategoryAndRating(context, isDark),
          const SizedBox(height: 24),

          // Descrição
          _buildDescriptionSection(context, isDark),
          const SizedBox(height: 24),

          // Características
          if (_vehicle!.features.isNotEmpty) ...[
            _buildFeaturesSection(context, isDark),
            const SizedBox(height: 24),
          ],

          // Tipos de evento
          _buildEventTypesSection(context, isDark),
          const SizedBox(height: 24),

          // Proprietário
          if (!isOwner && _owner != null) ...[
            _buildOwnerSection(context, isDark),
            const SizedBox(height: 24),
          ],

          // Avaliações
          _buildReviewsSection(context, isDark),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vehicle!.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _vehicle!.location['city'] ?? 'Porto',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Text(
                '€${_vehicle!.pricePerDay.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'por dia',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryAndRating(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryOpacity10,
            borderRadius: AppRadius.borderRadiusFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _vehicle!.category == 'classic'
                    ? Icons.watch_later_outlined
                    : _vehicle!.category == 'vintage'
                        ? Icons.auto_awesome_outlined
                        : Icons.star_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _vehicle!.category == 'classic'
                    ? 'Clássico'
                    : _vehicle!.category == 'vintage'
                        ? 'Vintage'
                        : 'Luxo',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < _vehicle!.stats.rating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 20,
                color: AppColors.accent,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '${_vehicle!.stats.rating.toStringAsFixed(1)} (${_vehicle!.stats.totalReviews})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Descrição',
            Icons.description_outlined,
            AppColors.info,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _vehicle!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Características',
            Icons.auto_awesome_rounded,
            AppColors.accent,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _vehicle!.features.map((feature) {
                IconData icon;
                switch (feature.toLowerCase()) {
                  case 'ac':
                    icon = Icons.ac_unit_rounded;
                    break;
                  case 'chauffeur':
                    icon = Icons.person_rounded;
                    break;
                  case 'decorated':
                    icon = Icons.celebration_rounded;
                    break;
                  case 'gps':
                    icon = Icons.gps_fixed_rounded;
                    break;
                  case 'bluetooth':
                    icon = Icons.bluetooth_rounded;
                    break;
                  case 'usb charger':
                    icon = Icons.usb_rounded;
                    break;
                  default:
                    icon = Icons.check_rounded;
                }
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardHover
                        : AppColors.lightCardHover,
                    borderRadius: AppRadius.borderRadiusFull,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypesSection(BuildContext context, bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Ideal para',
            Icons.event_rounded,
            AppColors.success,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _vehicle!.eventTypes.map((type) {
                String emoji;
                String text;
                switch (type) {
                  case 'wedding':
                    emoji = '💒';
                    text = 'Casamento';
                    break;
                  case 'party':
                    emoji = '🎉';
                    text = 'Festa';
                    break;
                  case 'photoshoot':
                    emoji = '📸';
                    text = 'Fotografia';
                    break;
                  default:
                    emoji = '🚗';
                    text = 'Tour';
                }
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.successOpacity10,
                    borderRadius: AppRadius.borderRadiusFull,
                    border: Border.all(
                      color: AppColors.successOpacity30,
                    ),
                  ),
                  child: Text(
                    '$emoji $text',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(BuildContext context, bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Proprietário',
            Icons.person_outline_rounded,
            AppColors.primaryEnd,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _owner!.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _owner!.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _owner!.isVerified
                                ? Icons.verified_rounded
                                : Icons.gpp_maybe_rounded,
                            size: 16,
                            color: _owner!.isVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _owner!.isVerified ? 'Verificado' : 'Não verificado',
                            style: TextStyle(
                              color: _owner!.isVerified
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.successOpacity10,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.phone_rounded,
                      color: AppColors.success,
                    ),
                    onPressed: () async {
                      final uri = Uri.parse('tel:${_owner!.phone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryOpacity10,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Enviar mensagem',
                    onPressed: () => _startConversation(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentOpacity10,
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Avaliações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleReviewsScreen(
                          vehicleId: _vehicle!.vehicleId!,
                          vehicle: _vehicle!,
                        ),
                      ),
                    );
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _vehicle!.stats.totalReviews > 0
                ? RatingDisplay(
                    rating: _vehicle!.stats.rating,
                    totalReviews: _vehicle!.stats.totalReviews,
                    starSize: 24,
                  )
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardHover
                          : AppColors.lightCardHover,
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Ainda sem avaliações',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity08,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: isOwner
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton.secondary(
                          text: 'Editar',
                          icon: Icons.edit_rounded,
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditVehicleScreen(
                                  vehicle: _vehicle!,
                                ),
                              ),
                            );

                            if (result == true) {
                              _loadVehicleData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ModernButton(
                          text: _vehicle!.isAvailable ? 'Indisponível' : 'Disponível',
                          icon: _vehicle!.isAvailable
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: _vehicle!.isAvailable ? AppColors.warning : AppColors.success,
                          onPressed: () => _toggleAvailability(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ModernButton(
                    text: 'Gerir Disponibilidade',
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.info,
                    onPressed: () => context.push('/vehicle-availability/${_vehicle!.vehicleId}'),
                  ),
                ],
              )
            : ModernButton.primary(
                text: 'Reservar Agora',
                icon: Icons.calendar_today_rounded,
                onPressed: _vehicle!.isAvailable
                    ? () => context.push('/booking/${_vehicle!.vehicleId}')
                    : null,
              ),
      ),
    );
  }

  Future<void> _toggleAvailability() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_vehicle!.isAvailable
                        ? AppColors.warning
                        : AppColors.success)
                    .withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Icon(
                _vehicle!.isAvailable
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color:
                    _vehicle!.isAvailable ? AppColors.warning : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_vehicle!.isAvailable
                  ? 'Marcar como Indisponível?'
                  : 'Marcar como Disponível?'),
            ),
          ],
        ),
        content: Text(
          _vehicle!.isAvailable
              ? 'O veículo ficará oculto e não poderá receber novas reservas.'
              : 'O veículo voltará a aparecer nas pesquisas e poderá receber reservas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vehicle!.isAvailable
                  ? AppColors.warning
                  : AppColors.success,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final databaseService =
            Provider.of<DatabaseService>(context, listen: false);

        await databaseService.updateVehicle(
          _vehicle!.vehicleId!,
          {
            'is_available': !_vehicle!.isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        _loadVehicleData();

        if (mounted) {
          _showSuccessSnackbar(_vehicle!.isAvailable
              ? 'Veículo marcado como indisponível'
              : 'Veículo marcado como disponível');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('Erro ao atualizar disponibilidade: $e');
        }
      }
    }
  }
}

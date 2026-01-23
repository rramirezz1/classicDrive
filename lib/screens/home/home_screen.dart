import 'dart:ui';
import 'package:flutter/material.dart';
import '../map_screen.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/verification_service.dart';
import '../../services/admin_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/verification_badge_widget.dart';
import '../../widgets/recommendations_widget.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../main.dart' show mainNavigationKey;
import '../notifications/notifications_screen.dart' show NotificationState;
import 'package:classic_drive/l10n/app_localizations.dart';

/// Ecrã principal HomeScreen com design moderno.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VerificationService _verificationService = VerificationService();
  VerificationStatus? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final status = await _verificationService.getVerificationStatus(
        authService.currentUser!.id,
      );
      if (mounted) {
        setState(() => _verificationStatus = status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;
    final isOwner = authService.isOwner;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header moderno com gradiente
          _buildModernHeader(context, user, isDark),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recomendações personalizadas (para arrendatários)
                  if (!isOwner && authService.currentUser != null) ...[
                    const SizedBox(height: 24),
                    RecommendationsWidget(
                      title: AppLocalizations.of(context)!.recommendedForYou,
                      limit: 5,
                      showReasons: true,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Cartões de ação rápida
                  if (isOwner)
                    _buildOwnerQuickActions(context, isDark)
                  else
                    _buildRenterQuickActions(context, isDark),

                  const SizedBox(height: 32),

                  // Estatísticas (para proprietários)
                  if (isOwner) ...[
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.myStats,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildOwnerStats(isDark),
                    const SizedBox(height: 32),
                  ],

                  // Veículos em destaque
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.featuredVehicles,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturedVehicles(isDark),

                  const SizedBox(height: 32),

                  // Categorias
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.exploreByCategory,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildCategories(context, isDark),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, dynamic user, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        // Botão Notificações
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteOpacity15,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
                ),
                // Badge só aparece se houver notificações não lidas
                if (NotificationState.unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notificações',
            onPressed: () => context.push('/notifications'),
          ),
        ),
        // Botão Mensagens
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.whiteOpacity15,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            ),
            tooltip: 'Mensagens',
            onPressed: () => context.push('/conversations'),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.whiteOpacity15,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
            ),
            tooltip: AppLocalizations.of(context)!.mapButton,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            ),
          ),
        ),
        // Botão Admin
        FutureBuilder<bool>(
          future: Provider.of<AdminService>(context, listen: false).isAdmin(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOpacity90,
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: AppLocalizations.of(context)!.adminPanel,
                  onPressed: () => context.go('/admin'),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
          child: Stack(
            children: [
              // Círculos decorativos
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.whiteOpacity08,
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.whiteOpacity05,
                  ),
                ),
              ),
              // Conteúdo
              Positioned(
                left: 24,
                right: 24,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user != null)
                          VerificationBadge(
                            user: user,
                            size: 14,
                            showLabel: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.name ?? AppLocalizations.of(context)!.user,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Banner de verificação pendente
                    if (_verificationStatus != null &&
                        _verificationStatus!.isPending)
                      _buildVerificationBanner(
                        icon: Icons.access_time_rounded,
                        text: AppLocalizations.of(context)!.verificationPending,
                        color: AppColors.warning,
                      ),
                    // Prompt de verificação
                    if (user != null &&
                        !user.hasKYC &&
                        _verificationStatus?.isPending != true)
                      GestureDetector(
                        onTap: () => context.push('/kyc-verification'),
                        child: _buildVerificationBanner(
                          icon: Icons.verified_user_rounded,
                          text: AppLocalizations.of(context)!.verifyAccount,
                          color: Colors.white,
                          isOutlined: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner({
    required IconData icon,
    required String text,
    required Color color,
    bool isOutlined = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.2),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(
          color: isOutlined ? AppColors.whiteOpacity40 : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isOutlined) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustScoreCard(dynamic user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: () => context.push('/kyc-verification'),
        child: GradientCard(
          gradient: const LinearGradient(
            colors: [AppColors.success, AppColors.successDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.whiteOpacity20,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.accountVerified,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.trustScore(user.trustLevel),
                      style: TextStyle(
                        color: AppColors.whiteOpacity85,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Trust meter circular
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: user.reliabilityScore,
                      backgroundColor: AppColors.whiteOpacity20,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 5,
                    ),
                    Center(
                      child: Text(
                        '${(user.reliabilityScore * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 18) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildOwnerQuickActions(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        ActionCard(
          icon: Icons.add_circle_outline_rounded,
          title: AppLocalizations.of(context)!.addVehicle,
          color: AppColors.success,
          onTap: () => context.push('/add-vehicle'),
        ),
        ActionCard(
          icon: Icons.directions_car_rounded,
          title: AppLocalizations.of(context)!.myVehicles,
          color: AppColors.info,
          onTap: () => context.push('/my-vehicles'),
        ),
        ActionCard(
          icon: Icons.calendar_today_rounded,
          title: AppLocalizations.of(context)!.bookings,
          color: AppColors.accent,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            mainNavigationKey.currentState?.changeTab(2);
          },
        ),
        ActionCard(
          icon: Icons.bar_chart_rounded,
          title: AppLocalizations.of(context)!.reports,
          color: AppColors.primaryEnd,
          onTap: () => context.push('/reports'),
        ),
      ],
    );
  }

  Widget _buildRenterQuickActions(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        ActionCard(
          icon: Icons.search_rounded,
          title: AppLocalizations.of(context)!.search,
          color: AppColors.info,
          onTap: () => context.push('/search'),
        ),
        ActionCard(
          icon: Icons.calendar_today_rounded,
          title: AppLocalizations.of(context)!.myBookings,
          color: AppColors.accent,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            mainNavigationKey.currentState?.changeTab(2);
          },
        ),
        ActionCard(
          icon: Icons.favorite_rounded,
          title: AppLocalizations.of(context)!.favorites,
          color: AppColors.error,
          onTap: () => context.push('/favorites'),
        ),
        ActionCard(
          icon: Icons.shield_rounded,
          title: AppLocalizations.of(context)!.myInsurance,
          color: AppColors.success,
          badge: _hasActiveInsurance()
              ? AppLocalizations.of(context)!.active
              : null,
          onTap: () => _showInsuranceDialog(context),
        ),
      ],
    );
  }

  Widget _buildOwnerStats(bool isDark) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<VehicleModel>>(
      stream: databaseService.getVehiclesByOwner(authService.currentUser!.id),
      builder: (context, vehicleSnapshot) {
        final vehicleCount = vehicleSnapshot.data?.length ?? 0;

        return StreamBuilder<List<BookingModel>>(
          stream: databaseService.getUserBookings(
            authService.currentUser!.id,
            asOwner: true,
          ),
          builder: (context, bookingSnapshot) {
            final bookings = bookingSnapshot.data ?? [];
            final activeBookings = bookings
                .where((b) => b.status == 'confirmed' || b.status == 'pending')
                .length;
            final totalRevenue = bookings
                .where((b) => b.status == 'completed')
                .fold(0.0, (sum, b) => sum + b.totalPrice);

            return Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.directions_car_rounded,
                    value: vehicleCount.toString(),
                    label: 'Veículos',
                    iconColor: AppColors.info,
                    onTap: () => context.push('/my-vehicles'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.calendar_today_rounded,
                    value: activeBookings.toString(),
                    label: 'Reservas Ativas',
                    iconColor: AppColors.accent,
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      mainNavigationKey.currentState?.changeTab(2);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.euro_rounded,
                    value: '€${totalRevenue.toStringAsFixed(0)}',
                    label: 'Receita',
                    iconColor: AppColors.success,
                    onTap: () => context.push('/reports'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedVehicles(bool isDark) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return StreamBuilder<List<VehicleModel>>(
      stream: databaseService.getApprovedVehicles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppRadius.borderRadiusLg,
                  ),
                );
              },
            ),
          );
        }

        final vehicles = snapshot.data!.take(5).toList();

        if (vehicles.isEmpty) {
          return ModernCard(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 56,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noVehiclesAvailable,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _buildVehicleCard(vehicle, isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
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
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardHover
                    : AppColors.lightCardHover,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  vehicle.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vehicle.images.first,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.directions_car_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                  // Overlay gradiente
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.blackOpacity60,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Preço
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppRadius.borderRadiusFull,
                      ),
                      child: Text(
                        '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Informações
            Padding(
              padding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.stats.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        vehicle.location['city'] ?? 'Porto',
                        style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildCategories(BuildContext context, bool isDark) {
    final categories = [
      {
        'id': 'classic',
        'name': AppLocalizations.of(context)!.classics,
        'icon': Icons.watch_later_outlined,
        'color': AppColors.categoryClassic,
      },
      {
        'id': 'vintage',
        'name': AppLocalizations.of(context)!.vintage,
        'icon': Icons.auto_awesome_outlined,
        'color': AppColors.categoryVintage,
      },
      {
        'id': 'luxury',
        'name': AppLocalizations.of(context)!.luxury,
        'icon': Icons.star_outline_rounded,
        'color': AppColors.categoryLuxury,
      },
    ];

    return Row(
      children: categories.map((category) {
        final color = category['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              context.push('/vehicles-category', extra: {
                'category': category['id'],
                'title': category['name'],
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                right: categories.indexOf(category) < categories.length - 1
                    ? 12
                    : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadius.borderRadiusLg,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow:
                    isDark ? AppShadows.softShadowDark : AppShadows.softShadow,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category['name'] as String,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _hasActiveInsurance() {
    return false;
  }

  void _showInsuranceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.insuranceDialogTitle),
        content: Text(AppLocalizations.of(context)!.featureInDevelopment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/verification_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/verification_badge_widget.dart';
import '../../widgets/recommendations_widget.dart';
import '../../widgets/animated_widgets.dart';
import '../../main.dart' show mainNavigationKey;

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
        authService.currentUser!.uid,
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Padrão decorativo
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Conteúdo
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge de verificação
                              if (user != null)
                                VerificationBadge(
                                  user: user,
                                  size: 16,
                                  showLabel: false,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.name ?? 'Utilizador',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Banner de verificação pendente
                          if (_verificationStatus != null &&
                              _verificationStatus!.isPending)
                            AnimatedWidgets.fadeInContent(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Verificação em análise',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Prompt de verificação
                          if (user != null &&
                              !user.hasKYC &&
                              _verificationStatus?.isPending != true)
                            AnimatedWidgets.fadeInContent(
                              child: InkWell(
                                onTap: () => context.push('/kyc-verification'),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Verificar conta →',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trust Score Card (se verificado)
                if (user != null && user.hasKYC)
                  AnimatedWidgets.fadeInContent(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Conta Verificada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Score de confiança: ${user.trustLevel}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Trust meter
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: user.reliabilityScore,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 6,
                                ),
                                Center(
                                  child: Text(
                                    '${(user.reliabilityScore * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Recomendações personalizadas (para arrendatários)
                if (!isOwner && authService.currentUser != null)
                  const RecommendationsWidget(
                    title: '🎯 Recomendados para Si',
                    limit: 5,
                    showReasons: true,
                  ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cartões de ação rápida
                      if (isOwner) _buildOwnerQuickActions(context),
                      if (!isOwner) _buildRenterQuickActions(context),

                      const SizedBox(height: 24),

                      // Estatísticas (para proprietários)
                      if (isOwner) ...[
                        _buildSectionTitle('As Minhas Estatísticas'),
                        const SizedBox(height: 16),
                        _buildOwnerStats(),
                        const SizedBox(height: 24),
                      ],

                      // Veículos em destaque
                      _buildSectionTitle('Veículos em Destaque'),
                      const SizedBox(height: 16),
                      _buildFeaturedVehicles(),

                      const SizedBox(height: 24),

                      // Categorias
                      _buildSectionTitle('Explorar por Categoria'),
                      const SizedBox(height: 16),
                      _buildCategories(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOwnerQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.add_circle_outline,
          title: 'Adicionar Veículo',
          color: Colors.green,
          onTap: () => context.push('/add-vehicle'),
        ),
        _buildActionCard(
          context,
          icon: Icons.directions_car,
          title: 'Meus Veículos',
          color: Colors.blue,
          onTap: () => context.push('/my-vehicles'),
        ),
        _buildActionCard(
          context,
          icon: Icons.calendar_today,
          title: 'Reservas',
          color: Colors.orange,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            mainNavigationKey.currentState?.changeTab(2);
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.bar_chart,
          title: 'Relatórios',
          color: Colors.purple,
          onTap: () => context.push('/reports'),
        ),
      ],
    );
  }

  Widget _buildRenterQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.search,
          title: 'Procurar',
          color: Colors.blue,
          onTap: () => context.push('/search'),
        ),
        _buildActionCard(
          context,
          icon: Icons.book_outlined,
          title: 'Minhas Reservas',
          color: Colors.orange,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            mainNavigationKey.currentState?.changeTab(2);
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.favorite_outline,
          title: 'Favoritos',
          color: Colors.red,
          onTap: () => context.push('/favorites'),
        ),
        _buildActionCard(
          context,
          icon: Icons.shield,
          title: 'Meus Seguros',
          color: Colors.green,
          badge: _hasActiveInsurance() ? 'Ativo' : null,
          onTap: () => _showInsuranceDialog(context),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerStats() {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<VehicleModel>>(
      stream: databaseService.getVehiclesByOwner(authService.currentUser!.uid),
      builder: (context, vehicleSnapshot) {
        final vehicleCount = vehicleSnapshot.data?.length ?? 0;

        return StreamBuilder<List<BookingModel>>(
          stream: databaseService.getUserBookings(authService.currentUser!.uid,
              asOwner: true),
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
                  child: InkWell(
                    onTap: () => context.push('/my-vehicles'),
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStatCard(
                      title: 'Total Veículos',
                      value: vehicleCount.toString(),
                      icon: Icons.directions_car,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      mainNavigationKey.currentState?.changeTab(2);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStatCard(
                      title: 'Reservas Ativas',
                      value: activeBookings.toString(),
                      icon: Icons.calendar_today,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/reports'),
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStatCard(
                      title: 'Receita Total',
                      value: '€${totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.euro,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedVehicles() {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    return StreamBuilder<List<VehicleModel>>(
      stream: databaseService.getApprovedVehicles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final vehicles = snapshot.data!.take(5).toList();

        if (vehicles.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ainda não há veículos disponíveis',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _buildVehicleCard(vehicle);
            },
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/vehicle/${vehicle.vehicleId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: vehicle.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: vehicle.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : const Center(
                        child: Icon(
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
                        fontSize: 16,
                      ),
                      maxLines: 1,
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
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.stats.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 14),
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
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = [
      {'id': 'classic', 'name': 'Clássicos', 'icon': Icons.access_time},
      {'id': 'vintage', 'name': 'Vintage', 'icon': Icons.style},
      {'id': 'luxury', 'name': 'Luxo', 'icon': Icons.star},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: categories.map((category) {
        return Expanded(
          child: Card(
            child: InkWell(
              onTap: () {
                context.push('/vehicles-category', extra: {
                  'category': category['id'],
                  'title': category['name'],
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
        title: const Text('Meus Seguros'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

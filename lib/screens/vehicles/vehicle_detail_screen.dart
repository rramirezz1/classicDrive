import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/rating_widget.dart';
import '../reviews/vehicle_reviews_screen.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/animated_widgets.dart';

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

      // Carregar dados do veículo
      final vehicle = await databaseService.getVehicleById(widget.vehicleId);

      if (vehicle != null) {
        // Carregar dados do proprietário
        UserModel? owner;
        try {
          final ownerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(vehicle.ownerId)
              .get();

          if (ownerDoc.exists) {
            owner = UserModel.fromMap(ownerDoc.data()!);
          }
        } catch (e) {
          print('Erro ao buscar proprietário: $e');
        }

        setState(() {
          _vehicle = vehicle;
          _owner = owner;
          _isLoading = false;
        });
      } else {
        // Veículo não encontrado
        if (mounted) {
          AnimatedWidgets.showAnimatedSnackBar(
            context,
            message: 'Veículo não encontrado',
            backgroundColor: Colors.red,
            icon: Icons.error,
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AnimatedWidgets.showAnimatedSnackBar(
          context,
          message: 'Erro ao carregar veículo: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: LoadingWidgets.vehicleDetailShimmer(),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        body: AnimatedWidgets.fadeInContent(
          child: const Center(
            child: Text('Veículo não encontrado'),
          ),
        ),
      );
    }

    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.currentUser?.uid == _vehicle!.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // IMAGENS COM HERO ANIMATION
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Carrossel de imagens com Hero Animation
                  _vehicle!.images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemCount: _vehicle!.images.length,
                          itemBuilder: (context, index) {
                            return AnimatedWidgets.heroVehicleImage(
                              vehicleId: _vehicle!.vehicleId!,
                              imageUrl: _vehicle!.images[index],
                              fit: BoxFit.cover,
                              placeholder: Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),

                  // Indicadores de página com animação
                  if (_vehicle!.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: AnimatedWidgets.fadeInContent(
                        delay: const Duration(milliseconds: 500),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _vehicle!.images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImageIndex == index ? 12 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // CONTEÚDO COM ANIMAÇÕES
          SliverToBoxAdapter(
            child: AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título e preço
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _vehicle!.fullName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _vehicle!.location['city'] ?? 'Porto',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${_vehicle!.pricePerDay.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Text(
                              'por dia',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Categoria e avaliação com animação
                    AnimatedWidgets.fadeInContent(
                      delay: const Duration(milliseconds: 300),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _vehicle!.category == 'classic'
                                  ? 'Clássico'
                                  : _vehicle!.category == 'vintage'
                                      ? 'Vintage'
                                      : 'Luxo',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < _vehicle!.stats.rating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 20,
                                  color: Colors.amber,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${_vehicle!.stats.rating.toStringAsFixed(1)} (${_vehicle!.stats.totalBookings} reservas)',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Descrição com animação
                    AnimatedWidgets.fadeInContent(
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descrição',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _vehicle!.description,
                            style: const TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Características com animação
                    if (_vehicle!.features.isNotEmpty) ...[
                      AnimatedWidgets.fadeInContent(
                        delay: const Duration(milliseconds: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Características',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _vehicle!.features.map((feature) {
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
                                  case 'gps':
                                    icon = Icons.gps_fixed;
                                    break;
                                  case 'bluetooth':
                                    icon = Icons.bluetooth;
                                    break;
                                  case 'usb charger':
                                    icon = Icons.usb;
                                    break;
                                  default:
                                    icon = Icons.check;
                                }
                                return Chip(
                                  avatar: Icon(icon, size: 18),
                                  label: Text(feature),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Tipos de evento com animação
                    AnimatedWidgets.fadeInContent(
                      delay: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ideal para',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _vehicle!.eventTypes.map((type) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  type == 'wedding'
                                      ? '💒 Casamento'
                                      : type == 'party'
                                          ? '🎉 Festa'
                                          : type == 'photoshoot'
                                              ? '📸 Fotografia'
                                              : '🚗 Tour',
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Informações do proprietário com animação
                    if (!isOwner && _owner != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      AnimatedWidgets.fadeInContent(
                        delay: const Duration(milliseconds: 700),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proprietário',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: CircleAvatar(
                                child: Text(_owner!.name[0].toUpperCase()),
                              ),
                              title: Text(_owner!.name),
                              subtitle: Text(
                                _owner!.isVerified
                                    ? 'Verificado'
                                    : 'Não verificado',
                                style: TextStyle(
                                  color: _owner!.isVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () async {
                                  final uri = Uri.parse('tel:${_owner!.phone}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Secção de Avaliações com animação
                    const Divider(),
                    const SizedBox(height: 16),
                    AnimatedWidgets.fadeInContent(
                      delay: const Duration(milliseconds: 800),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Avaliações',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VehicleReviewsScreen(
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
                          const SizedBox(height: 12),
                          // Mostrar resumo das avaliações
                          if (_vehicle!.stats.totalBookings > 0) ...[
                            RatingDisplay(
                              rating: _vehicle!.stats.rating,
                              totalReviews: _vehicle!.stats.totalBookings,
                              starSize: 24,
                            ),
                          ] else ...[
                            Text(
                              'Ainda sem avaliações',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Espaço para o botão fixo
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // BOTÃO DE AÇÃO ANIMADO
      bottomNavigationBar: AnimatedWidgets.fadeInContent(
        delay: const Duration(milliseconds: 900),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: isOwner
                ? Row(
                    children: [
                      Expanded(
                        child: AnimatedWidgets.animatedButton(
                          text: 'Editar',
                          icon: Icons.edit,
                          color: Colors.grey[600],
                          onPressed: () {
                            // Editar veículo
                            AnimatedWidgets.showAnimatedSnackBar(
                              context,
                              message: 'Funcionalidade em desenvolvimento',
                              icon: Icons.info,
                              backgroundColor: Colors.blue,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedWidgets.animatedButton(
                          text: _vehicle!.isAvailable
                              ? 'Indisponível'
                              : 'Disponível',
                          icon: _vehicle!.isAvailable
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _vehicle!.isAvailable
                              ? Colors.orange
                              : Colors.green,
                          onPressed: () {
                            AnimatedWidgets.showAnimatedSnackBar(
                              context,
                              message: 'Funcionalidade em desenvolvimento',
                              icon: Icons.info,
                              backgroundColor: Colors.blue,
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : AnimatedWidgets.animatedButton(
                    text: 'Reservar Agora',
                    icon: Icons.calendar_today,
                    width: double.infinity,
                    onPressed: _vehicle!.isAvailable
                        ? () => context.push('/booking/${_vehicle!.vehicleId}')
                        : null,
                  ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../reviews/add_review_screen.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        bottom: isOwner
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Dos Meus Veículos'),
                  Tab(text: 'Minhas Reservas'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _filterStatus == 'all',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pendentes'),
                    selected: _filterStatus == 'pending',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'pending');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Confirmadas'),
                    selected: _filterStatus == 'confirmed',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'confirmed');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Concluídas'),
                    selected: _filterStatus == 'completed',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'completed');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Canceladas'),
                    selected: _filterStatus == 'cancelled',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'cancelled');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Lista de reservas
          Expanded(
            child: isOwner
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(asOwner: true),
                      _buildBookingsList(asOwner: false),
                    ],
                  )
                : _buildBookingsList(asOwner: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList({required bool asOwner}) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    print("=== BUSCANDO RESERVAS ===");
    print("User ID: ${authService.currentUser!.uid}");
    print("As Owner: $asOwner");

    return StreamBuilder<List<BookingModel>>(
      stream: databaseService.getUserBookings(
        authService.currentUser!.uid,
        asOwner: asOwner,
      ),
      builder: (context, snapshot) {
        print("Snapshot: ${snapshot.connectionState}");
        print("Has Data: ${snapshot.hasData}");
        print("Data Length: ${snapshot.data?.length ?? 0}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  asOwner
                      ? 'Ainda não tem reservas nos seus veículos'
                      : 'Ainda não fez nenhuma reserva',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Filtrar reservas
        var bookings = snapshot.data!;
        if (_filterStatus != 'all') {
          bookings = bookings.where((b) => b.status == _filterStatus).toList();
        }

        if (bookings.isEmpty) {
          return const Center(
            child: Text('Nenhuma reserva encontrada com este filtro'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _BookingCard(
              booking: bookings[index],
              isOwnerView: asOwner,
            );
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isOwnerView;

  const _BookingCard({
    required this.booking,
    required this.isOwnerView,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    return FutureBuilder<VehicleModel?>(
      future: databaseService.getVehicleById(booking.vehicleId),
      builder: (context, snapshot) {
        final vehicle = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              _showBookingDetails(context, booking, vehicle);
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(booking.status),
                            color: _getStatusColor(booking.status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Constants.bookingStatuses[booking.status] ??
                                booking.status,
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'ID: ${booking.bookingId?.substring(0, 8).toUpperCase() ?? ""}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Imagem do veículo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: vehicle != null && vehicle.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: vehicle.images.first,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.directions_car,
                                    size: 40,
                                  ),
                                )
                              : const Icon(
                                  Icons.directions_car,
                                  size: 40,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Informações
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle?.fullName ?? 'A carregar...',
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
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${DateFormat('dd/MM').format(booking.startDate)} - ${DateFormat('dd/MM').format(booking.endDate)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.event, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  booking.eventType == 'wedding'
                                      ? 'Casamento'
                                      : booking.eventType == 'party'
                                          ? 'Festa'
                                          : booking.eventType == 'photoshoot'
                                              ? 'Fotografia'
                                              : 'Tour',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Preço
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '€${booking.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${booking.numberOfDays} ${booking.numberOfDays == 1 ? "dia" : "dias"}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ações (se aplicável)
                if (booking.status == 'pending' && isOwnerView) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              _handleBookingAction(context, 'cancelled'),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rejeitar'),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          // <-- ADICIONA ISTO
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _handleBookingAction(context, 'confirmed'),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Botão avaliar (para reservas concluídas sem avaliação)
                if (booking.status == 'completed' && !isOwnerView) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddReviewScreen(
                                bookingId: booking.bookingId!,
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Obrigado pela sua avaliação!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.star, size: 18),
                        label: const Text('Avaliar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookingDetails(
      BuildContext context, BookingModel booking, VehicleModel? vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Detalhes da Reserva',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // ID e Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ID da Reserva',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        booking.bookingId?.substring(0, 8).toUpperCase() ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(booking.status),
                          color: _getStatusColor(booking.status),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Constants.bookingStatuses[booking.status] ??
                              booking.status,
                          style: TextStyle(
                            color: _getStatusColor(booking.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Veículo
              if (vehicle != null) ...[
                const Text(
                  'Veículo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: vehicle.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: vehicle.images.first,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.directions_car),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            vehicle.location['city'] ?? 'Porto',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Datas
              const Text(
                'Período',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Check-in'),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(booking.startDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Check-out'),
                            Text(
                              DateFormat('dd/MM/yyyy').format(booking.endDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${booking.numberOfDays} ${booking.numberOfDays == 1 ? "dia" : "dias"}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tipo de evento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tipo de Evento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      booking.eventType == 'wedding'
                          ? 'Casamento'
                          : booking.eventType == 'party'
                              ? 'Festa'
                              : booking.eventType == 'photoshoot'
                                  ? 'Fotografia'
                                  : 'Tour',
                    ),
                  ),
                ],
              ),

              if (booking.specialRequests != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Pedidos Especiais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Text(booking.specialRequests!),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Preço
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '€${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBookingAction(BuildContext context, String newStatus) async {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus == 'confirmed' ? 'Confirmar Reserva?' : 'Rejeitar Reserva?',
        ),
        content: Text(
          newStatus == 'confirmed'
              ? 'Tem a certeza que deseja confirmar esta reserva?'
              : 'Tem a certeza que deseja rejeitar esta reserva?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'confirmed' ? Colors.green : Colors.red,
            ),
            child: Text(newStatus == 'confirmed' ? 'Confirmar' : 'Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await databaseService.updateBookingStatus(
        booking.bookingId!,
        newStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Reserva ${newStatus == "confirmed" ? "confirmada" : "rejeitada"} com sucesso!'
                  : 'Erro ao atualizar reserva',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

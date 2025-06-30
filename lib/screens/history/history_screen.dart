import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/animated_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: databaseService.getUserBookings(
          authService.currentUser!.uid,
          asOwner: false,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar apenas reservas concluídas ou canceladas
          final historicBookings = snapshot.data!
              .where((booking) =>
                  booking.status == 'completed' ||
                  booking.status == 'cancelled')
              .toList();

          // Ordenar por data mais recente
          historicBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (historicBookings.isEmpty) {
            return AnimatedWidgets.fadeInContent(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sem histórico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As suas reservas anteriores aparecerão aqui',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historicBookings.length,
            itemBuilder: (context, index) {
              final booking = historicBookings[index];
              return AnimatedWidgets.fadeInContent(
                delay: Duration(milliseconds: index * 50),
                child: FutureBuilder<VehicleModel?>(
                  future: databaseService.getVehicleById(booking.vehicleId),
                  builder: (context, vehicleSnapshot) {
                    final vehicle = vehicleSnapshot.data;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: vehicle != null && vehicle.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: vehicle.images.first,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.directions_car),
                          ),
                        ),
                        title: Text(
                          vehicle?.fullName ?? 'A carregar...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(booking.startDate)} - ${DateFormat('dd/MM/yyyy').format(booking.endDate)}',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: booking.status == 'completed'
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.status == 'completed'
                                    ? 'Concluída'
                                    : 'Cancelada',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: booking.status == 'completed'
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${booking.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yy').format(booking.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

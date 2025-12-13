import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        elevation: 0,
      ),
      body: StreamBuilder<List<VehicleModel>>(
        stream: databaseService.getVehiclesByOwner(authService.currentUser!.id),
        builder: (context, vehicleSnapshot) {
          return StreamBuilder<List<BookingModel>>(
            stream: databaseService.getUserBookings(
              authService.currentUser!.id,
              asOwner: true,
            ),
            builder: (context, bookingSnapshot) {
              if (!vehicleSnapshot.hasData || !bookingSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final vehicles = vehicleSnapshot.data!;
              final bookings = bookingSnapshot.data!;

              // Calcular estatísticas
              final totalRevenue = bookings
                  .where((b) => b.status == 'completed')
                  .fold(0.0, (sum, b) => sum + b.totalPrice);

              final currentMonthRevenue = bookings
                  .where((b) =>
                      b.status == 'completed' &&
                      b.createdAt.month == DateTime.now().month &&
                      b.createdAt.year == DateTime.now().year)
                  .fold(0.0, (sum, b) => sum + b.totalPrice);

              final totalBookings = bookings.length;
              final completedBookings =
                  bookings.where((b) => b.status == 'completed').length;
              final pendingBookings =
                  bookings.where((b) => b.status == 'pending').length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumo Geral
                    _buildSummaryCard(
                      context,
                      'Resumo Geral',
                      [
                        _StatItem(
                            'Total de Veículos', vehicles.length.toString()),
                        _StatItem(
                            'Total de Reservas', totalBookings.toString()),
                        _StatItem('Reservas Concluídas',
                            completedBookings.toString()),
                        _StatItem('Taxa de Conclusão',
                            '${(completedBookings / (totalBookings > 0 ? totalBookings : 1) * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Receitas
                    _buildSummaryCard(
                      context,
                      'Receitas',
                      [
                        _StatItem('Receita Total',
                            '€${totalRevenue.toStringAsFixed(2)}'),
                        _StatItem('Receita Mensal',
                            '€${currentMonthRevenue.toStringAsFixed(2)}'),
                        _StatItem('Ticket Médio',
                            '€${(totalRevenue / (completedBookings > 0 ? completedBookings : 1)).toStringAsFixed(2)}'),
                        _StatItem(
                            'Reservas Pendentes', pendingBookings.toString()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Veículos mais populares
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Veículos Mais Populares',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...vehicles.take(3).map((vehicle) {
                              final vehicleBookings = bookings
                                  .where(
                                      (b) => b.vehicleId == vehicle.vehicleId)
                                  .length;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(vehicle.fullName),
                                subtitle: Text('$vehicleBookings reservas'),
                                trailing: Chip(
                                  label: Text(
                                      '€${vehicle.pricePerDay.toStringAsFixed(0)}/dia'),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nota de desenvolvimento
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gráficos e análises detalhadas em desenvolvimento',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, String title, List<_StatItem> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: stats.map((stat) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}

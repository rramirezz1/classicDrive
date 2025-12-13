import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/comparison_provider.dart';
import '../../models/vehicle_model.dart';


class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar Veículos'), // TODO: Localize
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Provider.of<ComparisonProvider>(context, listen: false).clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<ComparisonProvider>(
        builder: (context, provider, child) {
          if (provider.isEmpty) {
            return const Center(
              child: Text('Nenhum veículo selecionado para comparação'), // TODO: Localize
            );
          }

          final vehicles = provider.selectedVehicles;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  const DataColumn(label: Text('Característica')), // TODO: Localize
                  ...vehicles.map((v) => DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text(
                            v.brand,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )),
                ],
                rows: [
                  _buildImageRow(vehicles),
                  _buildTextRow('Modelo', vehicles, (v) => v.model),
                  _buildTextRow('Ano', vehicles, (v) => v.year.toString()),
                  _buildTextRow('Preço/Dia', vehicles, (v) => '€${v.pricePerDay.toStringAsFixed(0)}'),
                  _buildTextRow('Lugares', vehicles, (v) => v.seats.toString()),
                  _buildTextRow('Transmissão', vehicles, (v) => v.transmission),
                  _buildTextRow('Motor', vehicles, (v) => v.engineType),
                  _buildTextRow('Avaliação', vehicles, (v) => v.stats.rating.toStringAsFixed(1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildImageRow(List<VehicleModel> vehicles) {
    return DataRow(
      cells: [
        const DataCell(Text('')),
        ...vehicles.map((v) => DataCell(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: v.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: v.images.first,
                          width: 100,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.directions_car),
                        ),
                ),
              ),
            )),
      ],
    );
  }

  DataRow _buildTextRow(
    String label,
    List<VehicleModel> vehicles,
    String Function(VehicleModel) extractor,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        ...vehicles.map((v) => DataCell(Text(extractor(v)))),
      ],
    );
  }
}

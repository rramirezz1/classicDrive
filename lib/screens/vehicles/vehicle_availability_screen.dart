import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../services/database_service.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/availability_calendar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã para gerir disponibilidade de um veículo.
class VehicleAvailabilityScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleAvailabilityScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleAvailabilityScreen> createState() =>
      _VehicleAvailabilityScreenState();
}

class _VehicleAvailabilityScreenState extends State<VehicleAvailabilityScreen> {
  VehicleModel? _vehicle;
  bool _isLoading = true;
  bool _isSaving = false;
  List<DateTime> _blockedDates = [];

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final vehicle = await databaseService.getVehicleById(widget.vehicleId);

      if (mounted && vehicle != null) {
        setState(() {
          _vehicle = vehicle;
          _isLoading = false;
          // Carregar datas bloqueadas do veículo (se existir no modelo)
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Erro ao carregar veículo', AppColors.error);
      }
    }
  }

  Future<void> _saveBlockedDates() async {
    setState(() => _isSaving = true);

    try {
      // Aqui salvaria as datas bloqueadas no Supabase
      // Por agora, mostra mensagem de sucesso
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        _showSnackbar('Disponibilidade atualizada', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Erro ao guardar', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: const Text('Gerir Disponibilidade'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveBlockedDates,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Guardar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info do veículo
                  if (_vehicle != null)
                    ModernCard(
                      useGlass: false,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardHover
                                  : Colors.grey[200],
                              borderRadius: AppRadius.borderRadiusMd,
                            ),
                            child: const Icon(Icons.directions_car_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _vehicle!.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Toque nas datas para bloquear/desbloquear',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Calendário
                  ModernCard(
                    useGlass: false,
                    child: AvailabilityCalendar(
                      blockedDates: _blockedDates,
                      bookedDates: [], // Seriam carregadas das reservas
                      isEditable: true,
                      onBlockedDatesChanged: (dates) {
                        setState(() => _blockedDates = dates);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info
                  ModernCard(
                    useGlass: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Como funciona',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          isDark,
                          '🟢 Verde claro',
                          'Dias disponíveis para reserva',
                        ),
                        _buildInfoItem(
                          isDark,
                          '🟡 Amarelo',
                          'Dias com reservas confirmadas',
                        ),
                        _buildInfoItem(
                          isDark,
                          '🔴 Vermelho',
                          'Dias bloqueados por si',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(bool isDark, String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

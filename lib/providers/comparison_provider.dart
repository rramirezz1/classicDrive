import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';

/// Provider para gestão da comparação de veículos.
class ComparisonProvider extends ChangeNotifier {
  final List<VehicleModel> _selectedVehicles = [];
  static const int maxSelection = 3;

  List<VehicleModel> get selectedVehicles => List.unmodifiable(_selectedVehicles);
  
  bool get canAdd => _selectedVehicles.length < maxSelection;
  bool get isEmpty => _selectedVehicles.isEmpty;
  int get count => _selectedVehicles.length;

  /// Alterna a seleção de um veículo.
  void toggleVehicle(VehicleModel vehicle) {
    if (isSelected(vehicle)) {
      removeVehicle(vehicle);
    } else {
      addVehicle(vehicle);
    }
  }

  /// Adiciona um veículo à comparação.
  void addVehicle(VehicleModel vehicle) {
    if (_selectedVehicles.length >= maxSelection) {
      return;
    }
    if (!_selectedVehicles.any((v) => v.vehicleId == vehicle.vehicleId)) {
      _selectedVehicles.add(vehicle);
      notifyListeners();
    }
  }

  /// Remove um veículo da comparação.
  void removeVehicle(VehicleModel vehicle) {
    _selectedVehicles.removeWhere((v) => v.vehicleId == vehicle.vehicleId);
    notifyListeners();
  }

  /// Verifica se um veículo está selecionado.
  bool isSelected(VehicleModel vehicle) {
    return _selectedVehicles.any((v) => v.vehicleId == vehicle.vehicleId);
  }

  /// Limpa todas as seleções.
  void clear() {
    _selectedVehicles.clear();
    notifyListeners();
  }
}

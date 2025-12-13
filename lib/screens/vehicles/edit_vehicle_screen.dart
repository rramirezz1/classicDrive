import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/vehicle_model.dart';
import '../../services/database_service.dart';
import '../../widgets/animated_widgets.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const EditVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _cityController;

  late String _category;
  late List<String> _selectedFeatures;
  late List<String> _selectedEventTypes;
  bool _isSaving = false;

  final List<String> _categories = ['classic', 'vintage', 'luxury'];
  final Map<String, String> _categoryLabels = {
    'classic': 'Clássico',
    'vintage': 'Vintage',
    'luxury': 'Luxo',
  };

  final List<Map<String, dynamic>> _availableFeatures = [
    {'value': 'chauffeur', 'label': 'Chauffeur', 'icon': Icons.person},
    {'value': 'gps', 'label': 'GPS', 'icon': Icons.navigation},
    {'value': 'bluetooth', 'label': 'Bluetooth', 'icon': Icons.bluetooth},
    {
      'value': 'air_conditioning',
      'label': 'Ar Condicionado',
      'icon': Icons.ac_unit
    },
    {
      'value': 'leather_seats',
      'label': 'Bancos em Pele',
      'icon': Icons.event_seat
    },
  ];

  final List<Map<String, dynamic>> _eventTypes = [
    {'value': 'wedding', 'label': 'Casamento', 'icon': Icons.favorite},
    {
      'value': 'photoshoot',
      'label': 'Sessão Fotográfica',
      'icon': Icons.camera_alt
    },
    {
      'value': 'corporate',
      'label': 'Evento Corporativo',
      'icon': Icons.business
    },
    {'value': 'birthday', 'label': 'Aniversário', 'icon': Icons.cake},
    {'value': 'prom', 'label': 'Formatura', 'icon': Icons.school},
    {'value': 'tourism', 'label': 'Turismo', 'icon': Icons.map},
  ];

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle.brand);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _yearController =
        TextEditingController(text: widget.vehicle.year.toString());
    _descriptionController =
        TextEditingController(text: widget.vehicle.description);
    _priceController = TextEditingController(
        text: widget.vehicle.pricePerDay.toStringAsFixed(0));
    _cityController =
        TextEditingController(text: widget.vehicle.location['city'] ?? 'Porto');

    _category = widget.vehicle.category;
    _selectedFeatures = List<String>.from(widget.vehicle.features);
    _selectedEventTypes = List<String>.from(widget.vehicle.eventTypes);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      // Criar mapa com as atualizações
      final updates = {
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'description': _descriptionController.text.trim(),
        'price_per_day': double.parse(_priceController.text.trim()),
        'category': _category,
        'features': _selectedFeatures,
        'event_types': _selectedEventTypes,
        'location': {
          'city': _cityController.text.trim(),
          'country': widget.vehicle.location['country'] ?? 'Portugal',
          'coordinates': widget.vehicle.location['coordinates'] ?? {},
        },
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Atualizar no Supabase
      await databaseService.updateVehicle(widget.vehicle.vehicleId!, updates);

      if (mounted) {
        AnimatedWidgets.showAnimatedSnackBar(
          context,
          message: 'Veículo atualizado com sucesso!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        // Voltar para a página anterior
        context.pop(true); // true indica que houve alterações
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AnimatedWidgets.showAnimatedSnackBar(
          context,
          message: 'Erro ao atualizar veículo: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Veículo'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informações Básicas
            AnimatedWidgets.fadeInContent(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações Básicas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor insira a marca';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.car_rental),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor insira o modelo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Ano',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor insira o ano';
                          }
                          final year = int.tryParse(value);
                          if (year == null ||
                              year < 1900 ||
                              year > DateTime.now().year) {
                            return 'Ano inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descrição
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 100),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição do veículo',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor insira uma descrição';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preço e Localização
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 200),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preço e Localização',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço por dia (€)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor insira o preço';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Preço inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor insira a cidade';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categoria
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 300),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categoria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _category == category;
                          return ChoiceChip(
                            label: Text(_categoryLabels[category]!),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _category = category);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Características
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione as características do veículo',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableFeatures.map((feature) {
                          final isSelected =
                              _selectedFeatures.contains(feature['value']);
                          return FilterChip(
                            label: Text(feature['label']),
                            avatar: Icon(feature['icon'], size: 18),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFeatures.add(feature['value']);
                                } else {
                                  _selectedFeatures.remove(feature['value']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tipos de Eventos
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione os tipos de eventos',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _eventTypes.map((event) {
                          final isSelected =
                              _selectedEventTypes.contains(event['value']);
                          return FilterChip(
                            label: Text(event['label']),
                            avatar: Icon(event['icon'], size: 18),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedEventTypes.add(event['value']);
                                } else {
                                  _selectedEventTypes.remove(event['value']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botões de Ação
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 600),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController(text: 'Porto');

  String _selectedCategory = 'classic';
  final List<String> _selectedEventTypes = [];
  final List<String> _selectedFeatures = [];
  final List<File> _images = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _images.add(File(image.path));
        });
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Veículo'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveVehicle,
            child: const Text('GUARDAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('A guardar veículo...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card de Imagens
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fotografias',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${_images.length}/5',
                                  style: TextStyle(
                                    color: _images.isEmpty
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Adicione pelo menos uma foto do veículo',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),

                            // Grid de imagens
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length +
                                    (_images.length < 5 ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _images.length) {
                                    // Botão adicionar
                                    return GestureDetector(
                                      onTap: _showImageSourceDialog,
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 32,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Adicionar',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // Imagem
                                  return Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            _images[index],
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de Informações Básicas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações Básicas',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Marca *',
                                hintText: 'Ex: Mercedes-Benz',
                                prefixIcon: Icon(Icons.directions_car),
                              ),
                              validator: (value) =>
                                  Validators.required(value, 'Marca'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Modelo *',
                                hintText: 'Ex: 280 SL',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (value) =>
                                  Validators.required(value, 'Modelo'),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _yearController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ano *',
                                      hintText: 'Ex: 1971',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: Validators.vehicleYear,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(
                                      labelText: 'Categoria *',
                                      prefixIcon: Icon(Icons.category),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'classic',
                                          child: Text('Clássico')),
                                      DropdownMenuItem(
                                          value: 'vintage',
                                          child: Text('Vintage')),
                                      DropdownMenuItem(
                                          value: 'luxury', child: Text('Luxo')),
                                    ],
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedCategory = value!);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de Detalhes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalhes e Localização',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descrição *',
                                hintText:
                                    'Descreva o veículo, história, estado de conservação...',
                                prefixIcon: Icon(Icons.description),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              validator: (value) =>
                                  Validators.description(value, minLength: 50),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Preço por dia (€) *',
                                      hintText: 'Ex: 250',
                                      prefixIcon: Icon(Icons.euro),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: Validators.price,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Cidade *',
                                      hintText: 'Ex: Porto',
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                    validator: (value) =>
                                        Validators.required(value, 'Cidade'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de Eventos
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipos de Evento',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text(
                              'Selecione pelo menos um tipo de evento',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.favorite, size: 18),
                                      SizedBox(width: 4),
                                      Text('Casamento'),
                                    ],
                                  ),
                                  selected:
                                      _selectedEventTypes.contains('wedding'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedEventTypes.add('wedding');
                                      } else {
                                        _selectedEventTypes.remove('wedding');
                                      }
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.celebration, size: 18),
                                      SizedBox(width: 4),
                                      Text('Festa'),
                                    ],
                                  ),
                                  selected:
                                      _selectedEventTypes.contains('party'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedEventTypes.add('party');
                                      } else {
                                        _selectedEventTypes.remove('party');
                                      }
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.camera_alt, size: 18),
                                      SizedBox(width: 4),
                                      Text('Fotografia'),
                                    ],
                                  ),
                                  selected: _selectedEventTypes
                                      .contains('photoshoot'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedEventTypes.add('photoshoot');
                                      } else {
                                        _selectedEventTypes
                                            .remove('photoshoot');
                                      }
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.map, size: 18),
                                      SizedBox(width: 4),
                                      Text('Tour'),
                                    ],
                                  ),
                                  selected:
                                      _selectedEventTypes.contains('tour'),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedEventTypes.add('tour');
                                      } else {
                                        _selectedEventTypes.remove('tour');
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de Características
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Características',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text(
                              'Selecione as características do veículo',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  Constants.vehicleFeatures.map((feature) {
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

                                return FilterChip(
                                  avatar: Icon(icon, size: 18),
                                  label: Text(feature),
                                  selected: _selectedFeatures.contains(feature),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedFeatures.add(feature);
                                      } else {
                                        _selectedFeatures.remove(feature);
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

                    const SizedBox(height: 24),

                    // Botão guardar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveVehicle,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Veículo'),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedEventTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um tipo de evento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma fotografia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      // Criar o veículo primeiro
      final vehicle = VehicleModel(
        ownerId: authService.currentUser!.uid,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        category: _selectedCategory,
        eventTypes: _selectedEventTypes,
        description: _descriptionController.text.trim(),
        features: _selectedFeatures,
        images: [], // Vazio por agora
        pricePerDay: double.parse(_priceController.text),
        location: {
          'city': _cityController.text.trim(),
          'latitude': 41.1579,
          'longitude': -8.6291,
        },
        availability: {
          'isAvailable': true,
          'blockedDates': [],
        },
        validation: ValidationStatus(
          status: 'approved', // Auto-aprovar para teste
          validatedAt: DateTime.now(),
          validatedBy: 'system',
          documents: null,
        ),
        stats: VehicleStats(
          totalBookings: 0,
          rating: 4.5,
          views: 0,
        ),
        createdAt: DateTime.now(),
      );

      // Adicionar veículo à base de dados
      final vehicleId = await databaseService.addVehicle(vehicle);

      if (vehicleId != null) {
        // Upload das imagens
        print('A fazer upload de ${_images.length} imagens...');
        final imageUrls =
            await databaseService.uploadVehicleImages(vehicleId, _images);

        print('Upload concluído: ${imageUrls.length} URLs');

        // Atualizar veículo com as URLs das imagens
        if (imageUrls.isNotEmpty) {
          await databaseService.updateVehicle(vehicleId, {
            'images': imageUrls,
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo adicionado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        context.pop();
      } else {
        throw Exception('Erro ao adicionar veículo');
      }
    } catch (e) {
      print('Erro ao guardar veículo: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

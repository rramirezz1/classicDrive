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
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_input.dart';
import '../../widgets/loading_widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de adicionar veículo com design moderno.
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  void _showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
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
      if (!mounted) return;
      _showErrorSnackbar('Erro ao selecionar imagem: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Adicionar Foto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SourceOption(
                          icon: Icons.camera_alt_rounded,
                          label: 'Câmara',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SourceOption(
                          icon: Icons.photo_library_rounded,
                          label: 'Galeria',
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adicionar Veículo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isLoading ? null : _saveVehicle,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Guardar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? LoadingWidgets.formLoading(message: 'A guardar veículo...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagens
                    _buildImagesSection(isDark),
                    const SizedBox(height: 20),

                    // Informações Básicas
                    _buildBasicInfoSection(isDark),
                    const SizedBox(height: 20),

                    // Detalhes
                    _buildDetailsSection(isDark),
                    const SizedBox(height: 20),

                    // Eventos
                    _buildEventTypesSection(isDark),
                    const SizedBox(height: 20),

                    // Características
                    _buildFeaturesSection(isDark),
                    const SizedBox(height: 32),

                    // Botão guardar
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton.primary(
                        text: 'Guardar Veículo',
                        icon: Icons.save_rounded,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _saveVehicle,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagesSection(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Fotografias',
            Icons.photo_camera_rounded,
            AppColors.primary,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _images.isEmpty
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusFull,
              ),
              child: Text(
                '${_images.length}/5',
                style: TextStyle(
                  color: _images.isEmpty ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicione pelo menos uma foto do veículo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length + (_images.length < 5 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _images.length) {
                        return _buildAddImageButton(isDark);
                      }
                      return _buildImageThumbnail(index, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton(bool isDark) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: AppRadius.borderRadiusMd,
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicionar',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index, bool isDark) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.borderRadiusMd,
            child: Image.file(
              _images[index],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: const Text(
                  'Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Informações Básicas',
            Icons.info_outline_rounded,
            AppColors.info,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ModernInput(
                  controller: _brandController,
                  labelText: 'Marca',
                  hintText: 'Ex: Mercedes-Benz',
                  prefixIcon: Icons.directions_car_rounded,
                  validator: (value) => Validators.required(value, 'Marca'),
                ),
                const SizedBox(height: 16),
                ModernInput(
                  controller: _modelController,
                  labelText: 'Modelo',
                  hintText: 'Ex: 280 SL',
                  prefixIcon: Icons.badge_rounded,
                  validator: (value) => Validators.required(value, 'Modelo'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ModernInput(
                        controller: _yearController,
                        labelText: 'Ano',
                        hintText: 'Ex: 1971',
                        prefixIcon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.number,
                        validator: Validators.vehicleYear,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoria',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardHover
                                  : AppColors.lightCardHover,
                              borderRadius: AppRadius.borderRadiusMd,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'classic', child: Text('Clássico')),
                                  DropdownMenuItem(
                                      value: 'vintage', child: Text('Vintage')),
                                  DropdownMenuItem(
                                      value: 'luxury', child: Text('Luxo')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedCategory = value!);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Detalhes e Localização',
            Icons.description_rounded,
            AppColors.accent,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ModernInput(
                  controller: _descriptionController,
                  labelText: 'Descrição',
                  hintText:
                      'Descreva o veículo, história, estado de conservação...',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  validator: (value) =>
                      Validators.description(value, minLength: 50),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ModernInput(
                        controller: _priceController,
                        labelText: 'Preço por dia (€)',
                        hintText: 'Ex: 250',
                        prefixIcon: Icons.euro_rounded,
                        keyboardType: TextInputType.number,
                        validator: Validators.price,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernInput(
                        controller: _cityController,
                        labelText: 'Cidade',
                        hintText: 'Ex: Porto',
                        prefixIcon: Icons.location_city_rounded,
                        validator: (value) =>
                            Validators.required(value, 'Cidade'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypesSection(bool isDark) {
    final eventTypes = [
      ('wedding', '💒', 'Casamento'),
      ('party', '🎉', 'Festa'),
      ('photoshoot', '📸', 'Fotografia'),
      ('tour', '🚗', 'Tour'),
    ];

    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Tipos de Evento',
            Icons.event_rounded,
            AppColors.success,
            trailing: _selectedEventTypes.isEmpty
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                    child: const Text(
                      'Obrigatório',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione pelo menos um tipo de evento',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: eventTypes.map((event) {
                    final isSelected = _selectedEventTypes.contains(event.$1);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedEventTypes.remove(event.$1);
                          } else {
                            _selectedEventTypes.add(event.$1);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.success.withOpacity(0.15)
                              : (isDark
                                  ? AppColors.darkCardHover
                                  : AppColors.lightCardHover),
                          borderRadius: AppRadius.borderRadiusFull,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(event.$2, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              event.$3,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.success
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Características',
            Icons.auto_awesome_rounded,
            AppColors.warning,
            trailing: Text(
              '${_selectedFeatures.length} selecionadas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione as características do veículo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: Constants.vehicleFeatures.map((feature) {
                    IconData icon;
                    switch (feature.toLowerCase()) {
                      case 'ac':
                        icon = Icons.ac_unit_rounded;
                        break;
                      case 'chauffeur':
                        icon = Icons.person_rounded;
                        break;
                      case 'decorated':
                        icon = Icons.celebration_rounded;
                        break;
                      case 'gps':
                        icon = Icons.gps_fixed_rounded;
                        break;
                      case 'bluetooth':
                        icon = Icons.bluetooth_rounded;
                        break;
                      case 'usb charger':
                        icon = Icons.usb_rounded;
                        break;
                      default:
                        icon = Icons.check_rounded;
                    }

                    final isSelected = _selectedFeatures.contains(feature);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedFeatures.remove(feature);
                          } else {
                            _selectedFeatures.add(feature);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.warning.withOpacity(0.15)
                              : (isDark
                                  ? AppColors.darkCardHover
                                  : AppColors.lightCardHover),
                          borderRadius: AppRadius.borderRadiusFull,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.warning
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.warning
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              feature,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.warning
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color, {
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      _showWarningSnackbar('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    if (_selectedEventTypes.isEmpty) {
      _showWarningSnackbar('Selecione pelo menos um tipo de evento');
      return;
    }

    if (_images.isEmpty) {
      _showWarningSnackbar('Adicione pelo menos uma fotografia');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      final vehicle = VehicleModel(
        ownerId: authService.currentUser!.id,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        category: _selectedCategory,
        eventTypes: _selectedEventTypes,
        description: _descriptionController.text.trim(),
        features: _selectedFeatures,
        images: [],
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
          status: 'approved',
          validatedAt: DateTime.now(),
          validatedBy: 'system',
          documents: null,
        ),
        stats: VehicleStats(
          totalBookings: 0,
          rating: 0.0,
          views: 0,
        ),
        createdAt: DateTime.now(),
      );

      final vehicleId = await databaseService.addVehicle(vehicle);

      if (vehicleId != null) {
        final imageUrls =
            await databaseService.uploadVehicleImages(vehicleId, _images);

        if (imageUrls.isNotEmpty) {
          await databaseService.updateVehicle(vehicleId, {
            'images': imageUrls,
          });
        }

        if (!mounted) return;

        _showSuccessSnackbar('Veículo adicionado com sucesso!');

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        context.pop();
      } else {
        throw Exception('Erro ao adicionar veículo');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Erro: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

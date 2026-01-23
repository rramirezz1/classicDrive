import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/insurance_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../models/insurance_model.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../insurance/insurance_screen.dart';
import '../../services/payment_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de reserva com design moderno.
class BookingScreen extends StatefulWidget {
  final String vehicleId;

  const BookingScreen({super.key, required this.vehicleId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  VehicleModel? _vehicle;
  DateTime? _startDate;
  DateTime? _endDate;
  String _eventType = 'wedding';
  final _specialRequestsController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  InsuranceQuote? _selectedInsurance;
  bool _wantsInsurance = true;

  final DateTime _firstDate = DateTime.now();
  final DateTime _lastDate = DateTime.now().add(const Duration(days: 365));
  List<DateTime> _blockedDates = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final vehicle = await databaseService.getVehicleById(widget.vehicleId);

      if (vehicle != null) {
        final blockedDates =
            (vehicle.availability['blockedDates'] as List<dynamic>?)
                    ?.map((date) => DateTime.parse(date.toString()))
                    .toList() ??
                [];

        setState(() {
          _vehicle = vehicle;
          _eventType = vehicle.eventTypes.first;
          _blockedDates = blockedDates;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          _showErrorSnackbar('Veículo não encontrado');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Erro ao carregar veículo: $e');
      }
    }
  }

  int get _numberOfDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _basePrice {
    if (_vehicle == null || _numberOfDays == 0) return 0;
    return _vehicle!.pricePerDay * _numberOfDays;
  }

  double get _insurancePrice {
    if (!_wantsInsurance || _selectedInsurance == null) return 0;
    return _selectedInsurance!.totalPremium;
  }

  double get _totalPrice {
    return _basePrice + _insurancePrice;
  }

  bool _isDateBlocked(DateTime date) {
    return _blockedDates.any((blocked) =>
        blocked.year == date.year &&
        blocked.month == date.month &&
        blocked.day == date.day);
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

  Future<void> _selectDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: _firstDate,
      lastDate: _lastDate,
      currentDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkCard,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.lightCard,
                    onSurface: AppColors.lightTextPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      bool hasBlockedDates = false;
      for (DateTime date = picked.start;
          date.isBefore(picked.end) || date.isAtSameMomentAs(picked.end);
          date = date.add(const Duration(days: 1))) {
        if (_isDateBlocked(date)) {
          hasBlockedDates = true;
          break;
        }
      }

      if (hasBlockedDates) {
        _showWarningSnackbar('Algumas datas selecionadas não estão disponíveis');
        return;
      }

      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedInsurance = null;
      });
    }
  }

  Future<void> _selectInsurance() async {
    if (_startDate == null || _endDate == null) {
      _showWarningSnackbar('Por favor, selecione as datas primeiro');
      return;
    }

    final booking = BookingModel(
      vehicleId: widget.vehicleId,
      renterId: '',
      ownerId: _vehicle!.ownerId,
      startDate: _startDate!,
      endDate: _endDate!,
      eventType: _eventType,
      totalPrice: _basePrice,
      status: 'pending',
      payment: PaymentInfo(method: 'card', status: 'pending'),
      createdAt: DateTime.now(),
    );

    final result = await Navigator.push<InsuranceQuote?>(
      context,
      MaterialPageRoute(
        builder: (context) => InsuranceScreen(
          booking: booking,
          vehicle: _vehicle!,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedInsurance = result;
        _wantsInsurance = true;
      });
    } else {
      setState(() {
        _wantsInsurance = false;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_startDate == null || _endDate == null) {
      _showWarningSnackbar('Por favor, selecione as datas');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Usar processPaymentWithIntent para obter o payment_intent_id
      final paymentResult = await PaymentService().processPaymentWithIntent(
        amount: _totalPrice,
        currency: 'eur',
        context: context,
      );

      if (!paymentResult.success) {
        setState(() => _isSubmitting = false);
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final insuranceService = InsuranceService();

      final booking = BookingModel(
        vehicleId: widget.vehicleId,
        renterId: authService.currentUser!.id,
        ownerId: _vehicle!.ownerId,
        startDate: _startDate!,
        endDate: _endDate!,
        eventType: _eventType,
        totalPrice: _totalPrice,
        status: 'pending',
        paymentIntentId: paymentResult.paymentIntentId,  // Guardar para webhook
        payment: PaymentInfo(
          method: 'card',
          status: 'paid',
          transactionId: paymentResult.paymentIntentId,
        ),
        specialRequests: _specialRequestsController.text.trim().isNotEmpty
            ? _specialRequestsController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      final bookingId = await databaseService.createBooking(booking);

      if (bookingId != null) {
        if (_wantsInsurance && _selectedInsurance != null) {
          try {
            await insuranceService.activateInsurance(
              quote: _selectedInsurance!,
              paymentMethod: 'card',
              bookingId: bookingId,
            );
          } catch (e) {
            // Error ignored
          }
        }

        if (!mounted) return;

        _showSuccessDialog(bookingId);
      } else {
        throw Exception('Erro ao criar reserva');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Erro: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(String bookingId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.successOpacity10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reserva Confirmada!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'O pagamento foi processado com sucesso.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardHover
                    : AppColors.lightCardHover,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID da Reserva:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        bookingId.substring(0, 8).toUpperCase(),
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pago:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '€${_totalPrice.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ModernButton.primary(
                text: 'Concluir',
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fazer Reserva'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: LoadingWidgets.bookingShimmer(),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fazer Reserva'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.errorOpacity50,
              ),
              const SizedBox(height: 16),
              Text(
                'Veículo não encontrado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fazer Reserva',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do veículo
                _buildVehicleHeader(isDark),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seleção de datas
                      _buildDateSelector(isDark),
                      const SizedBox(height: 20),

                      // Tipo de evento
                      _buildEventTypeSelector(isDark),
                      const SizedBox(height: 20),

                      // Seguro
                      _buildInsuranceSection(isDark),
                      const SizedBox(height: 20),

                      // Pedidos especiais
                      _buildSpecialRequestsSection(isDark),
                      const SizedBox(height: 24),

                      // Resumo do preço
                      if (_numberOfDays > 0) _buildPriceSummary(isDark),

                      const SizedBox(height: 24),

                      // Botão de reserva
                      _buildBookingButton(isDark),

                      const SizedBox(height: 16),

                      // Info adicional
                      _buildInfoNote(isDark),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isSubmitting)
            LoadingWidgets.formLoading(message: 'Processando reserva...'),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(bool isDark) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: isDark ? AppShadows.softShadowDark : AppShadows.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _vehicle!.images.isNotEmpty
              ? Hero(
                  tag: 'vehicle-${_vehicle!.vehicleId}',
                  child: CachedNetworkImage(
                    imageUrl: _vehicle!.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDark
                          ? AppColors.darkCardHover
                          : AppColors.lightCardHover,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                )
              : Container(
                  color:
                      isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
                  child: const Icon(Icons.directions_car_rounded, size: 64),
                ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.blackOpacity70,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Info overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vehicle!.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _vehicle!.location['city'] ?? 'Porto',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '€${_vehicle!.pricePerDay.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'por dia',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      onTap: _selectDateRange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Período da Reserva',
            Icons.calendar_today_rounded,
            AppColors.primary,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                            : 'Selecione as datas',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: _startDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _startDate != null
                                  ? null
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary),
                            ),
                      ),
                      if (_numberOfDays > 0)
                        Text(
                          '$_numberOfDays ${_numberOfDays == 1 ? "dia" : "dias"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeSelector(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Tipo de Evento',
            Icons.event_rounded,
            AppColors.accent,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _vehicle!.eventTypes.map((type) {
                final isSelected = _eventType == type;
                String emoji;
                String label;
                switch (type) {
                  case 'wedding':
                    emoji = '💒';
                    label = 'Casamento';
                    break;
                  case 'party':
                    emoji = '🎉';
                    label = 'Festa';
                    break;
                  case 'photoshoot':
                    emoji = '📸';
                    label = 'Fotografia';
                    break;
                  default:
                    emoji = '🚗';
                    label = 'Tour';
                }
                return GestureDetector(
                  onTap: () => setState(() => _eventType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentOpacity15
                          : (isDark
                              ? AppColors.darkCardHover
                              : AppColors.lightCardHover),
                      borderRadius: AppRadius.borderRadiusFull,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '$emoji $label',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection(bool isDark) {
    final hasInsurance = _wantsInsurance && _selectedInsurance != null;

    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      onTap: _selectInsurance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasInsurance
                  ? AppColors.successOpacity10
                  : null,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (hasInsurance ? AppColors.success : AppColors.warning)
                        .withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: hasInsurance ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Seguro do Veículo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  hasInsurance
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: hasInsurance ? AppColors.success : AppColors.info,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedInsurance != null
                            ? 'Seguro ${_selectedInsurance!.coverageType == "basic" ? "Básico" : _selectedInsurance!.coverageType == "standard" ? "Standard" : "Premium"}'
                            : 'Adicionar Seguro',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        _selectedInsurance != null
                            ? '${_selectedInsurance!.partnerName} - €${_selectedInsurance!.totalPremium.toStringAsFixed(2)}'
                            : 'Proteja sua viagem com seguro completo',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ],
            ),
          ),
          if (!_wantsInsurance)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningOpacity10,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Viajará sem seguro adicional',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequestsSection(bool isDark) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Pedidos Especiais',
            Icons.edit_note_rounded,
            AppColors.info,
            trailing: Text(
              'Opcional',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _specialRequestsController,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Decoração específica, horários especiais, etc...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(bool isDark) {
    return ModernCard(
      useGlass: false,
      gradient: AppColors.primaryGradient,
      showBorder: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '€${_vehicle!.pricePerDay.toStringAsFixed(0)} x $_numberOfDays ${_numberOfDays == 1 ? "dia" : "dias"}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '€${_basePrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          if (_wantsInsurance && _selectedInsurance != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_rounded, size: 14, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'Seguro',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '€${_insurancePrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.whiteOpacity20,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '€${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ModernButton.primary(
        text: 'Pagar e Reservar',
        icon: Icons.credit_card_rounded,
        isLoading: _isSubmitting,
        onPressed: _isSubmitting ? null : _submitBooking,
      ),
    );
  }

  Widget _buildInfoNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoOpacity10,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.infoOpacity30,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O proprietário será notificado e terá 24h para confirmar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
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
}

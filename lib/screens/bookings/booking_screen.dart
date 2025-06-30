import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/insurance_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../models/insurance_model.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/animated_widgets.dart';
import '../insurance/insurance_screen.dart';

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

  // Seguro
  InsuranceQuote? _selectedInsurance;
  bool _wantsInsurance = true;

  // Para o calendário
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
        // Converter datas bloqueadas
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
          AnimatedWidgets.showAnimatedSnackBar(
            context,
            message: 'Veículo não encontrado',
            backgroundColor: Colors.red,
            icon: Icons.error,
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AnimatedWidgets.showAnimatedSnackBar(
          context,
          message: 'Erro ao carregar veículo: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
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

  Future<void> _selectDateRange() async {
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
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Verificar manualmente se as datas estão bloqueadas
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
        AnimatedWidgets.showAnimatedSnackBar(
          context,
          message: 'Algumas datas selecionadas não estão disponíveis',
          backgroundColor: Colors.orange,
          icon: Icons.warning,
        );
        return;
      }

      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        // Resetar seguro quando mudar datas
        _selectedInsurance = null;
      });
    }
  }

  Future<void> _selectInsurance() async {
    if (_startDate == null || _endDate == null) {
      AnimatedWidgets.showAnimatedSnackBar(
        context,
        message: 'Por favor, selecione as datas primeiro',
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
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
      AnimatedWidgets.showAnimatedSnackBar(
        context,
        message: 'Por favor, selecione as datas',
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final insuranceService = InsuranceService();

      final booking = BookingModel(
        vehicleId: widget.vehicleId,
        renterId: authService.currentUser!.uid,
        ownerId: _vehicle!.ownerId,
        startDate: _startDate!,
        endDate: _endDate!,
        eventType: _eventType,
        totalPrice: _totalPrice, 
        status: 'pending',
        payment: PaymentInfo(
          method: 'card',
          status: 'pending',
        ),
        specialRequests: _specialRequestsController.text.trim().isNotEmpty
            ? _specialRequestsController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      final bookingId = await databaseService.createBooking(booking);

      if (bookingId != null) {
        // Se tem seguro, ativar a apólice
        if (_wantsInsurance && _selectedInsurance != null) {
          try {
            final policy = await insuranceService.activateInsurance(
              quote: _selectedInsurance!,
              paymentMethod: 'card',
            );

            print('Seguro ativado: ${policy.policyNumber}');
          } catch (e) {
            print('Erro ao ativar seguro: $e');
          }
        }

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AnimatedWidgets.fadeInContent(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              title: const Text('Reserva Confirmada!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'A sua reserva foi criada com sucesso.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ID da Reserva:'),
                            Text(
                              bookingId.substring(0, 8).toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:'),
                            Text(
                              '€${_totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        if (_wantsInsurance && _selectedInsurance != null) ...[
                          const Divider(height: 16),
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Com seguro incluído',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                AnimatedWidgets.animatedButton(
                  text: 'OK',
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        throw Exception('Erro ao criar reserva');
      }
    } catch (e) {
      if (!mounted) return;

      AnimatedWidgets.showAnimatedSnackBar(
        context,
        message: 'Erro: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fazer Reserva'),
          elevation: 0,
        ),
        body: LoadingWidgets.bookingShimmer(),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fazer Reserva'),
          elevation: 0,
        ),
        body: AnimatedWidgets.fadeInContent(
          child: const Center(
            child: Text('Veículo não encontrado'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Reserva'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações do veículo
                AnimatedWidgets.fadeInContent(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                    child: _vehicle!.images.isNotEmpty
                        ? AnimatedWidgets.heroVehicleImage(
                            vehicleId: _vehicle!.vehicleId!,
                            imageUrl: _vehicle!.images.first,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.directions_car, size: 64),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e preço
                      AnimatedWidgets.fadeInContent(
                        delay: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _vehicle!.fullName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _vehicle!.location['city'] ?? 'Porto',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '€${_vehicle!.pricePerDay.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const Text(
                                    'por dia',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Seleção de datas
                      AnimatedWidgets.formField(
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Período da Reserva',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _selectDateRange,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _startDate != null &&
                                                    _endDate != null
                                                ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                                : 'Selecione as datas',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _startDate != null
                                                  ? Colors.black
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          if (_numberOfDays > 0)
                                            Text(
                                              '$_numberOfDays ${_numberOfDays == 1 ? "dia" : "dias"}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tipo de evento
                      AnimatedWidgets.formField(
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipo de Evento',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: _vehicle!.eventTypes.map((type) {
                                return ChoiceChip(
                                  label: Text(type == 'wedding'
                                      ? 'Casamento'
                                      : type == 'party'
                                          ? 'Festa'
                                          : type == 'photoshoot'
                                              ? 'Fotografia'
                                              : 'Tour'),
                                  selected: _eventType == type,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _eventType = type);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seguro
                      AnimatedWidgets.formField(
                        delay: const Duration(milliseconds: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text(
                                  'Seguro do Veículo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _selectInsurance,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _wantsInsurance &&
                                            _selectedInsurance != null
                                        ? Colors.green
                                        : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _wantsInsurance &&
                                          _selectedInsurance != null
                                      ? Colors.green[50]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _wantsInsurance &&
                                              _selectedInsurance != null
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      color: _wantsInsurance &&
                                              _selectedInsurance != null
                                          ? Colors.green
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedInsurance != null
                                                ? 'Seguro ${_selectedInsurance!.coverageType == "basic" ? "Básico" : _selectedInsurance!.coverageType == "standard" ? "Standard" : "Premium"}'
                                                : 'Adicionar Seguro',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _selectedInsurance != null
                                                ? '${_selectedInsurance!.partnerName} - €${_selectedInsurance!.totalPremium.toStringAsFixed(2)}'
                                                : 'Proteja sua viagem com seguro completo',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (!_wantsInsurance)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.orange[700], size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Viajará sem seguro adicional',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pedidos especiais
                      AnimatedWidgets.formField(
                        delay: const Duration(milliseconds: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pedidos Especiais (Opcional)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _specialRequestsController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText:
                                    'Decoração específica, horários, etc...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Resumo do preço
                      if (_numberOfDays > 0)
                        AnimatedWidgets.fadeInContent(
                          delay: const Duration(milliseconds: 700),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '€${_vehicle!.pricePerDay.toStringAsFixed(0)} x $_numberOfDays ${_numberOfDays == 1 ? "dia" : "dias"}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '€${_basePrice.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                if (_wantsInsurance &&
                                    _selectedInsurance != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.shield,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Seguro',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '€${_insurancePrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '€${_totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Botão de reserva
                      AnimatedWidgets.fadeInContent(
                        delay: const Duration(milliseconds: 800),
                        child: AnimatedWidgets.animatedButton(
                          text: 'Confirmar Reserva',
                          icon: Icons.check,
                          width: double.infinity,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submitBooking,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Informação adicional
                      AnimatedWidgets.fadeInContent(
                        delay: const Duration(milliseconds: 900),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'O proprietário será notificado e terá 24h para confirmar',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isSubmitting)
            LoadingWidgets.formLoading(message: 'Criando reserva...'),
        ],
      ),
    );
  }
}

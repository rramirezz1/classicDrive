import 'package:flutter/material.dart';
import '../../services/insurance_service.dart';
import '../../models/insurance_model.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/animated_widgets.dart';

class InsuranceScreen extends StatefulWidget {
  final BookingModel booking;
  final VehicleModel vehicle;

  const InsuranceScreen({
    super.key,
    required this.booking,
    required this.vehicle,
  });

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  final InsuranceService _insuranceService = InsuranceService();
  String _selectedCoverage = 'standard';
  String _selectedPartner = 'liberty';
  bool _isLoading = true;
  InsuranceQuote? _currentQuote;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoading = true);

    try {
      final quote = await _insuranceService.calculateInsurance(
        booking: widget.booking,
        vehicle: widget.vehicle,
        coverageType: _selectedCoverage,
        partnerId: _selectedPartner,
      );

      setState(() {
        _currentQuote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AnimatedWidgets.showAnimatedSnackBar(
        context,
        message: 'Erro ao calcular seguro: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguro do Veículo'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informação do veículo
                  AnimatedWidgets.fadeInContent(
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.directions_car),
                        ),
                        title: Text(widget.vehicle.fullName),
                        subtitle: Text(
                          'Valor estimado: €${_currentQuote?.vehicleValue.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seleção de cobertura
                  AnimatedWidgets.fadeInContent(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de Cobertura',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCoverageOption(
                          type: 'basic',
                          title: 'Básica',
                          price: 0, 
                          features: [
                            'Responsabilidade civil',
                            'Cobertura até €50.000',
                          ],
                          selected: _selectedCoverage == 'basic',
                        ),
                        _buildCoverageOption(
                          type: 'standard',
                          title: 'Standard',
                          price: 0,
                          features: [
                            'Responsabilidade civil',
                            'Danos por colisão',
                            'Assistência em viagem',
                            'Cobertura até €100.000',
                          ],
                          selected: _selectedCoverage == 'standard',
                          recommended: true,
                        ),
                        _buildCoverageOption(
                          type: 'premium',
                          title: 'Premium',
                          price: 0,
                          features: [
                            'Cobertura completa',
                            'Veículo de substituição',
                            'Sem franquia',
                            'Cobertura até €250.000',
                          ],
                          selected: _selectedCoverage == 'premium',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seleção de parceiro
                  AnimatedWidgets.fadeInContent(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seguradora Parceira',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: InsuranceService.partners.map((partner) {
                            return InkWell(
                              onTap: () {
                                setState(() => _selectedPartner = partner.id);
                                _loadQuote();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedPartner == partner.id
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.shield,
                                      size: 40,
                                      color: _selectedPartner == partner.id
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      partner.name.split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            _selectedPartner == partner.id
                                                ? FontWeight.bold
                                                : FontWeight.normal,
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

                  const SizedBox(height: 24),

                  // Resumo do seguro
                  if (_currentQuote != null)
                    AnimatedWidgets.fadeInContent(
                      delay: const Duration(milliseconds: 300),
                      child: Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumo do Seguro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(
                                'Seguradora',
                                _currentQuote!.partnerName,
                              ),
                              _buildSummaryRow(
                                'Tipo de Cobertura',
                                _getCoverageTitle(_selectedCoverage),
                              ),
                              _buildSummaryRow(
                                'Período',
                                '${widget.booking.numberOfDays} dias',
                              ),
                              _buildSummaryRow(
                                'Franquia',
                                '€${_currentQuote!.deductible.toStringAsFixed(0)}',
                              ),
                              const Divider(height: 24),
                              _buildSummaryRow(
                                'Prémio Total',
                                '€${_currentQuote!.totalPremium.toStringAsFixed(2)}',
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Informações importantes
                  AnimatedWidgets.fadeInContent(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informações Importantes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• O seguro é ativado no início da reserva\n'
                                  '• Em caso de sinistro, contacte-nos imediatamente\n'
                                  '• Guarde todos os documentos e fotos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botões de ação
                  AnimatedWidgets.fadeInContent(
                    delay: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('Recusar Seguro'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedWidgets.animatedButton(
                            text: 'Adicionar Seguro',
                            icon: Icons.shield,
                            onPressed: () =>
                                Navigator.pop(context, _currentQuote),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCoverageOption({
    required String type,
    required String title,
    required double price,
    required List<String> features,
    required bool selected,
    bool recommended = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedCoverage = type);
        _loadQuote();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                selected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selected ? Theme.of(context).primaryColor : null,
                  ),
                ),
                const SizedBox(width: 8),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Recomendado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                if (_currentQuote != null)
                  Text(
                    '€${(_currentQuote!.totalPremium * _getCoverageMultiplier(type)).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: selected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: selected ? null : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getCoverageTitle(String type) {
    switch (type) {
      case 'basic':
        return 'Básica';
      case 'standard':
        return 'Standard';
      case 'premium':
        return 'Premium';
      default:
        return type;
    }
  }

  double _getCoverageMultiplier(String type) {
    switch (type) {
      case 'basic':
        return 1.0;
      case 'standard':
        return 1.5;
      case 'premium':
        return 2.0;
      default:
        return 1.0;
    }
  }
}

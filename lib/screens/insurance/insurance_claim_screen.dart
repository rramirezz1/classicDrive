import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/insurance_service.dart';
import '../../models/insurance_model.dart';
import '../../widgets/animated_widgets.dart';

class InsuranceClaimScreen extends StatefulWidget {
  final InsurancePolicy policy;

  const InsuranceClaimScreen({
    super.key,
    required this.policy,
  });

  @override
  State<InsuranceClaimScreen> createState() => _InsuranceClaimScreenState();
}

class _InsuranceClaimScreenState extends State<InsuranceClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final InsuranceService _insuranceService = InsuranceService();
  final ImagePicker _picker = ImagePicker();

  String _claimType = 'damage';

  // Controllers
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  // Imagens
  final List<File> _photos = [];

  // Informações adicionais
  bool _hasPoliceReport = false;
  bool _hasWitnesses = false;
  final _policeReportController = TextEditingController();
  final _witnessController = TextEditingController();

  bool _isSubmitting = false;
  DateTime _incidentDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _policeReportController.dispose();
    _witnessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Sinistro'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informação da apólice
            AnimatedWidgets.fadeInContent(
              child: Card(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Apólice: ${widget.policy.policyNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cobertura: ${_getCoverageTitle(widget.policy.coverageType)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Franquia: €${widget.policy.deductible.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tipo de sinistro
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de Sinistro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildClaimTypeCard(
                    type: 'damage',
                    title: 'Danos',
                    subtitle: 'Danos ao veículo por colisão ou vandalismo',
                    icon: Icons.car_crash,
                  ),
                  _buildClaimTypeCard(
                    type: 'theft',
                    title: 'Roubo',
                    subtitle: 'Roubo total ou parcial do veículo',
                    icon: Icons.security,
                  ),
                  _buildClaimTypeCard(
                    type: 'accident',
                    title: 'Acidente',
                    subtitle: 'Acidente com feridos ou danos a terceiros',
                    icon: Icons.warning,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detalhes do incidente
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalhes do Incidente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data e hora
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _incidentDate,
                              firstDate: widget.policy.startDate,
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _incidentDate = date;
                                _dateController.text =
                                    '${date.day}/${date.month}/${date.year}';
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, selecione a data';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Hora',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _timeController.text = time.format(context);
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, selecione a hora';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Localização
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Local do incidente',
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'Rua, cidade...',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o local';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Descrição
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrição detalhada',
                      alignLabelWithHint: true,
                      hintText:
                          'Descreva o que aconteceu com o máximo de detalhes...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, descreva o incidente';
                      }
                      if (value.length < 50) {
                        return 'Por favor, forneça mais detalhes (mínimo 50 caracteres)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Fotos
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fotografias',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione fotos dos danos ou do local',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Grid de fotos
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _photos.length) {
                          return _buildAddPhotoButton();
                        }
                        return _buildPhotoItem(_photos[index], index);
                      },
                    ),
                  ),

                  if (_photos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Adicione pelo menos 3 fotos',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informações adicionais
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações Adicionais',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Relatório policial
                  SwitchListTile(
                    title: const Text('Foi feito relatório policial?'),
                    value: _hasPoliceReport,
                    onChanged: (value) {
                      setState(() => _hasPoliceReport = value);
                    },
                  ),

                  if (_hasPoliceReport)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _policeReportController,
                        decoration: const InputDecoration(
                          labelText: 'Número do relatório',
                          prefixIcon: Icon(Icons.assignment),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Testemunhas
                  SwitchListTile(
                    title: const Text('Existem testemunhas?'),
                    value: _hasWitnesses,
                    onChanged: (value) {
                      setState(() => _hasWitnesses = value);
                    },
                  ),

                  if (_hasWitnesses)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _witnessController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Informações das testemunhas',
                          alignLabelWithHint: true,
                          hintText: 'Nome e contacto das testemunhas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Aviso importante
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                          Text(
                            'Importante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Não mova o veículo antes de fotografar\n'
                            '• Guarde todos os recibos relacionados\n'
                            '• Contacte-nos em até 48h após o incidente',
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

            // Botão submeter
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 600),
              child: AnimatedWidgets.animatedButton(
                text: 'Submeter Sinistro',
                icon: Icons.send,
                width: double.infinity,
                isLoading: _isSubmitting,
                onPressed: _submitClaim,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _claimType == type;

    return InkWell(
      onTap: () => setState(() => _claimType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? null : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _claimType,
              onChanged: (value) => setState(() => _claimType = value!),
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Adicionar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(File photo, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              photo,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: Container(
                decoration: const BoxDecoration(
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
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmara'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() => _photos.add(File(image.path)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() => _photos.add(File(image.path)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_photos.length < 3) {
      AnimatedWidgets.showAnimatedSnackBar(
        context,
        message: 'Por favor, adicione pelo menos 3 fotos',
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Upload das fotos para storage
      List<String> photoUrls = [];
      // ... código de upload ...

      // Informações adicionais
      Map<String, dynamic> additionalInfo = {
        'location': _locationController.text,
        'date': _incidentDate.toIso8601String(),
        'time': _timeController.text,
      };

      if (_hasPoliceReport) {
        additionalInfo['policeReport'] = _policeReportController.text;
      }

      if (_hasWitnesses) {
        additionalInfo['witnesses'] = _witnessController.text;
      }

      // Submeter claim
      final claim = await _insuranceService.submitClaim(
        policyNumber: widget.policy.policyNumber,
        type: _claimType,
        description: _descriptionController.text,
        photos: photoUrls,
        additionalInfo: additionalInfo,
      );

      if (!mounted) return;

      // Mostrar sucesso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text('Sinistro Submetido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O seu sinistro foi submetido com sucesso.',
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
                    Text(
                      'Número do Sinistro',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.claimNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Será contactado em até 24h úteis',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      AnimatedWidgets.showAnimatedSnackBar(
        context,
        message: 'Erro ao submeter sinistro: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
}

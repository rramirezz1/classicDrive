import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';
import 'kyc_camera_screen.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  // Dados do KYC
  File? _selfieImage;
  File? _idFrontImage;
  File? _idBackImage;
  File? _drivingLicenseImage;
  File? _proofOfAddressImage;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.isOwner;
    final totalSteps = isOwner ? 4 : 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de Identidade'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    totalSteps,
                    (index) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          left: index > 0 ? 4 : 0,
                          right: index < totalSteps - 1 ? 4 : 0,
                        ),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Passo ${_currentStep + 1} de $totalSteps',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSelfieStep(),
                _buildDocumentStep(),
                _buildDrivingLicenseStep(),
                if (isOwner) _buildProofOfAddressStep(),
              ],
            ),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _handleStepCancel,
                    child: const Text('Voltar'),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep < totalSteps - 1
                        ? _handleStepContinue
                        : (_isSubmitting ? null : _submitVerification),
                    child: _currentStep < totalSteps - 1
                        ? const Text('Continuar')
                        : _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submeter Verificação'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.face,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Selfie com Documento',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tire uma selfie segurando o seu documento de identidade',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_selfieImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selfieImage!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => setState(() => _selfieImage = null),
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () => _pickImage((image) => _selfieImage = image, overlayType: KycOverlayType.selfie),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tirar Selfie'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          const SizedBox(height: 16),
          _buildRequirements([
            'Rosto claramente visível',
            'Documento legível na foto',
            'Boa iluminação',
            'Sem óculos de sol ou chapéu',
          ]),
        ],
      ),
    );
  }

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.credit_card,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Documento de Identidade',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fotografe a frente e o verso do seu documento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDocumentUpload(
                title: 'Frente',
                image: _idFrontImage,
                onPick: (image) => setState(() => _idFrontImage = image),
                onRemove: () => setState(() => _idFrontImage = null),
              ),
              _buildDocumentUpload(
                title: 'Verso',
                image: _idBackImage,
                onPick: (image) => setState(() => _idBackImage = image),
                onRemove: () => setState(() => _idBackImage = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirements([
            'Documento dentro da validade',
            'Todas as informações legíveis',
            'Sem reflexos ou sombras',
            'Foto completa do documento',
          ]),
        ],
      ),
    );
  }

  Widget _buildDrivingLicenseStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Carta de Condução',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fotografe a sua carta de condução',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_drivingLicenseImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _drivingLicenseImage!,
                    height: 200,
                    width: MediaQuery.of(context).size.width - 64,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () =>
                        setState(() => _drivingLicenseImage = null),
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () =>
                  _pickImage((image) => _drivingLicenseImage = image),
              icon: const Icon(Icons.credit_card),
              label: const Text('Fotografar Carta'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 48),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Necessária para alugar ou disponibilizar veículos',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofOfAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.home,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Comprovativo de Morada',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envie um comprovativo de morada recente',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Fatura de eletricidade, água, gás ou extrato bancário',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (_proofOfAddressImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _proofOfAddressImage!,
                    height: 200,
                    width: MediaQuery.of(context).size.width - 64,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () =>
                        setState(() => _proofOfAddressImage = null),
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () =>
                  _pickImage((image) => _proofOfAddressImage = image),
              icon: const Icon(Icons.home),
              label: const Text('Adicionar Comprovativo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 48),
              ),
            ),
          const SizedBox(height: 16),
          _buildRequirements([
            'Documento dos últimos 3 meses',
            'Nome e morada visíveis',
            'Data claramente legível',
          ]),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required File? image,
    required Function(File) onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (image != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onRemove,
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: () => _pickImage(onPick),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text('Adicionar', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRequirements(List<String> requirements) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: requirements
            .map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req,
                          style:
                              TextStyle(fontSize: 13, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _pickImage(Function(File) onPicked, {KycOverlayType overlayType = KycOverlayType.document}) async {
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
                // Usar câmara KYC personalizada
                final File? image = await Navigator.push<File>(
                  this.context,
                  MaterialPageRoute(
                    builder: (_) => KycCameraScreen(
                      overlayType: overlayType,
                      currentStep: _currentStep + 1,
                      totalSteps: 4,
                    ),
                  ),
                );
                if (image != null) {
                  setState(() => onPicked(image));
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
                  setState(() => onPicked(File(image.path)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleStepContinue() {
    if (_validateCurrentStep()) {
      setState(() {
        _currentStep++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos os campos necessários'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selfieImage != null;
      case 1:
        return _idFrontImage != null && _idBackImage != null;
      case 2:
        return _drivingLicenseImage != null;
      case 3:
        return _proofOfAddressImage != null;
      default:
        return false;
    }
  }

  Future<void> _submitVerification() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwner = authService.isOwner;

    // Validar todos os passos
    bool isValid = _selfieImage != null &&
        _idFrontImage != null &&
        _idBackImage != null &&
        _drivingLicenseImage != null;

    if (isOwner) {
      isValid = isValid && _proofOfAddressImage != null;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos os passos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Criar o serviço de verificação
      final verificationService = VerificationService();

      // Submeter documentos
      await verificationService.submitKYCDocuments(
        userId: authService.currentUser!.id,
        selfie: _selfieImage!,
        idFront: _idFrontImage!,
        idBack: _idBackImage!,
        drivingLicense: _drivingLicenseImage!,
        proofOfAddress: _proofOfAddressImage,
      );

      if (!mounted) return;

      // Mostrar sucesso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text('Verificação Submetida!'),
          content: const Text(
            'Os seus documentos foram enviados para verificação. '
            'Será notificado assim que o processo estiver concluído.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao submeter verificação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

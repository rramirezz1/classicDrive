import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:io';

/// Tipos de overlay para a câmara KYC
enum KycOverlayType {
  selfie,   // Oval para rosto
  document, // Retângulo para documento/BI
}

/// Ecrã de câmara personalizada para verificação KYC
/// Inclui overlays visuais, instruções, verificação de luz, preview e haptic feedback
class KycCameraScreen extends StatefulWidget {
  final KycOverlayType overlayType;
  final int currentStep;
  final int totalSteps;

  const KycCameraScreen({
    super.key,
    required this.overlayType,
    this.currentStep = 1,
    this.totalSteps = 2,
  });

  @override
  State<KycCameraScreen> createState() => _KycCameraScreenState();
}

class _KycCameraScreenState extends State<KycCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _showFlash = false;
  bool _lowLight = false;
  File? _capturedImage;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('Nenhuma câmara disponível');
        return;
      }

      // Para selfie, usar câmara frontal por defeito
      if (widget.overlayType == KycOverlayType.selfie) {
        _selectedCameraIndex = _cameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;
      } else {
        // Para documento, usar câmara traseira
        _selectedCameraIndex = _cameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;
      }

      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      _showError('Erro ao iniciar câmara: $e');
    }
  }

  Future<void> _setupCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller?.dispose();

    _controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      
      // Monitorar luminosidade (simulado via exposure)
      _controller!.setExposureMode(ExposureMode.auto);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _selectedCameraIndex = index;
        });
      }
    } catch (e) {
      _showError('Erro ao configurar câmara: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final newIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    setState(() => _isInitialized = false);
    await _setupCamera(newIndex);
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Flash animation
      setState(() => _showFlash = true);
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _showFlash = false);

      // Capturar imagem
      final XFile image = await _controller!.takePicture();

      setState(() {
        _capturedImage = File(image.path);
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      _showError('Erro ao capturar imagem: $e');
    }
  }

  void _retakePhoto() {
    setState(() => _capturedImage = null);
  }

  void _usePhoto() {
    if (_capturedImage != null) {
      Navigator.pop(context, _capturedImage);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String get _instructionText {
    if (widget.overlayType == KycOverlayType.selfie) {
      return 'Posicione o rosto dentro do círculo';
    } else {
      return 'Alinhe o documento dentro do retângulo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview ou imagem capturada
          if (_capturedImage != null)
            _buildPreview()
          else if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Overlay (só mostra durante captura)
          if (_capturedImage == null && _isInitialized)
            CustomPaint(
              painter: _OverlayPainter(
                overlayType: widget.overlayType,
              ),
            ),

          // Flash effect
          if (_showFlash)
            Container(color: Colors.white),

          // UI Elements
          if (_capturedImage == null) ...[
            // App bar com progresso
            _buildTopBar(),

            // Instruções
            _buildInstructions(),

            // Aviso de luz baixa
            if (_lowLight) _buildLowLightWarning(),

            // Controlos da câmara
            _buildCameraControls(),
          ] else
            _buildPreviewControls(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Image.file(
      _capturedImage!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Botão voltar
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Indicador de progresso
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Passo ${widget.currentStep}/${widget.totalSteps}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _instructionText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLowLightWarning() {
    return Positioned(
      bottom: 180,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Iluminação baixa - procure mais luz',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Espaço vazio para balancear
              const SizedBox(width: 60),

              // Botão de captura
              GestureDetector(
                onTap: _isCapturing ? null : _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing ? Colors.grey : Colors.white,
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              // Trocar câmara
              IconButton(
                icon: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _switchCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Repetir
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Repetir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Usar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _usePhoto,
                  icon: const Icon(Icons.check),
                  label: const Text('Usar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter para desenhar o overlay da câmara
class _OverlayPainter extends CustomPainter {
  final KycOverlayType overlayType;

  _OverlayPainter({required this.overlayType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (overlayType == KycOverlayType.selfie) {
      // Oval para selfie
      final centerX = size.width / 2;
      final centerY = size.height * 0.4;
      final radiusX = size.width * 0.35;
      final radiusY = size.height * 0.22;

      final ovalRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radiusX * 2,
        height: radiusY * 2,
      );

      path.addOval(ovalRect);
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);

      // Borda do oval
      canvas.drawOval(ovalRect, borderPaint);

      // Marcadores guia nos cantos do oval
      _drawCornerGuides(canvas, ovalRect, borderPaint);
    } else {
      // Retângulo para documento
      final centerX = size.width / 2;
      final centerY = size.height * 0.4;
      final rectWidth = size.width * 0.85;
      final rectHeight = rectWidth * 0.63; // Proporção de cartão ID

      final docRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: rectWidth,
        height: rectHeight,
      );

      final rrect = RRect.fromRectAndRadius(docRect, const Radius.circular(12));
      path.addRRect(rrect);
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);

      // Borda do retângulo
      canvas.drawRRect(rrect, borderPaint);

      // Marcadores guia nos cantos
      _drawRectCornerGuides(canvas, docRect, borderPaint);
    }
  }

  void _drawCornerGuides(Canvas canvas, Rect rect, Paint paint) {
    final guidePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const guideLength = 20.0;

    // Top left
    canvas.drawLine(
      Offset(rect.left, rect.top + rect.height * 0.1),
      Offset(rect.left, rect.top + rect.height * 0.1 + guideLength),
      guidePaint,
    );
  }

  void _drawRectCornerGuides(Canvas canvas, Rect rect, Paint paint) {
    final guidePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const guideLength = 30.0;

    // Top left corner
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(guideLength, 0),
      guidePaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, guideLength),
      guidePaint,
    );

    // Top right corner
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-guideLength, 0),
      guidePaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, guideLength),
      guidePaint,
    );

    // Bottom left corner
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(guideLength, 0),
      guidePaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -guideLength),
      guidePaint,
    );

    // Bottom right corner
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-guideLength, 0),
      guidePaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -guideLength),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço de inteligência artificial para geração de respostas.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  /// Inicializa o modelo de IA.
  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    _isInitialized = true;
  }

  /// Gera uma resposta baseada no prompt e contexto fornecidos.
  Future<String?> generateResponse(String prompt, {String? context}) async {
    if (!_isInitialized || _model == null) {
      initialize();
      if (!_isInitialized) {
        return null;
      }
    }

    try {
      final content = [
        Content.text('''
Contexto do sistema:
$context

Pergunta do utilizador:
$prompt

Responde de forma útil, amigável e concisa. Se não souberes a resposta com base no contexto, diz que não sabes e sugere contactar o suporte humano.
''')
      ];

      final response = await _model!.generateContent(content);
      return response.text;
    } catch (e) {
      return null;
    }
  }
}

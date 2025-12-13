import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// Serviço de chatbot para suporte ao utilizador.
class ChatbotService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Processa uma mensagem do utilizador e retorna uma resposta.
  Future<ChatbotReply> processMessage(String message, String userId) async {
    await _logMessage(userId, message, true);

    String responseText;
    List<String> actions = [];
    bool needsHuman = false;

    try {
      final context = '''
      És o assistente virtual da ClassicDrive, uma app de aluguer de carros clássicos.
      
      Regras:
      1. Sê educado e profissional.
      2. O teu objetivo é ajudar os utilizadores a alugar carros ou tirar dúvidas.
      3. Se o utilizador quiser falar com um humano, diz que vais encaminhar.
      4. Responde em Português de Portugal.
      
      Informação útil:
      - Aceitamos pagamentos por Cartão e MB Way.
      - O cancelamento é gratuito até 48h antes.
      - É necessário verificar a conta (KYC) para alugar.
      ''';

      final aiResponse = await AIService().generateResponse(message, context: context);

      if (aiResponse != null) {
        responseText = aiResponse;
        if (responseText.toLowerCase().contains('reserva')) {
          actions = ['Ver veículos', 'Fazer reserva'];
        } else if (responseText.toLowerCase().contains('verifi')) {
          actions = ['Verificar conta'];
        }
      } else {
        responseText = 'Desculpe, estou com dificuldades de conexão. Mas posso ajudar com reservas e informações.';
        actions = ['Ver veículos', 'Suporte'];
      }
    } catch (e) {
      responseText = 'Ocorreu um erro. Por favor tente mais tarde.';
      needsHuman = true;
    }

    if (message.toLowerCase().contains('humano') || message.toLowerCase().contains('suporte')) {
      needsHuman = true;
      actions.add('Contactar Suporte');
    }

    await _logMessage(userId, responseText, false);

    return ChatbotReply(
      text: responseText,
      suggestedActions: actions,
      requiresHuman: needsHuman,
    );
  }

  /// Regista uma mensagem na base de dados.
  Future<void> _logMessage(String userId, String message, bool isUser) async {
    try {
      await _supabase.from('chatbot_logs').insert({
        'user_id': userId,
        'message': message,
        'is_user': isUser,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Erro silencioso
    }
  }

  /// Obtém as perguntas frequentes mais comuns.
  Future<List<FAQ>> getTopFAQs() async {
    return [
      FAQ(
        question: 'Como faço para reservar um veículo?',
        answer: 'Procure o veículo desejado, verifique a disponibilidade, '
            'selecione as datas e complete o pagamento.',
        category: 'reservas',
      ),
      FAQ(
        question: 'Quais documentos preciso para alugar?',
        answer: 'Precisa de: Carta de condução válida, documento de identidade '
            'e comprovativo de morada (para alguns veículos).',
        category: 'documentos',
      ),
      FAQ(
        question: 'Posso cancelar minha reserva?',
        answer: 'Sim! Até 48h antes tem reembolso total. Entre 24-48h, '
            'reembolso de 50%. Menos de 24h não há reembolso.',
        category: 'cancelamento',
      ),
      FAQ(
        question: 'O seguro está incluído?',
        answer: 'O seguro básico está incluído. Pode adicionar coberturas '
            'adicionais (standard ou premium) por um custo extra.',
        category: 'seguro',
      ),
      FAQ(
        question: 'Como funciona a verificação de conta?',
        answer: 'Envie seus documentos (ID, carta de condução) pelo app. '
            'A aprovação demora até 48h e aumenta sua confiabilidade.',
        category: 'verificacao',
      ),
    ];
  }

  /// Cria um ticket de suporte.
  Future<String> createSupportTicket({
    required String userId,
    required String subject,
    required String message,
    required String priority,
  }) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'subject': subject,
            'message': message,
            'priority': priority,
            'status': 'open',
            'created_at': DateTime.now().toIso8601String(),
            'assigned_to': null,
            'chat_history': [],
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Falha ao criar ticket de suporte');
    }
  }
}

/// Modelo de resposta do chatbot.
class ChatbotResponse {
  final List<String> patterns;
  final List<String> responses;
  final List<String> suggestedActions;

  const ChatbotResponse({
    required this.patterns,
    required this.responses,
    required this.suggestedActions,
  });
}

/// Modelo de resposta do chatbot para o utilizador.
class ChatbotReply {
  final String text;
  final List<String> suggestedActions;
  final bool requiresHuman;

  ChatbotReply({
    required this.text,
    required this.suggestedActions,
    required this.requiresHuman,
  });
}

/// Modelo de pergunta frequente.
class FAQ {
  final String question;
  final String answer;
  final String category;

  FAQ({
    required this.question,
    required this.answer,
    required this.category,
  });
}

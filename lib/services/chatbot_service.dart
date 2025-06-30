import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Base de conhecimento do chatbot
  static const Map<String, ChatbotResponse> knowledgeBase = {
    'reserva': ChatbotResponse(
      patterns: ['reserva', 'reservar', 'alugar', 'booking'],
      responses: [
        'Para fazer uma reserva, siga estes passos:\n'
            '1. Procure o veículo desejado\n'
            '2. Verifique a disponibilidade\n'
            '3. Selecione as datas\n'
            '4. Complete o pagamento',
      ],
      suggestedActions: [
        'Ver veículos disponíveis',
        'Política de cancelamento',
        'Métodos de pagamento',
      ],
    ),
    'pagamento': ChatbotResponse(
      patterns: ['pagamento', 'pagar', 'cartão', 'mbway'],
      responses: [
        'Aceitamos vários métodos de pagamento:\n'
            '💳 Cartão de crédito/débito\n'
            '📱 MB Way\n'
            '🏦 Transferência bancária\n'
            '💰 PayPal',
      ],
      suggestedActions: [
        'Problemas com pagamento',
        'Segurança dos pagamentos',
        'Solicitar fatura',
      ],
    ),
    'verificacao': ChatbotResponse(
      patterns: ['verificar', 'verificação', 'kyc', 'identidade'],
      responses: [
        'A verificação de conta é importante para:\n'
            '✅ Aumentar a confiança\n'
            '✅ Desbloquear todos os recursos\n'
            '✅ Obter o badge de verificado\n\n'
            'O processo é rápido e seguro!',
      ],
      suggestedActions: [
        'Iniciar verificação',
        'Documentos necessários',
        'Tempo de aprovação',
      ],
    ),
    'seguro': ChatbotResponse(
      patterns: ['seguro', 'cobertura', 'sinistro', 'acidente'],
      responses: [
        'Oferecemos seguro completo:\n'
            '🛡️ Básico: Responsabilidade civil\n'
            '🛡️ Standard: + Colisão e assistência\n'
            '🛡️ Premium: Cobertura total sem franquia',
      ],
      suggestedActions: [
        'Comparar coberturas',
        'Como acionar o seguro',
        'Fazer um claim',
      ],
    ),
    'cancelamento': ChatbotResponse(
      patterns: ['cancelar', 'cancelamento', 'desistir'],
      responses: [
        'Política de cancelamento:\n'
            '• Até 48h antes: Reembolso total\n'
            '• 24-48h antes: Reembolso de 50%\n'
            '• Menos de 24h: Sem reembolso\n\n'
            'Exceções aplicam-se em casos especiais.',
      ],
      suggestedActions: [
        'Cancelar reserva',
        'Alterar datas',
        'Contactar proprietário',
      ],
    ),
  };

  // Processar mensagem do utilizador
  Future<ChatbotReply> processMessage(String message, String userId) async {
    // Registar mensagem
    await _logMessage(userId, message, true);

    // Analisar intenção
    final intent = _analyzeIntent(message.toLowerCase());

    // Gerar resposta
    ChatbotReply reply;
    if (intent != null) {
      final response = knowledgeBase[intent]!;
      reply = ChatbotReply(
        text: response.responses.first,
        suggestedActions: response.suggestedActions,
        requiresHuman: false,
      );
    } else {
      // Não entendeu - verificar se precisa de humano
      final needsHuman = _checkIfNeedsHuman(message);
      reply = ChatbotReply(
        text: needsHuman
            ? 'Vou transferir você para um atendente humano.'
            : 'Desculpe, não entendi. Posso ajudar com reservas, pagamentos, verificação ou seguro.',
        suggestedActions: needsHuman
            ? ['Deixar mensagem', 'Ver FAQ']
            : ['Fazer reserva', 'Verificação', 'Suporte', 'FAQ'],
        requiresHuman: needsHuman,
      );
    }

    // Registar resposta
    await _logMessage(userId, reply.text, false);

    return reply;
  }

  // Analisar intenção da mensagem
  String? _analyzeIntent(String message) {
    for (var entry in knowledgeBase.entries) {
      for (var pattern in entry.value.patterns) {
        if (message.contains(pattern)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // Verificar se precisa de atendimento humano
  bool _checkIfNeedsHuman(String message) {
    final humanKeywords = [
      'humano',
      'atendente',
      'pessoa',
      'falar com alguém',
      'urgente',
      'problema grave',
      'não funciona',
      'bug'
    ];

    return humanKeywords
        .any((keyword) => message.toLowerCase().contains(keyword));
  }

  // Registar conversa
  Future<void> _logMessage(String userId, String message, bool isUser) async {
    try {
      await _firestore.collection('chatbot_logs').add({
        'userId': userId,
        'message': message,
        'isUser': isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao registar mensagem do chatbot: $e');
    }
  }

  // Obter FAQs mais comuns
  Future<List<FAQ>> getTopFAQs() async {
    // Por agora, retornar FAQs estáticas
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

  // Criar ticket de suporte quando necessário
  Future<String> createSupportTicket({
    required String userId,
    required String subject,
    required String message,
    required String priority,
  }) async {
    try {
      final docRef = await _firestore.collection('support_tickets').add({
        'userId': userId,
        'subject': subject,
        'message': message,
        'priority': priority,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'assignedTo': null,
        'chatHistory': [],
      });

      return docRef.id;
    } catch (e) {
      print('Erro ao criar ticket de suporte: $e');
      throw Exception('Falha ao criar ticket de suporte');
    }
  }
}

// Modelos
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

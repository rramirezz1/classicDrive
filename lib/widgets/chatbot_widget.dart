// lib/widgets/chatbot_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'animated_widgets.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    // Mensagem inicial
    _addBotMessage(
      'Olá! 👋 Sou o assistente virtual do ClassicDrive. '
      'Como posso ajudá-lo hoje?',
      options: [
        'Como fazer uma reserva?',
        'Problemas com pagamento',
        'Verificar minha conta',
        'Falar com humano',
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _addBotMessage(String text, {List<String>? options}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        options: options,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();
    _processMessage(text);
  }

  void _processMessage(String message) async {
    // Simular processamento
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() => _isTyping = false);

    // Respostas baseadas em palavras-chave
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('reserva') || lowerMessage.contains('alugar')) {
      _addBotMessage(
        'Para fazer uma reserva:\n\n'
        '1. Procure o veículo desejado\n'
        '2. Selecione as datas\n'
        '3. Clique em "Reservar"\n'
        '4. Complete o pagamento\n\n'
        'Precisa de mais ajuda com reservas?',
        options: [
          'Ver veículos disponíveis',
          'Política de cancelamento',
          'Métodos de pagamento',
        ],
      );
    } else if (lowerMessage.contains('pagamento')) {
      _addBotMessage(
        'Aceitamos os seguintes métodos de pagamento:\n\n'
        '💳 Cartão de crédito/débito\n'
        '📱 MB Way\n'
        '🏦 Transferência bancária\n'
        '💰 PayPal\n\n'
        'Está com problemas no pagamento?',
        options: [
          'Pagamento recusado',
          'Alterar método de pagamento',
          'Solicitar fatura',
        ],
      );
    } else if (lowerMessage.contains('verificar') ||
        lowerMessage.contains('kyc')) {
      _addBotMessage(
        'A verificação de conta garante mais segurança! 🔒\n\n'
        'Para verificar sua conta:\n'
        '1. Aceda ao seu perfil\n'
        '2. Clique em "Verificar conta"\n'
        '3. Siga os passos para enviar documentos\n\n'
        'Vantagens:\n'
        '✅ Badge de verificado\n'
        '✅ Maior confiança\n'
        '✅ Acesso a todos os veículos',
        options: [
          'Iniciar verificação',
          'Documentos necessários',
          'Tempo de aprovação',
        ],
      );
    } else if (lowerMessage.contains('humano') ||
        lowerMessage.contains('atendente')) {
      _addBotMessage(
        'Vou transferir para um atendente humano. 👤\n\n'
        'Horário de atendimento:\n'
        '🕐 Segunda a Sexta: 9h às 18h\n'
        '🕐 Sábados: 9h às 13h\n\n'
        'Fora do horário? Deixe sua mensagem que retornaremos!',
        options: [
          'Deixar mensagem',
          'Ver FAQ',
          'Voltar ao menu',
        ],
      );
    } else if (lowerMessage.contains('seguro')) {
      _addBotMessage(
        'Oferecemos seguro completo para sua tranquilidade! 🛡️\n\n'
        '• Cobertura básica: Incluída\n'
        '• Cobertura standard: +15% do valor\n'
        '• Cobertura premium: +25% do valor\n\n'
        'Parceiros: Liberty, Allianz, Fidelidade',
        options: [
          'Detalhes das coberturas',
          'Como acionar o seguro',
          'Fazer um claim',
        ],
      );
    } else {
      _addBotMessage(
        'Não entendi completamente sua pergunta. 🤔\n'
        'Posso ajudar com:',
        options: [
          'Fazer reserva',
          'Verificação de conta',
          'Problemas técnicos',
          'Falar com humano',
        ],
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Envolver o Stack com SizedBox para dar constraints definidos
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Botão flutuante do chat
          Positioned(
            right: 16,
            bottom: 16,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.8).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: FloatingActionButton(
                onPressed: _toggleChat,
                backgroundColor:
                    _isOpen ? Colors.grey : Theme.of(context).primaryColor,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isOpen ? Icons.close : Icons.chat,
                    key: ValueKey(_isOpen),
                  ),
                ),
              ),
            ),
          ),

          // Janela do chat
          if (_isOpen)
            Positioned(
              right: 16,
              bottom: 80,
              // CORREÇÃO: Definir width e height para evitar overflow
              width: MediaQuery.of(context).size.width > 370
                  ? 350
                  : MediaQuery.of(context).size.width - 32,
              height: MediaQuery.of(context).size.height > 600
                  ? 500
                  : MediaQuery.of(context).size.height * 0.7,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.bottomRight,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Cabeçalho
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.support_agent,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Assistente ClassicDrive',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Online 24/7',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.minimize,
                                    color: Colors.white),
                                onPressed: _toggleChat,
                              ),
                            ],
                          ),
                        ),

                        // Mensagens
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isTyping && index == _messages.length) {
                                return _buildTypingIndicator();
                              }
                              return _buildMessage(_messages[index]);
                            },
                          ),
                        ),

                        // Input
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Digite sua mensagem...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    if (text.trim().isNotEmpty) {
                                      _addUserMessage(text.trim());
                                      _messageController.clear();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: IconButton(
                                  icon: const Icon(Icons.send,
                                      color: Colors.white),
                                  onPressed: () {
                                    final text = _messageController.text.trim();
                                    if (text.isNotEmpty) {
                                      _addUserMessage(text);
                                      _messageController.clear();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return AnimatedWidgets.fadeInContent(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.support_agent,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (message.options != null) ...[
                    const SizedBox(height: 8),
                    ...message.options!.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: InkWell(
                            onTap: () => _addUserMessage(option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _getUserInitial(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.support_agent,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(
                3,
                (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300 + index * 100),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    )),
          ),
        ),
      ],
    );
  }

  String _getUserInitial() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final name = authService.userData?.name ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? options;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.options,
  });
}

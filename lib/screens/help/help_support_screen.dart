import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/animated_widgets.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _contactFormKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';


  final List<FAQItem> _faqItems = [
    FAQItem(
      category: 'Geral',
      question: 'Como funciona o ClassicDrive?',
      answer:
          'O ClassicDrive é uma plataforma que conecta proprietários de carros clássicos '
          'com pessoas que desejam alugá-los para eventos especiais. Os proprietários '
          'expôem os seus veículos, definem preços e disponibilidade, enquanto os arrendatários '
          'podem pesquisar, reservar e pagar diretamente pela plataforma.',
    ),
    FAQItem(
      category: 'Proprietários',
      question: 'Como adiciono o meu veículo?',
      answer: 'Para adicionar um veículo:\n'
          '1. Aceda ao menu "Adicionar Veículo"\n'
          '2. Preencha todos os detalhes do veículo\n'
          '3. Adicione fotos de alta qualidade\n'
          '4. Defina o preço e disponibilidade\n'
          '5. Submeta para aprovação\n\n'
          'A nossa equipa irá revisar e aprovar em até 48 horas.',
    ),
    FAQItem(
      category: 'Proprietários',
      question: 'Qual a comissão da plataforma?',
      answer:
          'O ClassicDrive cobra uma comissão de 15% sobre cada reserva confirmada. '
          'Esta comissão cobre os custos de manutenção da plataforma, processamento de '
          'pagamentos, suporte ao cliente e marketing.',
    ),
    FAQItem(
      category: 'Arrendatários',
      question: 'Como faço uma reserva?',
      answer: 'Para fazer uma reserva:\n'
          '1. Procure o veículo desejado\n'
          '2. Verifique a disponibilidade\n'
          '3. Clique em "Reservar"\n'
          '4. Selecione as datas\n'
          '5. Preencha os detalhes e efetue o pagamento\n\n'
          'Receberá uma confirmação assim que o proprietário aprovar.',
    ),
    FAQItem(
      category: 'Arrendatários',
      question: 'Posso cancelar uma reserva?',
      answer:
          'Sim, pode cancelar uma reserva até 48 horas antes da data de início '
          'para receber um reembolso total. Cancelamentos feitos com menos de 48 horas '
          'estão sujeitos a uma taxa de cancelamento de 50%.',
    ),
    FAQItem(
      category: 'Pagamentos',
      question: 'Que métodos de pagamento são aceites?',
      answer: 'Aceitamos:\n'
          '• Cartões de crédito/débito (Visa, Mastercard)\n'
          '• MB Way\n'
          '• Transferência bancária\n'
          '• PayPal\n\n'
          'Todos os pagamentos são processados de forma segura.',
    ),
    FAQItem(
      category: 'Segurança',
      question: 'Os veículos têm seguro?',
      answer:
          'Sim, todos os veículos listados na plataforma devem ter seguro válido. '
          'Além disso, oferecemos um seguro adicional opcional que cobre danos durante '
          'o período de aluguer.',
    ),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contactos Rápidos
            AnimatedWidgets.fadeInContent(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Precisa de ajuda imediata?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickContact(
                          icon: Icons.phone,
                          label: 'Ligar',
                          onTap: () => _launchPhone(),
                        ),
                        _buildQuickContact(
                          icon: Icons.email,
                          label: 'Email',
                          onTap: () => _launchEmail(),
                        ),
                        _buildQuickContact(
                          icon: Icons.chat,
                          label: 'Chat',
                          onTap: () => _openChat(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Perguntas Frequentes
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 100),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perguntas Frequentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ExpansionPanelList.radio(
                      elevation: 1,
                      children: _faqItems.map((item) {
                        return ExpansionPanelRadio(
                          value: item.question,
                          headerBuilder: (context, isExpanded) {
                            return ListTile(
                              title: Text(
                                item.question,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                item.category,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                          body: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              item.answer,
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Formulário de Contacto
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Form(
                  key: _contactFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enviar Mensagem',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Não encontrou a resposta? Envie-nos uma mensagem.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Categoria
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'general',
                            child: Text('Questão Geral'),
                          ),
                          DropdownMenuItem(
                            value: 'technical',
                            child: Text('Problema Técnico'),
                          ),
                          DropdownMenuItem(
                            value: 'payment',
                            child: Text('Pagamentos'),
                          ),
                          DropdownMenuItem(
                            value: 'account',
                            child: Text('Conta'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Outro'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Assunto
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Assunto',
                          prefixIcon: Icon(Icons.subject),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira um assunto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Mensagem
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Mensagem',
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma mensagem';
                          }
                          if (value.length < 10) {
                            return 'A mensagem deve ter pelo menos 10 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitContactForm,
                          child: const Text('Enviar Mensagem'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Links Úteis
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Links Úteis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Guia do Utilizador'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openGuide(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle),
                      title: const Text('Tutoriais em Vídeo'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openTutorials(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.article),
                      title: const Text('Blog'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openBlog(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.group),
                      title: const Text('Comunidade'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openCommunity(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContact({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchPhone() async {
    const phoneNumber = 'tel:+351912345678';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o telefone'),
          ),
        );
      }
    }
  }

  void _launchEmail() async {
    const email = 'mailto:suporte@classicdrive.pt?subject=Ajuda%20ClassicDrive';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o email'),
          ),
        );
      }
    }
  }

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat em desenvolvimento'),
      ),
    );
  }

  void _submitContactForm() {
    if (_contactFormKey.currentState!.validate()) {
      // TODO: Enviar mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensagem enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Limpar formulário
      _subjectController.clear();
      _messageController.clear();
      setState(() => _selectedCategory = 'general');
    }
  }

  void _openGuide() async {
    const url = 'https://classicdrive.pt/guia';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openTutorials() async {
    const url = 'https://youtube.com/@classicdrive';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openBlog() async {
    const url = 'https://classicdrive.pt/blog';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openCommunity() async {
    const url = 'https://facebook.com/classicdrive';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class FAQItem {
  final String category;
  final String question;
  final String answer;

  FAQItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

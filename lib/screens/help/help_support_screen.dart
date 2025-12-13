import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de ajuda e suporte com design moderno.
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
  int? _expandedFAQ;

  final List<FAQItem> _faqItems = [
    FAQItem(
      category: 'Geral',
      question: 'Como funciona o ClassicDrive?',
      answer:
          'O ClassicDrive é uma plataforma que conecta proprietários de carros clássicos '
          'com pessoas que desejam alugá-los para eventos especiais.',
    ),
    FAQItem(
      category: 'Proprietários',
      question: 'Como adiciono o meu veículo?',
      answer:
          'Aceda ao menu "Adicionar Veículo", preencha os detalhes, adicione fotos e submeta para aprovação.',
    ),
    FAQItem(
      category: 'Proprietários',
      question: 'Qual a comissão da plataforma?',
      answer:
          'O ClassicDrive cobra uma comissão de 15% sobre cada reserva confirmada.',
    ),
    FAQItem(
      category: 'Arrendatários',
      question: 'Como faço uma reserva?',
      answer:
          'Procure o veículo, verifique disponibilidade, clique em "Reservar" e efetue o pagamento.',
    ),
    FAQItem(
      category: 'Arrendatários',
      question: 'Posso cancelar uma reserva?',
      answer:
          'Sim, pode cancelar até 48h antes para reembolso total. Menos de 48h tem taxa de 50%.',
    ),
    FAQItem(
      category: 'Pagamentos',
      question: 'Que métodos de pagamento são aceites?',
      answer: 'Visa, Mastercard, MB Way, Transferência bancária e PayPal.',
    ),
    FAQItem(
      category: 'Segurança',
      question: 'Os veículos têm seguro?',
      answer:
          'Sim, todos os veículos devem ter seguro válido. Oferecemos seguro adicional opcional.',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Ajuda e Suporte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contactos Rápidos
            _buildQuickContactCard(isDark),
            const SizedBox(height: 24),

            // Perguntas Frequentes
            Text(
              'Perguntas Frequentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildFAQList(isDark),
            const SizedBox(height: 24),

            // Formulário de Contacto
            _buildContactForm(isDark),
            const SizedBox(height: 24),

            // Links Úteis
            _buildUsefulLinks(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Precisa de ajuda imediata?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickContact(
                icon: Icons.phone_rounded,
                label: 'Ligar',
                onTap: _launchPhone,
              ),
              _buildQuickContact(
                icon: Icons.email_rounded,
                label: 'Email',
                onTap: _launchEmail,
              ),
              _buildQuickContact(
                icon: Icons.chat_rounded,
                label: 'Chat',
                onTap: _openChat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContact({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList(bool isDark) {
    return Column(
      children: _faqItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isExpanded = _expandedFAQ == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ModernCard(
            useGlass: false,
            padding: EdgeInsets.zero,
            onTap: () {
              setState(() {
                _expandedFAQ = isExpanded ? null : index;
              });
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: AppRadius.borderRadiusSm,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.question,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              item.category,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                      ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardHover
                            : AppColors.lightCardHover,
                        borderRadius: AppRadius.borderRadiusMd,
                      ),
                      child: Text(
                        item.answer,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactForm(bool isDark) {
    return ModernCard(
      useGlass: false,
      child: Form(
        key: _contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    Icons.mail_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enviar Mensagem',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Não encontrou a resposta?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoria',
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('Questão Geral')),
                DropdownMenuItem(
                    value: 'technical', child: Text('Problema Técnico')),
                DropdownMenuItem(value: 'payment', child: Text('Pagamentos')),
                DropdownMenuItem(value: 'account', child: Text('Conta')),
                DropdownMenuItem(value: 'other', child: Text('Outro')),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),

            // Assunto
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Assunto',
                prefixIcon: const Icon(Icons.subject_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
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
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Mensagem',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
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
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitContactForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
                child: const Text(
                  'Enviar Mensagem',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsefulLinks(bool isDark) {
    final links = [
      ('Guia do Utilizador', Icons.description_rounded, _openGuide),
      ('Tutoriais em Vídeo', Icons.play_circle_rounded, _openTutorials),
      ('Blog', Icons.article_rounded, _openBlog),
      ('Comunidade', Icons.group_rounded, _openCommunity),
    ];

    return ModernCard(
      useGlass: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Icon(Icons.link_rounded, color: AppColors.info, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Links Úteis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...links.map((link) => _buildLinkTile(
                isDark,
                link.$1,
                link.$2,
                link.$3,
              )),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
      bool isDark, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    isDark ? AppColors.darkTextSecondary : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
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
      _showSnackbar('Não foi possível abrir o telefone', AppColors.error);
    }
  }

  void _launchEmail() async {
    const email =
        'mailto:suporte@classicdrive.pt?subject=Ajuda%20ClassicDrive';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      _showSnackbar('Não foi possível abrir o email', AppColors.error);
    }
  }

  void _openChat() {
    _showSnackbar('Chat em desenvolvimento', AppColors.info);
  }

  void _submitContactForm() {
    if (_contactFormKey.currentState!.validate()) {
      _showSnackbar('Mensagem enviada com sucesso!', AppColors.success);
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

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
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

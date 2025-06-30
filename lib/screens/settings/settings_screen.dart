import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Configurações de notificações
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _marketingEmails = false;

  // Configurações de privacidade
  bool _profilePublic = true;
  bool _showPhone = false;
  bool _showLocation = true;

  // Tema
  bool _darkMode = false;

  // Idioma
  String _selectedLanguage = 'pt';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Definições'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notificações
            AnimatedWidgets.fadeInContent(
              child: _buildSection(
                title: 'Notificações',
                icon: Icons.notifications_outlined,
                children: [
                  _buildSwitchTile(
                    title: 'Notificações Push',
                    subtitle: 'Receber notificações no telemóvel',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                      _saveNotificationSettings();
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Notificações por Email',
                    subtitle: 'Receber atualizações por email',
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                      _saveNotificationSettings();
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Notificações por SMS',
                    subtitle: 'Receber SMS para reservas importantes',
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() => _smsNotifications = value);
                      _saveNotificationSettings();
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Emails de Marketing',
                    subtitle: 'Receber ofertas e novidades',
                    value: _marketingEmails,
                    onChanged: (value) {
                      setState(() => _marketingEmails = value);
                      _saveNotificationSettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacidade
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 100),
              child: _buildSection(
                title: 'Privacidade',
                icon: Icons.lock_outline,
                children: [
                  _buildSwitchTile(
                    title: 'Perfil Público',
                    subtitle: 'Permitir que outros vejam o seu perfil',
                    value: _profilePublic,
                    onChanged: (value) {
                      setState(() => _profilePublic = value);
                      _savePrivacySettings();
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Mostrar Telefone',
                    subtitle: 'Exibir número de telefone no perfil',
                    value: _showPhone,
                    onChanged: (value) {
                      setState(() => _showPhone = value);
                      _savePrivacySettings();
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Mostrar Localização',
                    subtitle: 'Exibir cidade nos anúncios',
                    value: _showLocation,
                    onChanged: (value) {
                      setState(() => _showLocation = value);
                      _savePrivacySettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Aparência
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 200),
              child: _buildSection(
                title: 'Aparência',
                icon: Icons.palette_outlined,
                children: [
                  _buildSwitchTile(
                    title: 'Modo Escuro',
                    subtitle: 'Ativar tema escuro',
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      // TODO: Implementar mudança de tema
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mudança de tema em desenvolvimento'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Idioma'),
                    subtitle: Text(_getLanguageName(_selectedLanguage)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Conta
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                title: 'Conta',
                icon: Icons.person_outline,
                children: [
                  ListTile(
                    title: const Text('Alterar Palavra-passe'),
                    leading: const Icon(Icons.lock_outline),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  if (authService.isOwner)
                    ListTile(
                      title: const Text('Mudar para Conta de Arrendatário'),
                      leading: const Icon(Icons.swap_horiz),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAccountTypeDialog(),
                    ),
                  ListTile(
                    title: const Text(
                      'Eliminar Conta',
                      style: TextStyle(color: Colors.red),
                    ),
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sobre
            AnimatedWidgets.fadeInContent(
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                title: 'Sobre',
                icon: Icons.info_outline,
                children: [
                  ListTile(
                    title: const Text('Versão da App'),
                    subtitle: const Text('1.0.0 (Build 1)'),
                    leading: const Icon(Icons.info_outline),
                  ),
                  ListTile(
                    title: const Text('Termos de Uso'),
                    leading: const Icon(Icons.description_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Abrir termos de uso
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Abrir termos de uso'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Política de Privacidade'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Abrir política de privacidade'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Licenças Open Source'),
                    leading: const Icon(Icons.code),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'ClassicDrive',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(
                          Icons.directions_car,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Português';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Português'),
              value: 'pt',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idioma alterado para Português'),
                  ),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language changed to English'),
                  ),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idioma cambiado a Español'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Palavra-passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe atual',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a palavra-passe atual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova palavra-passe',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a nova palavra-passe';
                  }
                  if (value.length < 6) {
                    return 'A palavra-passe deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova palavra-passe',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'As palavras-passe não coincidem';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                // TODO: Implementar alteração de senha
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                  ),
                );
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  void _showAccountTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mudar Tipo de Conta'),
        content: const Text(
          'Tem a certeza que deseja mudar para uma conta de arrendatário? '
          'Não poderá adicionar ou gerir veículos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar mudança de tipo de conta
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Mudar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Conta'),
        content: const Text(
          'Tem a certeza que deseja eliminar a sua conta? '
          'Esta ação é irreversível e todos os seus dados serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminação de conta
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _saveNotificationSettings() {
    // Salvar configurações no Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de notificações atualizadas'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _savePrivacySettings() {
    // Salvar configurações no Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de privacidade atualizadas'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

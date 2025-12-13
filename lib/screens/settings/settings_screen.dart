import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../widgets/modern_card.dart';

/// Ecrã de definições com design moderno.
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

  // Idioma
  String _selectedLanguage = 'pt';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Definições',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aparência - Com toggle de tema funcional
            _buildSection(
              context: context,
              title: 'Aparência',
              icon: Icons.palette_outlined,
              iconColor: AppColors.primaryEnd,
              isDark: isDark,
              children: [
                _buildThemeToggle(context, themeProvider, isDark),
                _buildDivider(isDark),
                _buildNavigationTile(
                  context: context,
                  title: 'Idioma',
                  subtitle: _getLanguageName(_selectedLanguage),
                  icon: Icons.language_rounded,
                  onTap: () => _showLanguageDialog(isDark),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Notificações
            _buildSection(
              context: context,
              title: 'Notificações',
              icon: Icons.notifications_outlined,
              iconColor: AppColors.accent,
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  title: 'Notificações Push',
                  subtitle: 'Receber notificações no telemóvel',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _saveNotificationSettings();
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  title: 'Notificações por Email',
                  subtitle: 'Receber atualizações por email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _saveNotificationSettings();
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  title: 'Notificações por SMS',
                  subtitle: 'Receber SMS para reservas importantes',
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() => _smsNotifications = value);
                    _saveNotificationSettings();
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  title: 'Emails de Marketing',
                  subtitle: 'Receber ofertas e novidades',
                  value: _marketingEmails,
                  onChanged: (value) {
                    setState(() => _marketingEmails = value);
                    _saveNotificationSettings();
                  },
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Privacidade
            _buildSection(
              context: context,
              title: 'Privacidade',
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.success,
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  title: 'Perfil Público',
                  subtitle: 'Permitir que outros vejam o seu perfil',
                  value: _profilePublic,
                  onChanged: (value) {
                    setState(() => _profilePublic = value);
                    _savePrivacySettings();
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  title: 'Mostrar Telefone',
                  subtitle: 'Exibir número de telefone no perfil',
                  value: _showPhone,
                  onChanged: (value) {
                    setState(() => _showPhone = value);
                    _savePrivacySettings();
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  title: 'Mostrar Localização',
                  subtitle: 'Exibir cidade nos anúncios',
                  value: _showLocation,
                  onChanged: (value) {
                    setState(() => _showLocation = value);
                    _savePrivacySettings();
                  },
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Conta
            _buildSection(
              context: context,
              title: 'Conta',
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.info,
              isDark: isDark,
              children: [
                _buildNavigationTile(
                  context: context,
                  title: 'Alterar Palavra-passe',
                  icon: Icons.lock_outline_rounded,
                  onTap: () => _showChangePasswordDialog(isDark),
                  isDark: isDark,
                ),
                if (authService.isOwner) ...[
                  _buildDivider(isDark),
                  _buildNavigationTile(
                    context: context,
                    title: 'Mudar para Conta de Arrendatário',
                    icon: Icons.swap_horiz_rounded,
                    onTap: () => _showAccountTypeDialog(isDark),
                    isDark: isDark,
                  ),
                ],
                _buildDivider(isDark),
                _buildNavigationTile(
                  context: context,
                  title: 'Eliminar Conta',
                  icon: Icons.delete_forever_rounded,
                  onTap: () => _showDeleteAccountDialog(isDark),
                  isDark: isDark,
                  color: AppColors.error,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sobre
            _buildSection(
              context: context,
              title: 'Sobre',
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.primary,
              isDark: isDark,
              children: [
                _buildInfoTile(
                  context: context,
                  title: 'Versão da App',
                  subtitle: '1.0.0 (Build 1)',
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  context: context,
                  title: 'Termos de Uso',
                  icon: Icons.description_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abrir termos de uso')),
                    );
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  context: context,
                  title: 'Política de Privacidade',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abrir política de privacidade'),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildNavigationTile(
                  context: context,
                  title: 'Licenças Open Source',
                  icon: Icons.code_rounded,
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'ClassicDrive',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: AppRadius.borderRadiusLg,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 52,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(
              themeProvider.themeMode == ThemeMode.system
                  ? Icons.brightness_auto_rounded
                  : (isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              color: isDark ? AppColors.accent : AppColors.primary,
              size: 20,
            ),
          ),
          title: const Text('Tema'),
          subtitle: Text(
            _getThemeModeName(themeProvider.themeMode),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildThemeChip(
                  context,
                  'Claro',
                  Icons.light_mode_rounded,
                  themeProvider.themeMode == ThemeMode.light,
                  () => themeProvider.setThemeMode(ThemeMode.light),
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeChip(
                  context,
                  'Escuro',
                  Icons.dark_mode_rounded,
                  themeProvider.themeMode == ThemeMode.dark,
                  () => themeProvider.setThemeMode(ThemeMode.dark),
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeChip(
                  context,
                  'Auto',
                  Icons.brightness_auto_rounded,
                  themeProvider.themeMode == ThemeMode.system,
                  () => themeProvider.setSystemMode(),
                  isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeChip(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCardHover : Colors.grey[200]),
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Tema escuro activado';
      case ThemeMode.light:
        return 'Tema claro activado';
      case ThemeMode.system:
        return 'Seguir preferência do sistema';
    }
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    String? subtitle,
    Color? color,
  }) {
    final tileColor = color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: AppRadius.borderRadiusSm,
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color ?? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: AppRadius.borderRadiusSm,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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

  void _showLanguageDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.topRadiusLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppRadius.borderRadiusFull,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Selecionar Idioma',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption('pt', 'Português', '🇵🇹', isDark),
            _buildLanguageOption('en', 'English', '🇬🇧', isDark),
            _buildLanguageOption('es', 'Español', '🇪🇸', isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String code,
    String name,
    String flag,
    bool isDark,
  ) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLanguage = code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Idioma alterado para $name'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null,
                  ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(bool isDark) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.topRadiusLg,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Alterar Palavra-passe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Palavra-passe atual',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
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
                    prefixIcon: Icon(Icons.lock_rounded),
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
                    prefixIcon: Icon(Icons.lock_rounded),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'As palavras-passe não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Funcionalidade em desenvolvimento'),
                              ),
                            );
                          }
                        },
                        child: const Text('Alterar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountTypeDialog(bool isDark) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Mudar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Eliminar Conta'),
          ],
        ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _saveNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Configurações de notificações atualizadas'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _savePrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Configurações de privacidade atualizadas'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

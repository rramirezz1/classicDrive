import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/admin_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/loyalty_widgets.dart';
import '../../services/loyalty_service.dart';
import '../../models/loyalty_model.dart';
import '../../main.dart' show mainNavigationKey;

/// Ecrã de perfil com design moderno.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _nameController =
        TextEditingController(text: authService.userData?.name ?? '');
    _phoneController =
        TextEditingController(text: authService.userData?.phone ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userData != null) {
      if (_nameController.text.isEmpty &&
          authService.userData!.name.isNotEmpty) {
        _nameController.text = authService.userData!.name;
      }
      if (_phoneController.text.isEmpty &&
          authService.userData!.phone.isNotEmpty) {
        _phoneController.text = authService.userData!.phone;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final result = await authService.updateUserProfile(
        updates: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        if (result == null) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });

          _showSuccessSnackbar('Perfil atualizado com sucesso!');
        } else {
          throw Exception(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackbar('Erro ao atualizar perfil: $e');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final user = authService.userData;
    final isOwner = authService.isOwner;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header com gradient
          _buildHeader(context, user, isOwner, authService, isDark),

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estatísticas (para proprietários)
                  if (isOwner) ...[
                    const SizedBox(height: 20),
                    _buildOwnerStats(
                      context,
                      authService,
                      databaseService,
                      isDark,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Informações Pessoais
                  _buildPersonalInfo(user, isDark),

                  const SizedBox(height: 24),

                  // Programa de Fidelidade
                  FutureBuilder<LoyaltyModel?>(
                    future: LoyaltyService().getUserLoyalty(
                      authService.currentUser?.id ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: LoyaltyCard(loyalty: snapshot.data!),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Ações Rápidas
                  _buildQuickActions(context, isOwner, isDark),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    bool isOwner,
    AuthService authService,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.whiteOpacity15,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: 'Terminar Sessão',
            onPressed: () => _showLogoutDialog(authService),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
          child: Stack(
            children: [
              // Círculos decorativos
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.whiteOpacity08,
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.whiteOpacity05,
                  ),
                ),
              ),
              // Conteúdo
              Positioned(
                left: 24,
                right: 24,
                bottom: 30,
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.whiteOpacity20,
                            AppColors.whiteOpacity10,
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.whiteOpacity20,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blackOpacity20,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nome
                    Text(
                      user?.name ?? 'Utilizador',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge tipo de conta
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteOpacity15,
                        borderRadius: AppRadius.borderRadiusFull,
                        border: Border.all(
                          color: AppColors.whiteOpacity20,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOwner ? Icons.key_rounded : Icons.person_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOwner ? 'Proprietário' : 'Cliente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (user?.isVerified == true) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerStats(
    BuildContext context,
    AuthService authService,
    DatabaseService databaseService,
    bool isDark,
  ) {
    return StreamBuilder<List<VehicleModel>>(
      stream: databaseService.getVehiclesByOwner(authService.currentUser!.id),
      builder: (context, vehicleSnapshot) {
        return StreamBuilder<List<BookingModel>>(
          stream: databaseService.getUserBookings(
            authService.currentUser!.id,
            asOwner: true,
          ),
          builder: (context, bookingSnapshot) {
            final vehicles = vehicleSnapshot.data ?? [];
            final bookings = bookingSnapshot.data ?? [];
            final activeBookings = bookings
                .where(
                    (b) => b.status == 'confirmed' || b.status == 'pending')
                .length;
            final totalRevenue = bookings
                .where((b) => b.status == 'completed')
                .fold(0.0, (sum, b) => sum + b.totalPrice);

            return Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.directions_car_rounded,
                    value: vehicles.length.toString(),
                    label: 'Veículos',
                    iconColor: AppColors.info,
                    onTap: () => context.push('/my-vehicles'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.calendar_today_rounded,
                    value: activeBookings.toString(),
                    label: 'Reservas Ativas',
                    iconColor: AppColors.accent,
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      mainNavigationKey.currentState?.changeTab(2);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.euro_rounded,
                    value: '€${totalRevenue.toStringAsFixed(0)}',
                    label: 'Receita',
                    iconColor: AppColors.success,
                    onTap: () => context.push('/reports'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPersonalInfo(dynamic user, bool isDark) {
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
                    color: AppColors.primaryOpacity10,
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informações Pessoais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (!_isEditing)
                  ModernIconButton(
                    icon: Icons.edit_rounded,
                    size: 40,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_rounded,
                    label: 'Nome',
                    controller: _nameController,
                    enabled: _isEditing,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: user?.email ?? '',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Telefone',
                    controller: _phoneController,
                    enabled: _isEditing,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o telefone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Membro desde',
                    value: user?.createdAt != null
                        ? DateFormat('dd/MM/yyyy').format(user!.createdAt)
                        : '',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  // Status de verificação
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (user?.isVerified == true
                              ? AppColors.success
                              : AppColors.warning)
                          .withOpacity(0.1),
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          user?.isVerified == true
                              ? Icons.verified_user_rounded
                              : Icons.gpp_maybe_rounded,
                          color: user?.isVerified == true
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conta Verificada',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user?.isVerified == true
                                    ? 'A sua identidade foi verificada'
                                    : 'Conta não verificada',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (user?.isVerified != true)
                          TextButton(
                            onPressed: () => context.push('/kyc-verification'),
                            child: const Text('Verificar'),
                          ),
                      ],
                    ),
                  ),
                  // Botões de edição
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton.secondary(
                            text: 'Cancelar',
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _nameController.text = user?.name ?? '';
                                _phoneController.text = user?.phone ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ModernButton.primary(
                            text: 'Guardar',
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    bool enabled = false,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOpacity10,
            borderRadius: AppRadius.borderRadiusSm,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (enabled && controller != null)
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(),
                  ),
                )
              else
                Text(
                  value ?? controller?.text ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isOwner,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Ações Rápidas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        // Para proprietários
        if (isOwner) ...[
          _buildActionTile(
            icon: Icons.directions_car_rounded,
            title: 'Meus Veículos',
            subtitle: 'Gerir os meus veículos',
            color: AppColors.info,
            onTap: () => context.push('/my-vehicles'),
            isDark: isDark,
          ),
          _buildActionTile(
            icon: Icons.add_circle_outline_rounded,
            title: 'Adicionar Veículo',
            subtitle: 'Adicionar novo veículo',
            color: AppColors.success,
            onTap: () => context.push('/add-vehicle'),
            isDark: isDark,
          ),
          _buildActionTile(
            icon: Icons.bar_chart_rounded,
            title: 'Estatísticas',
            subtitle: 'Ver estatísticas detalhadas',
            color: AppColors.accent,
            onTap: () => context.push('/reports'),
            isDark: isDark,
          ),
          _buildActionTile(
            icon: Icons.dashboard_rounded,
            title: 'Meu Dashboard',
            subtitle: 'Ganhos e performance',
            color: AppColors.success,
            onTap: () => context.push('/owner-dashboard'),
            isDark: isDark,
          ),
        ],
        // Histórico (para todos)
        _buildActionTile(
          icon: Icons.history_rounded,
          title: 'Histórico',
          subtitle: 'Ver histórico de reservas',
          color: AppColors.primary,
          onTap: () => context.push('/history'),
          isDark: isDark,
        ),
        // Mensagens
        _buildActionTile(
          icon: Icons.chat_bubble_rounded,
          title: 'Mensagens',
          subtitle: 'Conversas com utilizadores',
          color: AppColors.info,
          onTap: () => context.push('/conversations'),
          isDark: isDark,
        ),
        // Favoritos (para arrendatários)
        if (!isOwner)
          _buildActionTile(
            icon: Icons.favorite_rounded,
            title: 'Favoritos',
            subtitle: 'Veículos favoritos',
            color: AppColors.error,
            onTap: () => context.push('/favorites'),
            isDark: isDark,
          ),
        // Admin Panel (apenas para admins)
        FutureBuilder<bool>(
          future: Provider.of<AdminService>(context, listen: false).isAdmin(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return _buildActionTile(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Panel',
                subtitle: 'Painel de administração',
                color: AppColors.warning,
                onTap: () => context.go('/admin'),
                isDark: isDark,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Ajuda e Suporte
        _buildActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Ajuda e Suporte',
          subtitle: 'Perguntas frequentes e contacto',
          color: AppColors.info,
          onTap: () => context.push('/help-support'),
          isDark: isDark,
        ),
        // Definições
        _buildActionTile(
          icon: Icons.settings_rounded,
          title: 'Definições',
          subtitle: 'Notificações e privacidade',
          color: AppColors.primary,
          onTap: () => context.push('/settings'),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthService authService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorOpacity10,
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Terminar Sessão'),
          ],
        ),
        content: const Text('Tem a certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

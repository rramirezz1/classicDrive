import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã do painel de administração com design moderno.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final adminService = Provider.of<AdminService>(context, listen: false);
    final stats = await adminService.getAdminStats();

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar com gradiente
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadStats,
                tooltip: 'Atualizar',
              ),
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                onPressed: () => context.go('/'),
                tooltip: 'Voltar à App',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _showLogoutDialog(authService),
                tooltip: 'Sair',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.whiteOpacity20,
                                borderRadius: AppRadius.borderRadiusMd,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bem-vindo de volta!',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    authService.userData?.name ?? 'Administrador',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.whiteOpacity20,
                            borderRadius: AppRadius.borderRadiusFull,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Administrador',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
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
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Estatísticas
                          Text(
                            'Visão Geral',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildStatsGrid(isDark),
                          const SizedBox(height: 32),

                          // Ações Rápidas
                          Text(
                            'Ações Rápidas',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(isDark),
                          const SizedBox(height: 32),

                          // Gestão
                          Text(
                            'Gestão',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildManagementCards(isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthService authService) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorOpacity10,
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Terminar Sessão'),
          ],
        ),
        content: const Text('Deseja sair do painel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await authService.signOut();
      if (mounted) context.go('/login');
    }
  }

  Widget _buildStatsGrid(bool isDark) {
    if (_stats == null) {
      return ModernCard(
        useGlass: false,
        child: const Center(
          child: Text('Erro ao carregar estatísticas'),
        ),
      );
    }

    final statsList = [
      _StatItem(
        title: 'Utilizadores',
        value: _stats!['total_users']?.toString() ?? '0',
        subtitle: '${_stats!['verified_users'] ?? 0} verificados',
        icon: Icons.people_rounded,
        color: AppColors.info,
        onTap: () => context.push('/admin/users'),
      ),
      _StatItem(
        title: 'KYC Pendentes',
        value: _stats!['pending_kyc']?.toString() ?? '0',
        subtitle: 'Requerem aprovação',
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
        onTap: () => context.push('/admin/kyc'),
      ),
      _StatItem(
        title: 'Veículos',
        value: _stats!['total_vehicles']?.toString() ?? '0',
        subtitle: '${_stats!['available_vehicles'] ?? 0} disponíveis',
        icon: Icons.directions_car_rounded,
        color: AppColors.success,
        onTap: () => context.push('/admin/vehicles'),
      ),
      _StatItem(
        title: 'Reservas',
        value: _stats!['total_bookings']?.toString() ?? '0',
        subtitle: '${_stats!['confirmed_bookings'] ?? 0} confirmadas',
        icon: Icons.calendar_today_rounded,
        color: AppColors.accent,
        onTap: () => context.push('/admin/bookings'),
      ),
      _StatItem(
        title: 'Receita Total',
        value: '€${(_stats!['total_revenue'] ?? 0).toStringAsFixed(0)}',
        subtitle: 'Reservas completadas',
        icon: Icons.euro_rounded,
        color: AppColors.primary,
        onTap: null,
      ),
      _StatItem(
        title: 'Reservas Ativas',
        value: _stats!['confirmed_bookings']?.toString() ?? '0',
        subtitle: 'Em curso',
        icon: Icons.trending_up_rounded,
        color: Colors.indigo,
        onTap: null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: statsList.length,
      itemBuilder: (context, index) {
        final stat = statsList[index];
        return _buildStatCard(stat, isDark);
      },
    );
  }

  Widget _buildStatCard(_StatItem stat, bool isDark) {
    return ModernCard(
      useGlass: false,
      onTap: stat.onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              if (stat.onTap != null)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Flexible(
            child: Text(
              stat.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Aprovar KYC',
            icon: Icons.verified_user_rounded,
            color: AppColors.success,
            onTap: () => context.push('/admin/kyc'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'Ver Logs',
            icon: Icons.history_rounded,
            color: AppColors.info,
            onTap: () => context.push('/admin/logs'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: AppRadius.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCards(bool isDark) {
    final items = [
      _ManagementItem(
        title: 'Gestão de Utilizadores',
        subtitle: 'Ver, editar e gerir utilizadores',
        icon: Icons.people_rounded,
        color: AppColors.info,
        onTap: () => context.push('/admin/users'),
      ),
      _ManagementItem(
        title: 'Gestão de Veículos',
        subtitle: 'Aprovar, remover e moderar veículos',
        icon: Icons.directions_car_rounded,
        color: AppColors.success,
        onTap: () => context.push('/admin/vehicles'),
      ),
      _ManagementItem(
        title: 'Gestão de Reservas',
        subtitle: 'Ver e gerir todas as reservas',
        icon: Icons.calendar_today_rounded,
        color: AppColors.accent,
        onTap: () => context.push('/admin/bookings'),
      ),
      _ManagementItem(
        title: 'Logs de Atividade',
        subtitle: 'Histórico de ações administrativas',
        icon: Icons.history_rounded,
        color: AppColors.warning,
        onTap: () => context.push('/admin/logs'),
      ),
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ModernCard(
            useGlass: false,
            onTap: item.onTap,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _StatItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _ManagementItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

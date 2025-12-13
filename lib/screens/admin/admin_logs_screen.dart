import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de logs do sistema com design moderno.
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final AdminService _adminService = AdminService();

  String _selectedAction = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filteredLogs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _adminService.getAdminLogs(limit: 200);
      setState(() {
        _logs = logs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showErrorSnackbar('Erro ao carregar logs: $e');
    }
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

  void _applyFilters() {
    _filteredLogs = _logs.where((log) {
      if (_selectedAction != 'all' && log['action'] != _selectedAction) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Logs do Sistema',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLogs,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: _buildFilterChips(isDark),
          ),

          // Stats
          _buildStatsRow(isDark),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                  milliseconds: 150 + (index * 30).clamp(0, 200)),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 15 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: _LogCard(log: _filteredLogs[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final actionFilters = [
      ('all', 'Todas', AppColors.info),
      ('approve_kyc', 'KYC Aprovado', AppColors.success),
      ('reject_kyc', 'KYC Rejeitado', AppColors.error),
      ('approve_vehicle', 'Veículo Aprovado', AppColors.success),
      ('cancel_booking', 'Reserva Cancelada', AppColors.warning),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actionFilters.map((filter) {
          final isSelected = _selectedAction == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAction = filter.$1;
                  _applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? filter.$3.withOpacity(0.15)
                      : (isDark
                          ? AppColors.darkCardHover
                          : AppColors.lightCardHover),
                  borderRadius: AppRadius.borderRadiusFull,
                  border: Border.all(
                    color: isSelected
                        ? filter.$3
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    color: isSelected
                        ? filter.$3
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final now = DateTime.now();
    final today = _logs.where((log) {
      final createdAt = DateTime.parse(log['created_at']);
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;

    final thisWeek = _logs.where((log) {
      final createdAt = DateTime.parse(log['created_at']);
      return createdAt.isAfter(now.subtract(const Duration(days: 7)));
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatChip('Total', _logs.length.toString(), AppColors.info, isDark),
          const SizedBox(width: 10),
          _buildStatChip('Hoje', today.toString(), AppColors.success, isDark),
          const SizedBox(width: 10),
          _buildStatChip('Semana', thisWeek.toString(), AppColors.warning, isDark),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 48, color: AppColors.info),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum log encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogCard({required this.log});

  Color _getActionColor(String action) {
    if (action.contains('approve')) return AppColors.success;
    if (action.contains('reject') ||
        action.contains('cancel') ||
        action.contains('remove')) {
      return AppColors.error;
    }
    return AppColors.info;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('approve')) return Icons.check_circle_rounded;
    if (action.contains('reject')) return Icons.cancel_rounded;
    if (action.contains('remove')) return Icons.delete_rounded;
    if (action.contains('cancel')) return Icons.block_rounded;
    return Icons.info_rounded;
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'approve_kyc':
        return 'Aprovou KYC';
      case 'reject_kyc':
        return 'Rejeitou KYC';
      case 'approve_vehicle':
        return 'Aprovou Veículo';
      case 'remove_vehicle':
        return 'Removeu Veículo';
      case 'cancel_booking':
        return 'Cancelou Reserva';
      default:
        return action;
    }
  }

  String _getTargetTypeLabel(String type) {
    switch (type) {
      case 'user':
        return 'Utilizador';
      case 'vehicle':
        return 'Veículo';
      case 'booking':
        return 'Reserva';
      default:
        return type;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'Agora';
    if (difference.inMinutes < 60) return 'Há ${difference.inMinutes}m';
    if (difference.inHours < 24) return 'Há ${difference.inHours}h';
    if (difference.inDays < 7) return 'Há ${difference.inDays}d';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = _getActionColor(log['action']);
    final createdAt = DateTime.parse(log['created_at']);
    final admin = log['admin'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModernCard(
        useGlass: false,
        onTap: () => _showLogDetails(context, isDark),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Icon(
                _getActionIcon(log['action']),
                color: actionColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getActionLabel(log['action']),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Text(
                        _formatTimeAgo(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admin: ${admin?['name'] ?? 'Desconhecido'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardHover
                              : AppColors.lightCardHover,
                          borderRadius: AppRadius.borderRadiusSm,
                        ),
                        child: Text(
                          _getTargetTypeLabel(log['target_type']),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      if (log['target_id'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${log['target_id'].toString().substring(0, 8).toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(BuildContext context, bool isDark) {
    final createdAt = DateTime.parse(log['created_at']);
    final admin = log['admin'] as Map<String, dynamic>?;
    final details = log['details'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                ),
              ),

              Text(
                'Detalhes do Log',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'ID: ${log['id'].toString().substring(0, 8).toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              _buildInfoRow(context, isDark, 'Ação', _getActionLabel(log['action'])),
              _buildInfoRow(context, isDark, 'Tipo', _getTargetTypeLabel(log['target_type'])),
              if (log['target_id'] != null)
                _buildInfoRow(context, isDark, 'ID do Alvo',
                    log['target_id'].toString().substring(0, 8).toUpperCase()),
              _buildInfoRow(context, isDark, 'Data/Hora',
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(createdAt)),
              const SizedBox(height: 20),

              Text(
                'Administrador',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (admin != null) ...[
                _buildInfoRow(context, isDark, 'Nome', admin['name']),
                _buildInfoRow(context, isDark, 'Email', admin['email']),
              ],

              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Detalhes Adicionais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardHover
                        : AppColors.lightCardHover,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: details.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../widgets/modern_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de gestão de KYC com design moderno.
class AdminKYCScreen extends StatefulWidget {
  const AdminKYCScreen({super.key});

  @override
  State<AdminKYCScreen> createState() => _AdminKYCScreenState();
}

class _AdminKYCScreenState extends State<AdminKYCScreen> {
  List<UserModel> _pendingUsers = [];
  bool _isLoading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadPendingKYC();
  }

  Future<void> _loadPendingKYC() async {
    setState(() => _isLoading = true);

    final adminService = Provider.of<AdminService>(context, listen: false);

    List<UserModel> users;
    if (_filter == 'pending') {
      users = await adminService.getPendingKYCUsers();
    } else {
      users = await adminService.getAllUsers(
          kycStatus: _filter == 'all' ? null : _filter);
    }

    if (mounted) {
      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveKYC(UserModel user) async {
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
                color: AppColors.successOpacity10,
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: const Icon(Icons.verified_user_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Aprovar KYC'),
          ],
        ),
        content: Text('Confirma a aprovação do KYC de ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final adminService = Provider.of<AdminService>(context, listen: false);
    final result = await adminService.approveKYC(user.id);

    if (mounted) {
      if (result == null) {
        _showSnackbar('KYC de ${user.name} aprovado!', AppColors.success);
        _loadPendingKYC();
      } else {
        _showSnackbar('Erro: $result', AppColors.error);
      }
    }
  }

  Future<void> _rejectKYC(UserModel user) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasonController = TextEditingController();

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
              child: const Icon(Icons.cancel_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Rejeitar KYC'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejeitar KYC de ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Motivo da rejeição',
                hintText: 'Explique o motivo...',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                _showSnackbar('Por favor, indique o motivo', AppColors.warning);
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final adminService = Provider.of<AdminService>(context, listen: false);
    final result =
        await adminService.rejectKYC(user.id, reasonController.text.trim());

    if (mounted) {
      if (result == null) {
        _showSnackbar('KYC de ${user.name} rejeitado', AppColors.warning);
        _loadPendingKYC();
      } else {
        _showSnackbar('Erro: $result', AppColors.error);
      }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Gestão de KYC',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPendingKYC,
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

          // Contador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '${_pendingUsers.length} utilizador${_pendingUsers.length != 1 ? 'es' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingUsers.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadPendingKYC,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pendingUsers.length,
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                  milliseconds: 200 + (index * 50).clamp(0, 300)),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: _buildKYCCard(_pendingUsers[index], isDark),
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
    final filters = [
      ('pending', 'Pendentes', AppColors.warning),
      ('approved', 'Aprovados', AppColors.success),
      ('rejected', 'Rejeitados', AppColors.error),
      ('all', 'Todos', AppColors.info),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _filter = filter.$1);
                _loadPendingKYC();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
              color: AppColors.successOpacity10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 48,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _filter == 'pending'
                ? 'Nenhum KYC pendente'
                : 'Nenhum utilizador encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'pending'
                ? 'Todos os KYCs foram processados!'
                : 'Tente outro filtro',
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

  Widget _buildKYCCard(UserModel user, bool isDark) {
    final kycStatus = user.kycStatus ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (kycStatus) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Aprovado';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Rejeitado';
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        statusText = 'Pendente';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        useGlass: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info
            _buildInfoRow(isDark, Icons.phone_rounded, 'Telefone', user.phone),
            const SizedBox(height: 6),
            _buildInfoRow(
              isDark,
              Icons.person_rounded,
              'Tipo',
              user.userType == 'owner' ? 'Proprietário' : 'Cliente',
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              isDark,
              Icons.calendar_today_rounded,
              'Membro desde',
              DateFormat('dd/MM/yyyy').format(user.createdAt),
            ),
            if (user.verificationSubmittedAt != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                isDark,
                Icons.upload_file_rounded,
                'KYC submetido',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(user.verificationSubmittedAt!),
              ),
            ],

            // Ações
            if (kycStatus == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectKYC(user),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadiusMd,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveKYC(user),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadiusMd,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_input.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';

/// Ecrã de gestão de utilizadores com design moderno.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _userTypeFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final adminService = Provider.of<AdminService>(context, listen: false);
    final users = await adminService.getAllUsers();

    if (mounted) {
      setState(() {
        _users = users;
        _filterUsers();
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            user.name.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.phone.contains(searchQuery);

        final matchesType =
            _userTypeFilter == 'all' || user.userType == _userTypeFilter;

        final matchesStatus = _statusFilter == 'all';

        return matchesSearch && matchesType && matchesStatus;
      }).toList();
    });
  }

  void _showUserDetails(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _buildUserDetailsSheet(user, scrollController, isDark),
        ),
      ),
    );
  }

  Widget _buildUserDetailsSheet(
      UserModel user, ScrollController controller, bool isDark) {
    return ListView(
      controller: controller,
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

        // Avatar e Nome
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              _buildUserTypeBadge(user),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Informações Pessoais
        _buildDetailCard(
          isDark,
          title: 'Informações Pessoais',
          icon: Icons.person_rounded,
          color: AppColors.info,
          children: [
            _buildDetailRow(isDark, 'Telefone', user.phone),
            _buildDetailRow(
              isDark,
              'Tipo',
              user.userType == 'owner' ? 'Proprietário' : 'Cliente',
            ),
            _buildDetailRow(
              isDark,
              'Membro desde',
              DateFormat('dd/MM/yyyy').format(user.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Verificação
        _buildDetailCard(
          isDark,
          title: 'Verificação',
          icon: Icons.verified_user_rounded,
          color: AppColors.success,
          children: [
            _buildDetailRow(
              isDark,
              'Status KYC',
              _getKYCStatusText(user.verificationStatus),
            ),
            if (user.verificationSubmittedAt != null)
              _buildDetailRow(
                isDark,
                'Submetido em',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(user.verificationSubmittedAt!),
              ),
            if (user.verifiedAt != null)
              _buildDetailRow(
                isDark,
                'Verificado em',
                DateFormat('dd/MM/yyyy HH:mm').format(user.verifiedAt!),
              ),
            _buildDetailRow(
              isDark,
              'Conta Verificada',
              user.isVerified ? 'Sim ✓' : 'Não',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Estatísticas
        _buildDetailCard(
          isDark,
          title: 'Estatísticas',
          icon: Icons.analytics_rounded,
          color: AppColors.accent,
          children: [
            _buildDetailRow(
              isDark,
              'Trust Score',
              '${user.trustScore.toStringAsFixed(1)}/10',
            ),
            _buildDetailRow(
              isDark,
              'Reservas Completadas',
              user.completedBookings.toString(),
            ),
            _buildDetailRow(
              isDark,
              'Reservas Canceladas',
              user.cancelledBookings.toString(),
            ),
            _buildDetailRow(
              isDark,
              'Avaliação Média',
              user.totalReviews > 0
                  ? '${user.averageRating.toStringAsFixed(1)} ⭐ (${user.totalReviews} reviews)'
                  : 'Sem avaliações',
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserTypeBadge(UserModel user) {
    final isOwner = user.userType == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: (isOwner ? AppColors.accent : AppColors.info).withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(
          color: isOwner ? AppColors.accent : AppColors.info,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.car_rental_rounded : Icons.person_rounded,
            size: 16,
            color: isOwner ? AppColors.accent : AppColors.info,
          ),
          const SizedBox(width: 6),
          Text(
            isOwner ? 'Proprietário' : 'Cliente',
            style: TextStyle(
              color: isOwner ? AppColors.accent : AppColors.info,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getKYCStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Aprovado ✅';
      case 'rejected':
        return 'Rejeitado ❌';
      case 'pending':
        return 'Pendente ⏳';
      default:
        return 'Não submetido';
    }
  }

  Widget _buildDetailCard(
    bool isDark, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return ModernCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Icon(icon, color: color, size: 18),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
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
          'Gestão de Utilizadores',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pesquisa e Filtros
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
            child: Column(
              children: [
                // Barra de pesquisa
                ModernSearchField(
                  controller: _searchController,
                  hintText: 'Pesquisar por nome, email ou telefone...',
                  onChanged: (_) => _filterUsers(),
                ),
                const SizedBox(height: 12),

                // Filtros
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChips(isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '${_filteredUsers.length} utilizador${_filteredUsers.length != 1 ? 'es' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                  milliseconds: 200 + (index * 50).clamp(0, 300)),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildUserCard(_filteredUsers[index], isDark),
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
      ('all', 'Todos'),
      ('owner', 'Proprietários'),
      ('renter', 'Clientes'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _userTypeFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _userTypeFilter = filter.$1);
                _filterUsers();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkCardHover
                          : AppColors.lightCardHover),
                  borderRadius: AppRadius.borderRadiusFull,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
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
              color: AppColors.infoOpacity10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum utilizador encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros de pesquisa',
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

  Widget _buildUserCard(UserModel user, bool isDark) {
    final kycStatus = user.verificationStatus ?? 'not_submitted';
    Color kycColor;
    IconData kycIcon;

    switch (kycStatus) {
      case 'approved':
        kycColor = AppColors.success;
        kycIcon = Icons.verified_rounded;
        break;
      case 'pending':
        kycColor = AppColors.warning;
        kycIcon = Icons.pending_rounded;
        break;
      case 'rejected':
        kycColor = AppColors.error;
        kycIcon = Icons.cancel_rounded;
        break;
      default:
        kycColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
        kycIcon = Icons.help_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        useGlass: false,
        onTap: () => _showUserDetails(user),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.transparent,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(kycIcon, size: 18, color: kycColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (user.userType == 'owner'
                                  ? AppColors.accent
                                  : AppColors.info)
                              .withOpacity(0.1),
                          borderRadius: AppRadius.borderRadiusFull,
                        ),
                        child: Text(
                          user.userType == 'owner' ? 'Proprietário' : 'Cliente',
                          style: TextStyle(
                            fontSize: 11,
                            color: user.userType == 'owner'
                                ? AppColors.accent
                                : AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (user.totalReviews > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.averageRating.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Seta
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

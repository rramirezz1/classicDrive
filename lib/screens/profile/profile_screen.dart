import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/animated_widgets.dart';
import '../../main.dart' show mainNavigationKey;

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

      // Atualizar o perfil no Firebase usando o formato correto
      final result = await authService.updateUserProfile(
        updates: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': DateTime.now(),
        },
      );

      if (mounted) {
        if (result == null) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final user = authService.userData;
    final isOwner = authService.isOwner;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho do perfil
              AnimatedWidgets.fadeInContent(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Botão de logout no canto superior direito
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Terminar Sessão'),
                                content: const Text(
                                    'Tem a certeza que deseja sair?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Sair'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await authService.signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                          },
                        ),
                      ),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Tipo de conta
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOwner ? 'Proprietário' : 'Arrendatário',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Estatísticas (para proprietários)
              if (isOwner) ...[
                AnimatedWidgets.fadeInContent(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder<List<VehicleModel>>(
                      stream: databaseService
                          .getVehiclesByOwner(authService.currentUser!.uid),
                      builder: (context, vehicleSnapshot) {
                        return StreamBuilder<List<BookingModel>>(
                          stream: databaseService.getUserBookings(
                            authService.currentUser!.uid,
                            asOwner: true,
                          ),
                          builder: (context, bookingSnapshot) {
                            final vehicles = vehicleSnapshot.data ?? [];
                            final bookings = bookingSnapshot.data ?? [];
                            final activeBookings = bookings
                                .where((b) =>
                                    b.status == 'confirmed' ||
                                    b.status == 'pending')
                                .length;
                            final totalRevenue = bookings
                                .where((b) => b.status == 'completed')
                                .fold(0.0, (sum, b) => sum + b.totalPrice);

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.directions_car,
                                    value: vehicles.length.toString(),
                                    label: 'Veículos',
                                    color: Colors.blue,
                                    onTap: () => context.push('/my-vehicles'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.calendar_today,
                                    value: activeBookings.toString(),
                                    label: 'Reservas\nAtivas',
                                    color: Colors.orange,
                                    onTap: () {
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                      mainNavigationKey.currentState
                                          ?.changeTab(2);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.euro,
                                    value: totalRevenue.toStringAsFixed(0),
                                    label: 'Receita\nTotal',
                                    color: Colors.green,
                                    onTap: () => context.push('/reports'),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Informações Pessoais
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
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Informações Pessoais',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_isEditing)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() => _isEditing = true);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Nome
                        _buildInfoField(
                          icon: Icons.person,
                          label: 'Nome',
                          controller: _nameController,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Email (não editável)
                        _buildInfoField(
                          icon: Icons.email,
                          label: 'Email',
                          value: user?.email ?? '',
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        // Telefone
                        _buildInfoField(
                          icon: Icons.phone,
                          label: 'Telefone',
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o telefone';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Membro desde
                        _buildInfoField(
                          icon: Icons.calendar_month,
                          label: 'Membro desde',
                          value: user?.createdAt != null
                              ? DateFormat('dd/MM/yyyy').format(user!.createdAt)
                              : '',
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        // Conta verificada
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: user?.isVerified == true
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Conta Verificada',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    user?.isVerified == true
                                        ? 'A sua identidade foi verificada'
                                        : 'Conta não verificada',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (user?.isVerified == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Verificado',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Botões de ação
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      // Resetar valores
                                      _nameController.text = user?.name ?? '';
                                      _phoneController.text = user?.phone ?? '';
                                    });
                                  },
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Guardar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Ações Rápidas
              AnimatedWidgets.fadeInContent(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ações Rápidas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Meus Veículos (apenas para proprietários)
                      if (isOwner)
                        _buildActionTile(
                          icon: Icons.directions_car,
                          title: 'Meus Veículos',
                          subtitle: 'Gerir os meus veículos',
                          onTap: () => context.push('/my-vehicles'),
                        ),
                      // Adicionar Veículo (apenas para proprietários)
                      if (isOwner)
                        _buildActionTile(
                          icon: Icons.add,
                          title: 'Adicionar Veículo',
                          subtitle: 'Adicionar novo veículo',
                          onTap: () => context.push('/add-vehicle'),
                        ),
                      // Estatísticas (apenas para proprietários)
                      if (isOwner)
                        _buildActionTile(
                          icon: Icons.bar_chart,
                          title: 'Estatísticas',
                          subtitle: 'Ver estatísticas detalhadas',
                          onTap: () => context.push('/reports'),
                        ),
                      // Histórico (para todos)
                      _buildActionTile(
                        icon: Icons.history,
                        title: 'Histórico',
                        subtitle: 'Ver histórico de reservas',
                        onTap: () => context.push('/history'),
                      ),
                      // Favoritos (para arrendatários)
                      if (!isOwner)
                        _buildActionTile(
                          icon: Icons.favorite,
                          title: 'Favoritos',
                          subtitle: 'Veículos favoritos',
                          onTap: () => context.push('/favorites'),
                        ),
                      // Ajuda e Suporte 
                      _buildActionTile(
                        icon: Icons.help,
                        title: 'Ajuda e Suporte',
                        subtitle: 'Perguntas frequentes e contacto',
                        onTap: () => context.push('/help-support'),
                      ),
                      // Definições 
                      _buildActionTile(
                        icon: Icons.settings,
                        title: 'Definições',
                        subtitle: 'Notificações e privacidade',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (enabled && controller != null)
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: UnderlineInputBorder(),
                  ),
                )
              else
                Text(
                  value ?? controller?.text ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

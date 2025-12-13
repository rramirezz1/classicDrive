import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'animated_widgets.dart';

class VerificationBadge extends StatelessWidget {
  final UserModel? user;
  final double size;
  final bool showLabel;
  final bool interactive;

  const VerificationBadge({
    super.key,
    required this.user,
    this.size = 20,
    this.showLabel = false,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final isVerified = user!.hasKYC;
    final isPending = user!.isPendingVerification;
    final verificationLevel = user!.verificationLevel;

    if (!isVerified && !isPending) {
      return interactive
          ? _buildUnverifiedBadge(context)
          : const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: interactive ? () => _showVerificationDetails(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(size * 0.1),
            decoration: BoxDecoration(
              color: _getBadgeColor(isVerified, isPending, verificationLevel),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBadgeIcon(isVerified, isPending),
              size: size,
              color: Colors.white,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _getBadgeLabel(isVerified, isPending, verificationLevel),
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.w600,
                color: _getBadgeColor(isVerified, isPending, verificationLevel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnverifiedBadge(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isCurrentUser = authService.currentUser?.id == user!.uid;

    if (!isCurrentUser || !interactive) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/kyc-verification'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 16, color: Colors.orange[700]),
            const SizedBox(width: 4),
            Text(
              'Verificar conta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(bool isVerified, bool isPending, String? level) {
    if (isPending) return Colors.orange;
    if (!isVerified) return Colors.grey;

    switch (level) {
      case 'full':
        return Colors.green;
      case 'basic':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getBadgeIcon(bool isVerified, bool isPending) {
    if (isPending) return Icons.access_time;
    if (isVerified) return Icons.verified_user;
    return Icons.shield_outlined;
  }

  String _getBadgeLabel(bool isVerified, bool isPending, String? level) {
    if (isPending) return 'Em verificação';
    if (!isVerified) return 'Não verificado';

    switch (level) {
      case 'full':
        return 'Totalmente verificado';
      case 'basic':
        return 'Verificado';
      default:
        return 'Verificado';
    }
  }

  void _showVerificationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VerificationDetailsSheet(user: user!),
    );
  }
}

class _VerificationDetailsSheet extends StatelessWidget {
  final UserModel user;

  const _VerificationDetailsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isCurrentUser = authService.currentUser?.id == user.uid;

    return AnimatedWidgets.fadeInContent(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Ícone e título
              Icon(
                user.hasKYC ? Icons.verified_user : Icons.shield_outlined,
                size: 64,
                color: user.hasKYC ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 16),

              Text(
                user.hasKYC
                    ? 'Conta Verificada'
                    : user.isPendingVerification
                        ? 'Verificação em Análise'
                        : 'Conta Não Verificada',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                user.hasKYC
                    ? 'Este utilizador passou pelo processo de verificação de identidade'
                    : user.isPendingVerification
                        ? 'Os documentos estão em análise'
                        : 'Este utilizador ainda não verificou a sua identidade',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Detalhes da verificação
              if (user.hasKYC) ...[
                _buildVerificationItem(
                  icon: Icons.badge,
                  title: 'Identidade verificada',
                  subtitle: 'Documento de identificação validado',
                  verified: true,
                ),
                _buildVerificationItem(
                  icon: Icons.drive_eta,
                  title: 'Carta de condução',
                  subtitle: 'Habilitação para conduzir confirmada',
                  verified: true,
                ),
                if (user.verificationLevel == 'full')
                  _buildVerificationItem(
                    icon: Icons.home,
                    title: 'Morada confirmada',
                    subtitle: 'Comprovativo de residência validado',
                    verified: true,
                  ),
                if (user.verifiedAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Verificado em ${_formatDate(user.verifiedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],

              // Score de confiança
              const SizedBox(height: 24),
              _buildTrustScore(context),

              // Botão de ação
              if (isCurrentUser &&
                  !user.hasKYC &&
                  !user.isPendingVerification) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/kyc-verification');
                    },
                    child: const Text('Verificar Minha Conta'),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool verified,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: verified ? Colors.green[50] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: verified ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (verified) Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildTrustScore(BuildContext context) {
    final score = user.reliabilityScore;
    final level = user.trustLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score de Confiança',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTrustColor(score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: _getTrustColor(score),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getTrustColor(score)),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreStat(
                label: 'Reservas',
                value: user.completedBookings.toString(),
              ),
              _buildScoreStat(
                label: 'Avaliação',
                value: user.averageRating > 0
                    ? user.averageRating.toStringAsFixed(1)
                    : 'N/A',
              ),
              _buildScoreStat(
                label: 'Taxa Conclusão',
                value: user.completedBookings > 0
                    ? '${((user.completedBookings / (user.completedBookings + user.cancelledBookings)) * 100).toStringAsFixed(0)}%'
                    : 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getTrustColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Widget simplificado para mostrar apenas o ícone
class SimpleVerificationIcon extends StatelessWidget {
  final bool isVerified;
  final double size;
  final Color? color;

  const SimpleVerificationIcon({
    super.key,
    required this.isVerified,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Icon(
      Icons.verified,
      size: size,
      color: color ?? Colors.blue,
    );
  }
}

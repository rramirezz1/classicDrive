import 'package:flutter/material.dart';
import '../models/user_verification_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Badge de verificação do utilizador.
class UserVerificationBadge extends StatelessWidget {
  final UserVerification verification;
  final bool showLabel;
  final double size;

  const UserVerificationBadge({
    super.key,
    required this.verification,
    this.showLabel = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (verification.verificationLevel == 0) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: verification.verificationStatus,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(size * 0.2),
            decoration: BoxDecoration(
              color: _getColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              color: _getColor(),
              size: size,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              verification.verificationStatus,
              style: TextStyle(
                fontSize: 11,
                color: _getColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor() {
    switch (verification.verificationLevel) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (verification.verificationLevel) {
      case 1:
        return Icons.verified_outlined;
      case 2:
        return Icons.verified_rounded;
      case 3:
        return Icons.verified_rounded;
      case 4:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

/// Card detalhado de verificação para o perfil.
class VerificationCard extends StatelessWidget {
  final UserVerification verification;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyPhone;
  final VoidCallback? onVerifyDocument;
  final VoidCallback? onVerifyAddress;

  const VerificationCard({
    super.key,
    required this.verification,
    this.onVerifyEmail,
    this.onVerifyPhone,
    this.onVerifyDocument,
    this.onVerifyAddress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              UserVerificationBadge(
                verification: verification,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status de Verificação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      verification.verificationStatus,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildLevelBadge(isDark),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: AppRadius.borderRadiusFull,
            child: LinearProgressIndicator(
              value: verification.verificationPercentage,
              backgroundColor: isDark
                  ? AppColors.darkCardHover
                  : Colors.grey[200],
              color: _getLevelColor(),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 20),

          // Verification items
          _buildVerificationItem(
            context,
            icon: Icons.email_rounded,
            title: 'Email',
            isVerified: verification.emailVerified,
            onVerify: onVerifyEmail,
            isDark: isDark,
          ),
          _buildVerificationItem(
            context,
            icon: Icons.phone_rounded,
            title: 'Telefone',
            isVerified: verification.phoneVerified,
            onVerify: onVerifyPhone,
            isDark: isDark,
          ),
          _buildVerificationItem(
            context,
            icon: Icons.badge_rounded,
            title: 'Documento de Identidade',
            isVerified: verification.documentVerified,
            onVerify: onVerifyDocument,
            isDark: isDark,
          ),
          _buildVerificationItem(
            context,
            icon: Icons.home_rounded,
            title: 'Morada',
            isVerified: verification.addressVerified,
            onVerify: onVerifyAddress,
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor().withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusFull,
      ),
      child: Text(
        '${verification.verificationLevel}/4',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _getLevelColor(),
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getLevelColor() {
    switch (verification.verificationLevel) {
      case 0:
        return Colors.grey;
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildVerificationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isVerified,
    VoidCallback? onVerify,
    required bool isDark,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
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
              color: (isVerified ? AppColors.success : Colors.grey)
                  .withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(
              icon,
              color: isVerified ? AppColors.success : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (isVerified)
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            )
          else if (onVerify != null)
            TextButton(
              onPressed: onVerify,
              child: const Text('Verificar'),
            ),
        ],
      ),
    );
  }
}

/// Badge inline para mostrar verificação junto ao nome.
class VerifiedBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerifiedBadge({
    super.key,
    required this.isVerified,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Tooltip(
      message: 'Utilizador verificado',
      child: Icon(
        Icons.verified_rounded,
        color: AppColors.info,
        size: size,
      ),
    );
  }
}

/// Indicador de nível de confiança.
class TrustLevelIndicator extends StatelessWidget {
  final UserVerification verification;

  const TrustLevelIndicator({
    super.key,
    required this.verification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = verification.verificationLevel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < level;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isActive
                ? _getLevelColor(level)
                : (isDark ? AppColors.darkCardHover : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }
}

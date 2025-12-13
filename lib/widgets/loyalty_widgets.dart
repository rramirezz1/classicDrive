import 'package:flutter/material.dart';
import '../models/loyalty_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Card de resumo de fidelidade para o perfil.
class LoyaltyCard extends StatelessWidget {
  final LoyaltyModel loyalty;
  final VoidCallback? onTap;

  const LoyaltyCard({
    super.key,
    required this.loyalty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _getTierGradient(),
          borderRadius: AppRadius.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: _getTierColor().withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTierIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membro ${loyalty.tierName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${loyalty.discountPercentage.toInt()}% desconto',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                  child: Text(
                    '${loyalty.totalPoints} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress bar
            if (loyalty.tier != LoyaltyTier.gold) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Próximo nível',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${loyalty.pointsToNextTier} pts restantes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: loyalty.progressToNextTier.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.borderRadiusFull,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nível máximo atingido!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Quick stats
            Row(
              children: [
                _buildStat('Referências', loyalty.referralCount.toString()),
                const SizedBox(width: 24),
                _buildStat('Total ganho', '${loyalty.lifetimePoints}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getTierColor() {
    switch (loyalty.tier) {
      case LoyaltyTier.bronze:
        return const Color(0xFFCD7F32);
      case LoyaltyTier.silver:
        return const Color(0xFFC0C0C0);
      case LoyaltyTier.gold:
        return AppColors.accent;
    }
  }

  LinearGradient _getTierGradient() {
    switch (loyalty.tier) {
      case LoyaltyTier.bronze:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LoyaltyTier.silver:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LoyaltyTier.gold:
        return LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withRed(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getTierIcon() {
    switch (loyalty.tier) {
      case LoyaltyTier.bronze:
        return Icons.shield_outlined;
      case LoyaltyTier.silver:
        return Icons.shield_rounded;
      case LoyaltyTier.gold:
        return Icons.workspace_premium_rounded;
    }
  }
}

/// Badge pequeno para mostrar tier.
class LoyaltyBadge extends StatelessWidget {
  final LoyaltyTier tier;
  final bool showLabel;

  const LoyaltyBadge({
    super.key,
    required this.tier,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(color: _getColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: _getColor()),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _getName(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor() {
    switch (tier) {
      case LoyaltyTier.bronze:
        return const Color(0xFFCD7F32);
      case LoyaltyTier.silver:
        return const Color(0xFF808080);
      case LoyaltyTier.gold:
        return AppColors.accent;
    }
  }

  IconData _getIcon() {
    switch (tier) {
      case LoyaltyTier.bronze:
        return Icons.shield_outlined;
      case LoyaltyTier.silver:
        return Icons.shield_rounded;
      case LoyaltyTier.gold:
        return Icons.workspace_premium_rounded;
    }
  }

  String _getName() {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Prata';
      case LoyaltyTier.gold:
        return 'Ouro';
    }
  }
}

/// Lista de transações de pontos.
class LoyaltyTransactionsList extends StatelessWidget {
  final List<LoyaltyTransaction> transactions;

  const LoyaltyTransactionsList({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Sem transações ainda',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isPositive = tx.points > 0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: index < transactions.length - 1
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: Icon(
                  _getTypeIcon(tx.type),
                  size: 20,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatDate(tx.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${tx.points}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'referral':
        return Icons.people_rounded;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'redemption':
        return Icons.redeem_rounded;
      default:
        return Icons.monetization_on_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

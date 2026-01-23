import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Widget de calculadora de preço para reservas.
class PriceCalculatorWidget extends StatelessWidget {
  final double pricePerDay;
  final int numberOfDays;
  final double? insurancePrice;
  final double? depositAmount;
  final double? discountPercent;

  const PriceCalculatorWidget({
    super.key,
    required this.pricePerDay,
    required this.numberOfDays,
    this.insurancePrice,
    this.depositAmount,
    this.discountPercent,
  });

  double get subtotal => pricePerDay * numberOfDays;
  double get discount => discountPercent != null ? subtotal * (discountPercent! / 100) : 0;
  double get insuranceTotal => insurancePrice ?? 0;
  double get total => subtotal - discount + insuranceTotal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOpacity10,
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: Icon(
                  Icons.calculate_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Resumo do Preço',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Preço por dia
          _buildPriceRow(
            context,
            isDark,
            '€${pricePerDay.toStringAsFixed(0)}/dia × $numberOfDays dias',
            subtotal,
          ),

          // Desconto (se aplicável)
          if (discountPercent != null && discountPercent! > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              isDark,
              'Desconto (${discountPercent!.toStringAsFixed(0)}%)',
              -discount,
              isDiscount: true,
            ),
          ],

          // Seguro (se aplicável)
          if (insurancePrice != null && insurancePrice! > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              isDark,
              'Seguro',
              insuranceTotal,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '€${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),

          // Depósito (info)
          if (depositAmount != null && depositAmount! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoOpacity10,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caução de €${depositAmount!.toStringAsFixed(0)} devolvida após entrega',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    bool isDark,
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}€${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.success : null,
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar economia com descontos.
class SavingsBadge extends StatelessWidget {
  final double savingsAmount;
  final double percentOff;

  const SavingsBadge({
    super.key,
    required this.savingsAmount,
    required this.percentOff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.successOpacity80],
        ),
        borderRadius: AppRadius.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.savings_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Poupa €${savingsAmount.toStringAsFixed(0)} (${percentOff.toStringAsFixed(0)}%)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

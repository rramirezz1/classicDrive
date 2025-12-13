import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Widget de resumo de reserva compacto.
class BookingSummaryCard extends StatelessWidget {
  final String vehicleName;
  final String? vehicleImage;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final VoidCallback? onTap;

  const BookingSummaryCard({
    super.key,
    required this.vehicleName,
    this.vehicleImage,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.onTap,
  });

  int get numberOfDays => endDate.difference(startDate).inDays + 1;

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendente';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM', 'pt');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Imagem do veículo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardHover : Colors.grey[200],
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: vehicleImage != null
                      ? ClipRRect(
                          borderRadius: AppRadius.borderRadiusMd,
                          child: Image.network(
                            vehicleImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.directions_car_rounded,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : Colors.grey,
                        ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardHover : Colors.grey[50],
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$numberOfDays dias',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '€${totalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de timeline para estado de reserva.
class BookingTimeline extends StatelessWidget {
  final int currentStep;
  final List<TimelineStep> steps;

  const BookingTimeline({
    super.key,
    required this.currentStep,
    this.steps = const [
      TimelineStep(icon: Icons.pending_actions_rounded, label: 'Pendente'),
      TimelineStep(icon: Icons.check_circle_rounded, label: 'Confirmada'),
      TimelineStep(icon: Icons.drive_eta_rounded, label: 'Em curso'),
      TimelineStep(icon: Icons.done_all_rounded, label: 'Concluída'),
    ],
  });

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
          Text(
            'Estado da Reserva',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Linha de ligação
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : (isDark
                              ? AppColors.darkCardHover
                              : Colors.grey[200]),
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                  ),
                );
              } else {
                // Step
                final stepIndex = index ~/ 2;
                final step = steps[stepIndex];
                final isCompleted = stepIndex < currentStep;
                final isCurrent = stepIndex == currentStep;

                return _buildStep(
                  context,
                  step,
                  isCompleted,
                  isCurrent,
                  isDark,
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    TimelineStep step,
    bool isCompleted,
    bool isCurrent,
    bool isDark,
  ) {
    Color color;
    if (isCompleted) {
      color = AppColors.success;
    } else if (isCurrent) {
      color = AppColors.primary;
    } else {
      color = isDark ? AppColors.darkTextTertiary : Colors.grey[400]!;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isCompleted || isCurrent)
                ? color.withOpacity(0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : step.icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: (isCompleted || isCurrent)
                ? FontWeight.bold
                : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class TimelineStep {
  final IconData icon;
  final String label;

  const TimelineStep({
    required this.icon,
    required this.label,
  });
}

/// Widget de seleção de período de datas.
class DateRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTap;
  final String? errorText;

  const DateRangeSelector({
    super.key,
    this.startDate,
    this.endDate,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: errorText != null
                    ? AppColors.error
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                // Data início
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Início',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            startDate != null
                                ? dateFormat.format(startDate!)
                                : 'Selecionar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: startDate != null
                                  ? null
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Seta
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),

                // Data fim
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Fim',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            endDate != null
                                ? dateFormat.format(endDate!)
                                : 'Selecionar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: endDate != null
                                  ? null
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
        if (startDate != null && endDate != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: AppColors.info),
                const SizedBox(width: 6),
                Text(
                  '${endDate!.difference(startDate!).inDays + 1} dias',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

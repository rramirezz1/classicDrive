import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Gráfico de barras simples.
class SimpleBarChart extends StatelessWidget {
  final List<BarChartData> data;
  final double height;
  final bool showLabels;
  final bool showValues;
  final bool animated;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.showLabels = true,
    this.showValues = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = data.map((d) => d.value).reduce(math.max);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final item = data[index];
          final percentage = maxValue > 0 ? item.value / maxValue : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showValues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item.value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.color ?? AppColors.primary,
                        ),
                      ),
                    ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percentage),
                    duration: animated
                        ? Duration(milliseconds: 600 + (index * 100))
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Container(
                        height: (height - 50) * value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              item.color ?? AppColors.primary,
                              (item.color ?? AppColors.primary).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      );
                    },
                  ),
                  if (showLabels) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BarChartData {
  final String label;
  final double value;
  final Color? color;

  const BarChartData({
    required this.label,
    required this.value,
    this.color,
  });
}

/// Gráfico de progresso em anel.
class DonutChart extends StatelessWidget {
  final List<DonutChartData> data;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final bool animated;

  const DonutChart({
    super.key,
    required this.data,
    this.size = 150,
    this.strokeWidth = 20,
    this.center,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              data: data,
              total: total,
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) Center(child: center),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutChartData> data;
  final double total;
  final double strokeWidth;

  _DonutChartPainter({
    required this.data,
    required this.total,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    var startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = total > 0 ? (item.value / total) * 2 * math.pi : 0.0;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) => true;
}

class DonutChartData {
  final String label;
  final double value;
  final Color color;

  const DonutChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Sparkline mini chart.
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color? color;
  final double height;
  final double strokeWidth;
  final bool showDots;
  final bool filled;

  const SparklineChart({
    super.key,
    required this.data,
    this.color,
    this.height = 50,
    this.strokeWidth = 2,
    this.showDots = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(
          data: data,
          color: color ?? AppColors.primary,
          strokeWidth: strokeWidth,
          showDots: showDots,
          filled: filled,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool showDots;
  final bool filled;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.strokeWidth,
    required this.showDots,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Fill
    if (filled) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      );

      canvas.drawPath(
        fillPath,
        Paint()..shader = gradient.createShader(Offset.zero & size),
      );
    }

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    if (showDots) {
      for (final point in points) {
        canvas.drawCircle(
          point,
          strokeWidth * 1.5,
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) => true;
}

/// Lista de dados com ranking.
class RankingList extends StatelessWidget {
  final List<RankingItem> items;
  final int maxItems;
  final bool showRankNumbers;
  final bool animated;

  const RankingList({
    super.key,
    required this.items,
    this.maxItems = 5,
    this.showRankNumbers = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayItems = items.take(maxItems).toList();
    final maxValue = displayItems.isNotEmpty
        ? displayItems.map((i) => i.value).reduce(math.max)
        : 0.0;

    return Column(
      children: List.generate(displayItems.length, (index) {
        final item = displayItems[index];
        final percentage = maxValue > 0 ? item.value / maxValue : 0.0;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1.0),
          duration: animated
              ? Duration(milliseconds: 300 + (index * 100))
              : Duration.zero,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (showRankNumbers)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _getRankColor(index).withOpacity(0.1),
                      borderRadius: AppRadius.borderRadiusSm,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRankColor(index),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.valueLabel ?? item.value.toStringAsFixed(0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.color ?? AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percentage),
                        duration: animated
                            ? const Duration(milliseconds: 800)
                            : Duration.zero,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardHover
                                  : Colors.grey[200],
                              borderRadius: AppRadius.borderRadiusFull,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: item.color ?? AppColors.primary,
                                  borderRadius: AppRadius.borderRadiusFull,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppColors.accent;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }
}

class RankingItem {
  final String label;
  final double value;
  final String? valueLabel;
  final Color? color;

  const RankingItem({
    required this.label,
    required this.value,
    this.valueLabel,
    this.color,
  });
}

/// Stat card com mini gráfico.
class StatCardWithChart extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final List<double> chartData;
  final Color? color;
  final IconData? icon;
  final bool isPositive;

  const StatCardWithChart({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.chartData,
    this.color,
    this.icon,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartColor = color ?? (isPositive ? AppColors.success : AppColors.error);

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
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: chartColor.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Icon(icon, color: chartColor, size: 18),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (subtitle != null)
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: chartColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: chartColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: SparklineChart(
                    data: chartData,
                    color: chartColor,
                    filled: true,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

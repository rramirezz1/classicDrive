import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Progress bar linear animado.
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final String? label;
  final bool showPercentage;
  final Duration animationDuration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.label,
    this.showPercentage = false,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkCardHover : Colors.grey[200]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              if (showPercentage)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Progress circular arc.
class ArcProgressWidget extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? center;
  final bool animated;

  const ArcProgressWidget({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.color,
    this.center,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? AppColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: animated ? const Duration(milliseconds: 800) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _ArcProgressPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  color: progressColor,
                  backgroundColor: isDark
                      ? AppColors.darkCardHover
                      : Colors.grey[200]!,
                ),
              );
            },
          ),
          if (center != null)
            Center(child: center),
        ],
      ),
    );
  }
}

class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _ArcProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcProgressPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Timer countdown visual.
class VisualTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;
  final bool autoStart;
  final Color? color;
  final double size;

  const VisualTimer({
    super.key,
    required this.duration,
    this.onComplete,
    this.autoStart = true,
    this.color,
    this.size = 80,
  });

  @override
  State<VisualTimer> createState() => _VisualTimerState();
}

class _VisualTimerState extends State<VisualTimer> {
  late Timer _timer;
  late Duration _remaining;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    if (widget.autoStart) {
      _start();
    }
  }

  void _start() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          timer.cancel();
          _isRunning = false;
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    if (_isRunning) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remaining.inSeconds / widget.duration.inSeconds);
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return ArcProgressWidget(
      progress: progress,
      size: widget.size,
      color: widget.color ?? AppColors.primary,
      center: Text(
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: widget.size * 0.2,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Step progress indicator horizontal.
class HorizontalStepProgress extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;
  final List<String>? labels;

  const HorizontalStepProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ??
        (isDark ? AppColors.darkCardHover : Colors.grey[300]!);

    return Column(
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // Line
              final stepIndex = index ~/ 2;
              return Expanded(
                child: Container(
                  height: 3,
                  color: stepIndex < currentStep ? active : inactive,
                ),
              );
            }

            // Circle
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;

            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? active
                    : (isCurrent
                        ? active.withOpacity(0.2)
                        : inactive),
                border: isCurrent
                    ? Border.all(color: active, width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isCurrent
                              ? active
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
              ),
            );
          }),
        ),
        if (labels != null && labels!.length == totalSteps) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Text(
                  labels![index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: index == currentStep
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: index <= currentStep
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Upload progress with file info.
class UploadProgress extends StatelessWidget {
  final String fileName;
  final double progress;
  final int? fileSize;
  final VoidCallback? onCancel;
  final bool isComplete;
  final bool hasError;

  const UploadProgress({
    super.key,
    required this.fileName,
    required this.progress,
    this.fileSize,
    this.onCancel,
    this.isComplete = false,
    this.hasError = false,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;
    if (hasError) {
      statusColor = AppColors.error;
      statusIcon = Icons.error_outline_rounded;
    } else if (isComplete) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else {
      statusColor = AppColors.primary;
      statusIcon = Icons.upload_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (!isComplete && !hasError)
                  AnimatedProgressBar(
                    progress: progress,
                    height: 4,
                    color: statusColor,
                  )
                else
                  Text(
                    hasError
                        ? 'Erro no upload'
                        : 'Upload completo${fileSize != null ? ' • ${_formatSize(fileSize!)}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
          ),
          if (!isComplete && !hasError && onCancel != null)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                size: 20,
              ),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

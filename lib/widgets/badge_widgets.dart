import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Banner de notificação in-app.
class NotificationBanner extends StatefulWidget {
  final String message;
  final NotificationBannerType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;
  final Duration duration;

  const NotificationBanner({
    super.key,
    required this.message,
    this.type = NotificationBannerType.info,
    this.onDismiss,
    this.onAction,
    this.actionText,
    this.duration = const Duration(seconds: 4),
  });

  static OverlayEntry? _currentBanner;

  static void show(
    BuildContext context, {
    required String message,
    NotificationBannerType type = NotificationBannerType.info,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionText,
    Duration duration = const Duration(seconds: 4),
  }) {
    _currentBanner?.remove();

    final overlay = Overlay.of(context);

    _currentBanner = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: NotificationBanner(
          message: message,
          type: type,
          onDismiss: () {
            _currentBanner?.remove();
            _currentBanner = null;
            onDismiss?.call();
          },
          onAction: onAction,
          actionText: actionText,
          duration: duration,
        ),
      ),
    );

    overlay.insert(_currentBanner!);

    Future.delayed(duration, () {
      _currentBanner?.remove();
      _currentBanner = null;
    });
  }

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case NotificationBannerType.success:
        return AppColors.success;
      case NotificationBannerType.error:
        return AppColors.error;
      case NotificationBannerType.warning:
        return AppColors.warning;
      case NotificationBannerType.info:
      default:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotificationBannerType.success:
        return Icons.check_circle_rounded;
      case NotificationBannerType.error:
        return Icons.error_rounded;
      case NotificationBannerType.warning:
        return Icons.warning_rounded;
      case NotificationBannerType.info:
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: AppRadius.borderRadiusMd,
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.actionText != null && widget.onAction != null) ...[
                  TextButton(
                    onPressed: widget.onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      widget.actionText!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum NotificationBannerType { success, error, warning, info }

/// Badge de status.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool pulsing;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
    this.pulsing = false,
  });

  Color get _color {
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.success;
      case StatusBadgeType.error:
        return AppColors.error;
      case StatusBadgeType.warning:
        return AppColors.warning;
      case StatusBadgeType.info:
        return AppColors.info;
      case StatusBadgeType.primary:
        return AppColors.primary;
      case StatusBadgeType.neutral:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _color),
            const SizedBox(width: 4),
          ],
          if (pulsing)
            _PulsingDot(color: _color),
          if (pulsing)
            const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );

    return badge;
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.5 + _controller.value * 0.5),
          ),
        );
      },
    );
  }
}

enum StatusBadgeType { success, error, warning, info, primary, neutral }

/// Alert card com ação.
class AlertCard extends StatelessWidget {
  final String title;
  final String message;
  final AlertCardType type;
  final VoidCallback? onAction;
  final String? actionText;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    this.type = AlertCardType.info,
    this.onAction,
    this.actionText,
    this.onDismiss,
  });

  Color get _color {
    switch (type) {
      case AlertCardType.success:
        return AppColors.success;
      case AlertCardType.error:
        return AppColors.error;
      case AlertCardType.warning:
        return AppColors.warning;
      case AlertCardType.info:
      default:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertCardType.success:
        return Icons.check_circle_outline_rounded;
      case AlertCardType.error:
        return Icons.error_outline_rounded;
      case AlertCardType.warning:
        return Icons.warning_amber_rounded;
      case AlertCardType.info:
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (onAction != null && actionText != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionText!,
                      style: TextStyle(
                        color: _color,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

enum AlertCardType { success, error, warning, info }

/// Contador com badge.
class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final double size;
  final bool showZero;

  const CountBadge({
    super.key,
    required this.count,
    this.color,
    this.size = 18,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return const SizedBox.shrink();
    }

    final displayText = count > 99 ? '99+' : count.toString();
    final badgeColor = color ?? AppColors.error;

    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? 6 : 0,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Widget com badge no canto.
class BadgeWrapper extends StatelessWidget {
  final Widget child;
  final Widget badge;
  final AlignmentGeometry alignment;

  const BadgeWrapper({
    super.key,
    required this.child,
    required this.badge,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft ? -6 : null,
          bottom: alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft ? -6 : null,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? -6 : null,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? -6 : null,
          child: badge,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Tooltip personalizado.
class CustomTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final TooltipPosition position;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomTooltip({
    super.key,
    required this.child,
    required this.message,
    this.position = TooltipPosition.top,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? Colors.white : Colors.grey[800]);
    final txtColor = textColor ?? (isDark ? Colors.black : Colors.white);

    return Tooltip(
      message: message,
      preferBelow: position == TooltipPosition.bottom,
      verticalOffset: 20,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusSm,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: txtColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}

enum TooltipPosition { top, bottom }

/// Info icon com tooltip.
class InfoTooltip extends StatelessWidget {
  final String message;
  final double size;
  final Color? iconColor;

  const InfoTooltip({
    super.key,
    required this.message,
    this.size = 18,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomTooltip(
      message: message,
      child: Icon(
        Icons.info_outline_rounded,
        size: size,
        color: iconColor ??
            (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
      ),
    );
  }
}

/// Popover menu.
class PopoverMenu extends StatefulWidget {
  final Widget trigger;
  final List<PopoverMenuItem> items;
  final PopoverPosition position;

  const PopoverMenu({
    super.key,
    required this.trigger,
    required this.items,
    this.position = PopoverPosition.bottomRight,
  });

  @override
  State<PopoverMenu> createState() => _PopoverMenuState();
}

class _PopoverMenuState extends State<PopoverMenu> {
  final _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _PopoverOverlay(
        position: position,
        triggerSize: size,
        popoverPosition: widget.position,
        items: widget.items,
        onClose: _close,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _toggle,
      child: widget.trigger,
    );
  }
}

class _PopoverOverlay extends StatelessWidget {
  final Offset position;
  final Size triggerSize;
  final PopoverPosition popoverPosition;
  final List<PopoverMenuItem> items;
  final VoidCallback onClose;

  const _PopoverOverlay({
    required this.position,
    required this.triggerSize,
    required this.popoverPosition,
    required this.items,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double left = position.dx;
    double top = position.dy + triggerSize.height + 8;

    if (popoverPosition == PopoverPosition.bottomRight) {
      left = position.dx + triggerSize.width - 180;
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          left: left.clamp(16, MediaQuery.of(context).size.width - 196),
          top: top,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 150),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.95 + 0.05 * value,
                  alignment: Alignment.topRight,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: AppRadius.borderRadiusMd,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((item) {
                    return InkWell(
                      onTap: () {
                        onClose();
                        item.onTap?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            if (item.icon != null) ...[
                              Icon(
                                item.icon,
                                size: 18,
                                color: item.isDestructive
                                    ? AppColors.error
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: item.isDestructive
                                      ? AppColors.error
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PopoverMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const PopoverMenuItem({
    required this.label,
    this.icon,
    this.onTap,
    this.isDestructive = false,
  });
}

enum PopoverPosition { bottomLeft, bottomRight }

/// Help bubble com seta.
class HelpBubble extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final ArrowPosition arrowPosition;

  const HelpBubble({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
    this.arrowPosition = ArrowPosition.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrowPosition == ArrowPosition.topCenter ||
            arrowPosition == ArrowPosition.topLeft ||
            arrowPosition == ArrowPosition.topRight)
          _buildArrow(context, true),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.borderRadiusMd,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    GestureDetector(
                      onTap: onDismiss,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (arrowPosition == ArrowPosition.bottomCenter)
          _buildArrow(context, false),
      ],
    );
  }

  Widget _buildArrow(BuildContext context, bool pointUp) {
    return Align(
      alignment: _getArrowAlignment(),
      child: CustomPaint(
        size: const Size(16, 8),
        painter: _ArrowPainter(
          color: AppColors.primary,
          pointUp: pointUp,
        ),
      ),
    );
  }

  Alignment _getArrowAlignment() {
    switch (arrowPosition) {
      case ArrowPosition.topLeft:
      case ArrowPosition.bottomLeft:
        return Alignment.centerLeft;
      case ArrowPosition.topRight:
      case ArrowPosition.bottomRight:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointUp;

  _ArrowPainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => false;
}

enum ArrowPosition { topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight }

/// Expandable info panel.
class ExpandableInfo extends StatefulWidget {
  final String title;
  final String content;
  final IconData? icon;

  const ExpandableInfo({
    super.key,
    required this.title,
    required this.content,
    this.icon,
  });

  @override
  State<ExpandableInfo> createState() => _ExpandableInfoState();
}

class _ExpandableInfoState extends State<ExpandableInfo> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: AppRadius.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.content,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

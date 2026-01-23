import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Bottom Navigation Bar moderna com efeito glass e animações.
class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernNavItem> items;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkGlass
                  : AppColors.lightGlass,
              borderRadius: AppRadius.borderRadiusXl,
              border: Border.all(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightGlassBorder,
              ),
              boxShadow: isDark
                  ? AppShadows.softShadowDark
                  : AppShadows.mediumShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == currentIndex;

                return _NavItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item de navegação.
class ModernNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const ModernNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

class _NavItemWidget extends StatefulWidget {
  final ModernNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_NavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(widget.isSelected ? 10 : 8),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? AppColors.primaryOpacity15
                        : Colors.transparent,
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      widget.isSelected
                          ? (widget.item.selectedIcon ?? widget.item.icon)
                          : widget.item.icon,
                      color: widget.isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// App Bar moderna com efeito glass opcional.
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool useGlass;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const ModernAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.useGlass = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget appBar = AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: useGlass
          ? Colors.transparent
          : (backgroundColor ??
              (isDark ? AppColors.darkBackground : AppColors.lightBackground)),
      bottom: bottom,
    );

    if (useGlass) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkGlass : AppColors.lightGlass,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.darkGlassBorder
                      : AppColors.lightGlassBorder,
                ),
              ),
            ),
            child: appBar,
          ),
        ),
      );
    }

    return appBar;
  }
}

/// Sliver App Bar moderna com gradiente.
class ModernSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final double expandedHeight;
  final Widget? background;
  final bool pinned;
  final bool floating;

  const ModernSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.expandedHeight = 200,
    this.background,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: background ??
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Stack(
                children: [
                  // Círculos decorativos
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.whiteOpacity10,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.whiteOpacity05,
                      ),
                    ),
                  ),
                  // Conteúdo
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

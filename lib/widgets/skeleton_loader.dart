import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Widget de skeleton para loading states.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? [
                      AppColors.darkCardHover,
                      AppColors.darkCard,
                      AppColors.darkCardHover,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card para listas.
class SkeletonCard extends StatelessWidget {
  final bool showImage;
  final int textLines;

  const SkeletonCard({
    super.key,
    this.showImage = true,
    this.textLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          if (showImage) ...[
            const SkeletonLoader(
              width: 80,
              height: 80,
              borderRadius: 12,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(textLines, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index < textLines - 1 ? 8 : 0),
                  child: SkeletonLoader(
                    height: index == 0 ? 18 : 14,
                    width: index == textLines - 1 ? 100 : double.infinity,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para lista de veículos.
class VehicleListSkeleton extends StatelessWidget {
  final int itemCount;

  const VehicleListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => const SkeletonCard(showImage: true, textLines: 3),
        ),
      ),
    );
  }
}

/// Skeleton para grid de veículos.
class VehicleGridSkeleton extends StatelessWidget {
  final int itemCount;

  const VehicleGridSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 16,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLoader(height: 16),
                      SizedBox(height: 8),
                      SkeletonLoader(height: 14, width: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton para perfil.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SkeletonLoader(height: 100, isCircle: true),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 24, width: 150),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 14, width: 200),
          const SizedBox(height: 32),
          ...List.generate(
            4,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonCard(showImage: false, textLines: 2),
            ),
          ),
        ],
      ),
    );
  }
}

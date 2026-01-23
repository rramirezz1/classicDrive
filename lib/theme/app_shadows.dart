import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sistema de sombras e elevações para ClassicDrive.
class AppShadows {
  AppShadows._();

  // ══════════════════════════════════════════════════════════════════════════
  // SOMBRAS SUAVES (Cards, Containers)
  // ══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.blackOpacity05,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.blackOpacity05,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get softShadowDark => [
    BoxShadow(
      color: AppColors.blackOpacity30,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.blackOpacity20,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SOMBRAS MÉDIAS (Cards elevados, Modais)
  // ══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: AppColors.blackOpacity08,
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.blackOpacity05,
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get mediumShadowDark => [
    BoxShadow(
      color: AppColors.blackOpacity40,
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.blackOpacity30,
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SOMBRAS FORTES (FAB, Elementos flutuantes)
  // ══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: AppColors.blackOpacity12,
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.blackOpacity08,
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // GLOW EFFECTS (Botões, Elementos interativos)
  // ══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: AppColors.primaryOpacity40,
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: AppColors.accentOpacity40,
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get successGlow => [
    BoxShadow(
      color: AppColors.successOpacity40,
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get errorGlow => [
    BoxShadow(
      color: AppColors.errorOpacity40,
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // INNER SHADOWS (Para inputs, elementos "inset")
  // ══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get innerShadow => [
    BoxShadow(
      color: AppColors.blackOpacity08,
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SOMBRAS COLORIDAS (Para cards de categoria)
  // ══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> coloredShadow(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Tokens de espaçamento consistentes.
class AppSpacing {
  AppSpacing._();

  // Espaçamentos base
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Padding padrão para screens
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  
  // Padding para cards
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(lg);

  // Gap entre elementos
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  // Vertical gaps
  static const SizedBox verticalGapXs = SizedBox(height: xs);
  static const SizedBox verticalGapSm = SizedBox(height: sm);
  static const SizedBox verticalGapMd = SizedBox(height: md);
  static const SizedBox verticalGapLg = SizedBox(height: lg);
  static const SizedBox verticalGapXl = SizedBox(height: xl);

  // Horizontal gaps
  static const SizedBox horizontalGapXs = SizedBox(width: xs);
  static const SizedBox horizontalGapSm = SizedBox(width: sm);
  static const SizedBox horizontalGapMd = SizedBox(width: md);
  static const SizedBox horizontalGapLg = SizedBox(width: lg);
  static const SizedBox horizontalGapXl = SizedBox(width: xl);
}

/// Tokens de border radius consistentes.
class AppRadius {
  AppRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 999.0;

  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(full));

  // Top only
  static const BorderRadius topRadiusLg = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );

  // Bottom only
  static const BorderRadius bottomRadiusLg = BorderRadius.only(
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );
}

/// Durações de animação consistentes.
class AppDurations {
  AppDurations._();

  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);
}

/// Curvas de animação.
class AppCurves {
  AppCurves._();

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

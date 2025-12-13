import 'package:flutter/material.dart';

/// Paleta de cores moderna para ClassicDrive.
/// Tema: Midnight Blue + Gold - Luxo e Elegância para carros clássicos.
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════════════════════════════
  // CORES PRIMÁRIAS - Gradient Principal
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color primaryStart = Color(0xFF667EEA);  // Indigo vibrante
  static const Color primaryEnd = Color(0xFF764BA2);    // Púrpura profundo
  static const Color primary = Color(0xFF667EEA);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryStart, primaryEnd],
  );

  // ══════════════════════════════════════════════════════════════════════════
  // COR DE DESTAQUE - Gold (Perfeito para carros clássicos)
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color accent = Color(0xFFF59E0B);        // Âmbar/Dourado
  static const Color accentLight = Color(0xFFFBBF24);   // Dourado claro
  static const Color accentDark = Color(0xFFD97706);    // Dourado escuro

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CORES SEMÂNTICAS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color success = Color(0xFF10B981);       // Esmeralda
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);       // Âmbar
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);         // Vermelho coral
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);          // Azul info
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ══════════════════════════════════════════════════════════════════════════
  // DARK MODE
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color darkBackground = Color(0xFF0F0F23);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkCardHover = Color(0xFF1F2B4D);
  static const Color darkBorder = Color(0xFF2A2A4A);
  
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkTextDisabled = Color(0xFF475569);

  // Glass effect colors for dark mode
  static Color darkGlass = Colors.white.withOpacity(0.08);
  static Color darkGlassBorder = Colors.white.withOpacity(0.12);
  static Color darkGlassHighlight = Colors.white.withOpacity(0.15);

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightTextDisabled = Color(0xFFCBD5E1);

  // Glass effect colors for light mode
  static Color lightGlass = Colors.white.withOpacity(0.7);
  static Color lightGlassBorder = Colors.black.withOpacity(0.08);
  static Color lightGlassHighlight = Colors.white.withOpacity(0.9);

  // ══════════════════════════════════════════════════════════════════════════
  // GRADIENTES ESPECIAIS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF667EEA),
      Color(0xFF764BA2),
      Color(0xFF0F0F23),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
    ],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF2A2A4A),
      Color(0xFF1A1A2E),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CATEGORIAS DE VEÍCULOS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color categoryClassic = Color(0xFFD4AF37);   // Dourado clássico
  static const Color categoryVintage = Color(0xFF8B4513);   // Castanho vintage
  static const Color categoryLuxury = Color(0xFF4A69BD);    // Azul luxo
}

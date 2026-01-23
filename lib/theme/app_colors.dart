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
  static const Color darkGlass = whiteOpacity08;
  static const Color darkGlassBorder = whiteOpacity12;
  static const Color darkGlassHighlight = whiteOpacity15;

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
  static const Color lightGlass = whiteOpacity70;
  static const Color lightGlassBorder = blackOpacity08;
  static const Color lightGlassHighlight = whiteOpacity90;

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

  // ══════════════════════════════════════════════════════════════════════════
  // CORES COM OPACIDADE PRÉ-CALCULADA
  // Evita criar novos objetos Color em cada rebuild, melhorando performance
  // ══════════════════════════════════════════════════════════════════════════
  
  // Primary com opacidades (0x1A=10%, 0x26=15%, 0x33=20%, 0x4D=30%, 0x66=40%, 0x80=50%, 0xB3=70%, 0xCC=80%, 0xE6=90%)
  static const Color primaryOpacity05 = Color(0x0D667EEA);  // primary @ 5%
  static const Color primaryOpacity10 = Color(0x1A667EEA);  // primary @ 10%
  static const Color primaryOpacity15 = Color(0x26667EEA);  // primary @ 15%
  static const Color primaryOpacity20 = Color(0x33667EEA);  // primary @ 20%
  static const Color primaryOpacity30 = Color(0x4D667EEA);  // primary @ 30%
  static const Color primaryOpacity40 = Color(0x66667EEA);  // primary @ 40%
  static const Color primaryOpacity50 = Color(0x80667EEA);  // primary @ 50%
  static const Color primaryOpacity70 = Color(0xB3667EEA);  // primary @ 70%
  static const Color primaryOpacity80 = Color(0xCC667EEA);  // primary @ 80%
  
  // Success com opacidades
  static const Color successOpacity10 = Color(0x1A10B981);  // success @ 10%
  static const Color successOpacity15 = Color(0x2610B981);  // success @ 15%
  static const Color successOpacity20 = Color(0x3310B981);  // success @ 20%
  static const Color successOpacity30 = Color(0x4D10B981);  // success @ 30%
  static const Color successOpacity40 = Color(0x6610B981);  // success @ 40%
  static const Color successOpacity80 = Color(0xCC10B981);  // success @ 80%
  static const Color successOpacity90 = Color(0xE610B981);  // success @ 90%
  
  // Error com opacidades
  static const Color errorOpacity10 = Color(0x1AEF4444);    // error @ 10%
  static const Color errorOpacity15 = Color(0x26EF4444);    // error @ 15%
  static const Color errorOpacity20 = Color(0x33EF4444);    // error @ 20%
  static const Color errorOpacity30 = Color(0x4DEF4444);    // error @ 30%
  static const Color errorOpacity40 = Color(0x66EF4444);    // error @ 40%
  static const Color errorOpacity50 = Color(0x80EF4444);    // error @ 50%
  
  // Warning com opacidades
  static const Color warningOpacity10 = Color(0x1AF59E0B);  // warning @ 10%
  static const Color warningOpacity15 = Color(0x26F59E0B);  // warning @ 15%
  static const Color warningOpacity20 = Color(0x33F59E0B);  // warning @ 20%
  static const Color warningOpacity30 = Color(0x4DF59E0B);  // warning @ 30%
  
  // Info com opacidades
  static const Color infoOpacity10 = Color(0x1A3B82F6);     // info @ 10%
  static const Color infoOpacity20 = Color(0x333B82F6);     // info @ 20%
  static const Color infoOpacity30 = Color(0x4D3B82F6);     // info @ 30%
  
  // Accent com opacidades
  static const Color accentOpacity08 = Color(0x14F59E0B);   // accent @ 8%
  static const Color accentOpacity10 = Color(0x1AF59E0B);   // accent @ 10%
  static const Color accentOpacity15 = Color(0x26F59E0B);   // accent @ 15%
  static const Color accentOpacity30 = Color(0x4DF59E0B);   // accent @ 30%
  static const Color accentOpacity40 = Color(0x66F59E0B);   // accent @ 40%
  static const Color accentOpacity80 = Color(0xCCF59E0B);   // accent @ 80%
  static const Color accentOpacity90 = Color(0xE6F59E0B);   // accent @ 90%
  
  // Branco com opacidades
  static const Color whiteOpacity05 = Color(0x0DFFFFFF);    // white @ 5%
  static const Color whiteOpacity08 = Color(0x14FFFFFF);    // white @ 8%
  static const Color whiteOpacity10 = Color(0x1AFFFFFF);    // white @ 10%
  static const Color whiteOpacity12 = Color(0x1FFFFFFF);    // white @ 12%
  static const Color whiteOpacity15 = Color(0x26FFFFFF);    // white @ 15%
  static const Color whiteOpacity20 = Color(0x33FFFFFF);    // white @ 20%
  static const Color whiteOpacity30 = Color(0x4DFFFFFF);    // white @ 30%
  static const Color whiteOpacity40 = Color(0x66FFFFFF);    // white @ 40%
  static const Color whiteOpacity50 = Color(0x80FFFFFF);    // white @ 50%
  static const Color whiteOpacity70 = Color(0xB3FFFFFF);    // white @ 70%
  static const Color whiteOpacity80 = Color(0xCCFFFFFF);    // white @ 80%
  static const Color whiteOpacity85 = Color(0xD9FFFFFF);    // white @ 85%
  static const Color whiteOpacity90 = Color(0xE6FFFFFF);    // white @ 90%
  
  // Preto com opacidades
  static const Color blackOpacity05 = Color(0x0D000000);    // black @ 5%
  static const Color blackOpacity08 = Color(0x14000000);    // black @ 8%
  static const Color blackOpacity10 = Color(0x1A000000);    // black @ 10%
  static const Color blackOpacity12 = Color(0x1F000000);    // black @ 12%
  static const Color blackOpacity20 = Color(0x33000000);    // black @ 20%
  static const Color blackOpacity30 = Color(0x4D000000);    // black @ 30%
  static const Color blackOpacity40 = Color(0x66000000);    // black @ 40%
  static const Color blackOpacity50 = Color(0x80000000);    // black @ 50%
  static const Color blackOpacity60 = Color(0x99000000);    // black @ 60%
  static const Color blackOpacity70 = Color(0xB3000000);    // black @ 70%
  static const Color blackOpacity80 = Color(0xCC000000);    // black @ 80%
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_shadows.dart';

/// Tema principal da aplicação ClassicDrive.
class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Cores base
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryEnd,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.accentDark,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: AppColors.darkTextPrimary,
      onError: Colors.white,
    ),
    
    // Fundo
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    // Tipografia
    textTheme: AppTypography.darkTextTheme,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.darkTextTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Botões Elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
        ),
        textStyle: AppTypography.darkTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Botões Outlined
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
        ),
        side: const BorderSide(color: AppColors.primary, width: 2),
        textStyle: AppTypography.darkTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Botões de Texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: AppTypography.darkTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: AppTypography.darkTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextTertiary,
      ),
      labelStyle: AppTypography.darkTextTheme.bodyMedium,
      prefixIconColor: AppColors.darkTextTertiary,
      suffixIconColor: AppColors.darkTextTertiary,
    ),
    
    // Bottom Navigation
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      height: 80,
      indicatorColor: AppColors.primaryOpacity20,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.darkTextTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTypography.darkTextTheme.labelSmall?.copyWith(
          color: AppColors.darkTextTertiary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return IconThemeData(color: AppColors.darkTextTertiary, size: 24);
      }),
    ),
    
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCard,
      selectedColor: AppColors.primaryOpacity20,
      disabledColor: AppColors.darkCard,
      labelStyle: AppTypography.darkTextTheme.labelMedium!,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusFull,
        side: BorderSide(color: AppColors.darkBorder),
      ),
    ),
    
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
      ),
      titleTextStyle: AppTypography.darkTextTheme.headlineSmall,
      contentTextStyle: AppTypography.darkTextTheme.bodyMedium,
    ),
    
    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.topRadiusLg,
      ),
      dragHandleColor: AppColors.darkBorder,
      dragHandleSize: const Size(40, 4),
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: AppTypography.darkTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.darkTextSecondary,
      size: 24,
    ),
    
    // FloatingActionButton
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
      ),
    ),
    
    // TabBar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.darkTextTertiary,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTypography.darkTextTheme.labelLarge,
      unselectedLabelStyle: AppTypography.darkTextTheme.labelLarge,
    ),
    
    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.darkBorder,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primaryOpacity20,
      trackHeight: 4,
    ),
    
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.darkTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryOpacity30;
        }
        return AppColors.darkBorder;
      }),
    ),
    
    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.darkBorder,
      circularTrackColor: AppColors.darkBorder,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryEnd,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.accentLight,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: AppColors.lightTextPrimary,
      onError: Colors.white,
    ),
    
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: AppTypography.lightTextTheme,
    
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.lightTextTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
    ),
    
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
        ),
        textStyle: AppTypography.lightTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
        ),
        side: const BorderSide(color: AppColors.primary, width: 2),
        textStyle: AppTypography.lightTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: AppTypography.lightTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusLg,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: AppTypography.lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.lightTextTertiary,
      ),
      labelStyle: AppTypography.lightTextTheme.bodyMedium,
      prefixIconColor: AppColors.lightTextTertiary,
      suffixIconColor: AppColors.lightTextTertiary,
    ),
    
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      height: 80,
      indicatorColor: AppColors.primaryOpacity10,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.lightTextTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTypography.lightTextTheme.labelSmall?.copyWith(
          color: AppColors.lightTextTertiary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return IconThemeData(color: AppColors.lightTextTertiary, size: 24);
      }),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightCard,
      selectedColor: AppColors.primaryOpacity10,
      disabledColor: AppColors.lightCard,
      labelStyle: AppTypography.lightTextTheme.labelMedium!,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusFull,
        side: BorderSide(color: AppColors.lightBorder),
      ),
    ),
    
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
      ),
      titleTextStyle: AppTypography.lightTextTheme.headlineSmall,
      contentTextStyle: AppTypography.lightTextTheme.bodyMedium,
    ),
    
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.topRadiusLg,
      ),
      dragHandleColor: AppColors.lightBorder,
      dragHandleSize: const Size(40, 4),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: AppTypography.darkTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    ),
    
    dividerTheme: DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),
    
    iconTheme: const IconThemeData(
      color: AppColors.lightTextSecondary,
      size: 24,
    ),
    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
      ),
    ),
    
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.lightTextTertiary,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTypography.lightTextTheme.labelLarge,
      unselectedLabelStyle: AppTypography.lightTextTheme.labelLarge,
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.lightBorder,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primaryOpacity20,
      trackHeight: 4,
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.lightTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryOpacity30;
        }
        return AppColors.lightBorder;
      }),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.lightBorder,
      circularTrackColor: AppColors.lightBorder,
    ),
  );
}

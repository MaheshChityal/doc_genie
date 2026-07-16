import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:flutter/material.dart';

ThemeData lightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  const radius = 22.0;

  return base.copyWith(
    scaffoldBackgroundColor: ColorConstants.background,
    canvasColor: ColorConstants.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorConstants.primaryColor,
      primary: ColorConstants.primaryColor,
      secondary: ColorConstants.secondaryColor,
      surface: ColorConstants.surface,
      tertiary: ColorConstants.accentColor,
      error: ColorConstants.errorColor,
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: AppTextStyles.heading,
      headlineMedium: AppTextStyles.title,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.subtitle,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
    ),
    dividerTheme: const DividerThemeData(
      color: ColorConstants.border,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ColorConstants.textPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorConstants.surface,
      hintStyle: AppTextStyles.body.copyWith(color: ColorConstants.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: ColorConstants.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: ColorConstants.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: ColorConstants.primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: ColorConstants.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: ColorConstants.errorColor,
          width: 1.4,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: ColorConstants.surfaceAlt,
      selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.12),
      side: const BorderSide(color: ColorConstants.border),
      labelStyle: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: ColorConstants.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    cardTheme: CardThemeData(
      color: ColorConstants.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: ColorConstants.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorConstants.textPrimary,
        side: const BorderSide(color: ColorConstants.border),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorConstants.primaryColor,
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: ColorConstants.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ColorConstants.border),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: ColorConstants.primaryColor,
      selectionColor: Color(0x332D74DA),
      selectionHandleColor: ColorConstants.primaryColor,
    ),
  );
}

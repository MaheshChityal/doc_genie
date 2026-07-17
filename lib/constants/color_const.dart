import 'package:flutter/material.dart';

class ColorConstants {
  const ColorConstants._();

  static const Color primaryColor = Color(0xFF183B5B);
  static const Color secondaryColor = Color(0xFF1F7A6A);
  static const Color accentColor = Color(0xFFF47B50);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF228B5A);
  static const Color warningColor = Color(0xFFE4A11B);
  static const Color infoColor = Color(0xFF2D74DA);

  static const Color background = Color(0xFFF6F1E8);
  static const Color backgroundAlt = Color(0xFFEDE4D7);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color surfaceAlt = Color(0xFFF1E8DA);
  static const Color surfaceMuted = Color(0xFFE3D7C7);
  static const Color surfaceDark = Color(0xFF19324B);

  // Neutral greys for disabled / read-only fields.
  static const Color disabledFill = Color(0xFFF2F2F1);
  static const Color disabledBorder = Color(0xFFDCDCDA);

  static const Color textPrimary = Color(0xFF1C2730);
  static const Color textSecondary = Color(0xFF5D6A73);
  static const Color textMuted = Color(0xFF93A0A8);
  static const Color border = Color(0xFFE0D5C6);
  static const Color borderStrong = Color(0xFFCDBEAA);

  static const Color tagBg = Color(0xFFDCEFE9);
  static const Color tagFg = Color(0xFF165C50);
  static const Color glow = Color(0xFFF3C1A8);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF15314B), Color(0xFF1D4F73), Color(0xFF2C8A74)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shellGradient = LinearGradient(
    colors: [Color(0xFFF7F2EA), Color(0xFFEDE3D4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

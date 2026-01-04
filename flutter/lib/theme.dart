import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentGold = Color(0xFFE8B44C);
  static const Color borderColor = Color(0xFFE8F0DC);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);
  static const Color bgLight = Color(0xFFFAFBF8);
  static const Color bgWhite = Colors.white;

  static const BoxShadow shadowMd = BoxShadow(
    color: Colors.transparent,
    offset: Offset(0, 0),
    blurRadius: 0,
  );

  static const double spacingXs = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static LinearGradient gradientMain = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [
      0,
      0.08,
      0.16,
      0.24,
      0.32,
      0.4,
      0.48,
      0.56,
      0.64,
      0.72,
      0.8,
      0.88,
      1.0,
    ],
    colors: [
      Color(0xFFD9A641),
      Color(0xFFDCA943),
      Color(0xFFDFAE45),
      Color(0xFFE2B347),
      Color(0xFFE5B749),
      Color(0xFFE2BC4B),
      Color(0xFFDBC04E),
      Color(0xFFD4C551),
      Color(0xFFC8C856),
      Color(0xFFBBCB5A),
      Color(0xFFB0C95D),
      Color(0xFFAAC860),
      Color(0xFFA8C65D),
    ],
  );

  static LinearGradient gradientHover = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [
      0,
      0.08,
      0.16,
      0.24,
      0.32,
      0.4,
      0.48,
      0.56,
      0.64,
      0.72,
      0.8,
      0.88,
      1.0,
    ],
    colors: [
      Color(0xFFC99631),
      Color(0xFFCC9A33),
      Color(0xFFCF9E35),
      Color(0xFFD2A337),
      Color(0xFFD5A739),
      Color(0xFFD2AC3B),
      Color(0xFFCBB03E),
      Color(0xFFC4B541),
      Color(0xFFB8B846),
      Color(0xFFABBB4A),
      Color(0xFFA0B94D),
      Color(0xFF9AB850),
      Color(0xFF98B64D),
    ],
  );

  static LinearGradient gradientSoft = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFBF5), Color(0xFFF7FCE8)],
  );
}

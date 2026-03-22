import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primaryColor = Color(0xFF00BFA6); // Teal accent
  static const Color primaryDark = Color(0xFF009688);
  static const Color primaryLight = Color(0xFF64FFDA);

  // Background
  static const Color bgDark = Color(0xFF0D1117);
  static const Color bgCard = Color(0xFF161B22);
  static const Color bgCardLight = Color(0xFF1C2333);
  static const Color bgSurface = Color(0xFF21262D);

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // Accents
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentPurple = Color(0xFFBC8CFF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentOrange = Color(0xFFD29922);
  static const Color accentRed = Color(0xFFF85149);
  static const Color accentPink = Color(0xFFF778BA);

  // Borders
  static const Color border = Color(0xFF30363D);
  static const Color borderLight = Color(0xFF3D444D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00BFA6), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161B22), Color(0xFF1C2333)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00BFA6), Color(0xFF58A6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

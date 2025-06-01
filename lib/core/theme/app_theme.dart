import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData priColor =
      ThemeData(colorSchemeSeed: AppColors.primaryColor);

  static ThemeData lightTheme = ThemeData(
    appBarTheme: AppBarTheme(
      backgroundColor: priColor.primaryColor,
      foregroundColor: Colors.white,
    ),
    colorSchemeSeed: AppColors.primaryColor,
    useMaterial3: true,
  );
}

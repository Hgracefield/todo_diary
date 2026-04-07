import 'package:flutter/material.dart';
import 'package:my_todo_list_app/app/theme/app_colors.dart';
import 'package:my_todo_list_app/app/theme/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.mintBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mintPrimary,
        primary: AppColors.mintPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.heading,
        titleLarge: AppTextStyles.title,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      useMaterial3: true,
    );
  }

  const AppTheme._();
}

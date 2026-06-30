// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Базовый шрифт для всего приложения - Montserrat
  static const String _fontFamily = 'Montserrat';
  
  // ---- ЗАГОЛОВКИ (жирные, крупные) ----
  static const TextStyle headline25 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 25,
    fontWeight: FontWeight.w800,  // стал жирнее
    fontFamily: _fontFamily,
    letterSpacing: -0.3,  // небольшой кернинг для красоты
  );
  
  static const TextStyle headline20 = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 20,
    fontWeight: FontWeight.w800,  // стал жирнее
    fontFamily: _fontFamily,
  );
  
  static const TextStyle headline18 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle headline16 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle headline15 = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle headline14 = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle headline12 = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle headline11 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  // ---- СИНИЙ ТЕКСТ (#5F5B91) ----
  static const TextStyle blueText36 = TextStyle(
    color: AppColors.blueText,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle blueText30 = TextStyle(
    color: AppColors.blueText,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle blueText20 = TextStyle(
    color: AppColors.blueText,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle blueText15 = TextStyle(
    color: AppColors.blueText,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle blueText12 = TextStyle(
    color: AppColors.blueText,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    height: 1.4,  // добавил высоту строки для читаемости
  );
  
  static const TextStyle blueText11 = TextStyle(
    color: AppColors.blueText,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle blueText8 = TextStyle(
    color: AppColors.blueText,
    fontSize: 8,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  // ---- БЕЛЫЙ ТЕКСТ (для красного фона) ----
  static const TextStyle whiteText20 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle whiteText18 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle whiteText16 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle whiteText15 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle whiteText12 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    height: 1.4,
  );
  
  static const TextStyle whiteText11 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle whiteText8 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 8,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  // ---- ОСНОВНОЙ ТЕКСТ (читаемый, средняя жирность) ----
  static const TextStyle body12 = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 12,
    fontWeight: FontWeight.w500,  // стал читаемее
    fontFamily: _fontFamily,
    height: 1.5,  // хорошая высота строки для читаемости
  );
  
  static const TextStyle body12Bold = TextStyle(
    color: AppColors.primaryRed,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle body11 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  static const TextStyle body8 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 8,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
  );
  
  // ---- ITIM ШРИФТ (только для поздравлений, оставляем как есть) ----
  static const TextStyle itim25 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 25,
    fontFamily: 'Itim',
  );
  
  static const TextStyle itim20 = TextStyle(
    color: AppColors.whiteText,
    fontSize: 20,
    fontFamily: 'Itim',
  );
}
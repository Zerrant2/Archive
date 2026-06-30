// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Основные цвета (ШРИФТЫ)
  static const Color primaryRed = Color(0xFF870C0E);      // Красный шрифт
  static const Color blueText = Color(0xFF5F5B91);         // Синий шрифт
  static const Color whiteText = Color(0xFFFFFFFF);        // Белый шрифт
  
  // Фоновые цвета блоков
  static const Color darkRed = Color(0xFFB4191C);          // Красные блоки
  static const Color lightPink = Color.fromARGB(255, 239, 179, 179);        // Розовые блоки (светлый фон) - изменено на более светлый
  static const Color darkPink = Color(0xFFBC6F6D);         // Розовые блоки (темные для кнопок)
  static const Color beigeBackground = Color(0xFFFDF9F2);  // Бежевый фон
  static const Color greyBackground = Color(0xFFD7CFCF);   // Серый фон для карточек
  
  // Цвета для ответов в тестах
  static const Color greenCorrect = Color(0xFFCCFCD8);     // Зеленый для правильных ответов
  static const Color redWrong = Color(0xFFF2BCBC);         // Красный для неправильных ответов
  static const Color borderRed = Color(0xFFE22828);        // Красная граница
  
  // Градиенты
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB4191C), Color(0xFF4E0B0C)],
  );
}
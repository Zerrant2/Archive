// lib/theme/app_decorations.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shadows.dart';

class AppDecorations {
  // Красный квадрат (градиент) - СВОЙСТВО
  static BoxDecoration redGradientSquare = BoxDecoration(
    gradient: AppColors.redGradient,
    borderRadius: BorderRadius.circular(15),
  );
  
  // Красный квадрат (для неполученных достижений) - МЕТОД
  static BoxDecoration redSquare({double opacity = 1.0}) {
    return BoxDecoration(
      color: AppColors.darkRed.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(15),
    );
  }
  
  // Полупрозрачная красная карточка - СВОЙСТВО
  static BoxDecoration transparentRedCard = BoxDecoration(
    color: AppColors.primaryRed.withValues(alpha: 0.46),
    borderRadius: BorderRadius.circular(15),
  );
  
  // Розовая панель с границей - МЕТОД (для Аудиогид, Пройти тест)
  static BoxDecoration pinkPanel({bool hasShadow = false}) {
    return BoxDecoration(
      color: AppColors.lightPink,  // ← светлый розовый фон
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.borderRed, width: 2),
      boxShadow: hasShadow ? AppShadows.small : null,
    );
  }

  //  исторической сводки (розовый фон)
  static BoxDecoration historyCard = BoxDecoration(
    color: AppColors.lightPink,  
    borderRadius: BorderRadius.circular(15),
  );

  // Светло-розовая карточка  - СВОЙСТВО (для AI Ассистент)
  static BoxDecoration lightPinkCard = BoxDecoration(
    color: AppColors.lightPink,  // ← светлый розовый фон
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppColors.borderRed, width: 2), 
  );
  
  // Темно-розовая кнопка - СВОЙСТВО (для кнопок внутри карточек)
  static BoxDecoration darkPinkButton = BoxDecoration(
    color: AppColors.darkPink,
    borderRadius: BorderRadius.circular(15),
  );
  
  // Серый фон для вариантов ответов - СВОЙСТВО
  static BoxDecoration greyOption = BoxDecoration(
    color: AppColors.greyBackground,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppColors.whiteText, width: 1),
  );
  
  // Бежевый фон - СВОЙСТВО
  static BoxDecoration beigeBackground = BoxDecoration(
    color: AppColors.beigeBackground,
  );
}
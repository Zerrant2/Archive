// lib/theme/app_shadows.dart
import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> small = [
    const BoxShadow(
      color: Colors.black26,
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static List<BoxShadow> medium = [
    const BoxShadow(
      color: Colors.black26,
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];
  
  static List<BoxShadow> redGlow = [
    const BoxShadow(
      color: Color(0xFF8F0303),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}
import 'package:flutter/material.dart';

enum HeritageRouteTheme { city, warMemory, architecture, highlights }

extension HeritageRouteThemeInfo on HeritageRouteTheme {
  String get label {
    switch (this) {
      case HeritageRouteTheme.city:
        return 'Центр';
      case HeritageRouteTheme.warMemory:
        return 'Память';
      case HeritageRouteTheme.architecture:
        return 'Архитектура';
      case HeritageRouteTheme.highlights:
        return 'Главное';
    }
  }

  IconData get icon {
    switch (this) {
      case HeritageRouteTheme.city:
        return Icons.location_city;
      case HeritageRouteTheme.warMemory:
        return Icons.military_tech;
      case HeritageRouteTheme.architecture:
        return Icons.account_balance;
      case HeritageRouteTheme.highlights:
        return Icons.stars;
    }
  }

  Color get color {
    switch (this) {
      case HeritageRouteTheme.city:
        return const Color(0xFF5F5B91);
      case HeritageRouteTheme.warMemory:
        return const Color(0xFFB4191C);
      case HeritageRouteTheme.architecture:
        return const Color(0xFF8E44AD);
      case HeritageRouteTheme.highlights:
        return const Color(0xFFE67E22);
    }
  }
}

class HeritageRoute {
  final String id;
  final String name;
  final String description;
  final HeritageRouteTheme theme;
  final List<String> objectIds;
  final int durationMinutes;
  final double distanceKm;

  const HeritageRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.objectIds,
    required this.durationMinutes,
    required this.distanceKm,
  });

  int get pointsCount => objectIds.length;

  HeritageRoute copyWith({
    List<String>? objectIds,
    int? durationMinutes,
    double? distanceKm,
  }) {
    return HeritageRoute(
      id: id,
      name: name,
      description: description,
      theme: theme,
      objectIds: objectIds ?? this.objectIds,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

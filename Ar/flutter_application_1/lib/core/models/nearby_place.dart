import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum NearbyPlaceCategory {
  cafe,
  restaurant,
  museum,
  park,
  hotel,
  pharmacy,
  atm,
  shopping,
  viewpoint,
}

extension NearbyPlaceCategoryInfo on NearbyPlaceCategory {
  String get label {
    switch (this) {
      case NearbyPlaceCategory.cafe:
        return 'Кафе';
      case NearbyPlaceCategory.restaurant:
        return 'Еда';
      case NearbyPlaceCategory.museum:
        return 'Музеи';
      case NearbyPlaceCategory.park:
        return 'Парки';
      case NearbyPlaceCategory.hotel:
        return 'Отели';
      case NearbyPlaceCategory.pharmacy:
        return 'Аптеки';
      case NearbyPlaceCategory.atm:
        return 'Банкоматы';
      case NearbyPlaceCategory.shopping:
        return 'Магазины';
      case NearbyPlaceCategory.viewpoint:
        return 'Виды';
    }
  }

  IconData get icon {
    switch (this) {
      case NearbyPlaceCategory.cafe:
        return Icons.local_cafe;
      case NearbyPlaceCategory.restaurant:
        return Icons.restaurant;
      case NearbyPlaceCategory.museum:
        return Icons.museum;
      case NearbyPlaceCategory.park:
        return Icons.park;
      case NearbyPlaceCategory.hotel:
        return Icons.hotel;
      case NearbyPlaceCategory.pharmacy:
        return Icons.local_pharmacy;
      case NearbyPlaceCategory.atm:
        return Icons.account_balance;
      case NearbyPlaceCategory.shopping:
        return Icons.shopping_bag;
      case NearbyPlaceCategory.viewpoint:
        return Icons.landscape;
    }
  }

  Color get color {
    switch (this) {
      case NearbyPlaceCategory.cafe:
        return const Color(0xFFE67E22);
      case NearbyPlaceCategory.restaurant:
        return const Color(0xFFE74C3C);
      case NearbyPlaceCategory.museum:
        return const Color(0xFF2E9E68);
      case NearbyPlaceCategory.park:
        return const Color(0xFF27AE60);
      case NearbyPlaceCategory.hotel:
        return const Color(0xFF3498DB);
      case NearbyPlaceCategory.pharmacy:
        return const Color(0xFF1ABC9C);
      case NearbyPlaceCategory.atm:
        return const Color(0xFF2C3E50);
      case NearbyPlaceCategory.shopping:
        return const Color(0xFFF39C12);
      case NearbyPlaceCategory.viewpoint:
        return const Color(0xFF8E44AD);
    }
  }

  List<String> get overpassFilters {
    switch (this) {
      case NearbyPlaceCategory.cafe:
        return ['["amenity"="cafe"]'];
      case NearbyPlaceCategory.restaurant:
        return [
          '["amenity"="restaurant"]',
          '["amenity"="fast_food"]',
          '["amenity"="food_court"]',
        ];
      case NearbyPlaceCategory.museum:
        return ['["tourism"="museum"]', '["amenity"="museum"]'];
      case NearbyPlaceCategory.park:
        return ['["leisure"="park"]', '["leisure"="garden"]'];
      case NearbyPlaceCategory.hotel:
        return ['["tourism"="hotel"]'];
      case NearbyPlaceCategory.pharmacy:
        return ['["amenity"="pharmacy"]'];
      case NearbyPlaceCategory.atm:
        return ['["amenity"="atm"]', '["amenity"="bank"]'];
      case NearbyPlaceCategory.shopping:
        return [
          '["shop"="supermarket"]',
          '["shop"="mall"]',
          '["shop"="department_store"]',
        ];
      case NearbyPlaceCategory.viewpoint:
        return ['["tourism"="viewpoint"]', '["tourism"="attraction"]'];
    }
  }
}

class NearbyPlace {
  final String id;
  final String name;
  final LatLng position;
  final NearbyPlaceCategory category;
  final double distanceKm;
  final String? address;
  final String? phone;
  final String? openingHours;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    required this.distanceKm,
    this.address,
    this.phone,
    this.openingHours,
  });
}

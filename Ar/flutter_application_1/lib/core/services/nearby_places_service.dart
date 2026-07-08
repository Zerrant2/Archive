import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/nearby_place.dart';

class NearbyPlacesService {
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _userAgent = 'ARhiv MVP nearby places';
  static const _distance = Distance();

  Future<List<NearbyPlace>> getNearbyPlaces({
    required LatLng center,
    double radiusKm = 2.5,
    NearbyPlaceCategory? category,
    int limit = 24,
  }) async {
    try {
      final query = buildOverpassQuery(
        center: center,
        radiusMeters: (radiusKm * 1000).round(),
        category: category,
      );
      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': _userAgent,
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 16));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return fallbackPlaces(center: center, category: category);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return fallbackPlaces(center: center, category: category);
      }

      final places = parseOverpassResponse(
        decoded,
        center: center,
        fallbackCategory: category,
      );
      if (places.isEmpty) {
        return fallbackPlaces(center: center, category: category);
      }
      return places.take(limit).toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Nearby places loading failed: $error');
      }
      return fallbackPlaces(center: center, category: category);
    }
  }

  @visibleForTesting
  static String buildOverpassQuery({
    required LatLng center,
    required int radiusMeters,
    NearbyPlaceCategory? category,
  }) {
    final categories = category == null
        ? NearbyPlaceCategory.values
        : [category];
    final selectors = <String>[];

    for (final currentCategory in categories) {
      for (final filter in currentCategory.overpassFilters) {
        selectors.add(
          'node$filter(around:$radiusMeters,${center.latitude},${center.longitude});',
        );
        selectors.add(
          'way$filter(around:$radiusMeters,${center.latitude},${center.longitude});',
        );
        selectors.add(
          'relation$filter(around:$radiusMeters,${center.latitude},${center.longitude});',
        );
      }
    }

    return '''
[out:json][timeout:18];
(
  ${selectors.join('\n  ')}
);
out body center 60;
''';
  }

  @visibleForTesting
  static List<NearbyPlace> parseOverpassResponse(
    Map<String, dynamic> data, {
    required LatLng center,
    NearbyPlaceCategory? fallbackCategory,
  }) {
    final rawElements = data['elements'];
    if (rawElements is! List) return const [];

    final places = <NearbyPlace>[];
    final seenKeys = <String>{};

    for (final rawElement in rawElements) {
      if (rawElement is! Map) continue;
      final element = Map<String, dynamic>.from(rawElement);
      final tags = _mapFrom(element['tags']);
      if (tags == null) continue;

      final point = _pointFromElement(element);
      if (point == null) continue;

      final name = _firstNonEmpty([
        tags['name:ru'],
        tags['name'],
        tags['brand'],
        tags['operator'],
      ]);
      if (name == null) continue;

      final category = _categoryFromTags(tags) ?? fallbackCategory;
      if (category == null) continue;

      final normalizedKey = '${category.name}:${name.toLowerCase()}';
      if (!seenKeys.add(normalizedKey)) continue;

      places.add(
        NearbyPlace(
          id: '${element['type'] ?? 'osm'}:${element['id'] ?? name}',
          name: name,
          position: point,
          category: category,
          distanceKm: _distance.as(LengthUnit.Kilometer, center, point),
          address: _addressFromTags(tags),
          phone: _firstNonEmpty([tags['contact:phone'], tags['phone']]),
          openingHours: tags['opening_hours']?.trim(),
        ),
      );
    }

    places.sort((left, right) => left.distanceKm.compareTo(right.distanceKm));
    return places;
  }

  @visibleForTesting
  static List<NearbyPlace> fallbackPlaces({
    required LatLng center,
    NearbyPlaceCategory? category,
  }) {
    final fallback = <NearbyPlace>[
      _fallbackPlace(
        center,
        id: 'fallback-cafe',
        name: 'Кофейня рядом',
        category: NearbyPlaceCategory.cafe,
        offsetLat: 0.0017,
        offsetLng: 0.0012,
        address: 'В центре города',
      ),
      _fallbackPlace(
        center,
        id: 'fallback-restaurant',
        name: 'Ресторан рядом',
        category: NearbyPlaceCategory.restaurant,
        offsetLat: -0.0014,
        offsetLng: 0.0018,
        address: 'Недалеко от объекта',
      ),
      _fallbackPlace(
        center,
        id: 'fallback-museum',
        name: 'Музейная площадка',
        category: NearbyPlaceCategory.museum,
        offsetLat: 0.0022,
        offsetLng: -0.0015,
        address: 'Исторический квартал',
      ),
      _fallbackPlace(
        center,
        id: 'fallback-park',
        name: 'Пешеходная зона',
        category: NearbyPlaceCategory.park,
        offsetLat: -0.002,
        offsetLng: -0.001,
        address: 'Место для прогулки',
      ),
      _fallbackPlace(
        center,
        id: 'fallback-viewpoint',
        name: 'Смотровая точка',
        category: NearbyPlaceCategory.viewpoint,
        offsetLat: 0.001,
        offsetLng: -0.0022,
        address: 'Точка обзора',
      ),
    ];

    if (category == null) return fallback;
    return fallback.where((place) => place.category == category).toList();
  }

  static NearbyPlace _fallbackPlace(
    LatLng center, {
    required String id,
    required String name,
    required NearbyPlaceCategory category,
    required double offsetLat,
    required double offsetLng,
    required String address,
  }) {
    final point = LatLng(
      center.latitude + offsetLat,
      center.longitude + offsetLng,
    );
    return NearbyPlace(
      id: id,
      name: name,
      position: point,
      category: category,
      distanceKm: _distance.as(LengthUnit.Kilometer, center, point),
      address: address,
    );
  }

  static Map<String, String>? _mapFrom(Object? value) {
    if (value is! Map) return null;
    return value.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  static LatLng? _pointFromElement(Map<String, dynamic> element) {
    final lat = _numToDouble(element['lat']);
    final lon = _numToDouble(element['lon']);
    if (lat != null && lon != null) return LatLng(lat, lon);

    final center = element['center'];
    if (center is! Map) return null;

    final centerLat = _numToDouble(center['lat']);
    final centerLon = _numToDouble(center['lon']);
    if (centerLat == null || centerLon == null) return null;

    return LatLng(centerLat, centerLon);
  }

  static double? _numToDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static NearbyPlaceCategory? _categoryFromTags(Map<String, String> tags) {
    final amenity = tags['amenity'];
    final tourism = tags['tourism'];
    final leisure = tags['leisure'];
    final shop = tags['shop'];

    if (amenity == 'cafe') return NearbyPlaceCategory.cafe;
    if (amenity == 'restaurant' ||
        amenity == 'fast_food' ||
        amenity == 'food_court') {
      return NearbyPlaceCategory.restaurant;
    }
    if (tourism == 'museum' || amenity == 'museum') {
      return NearbyPlaceCategory.museum;
    }
    if (leisure == 'park' || leisure == 'garden') {
      return NearbyPlaceCategory.park;
    }
    if (tourism == 'hotel') return NearbyPlaceCategory.hotel;
    if (amenity == 'pharmacy') return NearbyPlaceCategory.pharmacy;
    if (amenity == 'atm' || amenity == 'bank') return NearbyPlaceCategory.atm;
    if (shop == 'supermarket' || shop == 'mall' || shop == 'department_store') {
      return NearbyPlaceCategory.shopping;
    }
    if (tourism == 'viewpoint' || tourism == 'attraction') {
      return NearbyPlaceCategory.viewpoint;
    }

    return null;
  }

  static String? _addressFromTags(Map<String, String> tags) {
    final full = _firstNonEmpty([tags['addr:full'], tags['address']]);
    if (full != null) return full;

    final street = tags['addr:street']?.trim();
    final house = tags['addr:housenumber']?.trim();
    if (street == null || street.isEmpty) return null;
    if (house == null || house.isEmpty) return street;
    return '$street, $house';
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}

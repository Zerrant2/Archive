import 'package:flutter_application_1/core/models/nearby_place.dart';
import 'package:flutter_application_1/core/services/nearby_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('NearbyPlacesService parses node and way center from Overpass', () {
    final places = NearbyPlacesService.parseOverpassResponse({
      'elements': [
        {
          'type': 'node',
          'id': 1,
          'lat': 48.7187,
          'lon': 44.5134,
          'tags': {
            'name': 'Cafe Test',
            'amenity': 'cafe',
            'addr:street': 'Lenina',
            'addr:housenumber': '1',
          },
        },
        {
          'type': 'way',
          'id': 2,
          'center': {'lat': 48.7192, 'lon': 44.5142},
          'tags': {'name:ru': 'Museum Test', 'tourism': 'museum'},
        },
      ],
    }, center: const LatLng(48.7186, 44.5133));

    expect(places, hasLength(2));
    expect(places.first.name, 'Cafe Test');
    expect(places.first.category, NearbyPlaceCategory.cafe);
    expect(places.first.address, 'Lenina, 1');
    expect(places.last.name, 'Museum Test');
    expect(places.last.category, NearbyPlaceCategory.museum);
  });

  test('NearbyPlacesService falls back to local places by category', () {
    final places = NearbyPlacesService.fallbackPlaces(
      center: const LatLng(48.7186, 44.5133),
      category: NearbyPlaceCategory.park,
    );

    expect(places, isNotEmpty);
    expect(
      places.every((place) => place.category == NearbyPlaceCategory.park),
      isTrue,
    );
  });
}

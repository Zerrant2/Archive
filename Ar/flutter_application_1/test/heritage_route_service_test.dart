import 'package:flutter_application_1/core/services/heritage_route_service.dart';
import 'package:flutter_application_1/models/historical_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HeritageRouteService builds predefined routes from known objects', () {
    final routes = HeritageRouteService.buildRoutes([
      _object('nevsky_cathedral', 48.7194, 44.5018),
      _object('fire_tower', 48.7098, 44.5162),
      _object('mayak', 48.7168, 44.5232),
    ]);

    expect(routes, isNotEmpty);

    final centerRoute = routes.firstWhere(
      (route) => route.id == 'historic_center',
    );
    expect(centerRoute.pointsCount, 3);
    expect(centerRoute.distanceKm, greaterThan(0));
    expect(centerRoute.durationMinutes, greaterThan(0));
  });

  test(
    'HeritageRouteService creates fallback route for unknown object ids',
    () {
      final routes = HeritageRouteService.buildRoutes([
        _object('custom_1', 48.7100, 44.5100),
        _object('custom_2', 48.7110, 44.5200),
        _object('custom_3', 48.7120, 44.5300),
      ]);

      expect(routes, hasLength(1));
      expect(routes.single.id, 'all_objects');
      expect(routes.single.pointsCount, 3);
      expect(routes.single.distanceKm, greaterThan(0));
    },
  );
}

HistoricalObject _object(String id, double latitude, double longitude) {
  return HistoricalObject(
    id: id,
    name: id,
    century: '',
    architectureType: '',
    address: '',
    yearsOfExistence: '',
    sources: '',
    shortDescription: '',
    detailedDescription: '',
    imageAsset: '',
    latitude: latitude,
    longitude: longitude,
    simpleQuestions: const [],
    hardQuestions: const [],
    panoramas: const [],
  );
}

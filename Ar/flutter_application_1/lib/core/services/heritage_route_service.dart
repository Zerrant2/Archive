import 'package:latlong2/latlong.dart';

import '../../models/historical_object.dart';
import '../models/heritage_route.dart';

class HeritageRouteService {
  static const _distance = Distance();

  static List<HeritageRoute> buildRoutes(
    List<HistoricalObject> objects, {
    required List<HeritageRoute> templates,
  }) {
    final objectsById = {for (final object in objects) object.id: object};
    final routes = templates
        .map((route) => _hydrateRoute(route, objectsById))
        .where((route) => route.objectIds.length >= 2)
        .toList();

    if (routes.isNotEmpty) return routes;
    return _fallbackRoute(objects);
  }

  static List<HistoricalObject> routeObjects(
    HeritageRoute route,
    List<HistoricalObject> objects,
  ) {
    final objectsById = {for (final object in objects) object.id: object};
    return route.objectIds
        .map((id) => objectsById[id])
        .whereType<HistoricalObject>()
        .toList();
  }

  static List<LatLng> routePoints(
    HeritageRoute route,
    List<HistoricalObject> objects,
  ) {
    return routeObjects(
      route,
      objects,
    ).map((object) => LatLng(object.latitude, object.longitude)).toList();
  }

  static LatLng routeCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(48.7186, 44.5133);
    final lat = points.map((point) => point.latitude).reduce((a, b) => a + b);
    final lng = points.map((point) => point.longitude).reduce((a, b) => a + b);
    return LatLng(lat / points.length, lng / points.length);
  }

  static HeritageRoute _hydrateRoute(
    HeritageRoute route,
    Map<String, HistoricalObject> objectsById,
  ) {
    final existingIds = route.objectIds
        .where((id) => objectsById.containsKey(id))
        .toList();
    final points = existingIds
        .map((id) => objectsById[id]!)
        .map((object) => LatLng(object.latitude, object.longitude))
        .toList();
    final distanceKm = calculateRouteDistanceKm(points);

    return route.copyWith(
      objectIds: existingIds,
      distanceKm: distanceKm,
      durationMinutes: estimateDurationMinutes(distanceKm, existingIds.length),
    );
  }

  static List<HeritageRoute> _fallbackRoute(List<HistoricalObject> objects) {
    if (objects.length < 2) return const [];

    final sortedObjects = [...objects]
      ..sort((left, right) => left.longitude.compareTo(right.longitude));
    final objectIds = sortedObjects.take(5).map((object) => object.id).toList();
    final points = sortedObjects
        .take(5)
        .map((object) => LatLng(object.latitude, object.longitude))
        .toList();
    final distanceKm = calculateRouteDistanceKm(points);

    return [
      HeritageRoute(
        id: 'all_objects',
        name: 'Обзорная прогулка',
        description: 'Маршрут по доступным объектам на карте.',
        theme: HeritageRouteTheme.highlights,
        objectIds: objectIds,
        durationMinutes: estimateDurationMinutes(distanceKm, objectIds.length),
        distanceKm: distanceKm,
      ),
    ];
  }

  static double calculateRouteDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;

    var total = 0.0;
    for (var index = 1; index < points.length; index++) {
      total += _distance.as(
        LengthUnit.Kilometer,
        points[index - 1],
        points[index],
      );
    }
    return total;
  }

  static int estimateDurationMinutes(double distanceKm, int pointsCount) {
    if (pointsCount <= 0) return 0;
    final walkingMinutes = (distanceKm / 4.2 * 60).round();
    final visitMinutes = pointsCount * 7;
    return (walkingMinutes + visitMinutes).clamp(10, 240);
  }
}

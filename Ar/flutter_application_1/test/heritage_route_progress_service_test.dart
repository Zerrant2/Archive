import 'package:flutter_application_1/core/models/heritage_route.dart';
import 'package:flutter_application_1/core/models/heritage_route_progress.dart';
import 'package:flutter_application_1/core/services/heritage_route_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('route progress persists visited stops and completion', () async {
    const service = HeritageRouteProgressService();
    var progress = HeritageRouteProgress.empty(_route.id);

    progress = await service.toggleVisited(
      route: _route,
      objectId: 'one',
      current: progress,
    );
    expect(progress.isVisited('one'), isTrue);
    expect(progress.isCompleted, isFalse);

    progress = await service.toggleVisited(
      route: _route,
      objectId: 'two',
      current: progress,
    );
    expect(progress.isCompleted, isTrue);

    final restored = await service.loadAll();
    expect(restored[_route.id]?.visitedObjectIds, {'one', 'two'});
    expect(restored[_route.id]?.completedAt, isNotNull);
  });

  test('removing a visited stop clears completion', () async {
    const service = HeritageRouteProgressService();
    var progress = HeritageRouteProgress(
      routeId: _route.id,
      visitedObjectIds: const {'one', 'two'},
      completedAt: DateTime(2026),
    );

    progress = await service.toggleVisited(
      route: _route,
      objectId: 'two',
      current: progress,
    );

    expect(progress.isCompleted, isFalse);
    expect(progress.isVisited('two'), isFalse);
  });
}

const _route = HeritageRoute(
  id: 'route',
  name: 'Route',
  description: '',
  theme: HeritageRouteTheme.city,
  objectIds: ['one', 'two'],
  durationMinutes: 0,
  distanceKm: 0,
);

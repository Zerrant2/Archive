import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/heritage_route.dart';
import '../models/heritage_route_progress.dart';

class HeritageRouteProgressService {
  static const storageKey = 'heritage_route_progress_v1';

  const HeritageRouteProgressService();

  Future<Map<String, HeritageRouteProgress>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final source = preferences.getString(storageKey);
    if (source == null || source.isEmpty) return {};

    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return decoded.map((routeId, value) {
        final json = Map<String, dynamic>.from(value as Map);
        json['routeId'] = routeId;
        return MapEntry(routeId, HeritageRouteProgress.fromJson(json));
      });
    } catch (_) {
      return {};
    }
  }

  Future<HeritageRouteProgress> toggleVisited({
    required HeritageRoute route,
    required String objectId,
    required HeritageRouteProgress current,
  }) async {
    final visited = Set<String>.from(current.visitedObjectIds)
      ..retainAll(route.objectIds);

    if (!visited.add(objectId)) {
      visited.remove(objectId);
    }

    final isCompleted =
        route.objectIds.isNotEmpty && route.objectIds.every(visited.contains);
    final updated = HeritageRouteProgress(
      routeId: route.id,
      visitedObjectIds: visited,
      completedAt: isCompleted ? current.completedAt ?? DateTime.now() : null,
    );

    final allProgress = await loadAll();
    allProgress[route.id] = updated;
    await _saveAll(allProgress);
    return updated;
  }

  Future<void> _saveAll(
    Map<String, HeritageRouteProgress> progressByRouteId,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = progressByRouteId.map(
      (routeId, progress) => MapEntry(routeId, progress.toJson()),
    );
    await preferences.setString(storageKey, jsonEncode(payload));
  }
}

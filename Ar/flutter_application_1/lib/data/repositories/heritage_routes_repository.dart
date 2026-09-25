import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/heritage_route.dart';

class HeritageRoutesRepository {
  static List<HeritageRoute>? _cachedRoutes;

  Future<List<HeritageRoute>> loadRoutes() async {
    final cached = _cachedRoutes;
    if (cached != null) return cached;

    final localRoutes = await loadLocalRoutes();
    try {
      final serverRoutes = await _loadSupabaseRoutes().timeout(
        const Duration(seconds: 8),
      );
      if (serverRoutes.isNotEmpty) {
        _cachedRoutes = serverRoutes;
        return serverRoutes;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Routes fallback to local JSON: $error');
      }
    }

    _cachedRoutes = localRoutes;
    return localRoutes;
  }

  Future<List<HeritageRoute>> loadLocalRoutes() async {
    final source = await rootBundle.loadString('assets/data/routes.json');
    return parseLocalRoutes(source);
  }

  @visibleForTesting
  static List<HeritageRoute> parseLocalRoutes(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final routes = decoded['routes'] as List<dynamic>? ?? const [];
    return routes
        .map(
          (row) =>
              HeritageRoute.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where((route) => route.id.isNotEmpty && route.objectIds.length >= 2)
        .toList();
  }

  @visibleForTesting
  static List<HeritageRoute> mapSupabaseRows({
    required List<Map<String, dynamic>> routeRows,
    required List<Map<String, dynamic>> stopRows,
  }) {
    final stopsByRouteId = <String, List<Map<String, dynamic>>>{};
    for (final stop in stopRows) {
      final routeId = stop['route_id']?.toString() ?? '';
      if (routeId.isEmpty) continue;
      stopsByRouteId.putIfAbsent(routeId, () => []).add(stop);
    }

    for (final stops in stopsByRouteId.values) {
      stops.sort(
        (left, right) => ((left['sort_order'] as num?)?.toInt() ?? 0).compareTo(
          (right['sort_order'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return routeRows
        .where((row) => row['published'] as bool? ?? true)
        .map((row) {
          final id = row['id']?.toString() ?? '';
          final objectIds = (stopsByRouteId[id] ?? const [])
              .map((stop) => stop['object_id']?.toString() ?? '')
              .where((objectId) => objectId.isNotEmpty)
              .toList();
          return HeritageRoute(
            id: id,
            name: row['name']?.toString() ?? '',
            description: row['description']?.toString() ?? '',
            theme: heritageRouteThemeFromValue(row['theme']),
            objectIds: objectIds,
            durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
            distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 0,
          );
        })
        .where((route) => route.id.isNotEmpty && route.objectIds.length >= 2)
        .toList();
  }

  Future<List<HeritageRoute>> _loadSupabaseRoutes() async {
    final client = Supabase.instance.client;
    final rawRoutes = await client
        .from('heritage_routes')
        .select()
        .eq('published', true)
        .order('sort_order', ascending: true);
    final routeRows = (rawRoutes as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (routeRows.isEmpty) return const [];

    final routeIds = routeRows.map((row) => row['id'].toString()).toList();
    final rawStops = await client
        .from('heritage_route_stops')
        .select()
        .inFilter('route_id', routeIds)
        .order('sort_order', ascending: true);
    final stopRows = (rawStops as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    return mapSupabaseRows(routeRows: routeRows, stopRows: stopRows);
  }
}

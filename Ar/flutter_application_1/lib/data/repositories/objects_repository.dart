// lib/data/repositories/objects_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ar_experience.dart';
import '../../models/historical_object.dart';
import '../../models/panorama_year.dart';

class ObjectsRepository {
  static List<HistoricalObject>? _cachedObjects;

  static Future<List<HistoricalObject>> loadObjects() async {
    if (_cachedObjects != null) return _cachedObjects!;

    try {
      final localObjects = await loadLocalObjects();
      final supabaseObjects = await _loadSupabaseObjects(localObjects);

      if (supabaseObjects.isNotEmpty) {
        _cachedObjects = supabaseObjects;
        if (kDebugMode) {
          debugPrint('Loaded ${supabaseObjects.length} objects from Supabase');
        }
        return supabaseObjects;
      }

      _cachedObjects = localObjects;
      return localObjects;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading objects from Supabase, using JSON: $e');
      }

      final localObjects = await loadLocalObjects();
      _cachedObjects = localObjects;
      return localObjects;
    }
  }

  static Future<List<HistoricalObject>> loadLocalObjects() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/objects.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> objectsJson = data['objects'];

      final List<HistoricalObject> objects = objectsJson.map((json) {
        return HistoricalObject.fromJson(json as Map<String, dynamic>);
      }).toList();

      if (kDebugMode) {
        debugPrint('Loaded ${objects.length} objects from JSON');
      }
      return objects;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading objects from JSON: $e');
      }
      return _getFallbackObjects();
    }
  }

  @visibleForTesting
  static List<HistoricalObject> mapSupabaseRows({
    required List<Map<String, dynamic>> objectRows,
    required List<Map<String, dynamic>> epochRows,
    required List<Map<String, dynamic>> arAssetRows,
    List<HistoricalObject> localFallbackObjects = const [],
  }) {
    final localById = {
      for (final object in localFallbackObjects) object.id: object,
    };
    final epochsByObjectId = <String, List<PanoramaYear>>{};
    final arAssetsByObjectId = <String, List<ArExperience>>{};

    for (final row in epochRows) {
      if (row['published'] == false) continue;

      final objectId = _readString(row['object_id']);
      final imagePath = _firstNonEmpty([
        row['panorama_url'],
        row['panorama_asset_path'],
      ]);
      if (objectId.isEmpty || imagePath == null) continue;

      epochsByObjectId
          .putIfAbsent(objectId, () => [])
          .add(
            PanoramaYear(
              year: _readString(row['year']),
              label: _readString(row['label']).isEmpty
                  ? _readString(row['year'])
                  : _readString(row['label']),
              imagePath: imagePath,
            ),
          );
    }

    for (final row in arAssetRows) {
      if (row['published'] == false) continue;

      final objectId = _readString(row['object_id']);
      if (objectId.isEmpty) {
        continue;
      }

      final experience = ArExperience(
        enabled: row['published'] as bool? ?? true,
        epochYear: _emptyToNull(row['epoch_year']),
        glbUrl: _emptyToNull(row['glb_url']),
        usdzUrl: _emptyToNull(row['usdz_url']),
        glbAssetPath: _emptyToNull(row['glb_asset_path']),
        usdzAssetPath: _emptyToNull(row['usdz_asset_path']),
        scale: (row['scale'] as num?)?.toDouble() ?? 1.0,
        placement: _emptyToNull(row['placement']) ?? 'plane',
      );

      if (experience.hasModelReference) {
        arAssetsByObjectId.putIfAbsent(objectId, () => []).add(experience);
      }
    }

    final objects = objectRows
        .where((row) => row['published'] as bool? ?? true)
        .map((row) {
          final id = _readString(row['id']);
          final local = localById[id];
          final panoramas = List<PanoramaYear>.from(
            epochsByObjectId[id] ?? const <PanoramaYear>[],
          );
          final arExperiences = List<ArExperience>.from(
            arAssetsByObjectId[id] ?? const <ArExperience>[],
          );
          panoramas.sort(
            (a, b) => _parseYear(a.year).compareTo(_parseYear(b.year)),
          );

          arExperiences.sort(
            (a, b) => _parseYear(
              a.epochYear ?? '',
            ).compareTo(_parseYear(b.epochYear ?? '')),
          );

          return HistoricalObject(
            id: id,
            name: _readString(row['name'], fallback: local?.name),
            century: _readString(row['century'], fallback: local?.century),
            architectureType: _readString(
              row['architecture_type'],
              fallback: local?.architectureType,
            ),
            address: _readString(row['address'], fallback: local?.address),
            yearsOfExistence: _readString(
              row['years_of_existence'],
              fallback: local?.yearsOfExistence,
            ),
            sources: _readString(row['sources'], fallback: local?.sources),
            shortDescription: _readString(
              row['short_description'],
              fallback: local?.shortDescription,
            ),
            detailedDescription: _readString(
              row['detailed_description'],
              fallback: local?.detailedDescription,
            ),
            imageAsset:
                _firstNonEmpty([
                  row['cover_image_asset'],
                  row['cover_image_url'],
                  local?.imageAsset,
                ]) ??
                'assets/images/mayak.jpg',
            latitude:
                (row['latitude'] as num?)?.toDouble() ?? local?.latitude ?? 0,
            longitude:
                (row['longitude'] as num?)?.toDouble() ?? local?.longitude ?? 0,
            simpleQuestions: local?.simpleQuestions ?? const [],
            hardQuestions: local?.hardQuestions ?? const [],
            panoramas: panoramas,
            arExperience: arExperiences.isNotEmpty
                ? arExperiences.first
                : local?.arExperience,
            arExperiences: arExperiences,
          );
        })
        .where((object) => object.id.isNotEmpty)
        .toList();

    objects.sort((a, b) => a.name.compareTo(b.name));
    return objects;
  }

  static Future<List<HistoricalObject>> _loadSupabaseObjects(
    List<HistoricalObject> localFallbackObjects,
  ) async {
    final client = Supabase.instance.client;
    final objectRows = await client
        .from('heritage_objects')
        .select(
          'id,name,century,architecture_type,address,years_of_existence,sources,short_description,detailed_description,cover_image_url,cover_image_asset,latitude,longitude,published',
        )
        .eq('published', true)
        .order('name', ascending: true);

    final objectMaps = objectRows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    final objectIds = objectMaps
        .map((row) => _readString(row['id']))
        .where((id) => id.isNotEmpty)
        .toList();
    if (objectIds.isEmpty) return const [];

    final epochRows = await client
        .from('heritage_epochs')
        .select(
          'id,object_id,year,label,panorama_url,panorama_asset_path,sort_order,published',
        )
        .inFilter('object_id', objectIds)
        .eq('published', true)
        .order('sort_order', ascending: true);

    final arAssetRows = await _loadSupabaseArAssetRows(client, objectIds);

    return mapSupabaseRows(
      objectRows: objectMaps,
      epochRows: epochRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      arAssetRows: arAssetRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      localFallbackObjects: localFallbackObjects,
    );
  }

  static Future<List<Map<String, dynamic>>> _loadSupabaseArAssetRows(
    SupabaseClient client,
    List<String> objectIds,
  ) async {
    try {
      final rows = await client
          .from('heritage_ar_assets')
          .select(
            'id,object_id,title,epoch_year,glb_url,usdz_url,glb_asset_path,usdz_asset_path,scale,placement,published',
          )
          .inFilter('object_id', objectIds)
          .eq('published', true)
          .order('created_at', ascending: true);

      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (error) {
      if (!_isMissingEpochYearColumn(error)) rethrow;

      final rows = await client
          .from('heritage_ar_assets')
          .select(
            'id,object_id,title,glb_url,usdz_url,glb_asset_path,usdz_asset_path,scale,placement,published',
          )
          .inFilter('object_id', objectIds)
          .eq('published', true)
          .order('created_at', ascending: true);

      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    }
  }

  static List<HistoricalObject> _getFallbackObjects() {
    return [
      HistoricalObject(
        id: 'water_mill',
        name: 'Водяная мельница',
        century: 'XVIII век',
        architectureType: 'Промышленная архитектура',
        address: 'ул. Мельничная, 15',
        yearsOfExistence: '1750-1942',
        sources: 'Архив города, Музей',
        imageAsset: 'assets/images/water_mill.jpg',
        shortDescription: 'Водяная мельница была построена в 1745 году.',
        detailedDescription: 'Подробное описание...',
        simpleQuestions: [],
        hardQuestions: [],
        latitude: 48.71555933681238,
        longitude: 44.53295195641159,
        panoramas: [],
      ),
    ];
  }

  static void clearCache() {
    _cachedObjects = null;
  }

  static String _readString(Object? value, {String? fallback}) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
    return fallback ?? '';
  }

  static String? _emptyToNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _emptyToNull(value);
      if (text != null) return text;
    }
    return null;
  }

  static bool _isMissingEpochYearColumn(Object error) {
    if (error is! PostgrestException) return false;
    final message = error.message.toLowerCase();
    return error.code == '42703' && message.contains('epoch_year');
  }

  static int _parseYear(String year) {
    final match = RegExp(r'(\d{4})').firstMatch(year);
    return match == null ? 0 : int.parse(match.group(1)!);
  }
}

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/repositories/objects_repository.dart';
import '../../models/ar_experience.dart';
import '../../models/historical_object.dart';
import '../../models/panorama_year.dart';
import '../models/admin_ar_asset.dart';
import '../models/admin_epoch.dart';
import '../models/admin_heritage_object.dart';

class AdminSessionState {
  final bool isAuthenticated;
  final bool isAdmin;
  final bool schemaReady;
  final String? email;
  final String? role;
  final String? message;

  const AdminSessionState({
    required this.isAuthenticated,
    required this.isAdmin,
    required this.schemaReady,
    this.email,
    this.role,
    this.message,
  });

  const AdminSessionState.signedOut()
    : isAuthenticated = false,
      isAdmin = false,
      schemaReady = true,
      email = null,
      role = null,
      message = null;
}

class AdminObjectsResult {
  final bool schemaReady;
  final List<AdminHeritageObject> objects;
  final String? message;

  const AdminObjectsResult({
    required this.schemaReady,
    required this.objects,
    this.message,
  });
}

class AdminSaveResult {
  final bool success;
  final String message;

  const AdminSaveResult({required this.success, required this.message});
}

class AdminImportResult {
  final bool success;
  final String message;

  const AdminImportResult({required this.success, required this.message});
}

class AdminEpochsResult {
  final bool success;
  final List<AdminEpoch> epochs;
  final String? message;

  const AdminEpochsResult({
    required this.success,
    required this.epochs,
    this.message,
  });
}

class AdminArAssetsResult {
  final bool success;
  final List<AdminArAsset> assets;
  final String? message;

  const AdminArAssetsResult({
    required this.success,
    required this.assets,
    this.message,
  });
}

class AdminUploadResult {
  final bool success;
  final String message;
  final String? publicUrl;
  final String? storagePath;

  const AdminUploadResult({
    required this.success,
    required this.message,
    this.publicUrl,
    this.storagePath,
  });
}

class AdminRepository {
  AdminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _storageBucket = 'archive-media';

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<AdminSessionState> loadSessionState() async {
    final user = currentUser;
    if (user == null) return const AdminSessionState.signedOut();

    try {
      final profile = await _client
          .from('admin_profiles')
          .select('role,is_active,display_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        return AdminSessionState(
          isAuthenticated: true,
          isAdmin: false,
          schemaReady: true,
          email: user.email,
          message:
              'Пользователь ${user.email ?? user.id} не добавлен в admin_profiles.',
        );
      }

      final isActive = profile['is_active'] as bool? ?? false;
      final role = profile['role']?.toString();

      return AdminSessionState(
        isAuthenticated: true,
        isAdmin: isActive,
        schemaReady: true,
        email: user.email,
        role: role,
        message: isActive ? null : 'Админ-профиль найден, но он отключен.',
      );
    } catch (error) {
      return AdminSessionState(
        isAuthenticated: true,
        isAdmin: false,
        schemaReady: false,
        email: user.email,
        message:
            'Таблицы админки пока недоступны для проекта $_supabaseUrl. '
            'Повторно примените supabase/admin_mvp_schema.sql. '
            'Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminObjectsResult> loadObjects() async {
    try {
      final rows = await _client
          .from('heritage_objects')
          .select(
            'id,name,address,century,architecture_type,latitude,longitude,short_description,published',
          )
          .order('updated_at', ascending: false);

      return AdminObjectsResult(
        schemaReady: true,
        objects: rows.map(AdminHeritageObject.fromSupabase).toList(),
      );
    } catch (_) {
      final localObjects = await ObjectsRepository.loadLocalObjects();
      return AdminObjectsResult(
        schemaReady: false,
        objects: localObjects
            .map(AdminHeritageObject.fromHistoricalObject)
            .toList(),
        message:
            'Supabase-таблицы админки не найдены или недоступны. '
            'Показаны локальные объекты из assets/data/objects.json.',
      );
    }
  }

  Future<AdminSaveResult> upsertObject(AdminHeritageObject object) async {
    final user = currentUser;
    if (user == null) {
      return const AdminSaveResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    try {
      await _client
          .from('heritage_objects')
          .upsert(object.toSupabasePayload(createdBy: user.id));

      return AdminSaveResult(
        success: true,
        message: 'Объект "${object.name}" сохранен.',
      );
    } catch (error) {
      return AdminSaveResult(
        success: false,
        message:
            'Не удалось сохранить объект. Проверьте SQL-схему, RLS и роль администратора. '
            'Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminImportResult> importLocalObjects() async {
    final user = currentUser;
    if (user == null) {
      return const AdminImportResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    try {
      final objects = await ObjectsRepository.loadLocalObjects();
      if (objects.isEmpty) {
        return const AdminImportResult(
          success: false,
          message: 'В локальном JSON нет объектов для импорта.',
        );
      }

      final now = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('heritage_objects')
          .upsert(
            objects
                .map((object) => _objectPayload(object, user.id, now))
                .toList(),
          );

      final epochPayloads = objects
          .expand(
            (object) => object.panoramas.map((panorama) {
              return _epochPayload(object, panorama, now);
            }),
          )
          .toList();

      if (epochPayloads.isNotEmpty) {
        await _client
            .from('heritage_epochs')
            .upsert(epochPayloads, onConflict: 'object_id,year');
      }

      final arPayloads = objects
          .expand(
            (object) => object.allArExperiences
                .where((experience) => experience.hasModelReference)
                .map((experience) => _arAssetPayload(object, experience, now)),
          )
          .toList();

      if (arPayloads.isNotEmpty) {
        await _client
            .from('heritage_ar_assets')
            .upsert(arPayloads, onConflict: 'object_id,title');
      }

      return AdminImportResult(
        success: true,
        message:
            'Импортировано: ${objects.length} объектов, ${epochPayloads.length} эпох, ${arPayloads.length} 3D/AR ассетов.',
      );
    } catch (error) {
      return AdminImportResult(
        success: false,
        message:
            'Не удалось импортировать локальный JSON. Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminEpochsResult> loadEpochs(String objectId) async {
    final cleanObjectId = objectId.trim();
    if (cleanObjectId.isEmpty) {
      return const AdminEpochsResult(success: true, epochs: []);
    }

    try {
      final rows = await _client
          .from('heritage_epochs')
          .select(
            'id,object_id,year,label,description,panorama_url,panorama_asset_path,sort_order,published',
          )
          .eq('object_id', cleanObjectId)
          .order('sort_order', ascending: true)
          .order('year', ascending: true);

      return AdminEpochsResult(
        success: true,
        epochs: rows.map(AdminEpoch.fromSupabase).toList(),
      );
    } catch (error) {
      return AdminEpochsResult(
        success: false,
        epochs: const [],
        message: 'Не удалось загрузить эпохи. Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminSaveResult> upsertEpoch(AdminEpoch epoch) async {
    final user = currentUser;
    if (user == null) {
      return const AdminSaveResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    final objectId = epoch.objectId.trim();
    if (objectId.isEmpty || epoch.year.trim().isEmpty) {
      return const AdminSaveResult(
        success: false,
        message: 'Для эпохи нужны Object ID и год/период.',
      );
    }

    try {
      final payload = epoch.toSupabasePayload(objectId: objectId);
      final epochId = epoch.id?.trim();

      if (epochId == null || epochId.isEmpty) {
        await _client.from('heritage_epochs').insert(payload);
      } else {
        payload.remove('id');
        await _client.from('heritage_epochs').update(payload).eq('id', epochId);
      }

      return AdminSaveResult(
        success: true,
        message: 'Эпоха "${epoch.displayTitle}" сохранена.',
      );
    } catch (error) {
      return AdminSaveResult(
        success: false,
        message:
            'Не удалось сохранить эпоху. Проверьте SQL-схему, RLS и уникальность года для объекта. '
            'Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminSaveResult> deleteEpoch(AdminEpoch epoch) async {
    final user = currentUser;
    if (user == null) {
      return const AdminSaveResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    final epochId = epoch.id?.trim();
    if (epochId == null || epochId.isEmpty) {
      return const AdminSaveResult(
        success: false,
        message: 'Эта эпоха еще не сохранена в Supabase.',
      );
    }

    try {
      await _client.from('heritage_epochs').delete().eq('id', epochId);
      return AdminSaveResult(
        success: true,
        message: 'Эпоха "${epoch.displayTitle}" удалена.',
      );
    } catch (error) {
      return AdminSaveResult(
        success: false,
        message: 'Не удалось удалить эпоху. Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminArAssetsResult> loadArAssets(String objectId) async {
    final cleanObjectId = objectId.trim();
    if (cleanObjectId.isEmpty) {
      return const AdminArAssetsResult(success: true, assets: []);
    }

    try {
      final rows = await _loadArAssetRows(
        cleanObjectId,
        includeEpochYear: true,
      );

      return AdminArAssetsResult(
        success: true,
        assets: rows.map(AdminArAsset.fromSupabase).toList(),
      );
    } catch (error) {
      if (_isMissingEpochYearColumn(error)) {
        try {
          final rows = await _loadArAssetRows(
            cleanObjectId,
            includeEpochYear: false,
          );
          return AdminArAssetsResult(
            success: true,
            assets: rows.map(AdminArAsset.fromSupabase).toList(),
          );
        } catch (fallbackError) {
          return AdminArAssetsResult(
            success: false,
            assets: const [],
            message:
                'Не удалось загрузить 3D/AR ассеты. Ошибка: ${_describeError(fallbackError)}',
          );
        }
      }

      return AdminArAssetsResult(
        success: false,
        assets: const [],
        message:
            'Не удалось загрузить 3D/AR ассеты. Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadArAssetRows(
    String objectId, {
    required bool includeEpochYear,
  }) async {
    final rows = await _client
        .from('heritage_ar_assets')
        .select(
          includeEpochYear
              ? 'id,object_id,title,epoch_year,glb_url,usdz_url,glb_asset_path,usdz_asset_path,scale,placement,published'
              : 'id,object_id,title,glb_url,usdz_url,glb_asset_path,usdz_asset_path,scale,placement,published',
        )
        .eq('object_id', objectId)
        .order('created_at', ascending: true)
        .order('title', ascending: true);

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<AdminSaveResult> upsertArAsset(AdminArAsset asset) async {
    final user = currentUser;
    if (user == null) {
      return const AdminSaveResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    final objectId = asset.objectId.trim();
    if (objectId.isEmpty || asset.title.trim().isEmpty) {
      return const AdminSaveResult(
        success: false,
        message: 'Для 3D/AR ассета нужны Object ID и название.',
      );
    }

    if (!asset.hasModelReference) {
      return const AdminSaveResult(
        success: false,
        message: 'Добавьте .glb/.usdz URL или asset path модели.',
      );
    }

    try {
      final payload = asset.toSupabasePayload(objectId: objectId);
      final assetId = asset.id?.trim();

      if (assetId == null || assetId.isEmpty) {
        await _client.from('heritage_ar_assets').insert(payload);
      } else {
        payload.remove('id');
        await _client
            .from('heritage_ar_assets')
            .update(payload)
            .eq('id', assetId);
      }

      return AdminSaveResult(
        success: true,
        message: '3D/AR ассет "${asset.displayTitle}" сохранен.',
      );
    } catch (error) {
      if (_isMissingEpochYearColumn(error)) {
        return const AdminSaveResult(
          success: false,
          message:
              'В Supabase еще нет колонки epoch_year. Повторно примените supabase/admin_mvp_schema.sql, затем сохраните 3D/AR ассет.',
        );
      }

      return AdminSaveResult(
        success: false,
        message:
            'Не удалось сохранить 3D/AR ассет. Проверьте SQL-схему, RLS и уникальность названия для объекта. '
            'Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminSaveResult> deleteArAsset(AdminArAsset asset) async {
    final user = currentUser;
    if (user == null) {
      return const AdminSaveResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    final assetId = asset.id?.trim();
    if (assetId == null || assetId.isEmpty) {
      return const AdminSaveResult(
        success: false,
        message: 'Этот 3D/AR ассет еще не сохранен в Supabase.',
      );
    }

    try {
      await _client.from('heritage_ar_assets').delete().eq('id', assetId);
      return AdminSaveResult(
        success: true,
        message: '3D/AR ассет "${asset.displayTitle}" удален.',
      );
    } catch (error) {
      return AdminSaveResult(
        success: false,
        message:
            'Не удалось удалить 3D/AR ассет. Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminUploadResult> uploadPanorama({
    required String objectId,
    required String year,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final user = currentUser;
    if (user == null) {
      return const AdminUploadResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    if (bytes.isEmpty) {
      return const AdminUploadResult(
        success: false,
        message: 'Выбран пустой файл.',
      );
    }

    try {
      final cleanObjectId = _sanitizePathSegment(objectId);
      final cleanYear = _sanitizePathSegment(
        year.trim().isEmpty ? 'epoch' : year,
      );
      final safeFileName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final path =
          'objects/$cleanObjectId/panoramas/$cleanYear-$timestamp-$safeFileName';

      await _client.storage
          .from(_storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '31536000',
              contentType: _emptyToNull(contentType),
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from(_storageBucket).getPublicUrl(path);
      return AdminUploadResult(
        success: true,
        message: 'Панорама загружена в Supabase Storage.',
        publicUrl: publicUrl,
        storagePath: path,
      );
    } catch (error) {
      return AdminUploadResult(
        success: false,
        message:
            'Не удалось загрузить панораму в Storage bucket $_storageBucket. '
            'Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<AdminUploadResult> uploadArModel({
    required String objectId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final user = currentUser;
    if (user == null) {
      return const AdminUploadResult(
        success: false,
        message: 'Нужно войти в админку.',
      );
    }

    if (bytes.isEmpty) {
      return const AdminUploadResult(
        success: false,
        message: 'Выбран пустой файл.',
      );
    }

    try {
      final cleanObjectId = _sanitizePathSegment(objectId);
      final safeFileName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final path = 'objects/$cleanObjectId/models/$timestamp-$safeFileName';

      await _client.storage
          .from(_storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '31536000',
              contentType: _emptyToNull(contentType),
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from(_storageBucket).getPublicUrl(path);
      return AdminUploadResult(
        success: true,
        message: '3D-модель загружена в Supabase Storage.',
        publicUrl: publicUrl,
        storagePath: path,
      );
    } catch (error) {
      return AdminUploadResult(
        success: false,
        message:
            'Не удалось загрузить 3D-модель в Storage bucket $_storageBucket. '
            'Ошибка: ${_describeError(error)}',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Map<String, dynamic> _objectPayload(
    HistoricalObject object,
    String userId,
    String now,
  ) {
    return {
      'id': object.id,
      'name': object.name,
      'century': object.century,
      'architecture_type': object.architectureType,
      'address': object.address,
      'years_of_existence': object.yearsOfExistence,
      'sources': object.sources,
      'short_description': object.shortDescription,
      'detailed_description': object.detailedDescription,
      'cover_image_asset': object.imageAsset,
      'latitude': object.latitude,
      'longitude': object.longitude,
      'published': true,
      'created_by': userId,
      'updated_at': now,
    };
  }

  Map<String, dynamic> _epochPayload(
    HistoricalObject object,
    PanoramaYear panorama,
    String now,
  ) {
    return {
      'object_id': object.id,
      'year': panorama.year,
      'label': panorama.label,
      'description': '',
      'panorama_asset_path': panorama.imagePath,
      'sort_order': _parseYear(panorama.year),
      'published': true,
      'updated_at': now,
    };
  }

  Map<String, dynamic> _arAssetPayload(
    HistoricalObject object,
    ArExperience experience,
    String now,
  ) {
    final epochYear = _emptyToNull(experience.epochYear);
    final title = epochYear == null
        ? '${object.id}_default'
        : '${object.id}_${_sanitizePathSegment(epochYear)}';

    return {
      'object_id': object.id,
      'title': title,
      'epoch_year': epochYear,
      'glb_url': experience.glbUrl,
      'usdz_url': experience.usdzUrl,
      'glb_asset_path': experience.glbAssetPath,
      'usdz_asset_path': experience.usdzAssetPath,
      'scale': experience.scale,
      'placement': experience.placement,
      'published': experience.enabled,
      'updated_at': now,
    };
  }

  int _parseYear(String year) {
    final match = RegExp(r'(\d{4})').firstMatch(year);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  String get _supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'SUPABASE_URL не найден';

  bool _isMissingEpochYearColumn(Object error) {
    if (error is! PostgrestException) return false;
    final message = error.message.toLowerCase();
    return error.code == '42703' && message.contains('epoch_year');
  }

  String _describeError(Object error) {
    if (error is PostgrestException) {
      final details = error.details?.toString();
      final hint = error.hint?.toString();
      return [
        if (error.code != null) error.code,
        error.message,
        if (details != null && details.isNotEmpty) details,
        if (hint != null && hint.isNotEmpty) hint,
      ].join(' · ');
    }

    if (error is StorageException) {
      return [
        error.message,
        if (error.statusCode != null) 'status ${error.statusCode}',
        if (error.error != null) error.error,
      ].join(' · ');
    }

    if (error is AuthException) return error.message;
    return error.toString();
  }

  String _sanitizePathSegment(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'item' : normalized;
  }

  String _sanitizeFileName(String fileName) {
    final raw = fileName.trim().replaceAll('\\', '/').split('/').last;
    final lower = raw.toLowerCase();
    final extensionMatch = RegExp(r'\.([a-z0-9]{2,5})$').firstMatch(lower);
    final extension = extensionMatch?.group(1);
    final safeExtension = switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' => extension!,
      _ => 'jpg',
    };
    final withoutExtension = extensionMatch == null
        ? lower
        : lower.substring(0, extensionMatch.start);
    final safeBase = withoutExtension
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${safeBase.isEmpty ? 'panorama' : safeBase}.$safeExtension';
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

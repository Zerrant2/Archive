import 'package:flutter/services.dart';

import '../models/ar_experience.dart';
import '../models/historical_object.dart';

enum ArExperienceState {
  notConfigured,
  localAssetsMissing,
  externalViewerReady,
  localPreviewReady,
}

class ArExperienceAvailability {
  final ArExperienceState state;
  final ArExperience? experience;
  final List<String> missingAssetPaths;

  const ArExperienceAvailability({
    required this.state,
    this.experience,
    this.missingAssetPaths = const [],
  });

  bool get canOpenExternalViewer =>
      state == ArExperienceState.externalViewerReady;

  bool get hasAnyReadyAsset =>
      state == ArExperienceState.externalViewerReady ||
      state == ArExperienceState.localPreviewReady;

  bool get hasModelPreview => hasAnyReadyAsset && experience != null;

  bool get hasExternalModelUrl => experience?.hasExternalModelReference == true;

  String get title {
    switch (state) {
      case ArExperienceState.externalViewerReady:
        return 'AR beta';
      case ArExperienceState.localPreviewReady:
        return '3D dev preview';
      case ArExperienceState.localAssetsMissing:
        return '3D asset не найден';
      case ArExperienceState.notConfigured:
        return 'AR/3D готовится';
    }
  }

  String messageFor(String objectName) {
    switch (state) {
      case ArExperienceState.externalViewerReady:
        return 'Для "$objectName" найдена модель для системного AR-viewer.';
      case ArExperienceState.localPreviewReady:
        return 'Для "$objectName" найдена локальная 3D-модель. Для релизного AR лучше использовать публичный URL из Supabase Storage.';
      case ArExperienceState.localAssetsMissing:
        return 'Для "$objectName" указан локальный 3D-файл, но он не входит в сборку: ${missingAssetPaths.join(', ')}. Загрузите модель в Supabase Storage и сохраните glb_url.';
      case ArExperienceState.notConfigured:
        return 'Для "$objectName" пока нет оптимизированной 3D-модели. Исторический вид доступен через 360-панораму.';
    }
  }
}

class ArExperienceService {
  const ArExperienceService._();

  static Future<ArExperienceAvailability> availabilityFor(
    HistoricalObject object, {
    String? epochYear,
  }) async {
    return availabilityForExperience(object.arExperienceForYear(epochYear));
  }

  static Future<ArExperienceAvailability> availabilityForExperience(
    ArExperience? experience, {
    Set<String>? availableAssets,
  }) async {
    if (experience == null ||
        !experience.enabled ||
        !experience.hasModelReference) {
      return const ArExperienceAvailability(
        state: ArExperienceState.notConfigured,
      );
    }

    if (experience.hasExternalModelReference) {
      return ArExperienceAvailability(
        state: ArExperienceState.externalViewerReady,
        experience: experience,
      );
    }

    if (experience.hasLocalModelReference) {
      final assets = availableAssets ?? await loadAvailableAssetPaths();
      final missingAssets = experience.localAssetPaths
          .where((path) => !assets.contains(path))
          .toList();

      if (missingAssets.isNotEmpty) {
        return ArExperienceAvailability(
          state: ArExperienceState.localAssetsMissing,
          experience: experience,
          missingAssetPaths: missingAssets,
        );
      }
    }

    return ArExperienceAvailability(
      state: ArExperienceState.localPreviewReady,
      experience: experience,
    );
  }

  static Future<Map<String, ArExperienceAvailability>>
  availabilityByEpochYearFor(HistoricalObject object) async {
    final availableAssets = await loadAvailableAssetPaths();
    final result = <String, ArExperienceAvailability>{};

    for (final experience in object.allArExperiences) {
      final key = experience.epochYear?.trim() ?? '';
      result[key] = await availabilityForExperience(
        experience,
        availableAssets: availableAssets,
      );
    }

    return result;
  }

  static Future<Set<String>> loadAvailableAssetPaths() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets().toSet();
  }
}

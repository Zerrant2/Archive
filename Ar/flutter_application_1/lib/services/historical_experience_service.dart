import '../models/historical_object.dart';
import '../models/panorama_year.dart';
import 'ar_experience_service.dart';
import 'panorama_availability_service.dart';

class HistoricalExperienceAvailability {
  final List<PanoramaYear> availablePanoramas;
  final ArExperienceAvailability arAvailability;
  final Map<String, ArExperienceAvailability> arAvailabilityByEpochYear;

  const HistoricalExperienceAvailability({
    required this.availablePanoramas,
    required this.arAvailability,
    this.arAvailabilityByEpochYear = const {},
  });

  bool get hasPanoramas => availablePanoramas.isNotEmpty;

  bool get has3dMode =>
      arAvailability.hasAnyReadyAsset ||
      arAvailabilityByEpochYear.values.any(
        (availability) => availability.hasAnyReadyAsset,
      );

  bool get hasLocal3dPreview =>
      arAvailability.state == ArExperienceState.localPreviewReady;

  bool get hasExternalArViewer =>
      arAvailability.state == ArExperienceState.externalViewerReady;

  bool get canOpen => hasPanoramas || has3dMode;

  ArExperienceAvailability arAvailabilityFor(PanoramaYear? panorama) {
    final year = panorama?.year.trim();
    if (year != null && year.isNotEmpty) {
      final exact = arAvailabilityByEpochYear[year];
      if (exact != null) return exact;
    }

    return arAvailabilityByEpochYear[''] ?? arAvailability;
  }

  String unavailableMessageFor(String objectName) {
    if (arAvailability.state == ArExperienceState.localAssetsMissing) {
      return arAvailability.messageFor(objectName);
    }

    return 'Для "$objectName" пока нет готовой панорамы или 3D-модели.';
  }
}

class HistoricalExperienceService {
  const HistoricalExperienceService._();

  static Future<HistoricalExperienceAvailability> availabilityFor(
    HistoricalObject object,
  ) async {
    final availableAssetPaths =
        await PanoramaAvailabilityService.loadAvailableAssetPaths();
    final arAvailabilityByEpochYear =
        await ArExperienceService.availabilityByEpochYearFor(object);
    final arAvailability =
        arAvailabilityByEpochYear[''] ??
        const ArExperienceAvailability(state: ArExperienceState.notConfigured);

    return HistoricalExperienceAvailability(
      availablePanoramas: availablePanoramasFor(object, availableAssetPaths),
      arAvailability: arAvailability,
      arAvailabilityByEpochYear: arAvailabilityByEpochYear,
    );
  }

  static bool hasAvailableExperience(
    HistoricalObject object,
    Set<String> availableAssetPaths,
  ) {
    if (availablePanoramasFor(object, availableAssetPaths).isNotEmpty) {
      return true;
    }

    final experiences = object.allArExperiences;
    if (experiences.isEmpty) {
      return false;
    }

    for (final experience in experiences) {
      if (!experience.enabled || !experience.hasModelReference) continue;

      if (experience.hasExternalModelReference) return true;

      if (experience.hasLocalModelReference &&
          experience.localAssetPaths.every(availableAssetPaths.contains)) {
        return true;
      }
    }

    return false;
  }

  static List<PanoramaYear> availablePanoramasFor(
    HistoricalObject object,
    Set<String> availableAssetPaths,
  ) {
    final panoramas = object.panoramas
        .where(
          (panorama) =>
              panorama.isRemoteImage ||
              availableAssetPaths.contains(panorama.imagePath),
        )
        .toList();

    panoramas.sort((a, b) => _parseYear(a.year).compareTo(_parseYear(b.year)));
    return panoramas;
  }

  static int _parseYear(String year) {
    final match = RegExp(r'(\d{4})').firstMatch(year);
    return match == null ? 0 : int.parse(match.group(1)!);
  }
}

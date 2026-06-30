import 'package:flutter/services.dart';

import '../models/historical_object.dart';

class PanoramaAvailabilityService {
  const PanoramaAvailabilityService._();

  static Future<Set<String>>? _assetPathsFuture;

  static Future<Set<String>> loadAvailableAssetPaths() {
    return _assetPathsFuture ??= AssetManifest.loadFromAssetBundle(
      rootBundle,
    ).then((manifest) => manifest.listAssets().toSet());
  }

  static Future<bool> hasAvailablePanoramasAsync(
    HistoricalObject object,
  ) async {
    final assetPaths = await loadAvailableAssetPaths();
    return hasAvailablePanoramas(object, assetPaths);
  }

  static bool hasAvailablePanoramas(
    HistoricalObject object,
    Set<String> assetPaths,
  ) {
    if (object.panoramas.isEmpty) return false;

    return object.panoramas.any((panorama) {
      return panorama.isRemoteImage || assetPaths.contains(panorama.imagePath);
    });
  }
}

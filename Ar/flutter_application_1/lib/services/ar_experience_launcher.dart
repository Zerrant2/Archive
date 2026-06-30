import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ar_experience.dart';

enum ArLaunchStatus {
  launched,
  noExternalModelUrl,
  unsupportedPlatform,
  launchFailed,
}

class ArLaunchResult {
  final ArLaunchStatus status;
  final String message;

  const ArLaunchResult({required this.status, required this.message});

  bool get launched => status == ArLaunchStatus.launched;
}

class ArExperienceLauncher {
  const ArExperienceLauncher._();

  static Future<ArLaunchResult> launchExternalViewer({
    required ArExperience experience,
    required String objectName,
  }) async {
    if (kIsWeb) {
      return _launchPlainModelUrl(experience, objectName);
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _launchAndroidSceneViewer(
        experience,
        objectName,
      ),
      TargetPlatform.iOS => _launchIosQuickLook(experience, objectName),
      _ => _launchPlainModelUrl(experience, objectName),
    };
  }

  static Future<ArLaunchResult> _launchAndroidSceneViewer(
    ArExperience experience,
    String objectName,
  ) async {
    final glbUrl = _firstNonEmpty([experience.glbUrl]);
    if (glbUrl == null) {
      return const ArLaunchResult(
        status: ArLaunchStatus.noExternalModelUrl,
        message: 'Для Android AR нужен публичный .glb URL модели.',
      );
    }

    final sceneViewerUrl = Uri.encodeComponent(glbUrl);
    final fallbackUrl = Uri.encodeComponent(glbUrl);
    final title = Uri.encodeComponent(objectName);
    final uri = Uri.parse(
      'intent://arvr.google.com/scene-viewer/1.0'
      '?file=$sceneViewerUrl'
      '&mode=ar_preferred'
      '&title=$title'
      '#Intent;scheme=https;package=com.google.ar.core;'
      'action=android.intent.action.VIEW;'
      'S.browser_fallback_url=$fallbackUrl;end;',
    );

    return _tryLaunch(
      uri,
      successMessage: 'Открываем "$objectName" в системном AR-viewer.',
      failureMessage:
          'Не удалось открыть Scene Viewer. Возможно, устройство не поддерживает ARCore или модель недоступна.',
    );
  }

  static Future<ArLaunchResult> _launchIosQuickLook(
    ArExperience experience,
    String objectName,
  ) async {
    final usdzUrl = _firstNonEmpty([experience.usdzUrl]);
    if (usdzUrl == null) {
      return const ArLaunchResult(
        status: ArLaunchStatus.noExternalModelUrl,
        message: 'Для iOS AR нужен публичный .usdz URL модели.',
      );
    }

    return _tryLaunch(
      Uri.parse(usdzUrl),
      successMessage: 'Открываем "$objectName" в Quick Look.',
      failureMessage:
          'Не удалось открыть Quick Look. Проверьте, что .usdz URL доступен с телефона.',
    );
  }

  static Future<ArLaunchResult> _launchPlainModelUrl(
    ArExperience experience,
    String objectName,
  ) async {
    final modelUrl = _firstNonEmpty([experience.glbUrl, experience.usdzUrl]);
    if (modelUrl == null) {
      return const ArLaunchResult(
        status: ArLaunchStatus.noExternalModelUrl,
        message:
            'Для внешнего AR-viewer нужна публичная ссылка на .glb или .usdz модель.',
      );
    }

    return _tryLaunch(
      Uri.parse(modelUrl),
      successMessage: 'Открываем 3D-модель "$objectName".',
      failureMessage:
          'Не удалось открыть ссылку на 3D-модель. Проверьте URL модели.',
    );
  }

  static Future<ArLaunchResult> _tryLaunch(
    Uri uri, {
    required String successMessage,
    required String failureMessage,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        return ArLaunchResult(
          status: ArLaunchStatus.launchFailed,
          message: failureMessage,
        );
      }

      return ArLaunchResult(
        status: ArLaunchStatus.launched,
        message: successMessage,
      );
    } catch (_) {
      return ArLaunchResult(
        status: ArLaunchStatus.launchFailed,
        message: failureMessage,
      );
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }

    return null;
  }
}

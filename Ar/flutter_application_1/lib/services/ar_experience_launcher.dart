import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

enum ArPreflightStatus {
  ready,
  installRequested,
  checking,
  unsupported,
  failed,
}

class ArPreflightResult {
  final ArPreflightStatus status;
  final String message;

  const ArPreflightResult({required this.status, required this.message});

  bool get ready => status == ArPreflightStatus.ready;
}

class ArExperienceLauncher {
  const ArExperienceLauncher._();

  static const MethodChannel _deviceChannel = MethodChannel(
    'retro_ar/device_capabilities',
  );

  static Future<ArPreflightResult> prepareEmbeddedAr() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const ArPreflightResult(
        status: ArPreflightStatus.ready,
        message: 'AR готов к запуску.',
      );
    }

    try {
      final raw = await _deviceChannel.invokeMapMethod<String, dynamic>(
        'prepareArCore',
      );
      final status = raw?['status']?.toString();
      final detail = raw?['detail']?.toString() ?? '';

      return switch (status) {
        'ready' => const ArPreflightResult(
          status: ArPreflightStatus.ready,
          message: 'ARCore готов к запуску.',
        ),
        'install_requested' => const ArPreflightResult(
          status: ArPreflightStatus.installRequested,
          message:
              'Установите или обновите Google Play Services for AR, затем нажмите AR еще раз.',
        ),
        'checking' => const ArPreflightResult(
          status: ArPreflightStatus.checking,
          message:
              'ARCore еще проверяет совместимость. Повторите через несколько секунд.',
        ),
        'unsupported' => const ArPreflightResult(
          status: ArPreflightStatus.unsupported,
          message:
              'Это устройство не подтверждено ARCore. Доступен обычный 3D-просмотр.',
        ),
        _ => ArPreflightResult(
          status: ArPreflightStatus.failed,
          message:
              'Не удалось подготовить ARCore${detail.isEmpty ? '.' : ': $detail.'}',
        ),
      };
    } catch (_) {
      return const ArPreflightResult(
        status: ArPreflightStatus.failed,
        message: 'Не удалось проверить ARCore. Доступен обычный 3D-просмотр.',
      );
    }
  }

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

    final capabilities = await _loadAndroidArCapabilities();
    if (capabilities.useSimplifiedFallback) {
      return ArLaunchResult(
        status: ArLaunchStatus.launchFailed,
        message:
            '${capabilities.fallbackReason} Остаемся во встроенном 3D-просмотре.',
      );
    }

    final launched = await _launchAndroidGoogleSceneViewer(
      glbUrl: glbUrl,
      objectName: objectName,
      mode: 'ar_preferred',
    );

    if (launched) {
      return ArLaunchResult(
        status: ArLaunchStatus.launched,
        message: 'Открываем "$objectName" через Google Scene Viewer с ARCore.',
      );
    }

    return const ArLaunchResult(
      status: ArLaunchStatus.launchFailed,
      message:
          'Google Scene Viewer не запустился. Остаемся во встроенном 3D-просмотре, чтобы не открывать старый AR-обработчик.',
    );
  }

  static Future<bool> _launchAndroidGoogleSceneViewer({
    required String glbUrl,
    required String objectName,
    required String mode,
  }) async {
    try {
      return await _deviceChannel.invokeMethod<bool>('launchSceneViewer', {
            'glbUrl': glbUrl,
            'title': objectName,
            'mode': mode,
          }) ??
          false;
    } catch (_) {
      return false;
    }
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
    LaunchMode mode = LaunchMode.externalApplication,
    required String successMessage,
    required String failureMessage,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: mode);

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

  static Future<_AndroidArCapabilities> _loadAndroidArCapabilities() async {
    try {
      final raw = await _deviceChannel.invokeMapMethod<String, dynamic>(
        'getArCapabilities',
      );
      return _AndroidArCapabilities.fromMap(raw ?? const {});
    } catch (_) {
      return const _AndroidArCapabilities.unknown();
    }
  }
}

class _AndroidArCapabilities {
  final bool isKnown;
  final bool hasCameraArFeature;
  final bool arCoreInstalled;
  final bool googleAppInstalled;
  final bool googlePlayServicesInstalled;
  final bool likelyChinaMarketWithoutGoogle;

  const _AndroidArCapabilities({
    required this.isKnown,
    required this.hasCameraArFeature,
    required this.arCoreInstalled,
    required this.googleAppInstalled,
    required this.googlePlayServicesInstalled,
    required this.likelyChinaMarketWithoutGoogle,
  });

  const _AndroidArCapabilities.unknown()
    : isKnown = false,
      hasCameraArFeature = false,
      arCoreInstalled = false,
      googleAppInstalled = false,
      googlePlayServicesInstalled = false,
      likelyChinaMarketWithoutGoogle = false;

  factory _AndroidArCapabilities.fromMap(Map<String, dynamic> map) {
    return _AndroidArCapabilities(
      isKnown: true,
      hasCameraArFeature: map['hasCameraArFeature'] == true,
      arCoreInstalled: map['arCoreInstalled'] == true,
      googleAppInstalled: map['googleAppInstalled'] == true,
      googlePlayServicesInstalled: map['googlePlayServicesInstalled'] == true,
      likelyChinaMarketWithoutGoogle:
          map['likelyChinaMarketWithoutGoogle'] == true,
    );
  }

  bool get canUseFullSceneViewer {
    if (!isKnown) return true;
    return arCoreInstalled &&
        googleAppInstalled &&
        googlePlayServicesInstalled &&
        !likelyChinaMarketWithoutGoogle;
  }

  bool get useSimplifiedFallback => isKnown && !canUseFullSceneViewer;

  String get fallbackReason {
    if (likelyChinaMarketWithoutGoogle) {
      return 'На устройстве не найден полный набор Google-сервисов для Scene Viewer.';
    }
    if (!arCoreInstalled) {
      return 'ARCore не найден на этом устройстве.';
    }
    if (!googleAppInstalled || !googlePlayServicesInstalled) {
      return 'Google Scene Viewer недоступен без Google App и Google Play Services.';
    }
    return 'Системный AR-viewer недоступен.';
  }
}

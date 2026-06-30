import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../theme/app_colors.dart';

class LoadingModelViewer extends StatefulWidget {
  final String src;
  final String alt;
  final bool ar;
  final List<String> arModes;
  final ArScale arScale;
  final ArPlacement arPlacement;
  final String? iosSrc;
  final String? scale;
  final bool autoRotate;
  final bool cameraControls;
  final bool disableZoom;
  final Color backgroundColor;

  const LoadingModelViewer({
    super.key,
    required this.src,
    required this.alt,
    this.ar = false,
    this.arModes = const ['scene-viewer', 'webxr', 'quick-look'],
    this.arScale = ArScale.auto,
    this.arPlacement = ArPlacement.floor,
    this.iosSrc,
    this.scale,
    this.autoRotate = true,
    this.cameraControls = true,
    this.disableZoom = false,
    this.backgroundColor = const Color(0xFFF5F0E8),
  });

  @override
  State<LoadingModelViewer> createState() => _LoadingModelViewerState();
}

class _LoadingModelViewerState extends State<LoadingModelViewer> {
  static const _bridgeName = 'RetroArModelLoadBridge';

  bool _isLoading = true;
  bool _hasError = false;
  double? _progress;
  Timer? _webFallbackTimer;

  @override
  void initState() {
    super.initState();
    _resetLoadingState();
  }

  @override
  void didUpdateWidget(covariant LoadingModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _resetLoadingState();
    }
  }

  @override
  void dispose() {
    _webFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ModelViewer(
            key: ValueKey(widget.src),
            src: widget.src,
            alt: widget.alt,
            loading: Loading.eager,
            reveal: Reveal.auto,
            ar: widget.ar,
            arModes: widget.arModes,
            arScale: widget.arScale,
            arPlacement: widget.arPlacement,
            iosSrc: widget.iosSrc,
            scale: widget.scale,
            autoRotate: widget.autoRotate,
            cameraControls: widget.cameraControls,
            disableZoom: widget.disableZoom,
            backgroundColor: widget.backgroundColor,
            debugLogging: false,
            javascriptChannels: {
              JavascriptChannel(
                _bridgeName,
                onMessageReceived: (message) {
                  _handleBridgeMessage(message.message);
                },
              ),
            },
            relatedJs: _bridgeScript,
          ),
        ),
        if (_isLoading)
          Positioned.fill(child: _ModelLoadingOverlay(progress: _progress)),
        if (_hasError) const Positioned.fill(child: _ModelLoadingError()),
      ],
    );
  }

  void _resetLoadingState() {
    _webFallbackTimer?.cancel();

    _isLoading = true;
    _hasError = false;
    _progress = null;

    if (kIsWeb) {
      _webFallbackTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  void _handleBridgeMessage(String rawMessage) {
    if (!mounted) return;

    final payload = _decodeBridgePayload(rawMessage);
    final event = payload['event']?.toString();
    final progress = payload['progress'];

    if (event == 'progress' && progress is num) {
      setState(() {
        _progress = progress.toDouble().clamp(0.0, 1.0);
      });
      return;
    }

    if (event == 'load') {
      setState(() {
        _isLoading = false;
        _hasError = false;
        _progress = 1;
      });
      return;
    }

    if (event == 'error') {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Map<String, Object?> _decodeBridgePayload(String rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return {'event': rawMessage};
    }
    return {'event': rawMessage};
  }

  static const _bridgeScript =
      '''
(function () {
  var post = function (payload) {
    try {
      var channel = window.$_bridgeName;
      if (channel && channel.postMessage) {
        channel.postMessage(JSON.stringify(payload));
      }
    } catch (_) {}
  };

  var attach = function () {
    var viewer = document.querySelector('model-viewer');
    if (!viewer) {
      window.setTimeout(attach, 60);
      return;
    }

    post({ event: 'ready' });

    viewer.addEventListener('progress', function (event) {
      var progress = event.detail && event.detail.totalProgress;
      post({
        event: 'progress',
        progress: typeof progress === 'number' ? progress : null
      });
    });

    viewer.addEventListener('load', function () {
      post({ event: 'load', progress: 1 });
    });

    viewer.addEventListener('error', function () {
      post({ event: 'error' });
    });
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', attach);
  } else {
    attach();
  }
})();
''';
}

class _ModelLoadingOverlay extends StatelessWidget {
  final double? progress;

  const _ModelLoadingOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress;
    final progressText = normalizedProgress == null
        ? null
        : '${(normalizedProgress * 100).round()}%';

    return ColoredBox(
      color: const Color(0xFFF5F0E8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primaryRed,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                progressText == null
                    ? 'Загружаем 3D-модель'
                    : 'Загружаем 3D-модель $progressText',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: normalizedProgress,
                minHeight: 4,
                color: AppColors.primaryRed,
                backgroundColor: const Color(0xFFD8C8C2),
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelLoadingError extends StatelessWidget {
  const _ModelLoadingError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5F0E8),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Не удалось загрузить 3D-модель. Проверьте ссылку в админке.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }
}

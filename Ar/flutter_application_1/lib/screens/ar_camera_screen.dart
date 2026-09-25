import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../models/ar_experience.dart';
import '../services/ar_experience_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ArCameraScreen extends StatefulWidget {
  final String objectName;
  final ArExperience experience;

  const ArCameraScreen({
    super.key,
    required this.objectName,
    required this.experience,
  });

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARNode? _modelNode;

  bool _isArReady = false;
  bool _isPlacing = false;
  double _scale = 1.0;
  double _distance = 1.5;
  String? _statusText = 'Запускаем AR-камеру';

  String? get _glbUrl {
    final text = widget.experience.glbUrl?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool get _canUseEmbeddedAr {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _scale = widget.experience.scale <= 0
        ? 1.0
        : widget.experience.scale.clamp(0.05, 3.0).toDouble();
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final glbUrl = _glbUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: !_canUseEmbeddedAr || glbUrl == null
                ? _ArCameraUnavailable(
                    objectName: widget.objectName,
                    reason: glbUrl == null
                        ? 'Для AR-камеры нужен публичный .glb URL.'
                        : 'AR-камера доступна только на Android/iOS.',
                  )
                : ARView(
                    onARViewCreated: _onArViewCreated,
                    planeDetectionConfig: PlaneDetectionConfig.none,
                    enableDepth: false,
                    permissionPromptDescription:
                        'Для AR-камеры нужен доступ к камере.',
                    permissionPromptButtonText: 'Разрешить камеру',
                    permissionPromptParentalRestriction:
                        'Доступ к камере ограничен настройками устройства.',
                  ),
          ),
          Positioned(
            top: viewPadding.top + 10,
            left: 12,
            right: 12,
            child: _ArCameraTopBar(
              title: widget.objectName,
              subtitle: 'AR-камера',
              onBack: () => Navigator.pop(context),
              onOpenExternalViewer: _openSceneViewerFallback,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: viewPadding.bottom + 14,
            child: _ArCameraControls(
              statusText: _statusText,
              isArReady: _isArReady,
              isPlacing: _isPlacing,
              scale: _scale,
              distance: _distance,
              onPlace: _placeModelInFront,
              onDecreaseScale: () => _changeScale(-0.15),
              onIncreaseScale: () => _changeScale(0.15),
              onMoveCloser: () => _changeDistance(-0.25),
              onMoveFarther: () => _changeDistance(0.25),
              onOpenExternalViewer: _openSceneViewerFallback,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onArViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    _sessionManager = sessionManager;
    _objectManager = objectManager;

    sessionManager.onError = (error) {
      if (!mounted) return;
      setState(() {
        _isPlacing = false;
        _statusText = 'ARCore не запустил сцену: $error';
      });
    };

    try {
      await sessionManager.onInitialize(
        showAnimatedGuide: false,
        showFeaturePoints: false,
        showPlanes: false,
        showWorldOrigin: false,
        handleTaps: false,
        handlePans: true,
        handleRotation: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Не удалось инициализировать ARCore: $error';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isArReady = true;
      _statusText = 'AR-камера готова';
    });

    _placeModelInFront();
  }

  Future<void> _placeModelInFront() async {
    final glbUrl = _glbUrl;
    final objectManager = _objectManager;

    if (glbUrl == null || objectManager == null) {
      setState(() {
        _statusText = 'Модель для AR-камеры недоступна';
      });
      return;
    }

    setState(() {
      _isPlacing = true;
      _statusText = 'Ставим модель перед камерой';
    });

    final previousNode = _modelNode;
    if (previousNode != null) {
      objectManager.removeNode(previousNode);
      _modelNode = null;
    }

    final transform = await _modelTransformInFrontOfCamera();
    if (!mounted) return;

    if (transform == null) {
      setState(() {
        _isPlacing = false;
        _statusText = 'ARCore еще не отдал позу камеры';
      });
      return;
    }

    final node = ARNode(
      type: NodeType.webGLB,
      uri: glbUrl,
      transformation: transform,
    );

    final didAdd = await objectManager.addNode(node) ?? false;
    if (!mounted) return;

    setState(() {
      _isPlacing = false;
      _modelNode = didAdd ? node : null;
      _statusText = didAdd
          ? 'Модель закреплена перед камерой'
          : 'Не удалось добавить модель в AR-сцену';
    });
  }

  Future<vector.Matrix4?> _modelTransformInFrontOfCamera() async {
    final sessionManager = _sessionManager;
    if (sessionManager == null) return null;

    for (var attempt = 0; attempt < 20; attempt++) {
      final cameraPose = await sessionManager.getCameraPose();
      if (cameraPose != null) {
        final transform = vector.Matrix4.copy(cameraPose);
        transform.translateByDouble(0.0, -0.25, -_distance, 1.0);
        transform.scaleByDouble(_scale, _scale, _scale, 1.0);
        return transform;
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    return null;
  }

  Future<void> _changeScale(double delta) async {
    _scale = (_scale + delta).clamp(0.05, 3.0).toDouble();
    await _placeModelInFront();
  }

  Future<void> _changeDistance(double delta) async {
    _distance = (_distance + delta).clamp(0.75, 4.0).toDouble();
    await _placeModelInFront();
  }

  Future<void> _openSceneViewerFallback() async {
    final result = await ArExperienceLauncher.launchExternalViewer(
      experience: widget.experience,
      objectName: widget.objectName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _ArCameraTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onOpenExternalViewer;

  const _ArCameraTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onOpenExternalViewer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundArButton(icon: Icons.arrow_back, onTap: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.whiteText.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RoundArButton(icon: Icons.open_in_new, onTap: onOpenExternalViewer),
      ],
    );
  }
}

class _ArCameraControls extends StatelessWidget {
  final String? statusText;
  final bool isArReady;
  final bool isPlacing;
  final double scale;
  final double distance;
  final VoidCallback onPlace;
  final VoidCallback onDecreaseScale;
  final VoidCallback onIncreaseScale;
  final VoidCallback onMoveCloser;
  final VoidCallback onMoveFarther;
  final VoidCallback onOpenExternalViewer;

  const _ArCameraControls({
    required this.statusText,
    required this.isArReady,
    required this.isPlacing,
    required this.scale,
    required this.distance,
    required this.onPlace,
    required this.onDecreaseScale,
    required this.onIncreaseScale,
    required this.onMoveCloser,
    required this.onMoveFarther,
    required this.onOpenExternalViewer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.whiteText.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isPlacing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.whiteText,
                  ),
                )
              else
                Icon(
                  isArReady ? Icons.view_in_ar : Icons.hourglass_bottom,
                  color: AppColors.whiteText,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ArControlButton(
                  icon: Icons.center_focus_strong,
                  label: 'Поставить',
                  onTap: isArReady && !isPlacing ? onPlace : null,
                ),
              ),
              const SizedBox(width: 8),
              _ArIconButton(
                icon: Icons.remove,
                onTap: isArReady && !isPlacing ? onDecreaseScale : null,
              ),
              const SizedBox(width: 6),
              _ArValueChip(text: 'x${scale.toStringAsFixed(2)}'),
              const SizedBox(width: 6),
              _ArIconButton(
                icon: Icons.add,
                onTap: isArReady && !isPlacing ? onIncreaseScale : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ArIconButton(
                icon: Icons.keyboard_double_arrow_down,
                onTap: isArReady && !isPlacing ? onMoveCloser : null,
              ),
              const SizedBox(width: 6),
              _ArValueChip(text: '${distance.toStringAsFixed(1)} м'),
              const SizedBox(width: 6),
              _ArIconButton(
                icon: Icons.keyboard_double_arrow_up,
                onTap: isArReady && !isPlacing ? onMoveFarther : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ArControlButton(
                  icon: Icons.open_in_new,
                  label: 'Scene Viewer',
                  onTap: onOpenExternalViewer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ArControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        disabledBackgroundColor: const Color(0xFF7C7471),
        foregroundColor: AppColors.whiteText,
        textStyle: AppTextStyles.whiteText15.copyWith(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ArIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ArIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFF7C7471)
              : AppColors.whiteText.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? AppColors.greyBackground
              : AppColors.primaryRed,
          size: 21,
        ),
      ),
    );
  }
}

class _RoundArButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundArButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.46),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.whiteText.withValues(alpha: 0.16),
          ),
        ),
        child: Icon(icon, color: AppColors.whiteText, size: 22),
      ),
    );
  }
}

class _ArValueChip extends StatelessWidget {
  final String text;

  const _ArValueChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 62),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteText.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.whiteText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ArCameraUnavailable extends StatelessWidget {
  final String objectName;
  final String reason;

  const _ArCameraUnavailable({required this.objectName, required this.reason});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.beigeBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.view_in_ar,
                color: AppColors.primaryRed,
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                objectName,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline20,
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

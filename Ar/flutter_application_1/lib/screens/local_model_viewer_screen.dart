import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/ar_experience.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_model_viewer.dart';

class LocalModelViewerScreen extends StatelessWidget {
  final String objectName;
  final ArExperience experience;

  const LocalModelViewerScreen({
    super.key,
    required this.objectName,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    final modelPath = experience.glbUrl ?? experience.glbAssetPath;

    return Scaffold(
      backgroundColor: AppColors.beigeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          objectName,
          style: const TextStyle(
            color: AppColors.whiteText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: modelPath == null
          ? const _MissingModelMessage()
          : Column(
              children: [
                Expanded(
                  child: LoadingModelViewer(
                    src: modelPath,
                    alt: '3D model of $objectName',
                    ar: experience.hasExternalModelReference,
                    arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                    arScale: ArScale.auto,
                    arPlacement:
                        experience.placement.trim().toLowerCase() == 'wall'
                        ? ArPlacement.wall
                        : ArPlacement.floor,
                    iosSrc: experience.usdzUrl,
                    scale: _modelScaleFor(experience.scale),
                    autoRotate: true,
                    cameraControls: true,
                    disableZoom: false,
                    backgroundColor: const Color(0xFFF5F0E8),
                  ),
                ),
                const _PreviewFooter(),
              ],
            ),
    );
  }

  static String? _modelScaleFor(double scale) {
    if (scale <= 0) return null;
    return '$scale $scale $scale';
  }
}

class _MissingModelMessage extends StatelessWidget {
  const _MissingModelMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '3D-модель не найдена',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryRed,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreviewFooter extends StatelessWidget {
  const _PreviewFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryRed,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: const Text(
        '3D-модель загружается с сервера при открытии просмотра.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.whiteText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}

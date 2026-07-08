import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../models/historical_object.dart';
import '../models/panorama_year.dart';
import '../services/ar_experience_service.dart';
import '../services/ar_experience_launcher.dart';
import '../services/historical_experience_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/loading_model_viewer.dart';
import 'ar_camera_screen.dart';
import 'object_detail_screen.dart';

enum _ExperienceMode { panorama, model3d }

class HistoricalExperienceScreen extends StatefulWidget {
  final HistoricalObject object;

  const HistoricalExperienceScreen({super.key, required this.object});

  @override
  State<HistoricalExperienceScreen> createState() =>
      _HistoricalExperienceScreenState();
}

class _HistoricalExperienceScreenState
    extends State<HistoricalExperienceScreen> {
  late final Future<HistoricalExperienceAvailability> _availabilityFuture;
  _ExperienceMode _selectedMode = _ExperienceMode.panorama;
  int _currentPanoramaIndex = 0;
  bool _showInfoPanel = false;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = HistoricalExperienceService.availabilityFor(
      widget.object,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HistoricalExperienceAvailability>(
      future: _availabilityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _ExperienceScaffold(
            objectName: widget.object.name,
            child: const _LoadingExperienceState(),
          );
        }

        final availability = snapshot.data;
        if (availability == null || !availability.canOpen) {
          return _ExperienceScaffold(
            objectName: widget.object.name,
            child: _UnavailableExperienceState(
              message:
                  availability?.unavailableMessageFor(widget.object.name) ??
                  'Исторический опыт для "${widget.object.name}" готовится.',
            ),
          );
        }

        return _buildExperience(context, availability);
      },
    );
  }

  Widget _buildExperience(
    BuildContext context,
    HistoricalExperienceAvailability availability,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final mode = _effectiveMode(availability);
    final panoramas = availability.availablePanoramas;
    final currentPanorama = _currentPanorama(panoramas);
    final currentArAvailability = availability.arAvailabilityFor(
      currentPanorama,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: mode == _ExperienceMode.panorama && currentPanorama != null
                ? _PanoramaExperience(
                    panorama: currentPanorama,
                    width: screenSize.width,
                    height: screenSize.height,
                  )
                : _ModelExperience(
                    objectName: widget.object.name,
                    arAvailability: currentArAvailability,
                    hasTimeline: panoramas.length > 1,
                    onOpenArCamera: _openArCamera,
                  ),
          ),
          _ExperienceTopBar(
            objectName: widget.object.name,
            onBack: () => Navigator.pop(context),
            onInfo: () => setState(() => _showInfoPanel = !_showInfoPanel),
          ),
          if (availability.hasPanoramas && availability.has3dMode)
            Positioned(
              top: 58 + viewPadding.top,
              left: 16,
              right: 16,
              child: _ModeSelector(
                selectedMode: mode,
                onModeSelected: (nextMode) {
                  setState(() {
                    _selectedMode = nextMode;
                    _showInfoPanel = false;
                  });
                },
              ),
            ),
          if (panoramas.length > 1)
            Positioned(
              bottom: 50 + viewPadding.bottom,
              left: 0,
              right: 0,
              child: _ExperienceTimeline(
                panoramas: panoramas,
                currentIndex: _normalizedPanoramaIndex(panoramas),
                width: screenSize.width,
                onChanged: (index) {
                  setState(() {
                    _currentPanoramaIndex = index;
                  });
                },
              ),
            ),
          if (_showInfoPanel)
            Positioned(
              bottom: (panoramas.length > 1 ? 120 : 28) + viewPadding.bottom,
              left: 16,
              right: 16,
              child: _ExperienceInfoPanel(
                object: widget.object,
                panorama: currentPanorama,
                mode: mode,
                onClose: () => setState(() => _showInfoPanel = false),
              ),
            ),
        ],
      ),
    );
  }

  _ExperienceMode _effectiveMode(
    HistoricalExperienceAvailability availability,
  ) {
    if (_selectedMode == _ExperienceMode.model3d && availability.has3dMode) {
      return _ExperienceMode.model3d;
    }

    if (_selectedMode == _ExperienceMode.panorama &&
        availability.hasPanoramas) {
      return _ExperienceMode.panorama;
    }

    return availability.hasPanoramas
        ? _ExperienceMode.panorama
        : _ExperienceMode.model3d;
  }

  PanoramaYear? _currentPanorama(List<PanoramaYear> panoramas) {
    if (panoramas.isEmpty) return null;
    return panoramas[_normalizedPanoramaIndex(panoramas)];
  }

  int _normalizedPanoramaIndex(List<PanoramaYear> panoramas) {
    if (panoramas.isEmpty) return 0;
    if (_currentPanoramaIndex < 0) return 0;
    if (_currentPanoramaIndex >= panoramas.length) return panoramas.length - 1;
    return _currentPanoramaIndex;
  }

  Future<void> _openExternalViewer() async {
    final availability = await _availabilityFuture;
    final experience = availability
        .arAvailabilityFor(_currentPanorama(availability.availablePanoramas))
        .experience;
    if (!mounted || experience == null) return;

    final result = await ArExperienceLauncher.launchExternalViewer(
      experience: experience,
      objectName: widget.object.name,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openArCamera() async {
    final availability = await _availabilityFuture;
    final experience = availability
        .arAvailabilityFor(_currentPanorama(availability.availablePanoramas))
        .experience;

    if (!mounted || experience == null) return;

    final glbUrl = experience.glbUrl?.trim();
    if (glbUrl == null || glbUrl.isEmpty) {
      await _openExternalViewer();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArCameraScreen(
          objectName: widget.object.name,
          experience: experience,
        ),
      ),
    );
  }
}

class _ExperienceScaffold extends StatelessWidget {
  final String objectName;
  final Widget child;

  const _ExperienceScaffold({required this.objectName, required this.child});

  @override
  Widget build(BuildContext context) {
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
      body: child,
    );
  }
}

class _LoadingExperienceState extends StatelessWidget {
  const _LoadingExperienceState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryRed),
    );
  }
}

class _UnavailableExperienceState extends StatelessWidget {
  final String message;

  const _UnavailableExperienceState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}

class _PanoramaExperience extends StatelessWidget {
  final PanoramaYear panorama;
  final double width;
  final double height;

  const _PanoramaExperience({
    required this.panorama,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final image = panorama.isRemoteImage
        ? Image.network(
            panorama.imagePath,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: _imageErrorBuilder,
          )
        : Image.asset(
            panorama.imagePath,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: _imageErrorBuilder,
          );

    return PanoramaViewer(animSpeed: 0.5, child: image);
  }

  Widget _imageErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const ColoredBox(
      color: Color(0xFF465063),
      child: Center(
        child: Text(
          'Панорама загружается...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.whiteText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ModelExperience extends StatelessWidget {
  final String objectName;
  final ArExperienceAvailability arAvailability;
  final bool hasTimeline;
  final VoidCallback onOpenArCamera;

  const _ModelExperience({
    required this.objectName,
    required this.arAvailability,
    required this.hasTimeline,
    required this.onOpenArCamera,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final experience = arAvailability.experience;
    final modelPath = experience?.glbUrl ?? experience?.glbAssetPath;
    final hasExternalModelUrl = arAvailability.hasExternalModelUrl;

    if (arAvailability.hasModelPreview && modelPath != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: LoadingModelViewer(
              src: modelPath,
              alt: '3D model of $objectName',
              ar: false,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              arScale: ArScale.auto,
              arPlacement: _arPlacementFor(experience?.placement),
              iosSrc: experience?.usdzUrl,
              scale: _modelScaleFor(experience?.scale),
              autoRotate: true,
              cameraControls: true,
              disableZoom: false,
              backgroundColor: const Color(0xFFF5F0E8),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: (hasTimeline ? 152 : 22) + bottomInset,
            child: _ArActionButton(
              hasExternalModelUrl: hasExternalModelUrl,
              onTap: onOpenArCamera,
            ),
          ),
        ],
      );
    }

    return _ModelUnavailableMessage(
      message: arAvailability.messageFor(objectName),
    );
  }

  static ArPlacement _arPlacementFor(String? placement) {
    return placement?.trim().toLowerCase() == 'wall'
        ? ArPlacement.wall
        : ArPlacement.floor;
  }

  static String? _modelScaleFor(double? scale) {
    if (scale == null || scale <= 0) return null;
    return '$scale $scale $scale';
  }
}

class _ArActionButton extends StatelessWidget {
  final bool hasExternalModelUrl;
  final VoidCallback onTap;

  const _ArActionButton({
    required this.hasExternalModelUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.view_in_ar),
        label: const Text('AR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasExternalModelUrl
              ? AppColors.primaryRed
              : const Color(0xFF8F8582),
          foregroundColor: AppColors.whiteText,
          textStyle: AppTextStyles.whiteText15,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }
}

class _ModelUnavailableMessage extends StatelessWidget {
  final String message;

  const _ModelUnavailableMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.beigeBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

class _ExperienceTopBar extends StatelessWidget {
  final String objectName;
  final VoidCallback onBack;
  final VoidCallback onInfo;

  const _ExperienceTopBar({
    required this.objectName,
    required this.onBack,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 112 + topInset,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.72),
              Colors.black.withValues(alpha: 0.34),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 11,
              top: 9 + topInset,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.39),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.whiteText,
                    size: 17,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 48,
              right: 62,
              top: 13 + topInset,
              child: Text(
                objectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 12 + topInset,
              child: GestureDetector(
                onTap: onInfo,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC13E40),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'И',
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final _ExperienceMode selectedMode;
  final ValueChanged<_ExperienceMode> onModeSelected;

  const _ModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          _ModeButton(
            icon: Icons.public,
            label: 'Панорама',
            isSelected: selectedMode == _ExperienceMode.panorama,
            onTap: () => onModeSelected(_ExperienceMode.panorama),
          ),
          const SizedBox(width: 4),
          _ModeButton(
            icon: Icons.view_in_ar,
            label: '3D',
            isSelected: selectedMode == _ExperienceMode.model3d,
            onTap: () => onModeSelected(_ExperienceMode.model3d),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.whiteText),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperienceTimeline extends StatelessWidget {
  final List<PanoramaYear> panoramas;
  final int currentIndex;
  final double width;
  final ValueChanged<int> onChanged;

  const _ExperienceTimeline({
    required this.panoramas,
    required this.currentIndex,
    required this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = panoramas.length;
    final lineStartOffset = 50.0;
    final lineEndOffset = 50.0;
    final lineWidth = width - lineStartOffset - lineEndOffset;
    final step = lineWidth / (count - 1);
    final circlePositions = List<double>.generate(
      count,
      (index) => lineStartOffset + index * step,
    );

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: circlePositions[currentIndex] - 25,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      panoramas[currentIndex].year,
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final localX = details.localPosition.dx;
              var closestIndex = 0;
              var minDistance = double.infinity;

              for (var i = 0; i < circlePositions.length; i++) {
                final distance = (circlePositions[i] - localX).abs();
                if (distance < minDistance) {
                  minDistance = distance;
                  closestIndex = i;
                }
              }

              if (closestIndex != currentIndex) {
                onChanged(closestIndex);
              }
            },
            child: SizedBox(
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: lineStartOffset,
                    child: Container(
                      height: 3,
                      width: lineWidth,
                      color: AppColors.whiteText,
                    ),
                  ),
                  ...List.generate(count, (index) {
                    final isSelected = currentIndex == index;
                    return Positioned(
                      left: circlePositions[index] - (isSelected ? 12 : 8),
                      top: 2.5 - (isSelected ? 12 : 8),
                      child: GestureDetector(
                        onTap: () => onChanged(index),
                        child: Container(
                          width: isSelected ? 24 : 16,
                          height: isSelected ? 24 : 16,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkRed
                                : AppColors.darkPink,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.whiteText
                                  : AppColors.whiteText.withValues(alpha: 0.5),
                              width: isSelected ? 3 : 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceInfoPanel extends StatelessWidget {
  final HistoricalObject object;
  final PanoramaYear? panorama;
  final _ExperienceMode mode;
  final VoidCallback onClose;

  const _ExperienceInfoPanel({
    required this.object,
    required this.panorama,
    required this.mode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final modeText = mode == _ExperienceMode.model3d ? '3D' : 'Панорама';
    final year = panorama?.year;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beigeBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  year == null ? object.name : '${object.name}, $year',
                  style: AppTextStyles.headline15,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_getDescription(object.name, year)}\nРежим: $modeText.',
            style: AppTextStyles.body12,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ObjectDetailScreen(objectName: object.name),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Подробнее',
                style: TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getDescription(String objectName, String? year) {
    final yearNum = _parseYear(year);

    if (objectName == 'Маяк') {
      if (yearNum == 1589) return 'В 1589 году основан город-крепость Царицын.';
      if (yearNum == 1930) {
        return 'В 1930-х годах построен первый деревянный маяк.';
      }
      if (yearNum == 2010) {
        return 'Современный ресторан «Маяк» открыт в 2010 году.';
      }
      return 'Историческое место с богатой историей.';
    }
    if (objectName == 'Водяная мельница') {
      if (yearNum == 1745) return 'В 1745 году построена водяная мельница.';
      return 'Мельница была важным промышленным объектом города.';
    }
    if (objectName == 'Родина Мать зовет') {
      if (yearNum == 1967) {
        return 'В 1967 году открыта скульптура «Родина-мать зовет!».';
      }
      return 'Монумент является символом Сталинградской битвы.';
    }
    if (objectName == 'Дом Павлова') {
      if (yearNum == 1942) return 'В 1942 году проходила оборона дома.';
      return 'Дом Павлова - символ стойкости советских солдат.';
    }
    if (objectName == 'Собор Александра Невского') {
      if (yearNum == 1888) return 'В 1888 году построен собор.';
      if (yearNum == 1932) return 'В 1932 году собор был разрушен.';
      if (yearNum == 2000) return 'С 2000 года началось восстановление собора.';
      return 'Главный храм города.';
    }
    if (objectName == 'Пожарная каланча') {
      if (yearNum == 1850) return 'В 1850 году построена каланча.';
      return 'Старейшее здание города.';
    }
    return 'Историческое место с богатой историей.';
  }

  static int _parseYear(String? year) {
    if (year == null) return 0;
    final match = RegExp(r'(\d{4})').firstMatch(year);
    return match == null ? 0 : int.parse(match.group(1)!);
  }
}

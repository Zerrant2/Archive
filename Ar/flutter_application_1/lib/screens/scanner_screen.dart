// lib/screens/scanner_screen.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import 'historical_experience_screen.dart';
import '../core/providers/user_provider.dart';
import '../core/providers/objects_provider.dart';
import '../models/historical_object.dart';
import '../services/historical_experience_service.dart';
import '../services/panorama_availability_service.dart';
import '../services/qr_payload_parser.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  static const String _defaultDevQrPayload = 'retroar://object/mayak';

  late final MobileScannerController _scannerController;
  late final TextEditingController _devQrController;
  Set<String> _availableAssetPaths = {};
  bool _isLoadingAssets = true;
  bool _isHandlingScan = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _devQrController = TextEditingController(text: _defaultDevQrPayload);
    unawaited(_loadAvailableAssets());
  }

  @override
  void dispose() {
    _devQrController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableAssets() async {
    try {
      final availableAssetPaths =
          await PanoramaAvailabilityService.loadAvailableAssetPaths();
      if (!mounted) return;

      setState(() {
        _availableAssetPaths = availableAssetPaths;
        _isLoadingAssets = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _availableAssetPaths = {};
        _isLoadingAssets = false;
      });
    }
  }

  bool _hasAvailableExperience(HistoricalObject object) {
    if (_isLoadingAssets) return false;

    return HistoricalExperienceService.hasAvailableExperience(
      object,
      _availableAssetPaths,
    );
  }

  List<HistoricalObject> _objectsWithAvailableExperience(
    List<HistoricalObject> objects,
  ) {
    return objects.where(_hasAvailableExperience).toList();
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_isHandlingScan) return;

    unawaited(_processBarcodeCapture(capture));
  }

  Future<void> _processBarcodeCapture(BarcodeCapture capture) async {
    final payload = _firstPayload(capture);
    if (payload == null) return;

    await _processQrPayload(payload);
  }

  Future<void> _processQrPayload(String payload) async {
    if (_isHandlingScan) return;

    final normalizedPayload = payload.trim();
    if (normalizedPayload.isEmpty) {
      _showSnackBar("QR-код пустой", isError: true);
      return;
    }

    setState(() => _isHandlingScan = true);
    final objectsProvider = context.read<ObjectsProvider>();
    await _stopScannerSafely();
    if (!mounted) return;

    final token = QrPayloadParser.extractObjectToken(normalizedPayload);
    final object = token == null
        ? null
        : _resolveObject(objectsProvider, token);

    if (!mounted) return;

    if (object == null) {
      _showSnackBar("QR-код не найден в базе объектов", isError: true);
      await _resumeScannerSafely();
      return;
    }

    await _openHistoricalExperience(object);
    await _resumeScannerSafely();
  }

  void _handleManualQrSubmit(String payload) {
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_processQrPayload(payload));
  }

  String? _firstPayload(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  HistoricalObject? _resolveObject(ObjectsProvider provider, String token) {
    final byId = provider.getObjectById(token);
    if (byId != null) return byId;

    final byName = provider.getObjectByName(token);
    if (byName != null) return byName;

    final normalizedToken = token.toLowerCase();
    for (final object in provider.allObjects) {
      if (object.id.toLowerCase() == normalizedToken ||
          object.name.toLowerCase() == normalizedToken) {
        return object;
      }
    }

    return null;
  }

  Future<void> _openHistoricalExperience(HistoricalObject object) async {
    if (_isLoadingAssets) {
      _showSnackBar("Материалы еще загружаются");
      return;
    }

    final availability = await HistoricalExperienceService.availabilityFor(
      object,
    );
    if (!mounted) return;

    if (!availability.canOpen) {
      _showSnackBar(
        availability.unavailableMessageFor(object.name),
        isError: true,
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final isFirstScan = !userProvider.isPlaceScanned(object.name);

    if (isFirstScan) {
      final result = await userProvider.addScannedPlace(
        placeName: object.name,
        objectId: object.id,
      );

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(
          "+${result.coinsEarned} монет за сканирование ${object.name}!",
          backgroundColor: AppColors.greenCorrect,
        );
      } else if (!result.isDuplicate) {
        _showSnackBar(result.error ?? "Ошибка при сканировании", isError: true);
      }
    } else {
      _showSnackBar(
        "Вы уже открыли ${object.name} ранее",
        backgroundColor: AppColors.blueText,
      );
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricalExperienceScreen(object: object),
      ),
    );
  }

  Future<void> _stopScannerSafely() async {
    try {
      await _scannerController.stop();
    } catch (_) {
      // The controller may already be stopped on platforms without camera access.
    }
  }

  Future<void> _resumeScannerSafely() async {
    if (!mounted) return;

    setState(() => _isHandlingScan = false);

    try {
      await _scannerController.start();
    } catch (_) {
      // Keep the screen usable through the MVP panorama list if camera restart fails.
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final objectsProvider = context.watch<ObjectsProvider>();
    final availableObjects = _objectsWithAvailableExperience(
      objectsProvider.allObjects,
    );
    const showDevQrPanel = kDebugMode || kIsWeb;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _ScannerHeader(),

            Container(
              color: AppColors.beigeBackground,
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  _ActionButtons(controller: _scannerController),
                  const SizedBox(height: 15),
                  _ScannerSquare(
                    controller: _scannerController,
                    isHandlingScan: _isHandlingScan,
                    onDetect: _handleBarcodeCapture,
                  ),
                  const SizedBox(height: 20),
                  const _ScannerHint(),
                  const SizedBox(height: 20),
                  if (showDevQrPanel) ...[
                    _DeveloperQrPanel(
                      controller: _devQrController,
                      isProcessing: _isHandlingScan,
                      onSubmit: _handleManualQrSubmit,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _AvailableExperiences(
                    isLoading: objectsProvider.isLoading || _isLoadingAssets,
                    objects: availableObjects,
                    onModelTap: _openHistoricalExperience,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerHeader extends StatelessWidget {
  const _ScannerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      color: AppColors.primaryRed,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 50),
      child: const Text(
        "АРхив",
        style: TextStyle(
          color: AppColors.whiteText,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final MobileScannerController controller;

  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<TorchState>(
            valueListenable: controller.torchState,
            builder: (context, state, _) {
              return _CircleButton(
                icon: state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                onTap: () async {
                  try {
                    await controller.toggleTorch();
                  } catch (_) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Вспышка недоступна"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          ),
          ValueListenableBuilder<CameraFacing>(
            valueListenable: controller.cameraFacingState,
            builder: (context, _, _) {
              return _CircleButton(
                icon: Icons.cameraswitch,
                onTap: () async {
                  try {
                    await controller.switchCamera();
                  } catch (_) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Смена камеры недоступна"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.greyBackground,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(icon, color: AppColors.primaryRed, size: 24),
      ),
    );
  }
}

class _ScannerSquare extends StatelessWidget {
  final MobileScannerController controller;
  final bool isHandlingScan;
  final void Function(BarcodeCapture capture) onDetect;

  const _ScannerSquare({
    required this.controller,
    required this.isHandlingScan,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.primaryRed,
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF8F0303),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD90000), width: 5),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: MobileScanner(
                  controller: controller,
                  fit: BoxFit.cover,
                  onDetect: onDetect,
                  placeholderBuilder: (context, child) =>
                      const _ScannerPlaceholder(),
                  errorBuilder: (context, error, child) =>
                      const _ScannerCameraError(),
                ),
              ),
            ),
            if (isHandlingScan)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.whiteText, width: 2),
                    left: BorderSide(color: AppColors.whiteText, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.whiteText, width: 2),
                    right: BorderSide(color: AppColors.whiteText, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.whiteText, width: 2),
                    left: BorderSide(color: AppColors.whiteText, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.whiteText, width: 2),
                    right: BorderSide(color: AppColors.whiteText, width: 2),
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

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primaryRed,
      child: Center(
        child: Icon(Icons.qr_code_scanner, color: Colors.white54, size: 60),
      ),
    );
  }
}

class _ScannerCameraError extends StatelessWidget {
  const _ScannerCameraError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primaryRed,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography, color: Colors.white70, size: 42),
              SizedBox(height: 12),
              Text(
                "Камера недоступна",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.whiteText,
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

class _ScannerHint extends StatelessWidget {
  const _ScannerHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "Наведите на QR-код исторического здания",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.blueText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}

class _DeveloperQrPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isProcessing;
  final ValueChanged<String> onSubmit;

  const _DeveloperQrPanel({
    required this.controller,
    required this.isProcessing,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderRed, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Тестовый QR", style: AppTextStyles.headline15),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              enabled: !isProcessing,
              textInputAction: TextInputAction.done,
              onSubmitted: onSubmit,
              style: AppTextStyles.blueText12,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.whiteText,
                hintText: _ScannerScreenState._defaultDevQrPayload,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => onSubmit(controller.text),
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.whiteText,
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 20),
                label: Text(isProcessing ? "Открываем..." : "Открыть"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: AppColors.whiteText,
                  disabledBackgroundColor: AppColors.primaryRed.withValues(
                    alpha: 0.5,
                  ),
                  disabledForegroundColor: AppColors.whiteText.withValues(
                    alpha: 0.8,
                  ),
                  textStyle: AppTextStyles.whiteText15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

class _AvailableExperiences extends StatelessWidget {
  final bool isLoading;
  final List<HistoricalObject> objects;
  final ValueChanged<HistoricalObject> onModelTap;

  const _AvailableExperiences({
    required this.isLoading,
    required this.objects,
    required this.onModelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("Доступный опыт", style: AppTextStyles.headline15),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(
              color: AppColors.primaryRed,
              backgroundColor: Color(0xFFEFCFD0),
            ),
          )
        else if (objects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Материалы пока не добавлены",
              style: AppTextStyles.blueText12,
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: objects.length,
              itemBuilder: (context, index) {
                final object = objects[index];

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onModelTap(object),
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 90,
                          decoration: AppDecorations.redGradientSquare,
                          child: const Center(
                            child: Icon(
                              Icons.travel_explore,
                              color: AppColors.whiteText,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            object.name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.blueText11,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

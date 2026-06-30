// lib/screens/panorama_screen.dart
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'object_detail_screen.dart';
import '../models/panorama_year.dart';

class PanoramaScreen extends StatefulWidget {
  final String objectName;
  final List<PanoramaYear> panoramas;

  const PanoramaScreen({
    super.key,
    required this.objectName,
    required this.panoramas,
  });

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
  int _currentPanoramaIndex = 0;
  bool _showInfoPanel = false;
  late List<PanoramaYear> _sortedPanoramas;

  @override
  void initState() {
    super.initState();
    _sortedPanoramas = List.from(widget.panoramas);
    _sortedPanoramas.sort(
      (a, b) => _parseYear(a.year).compareTo(_parseYear(b.year)),
    );
  }

  int _parseYear(String yearStr) {
    final match = RegExp(r'(\d{4})').firstMatch(yearStr);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  void _changePanorama(int index) {
    setState(() {
      _currentPanoramaIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentPanorama = _sortedPanoramas[_currentPanoramaIndex];
    final panoramaImage = currentPanorama.isRemoteImage
        ? Image.network(
            currentPanorama.imagePath,
            width: screenWidth,
            height: screenHeight,
            fit: BoxFit.cover,
            errorBuilder: _buildPanoramaError,
          )
        : Image.asset(
            currentPanorama.imagePath,
            width: screenWidth,
            height: screenHeight,
            fit: BoxFit.cover,
            errorBuilder: _buildPanoramaError,
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: PanoramaViewer(animSpeed: 0.5, child: panoramaImage),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 105,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 11,
                    top: 9,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.39),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.whiteText,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 45,
                    top: 13,
                    child: Text(
                      widget.objectName,
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 15,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showInfoPanel = !_showInfoPanel),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC13E40),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "И",
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
          ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildTimeline(screenWidth),
          ),

          if (_showInfoPanel)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: _buildInfoPanel(currentPanorama),
            ),
        ],
      ),
    );
  }

  Widget _buildPanoramaError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.blue,
      child: const Center(
        child: Text(
          "Панорама\nзагружается...",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTimeline(double screenWidth) {
    final count = _sortedPanoramas.length;
    if (count <= 1) return const SizedBox.shrink();

    final lineStartOffset = 50.0;
    final lineEndOffset = 50.0;
    final lineWidth = screenWidth - lineStartOffset - lineEndOffset;
    final step = lineWidth / (count - 1);

    List<double> circlePositions = List.generate(count, (index) {
      return lineStartOffset + (index * step);
    });

    return SizedBox(
      width: screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_currentPanoramaIndex >= 0)
                  Positioned(
                    left: circlePositions[_currentPanoramaIndex] - 25,
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
                        _sortedPanoramas[_currentPanoramaIndex].year,
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
              int closestIndex = 0;
              double minDistance = double.infinity;
              for (int i = 0; i < circlePositions.length; i++) {
                double distance = (circlePositions[i] - localX).abs();
                if (distance < minDistance) {
                  minDistance = distance;
                  closestIndex = i;
                }
              }
              if (closestIndex != _currentPanoramaIndex) {
                _changePanorama(closestIndex);
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
                      color: Colors.white,
                    ),
                  ),
                  ...List.generate(count, (index) {
                    final isSelected = _currentPanoramaIndex == index;
                    return Positioned(
                      left: circlePositions[index] - (isSelected ? 12 : 8),
                      top: 2.5 - (isSelected ? 12 : 8),
                      child: GestureDetector(
                        onTap: () => _changePanorama(index),
                        child: Container(
                          width: isSelected ? 24 : 16,
                          height: isSelected ? 24 : 16,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkRed
                                : AppColors.darkPink,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.whiteText,
                                    width: 3,
                                  )
                                : Border.all(
                                    color: AppColors.whiteText.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 2,
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

  Widget _buildInfoPanel(PanoramaYear currentPanorama) {
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
                child: Text(widget.objectName, style: AppTextStyles.headline15),
              ),
              GestureDetector(
                onTap: () => setState(() => _showInfoPanel = false),
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
            _getDescription(widget.objectName, currentPanorama.year),
            style: AppTextStyles.body12,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ObjectDetailScreen(objectName: widget.objectName),
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
                "Подробнее",
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

  String _getDescription(String objectName, String year) {
    final yearNum = _parseYear(year);

    if (objectName == "Маяк") {
      if (yearNum == 1589) return "В 1589 году основан город-крепость Царицын.";
      if (yearNum == 1930) {
        return "В 1930-х годах построен первый деревянный маяк.";
      }
      if (yearNum == 2010) {
        return "Современный ресторан «Маяк» открыт в 2010 году.";
      }
      return "Историческое место с богатой историей.";
    }
    if (objectName == "Водяная мельница") {
      if (yearNum == 1745) return "В 1745 году построена водяная мельница.";
      return "Мельница была важным промышленным объектом города.";
    }
    if (objectName == "Родина Мать зовет") {
      if (yearNum == 1967) {
        return "В 1967 году открыта скульптура «Родина-мать зовет!».";
      }
      return "Монумент является символом Сталинградской битвы.";
    }
    if (objectName == "Дом Павлова") {
      if (yearNum == 1942) return "В 1942 году проходила оборона дома.";
      return "Дом Павлова - символ стойкости советских солдат.";
    }
    if (objectName == "Собор Александра Невского") {
      if (yearNum == 1888) return "В 1888 году построен собор.";
      if (yearNum == 1932) return "В 1932 году собор был разрушен.";
      if (yearNum == 2000) return "С 2000 года началось восстановление собора.";
      return "Главный храм города.";
    }
    if (objectName == "Пожарная каланча") {
      if (yearNum == 1850) return "В 1850 году построена каланча.";
      return "Старейшее здание города.";
    }
    return "Историческое место с богатой историей.";
  }
}

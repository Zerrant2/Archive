// lib/screens/scan_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'object_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../core/providers/user_provider.dart';
import '../core/providers/objects_provider.dart';
import '../services/scan_history_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    final userProvider = context.read<UserProvider>();
    final objectsProvider = context.read<ObjectsProvider>();

    await objectsProvider.loadObjects();
    await userProvider.loadUserData();

    final scannedPlaces = userProvider.scannedPlaces;
    final allObjects = objectsProvider.allObjects;

    // Загружаем историю сканирований из БД с реальными датами
    final scanHistoryFromDb = await ScanHistoryService.getScanHistory();

    final history = <Map<String, dynamic>>[];
    for (var placeName in scannedPlaces) {
      final object = allObjects.firstWhere(
        (obj) => obj.name == placeName,
        orElse: () => throw Exception("Object not found"),
      );

      // Находим дату сканирования из БД
      final scanRecord = scanHistoryFromDb.firstWhere(
        (scan) => scan['object_name'] == placeName,
        orElse: () => {},
      );

      final scannedAt = scanRecord['scanned_at'] != null
          ? DateTime.parse(scanRecord['scanned_at'])
          : DateTime.now();

      history.add({
        'name': object.name,
        'century': object.century,
        'id': object.id,
        'scannedAt': scannedAt,
      });
    }

    // Сортируем по дате (сначала новые)
    history.sort(
      (a, b) =>
          (b['scannedAt'] as DateTime).compareTo(a['scannedAt'] as DateTime),
    );

    setState(() {
      _scanHistory = history;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _HistoryHeader(scanCount: _scanHistory.length),

          Expanded(
            child: Container(
              color: AppColors.beigeBackground,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _scanHistory.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: AppColors.greyBackground,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "История сканирований пуста",
                            style: TextStyle(
                              color: AppColors.blueText,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Отсканируйте QR-код у исторического объекта",
                            style: TextStyle(
                              color: AppColors.blueText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _scanHistory.length,
                      itemBuilder: (context, index) {
                        final scan = _scanHistory[index];
                        return _ScanHistoryItem(
                          name: scan['name'],
                          century: scan['century'],
                          scannedDate: _formatDate(scan['scannedAt']),
                        );
                      },
                    ),
            ),
          ),

          const _CustomBottomNavBar(),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int scanCount;

  const _HistoryHeader({required this.scanCount});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      height: 105 + topInset,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 9 + topInset,
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
            left: 31,
            top: 27 + topInset,
            child: const Text(
              "История сканирования",
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Positioned(
            left: 31,
            top: 65 + topInset,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$scanCount",
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const TextSpan(
                    text: "   сканирований",
                    style: TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanHistoryItem extends StatelessWidget {
  final String name;
  final String century;
  final String scannedDate;

  const _ScanHistoryItem({
    required this.name,
    required this.century,
    required this.scannedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ObjectDetailScreen(objectName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 110,
              height: 100,
              decoration: AppDecorations.redGradientSquare,
              child: const Center(
                child: Icon(
                  Icons.photo_camera,
                  color: AppColors.whiteText,
                  size: 45,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.headline15),
                  const SizedBox(height: 4),
                  Text(
                    century,
                    style: const TextStyle(
                      color: Color(0xBF870C0E),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Аудиогид в разработке"),
                            duration: Duration(seconds: 1),
                          ),
                        ),
                        child: Container(
                          width: 86,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.darkRed.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(
                                0xFFDE3323,
                              ).withValues(alpha: 0.41),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Аудио",
                              style: TextStyle(
                                color: AppColors.whiteText,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Текст в разработке"),
                            duration: Duration(seconds: 1),
                          ),
                        ),
                        child: Container(
                          width: 86,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.darkPink,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFD3514A)),
                          ),
                          child: const Center(
                            child: Text(
                              "Текст",
                              style: TextStyle(
                                color: Color(0xFFFAF0F0),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scannedDate,
                    style: const TextStyle(
                      color: Color(0xD1FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9E3435),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  const _CustomBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 73,
        decoration: const BoxDecoration(
          color: AppColors.primaryRed,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.qr_code_scanner, label: "Сканер", index: 0),
            _NavItem(icon: Icons.map, label: "Карта", index: 1),
            _NavItem(icon: Icons.menu, label: "Меню", index: 2),
            _NavItem(icon: Icons.person, label: "Профиль", index: 3),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

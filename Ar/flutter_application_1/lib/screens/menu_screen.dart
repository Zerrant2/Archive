// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'scan_history_screen.dart';
import 'achievements_screen.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import 'notifications_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          _MenuHeader(),
          _MenuContent(),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 105,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          const Positioned(
            left: 20,
            top: 31,
            child: Text(
              "Меню",
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 66,
            child: Text(
              "Исследуйте возможности приложения",
              style: TextStyle(
                color: Color(0xFFBCB0B0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 18,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.whiteText,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuContent extends StatefulWidget {
  const _MenuContent();

  @override
  State<_MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends State<_MenuContent> {
  void _navigateToTab(int tabIndex) {
    final mainScreenState = context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainScreenState != null && mounted) {
      mainScreenState.changeTab(tabIndex);
    }
  }

  void _showInDevelopmentMessage(String sectionName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Раздел «$sectionName» в разработке"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beigeBackground,
      child: Column(
        children: [
          const SizedBox(height: 16),

          _MenuItem(
            icon: Icons.map,
            title: "Карта мест",
            subtitle: "Интерактивная карта исторических мест",
            onTap: () => _navigateToTab(1),
          ),

          const SizedBox(height: 20),

          _MenuItem(
            icon: Icons.camera_alt,
            title: "AI Камера времени",
            subtitle: "Сделать фото в исторических нарядах",
            onTap: () => _showInDevelopmentMessage("AI Камера времени"),
          ),

          const SizedBox(height: 20),

          _MenuItem(
            icon: Icons.emoji_events,
            title: "Достижения",
            subtitle: "Ваши награды и достижения",
            onTap: () async {
              final result = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsScreen(),
                ),
              );
              if (mounted && result != null && result != 2) {
                _navigateToTab(result);
              }
            },
          ),

          const SizedBox(height: 20),

          _MenuItem(
            icon: Icons.history,
            title: "История сканирований",
            subtitle: "Просмотр всех отсканированных мест",
            onTap: () async {
              final result = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanHistoryScreen(),
                ),
              );
              if (mounted && result != null && result != 2) {
                _navigateToTab(result);
              }
            },
          ),

          const SizedBox(height: 20),

          _MenuItem(
            icon: Icons.photo_library,
            title: "Галерея фотографий",
            subtitle: "Сохраненные исторические фото",
            onTap: () => _showInDevelopmentMessage("Галерея фотографий"),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 59,
              height: 59,
              decoration: AppDecorations.redGradientSquare,
              child: Icon(icon, color: AppColors.whiteText, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headline15,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: AppTextStyles.headline12,
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
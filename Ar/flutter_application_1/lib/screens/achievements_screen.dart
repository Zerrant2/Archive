// lib/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/services/achievement_service.dart';
import '../core/providers/user_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final Map<String, bool> _expandedState = {};

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    final unlockedAchievementsMap = <String, bool>{};
    for (final id in userProvider.achievements.keys) {
      unlockedAchievementsMap[id] = true;
    }

    final achievements = AchievementService.getAllAchievementsWithState(
      scannedPlaces: userProvider.scannedPlaces,
      completedTests: userProvider.completedTests,
      coins: userProvider.coins,
      unlockedAchievements: unlockedAchievementsMap,
    );

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AchievementsHeader(unlockedCount: unlockedCount),

          Expanded(
            child: Container(
              color: AppColors.beigeBackground,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isExpanded = _expandedState[achievement.id] ?? true;
                  return _AchievementCard(
                    achievement: achievement,
                    isExpanded: isExpanded,
                    onToggle: () {
                      setState(() {
                        _expandedState[achievement.id] = !isExpanded;
                      });
                    },
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

class _AchievementsHeader extends StatelessWidget {
  final int unlockedCount;

  const _AchievementsHeader({required this.unlockedCount});

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
              "Достижения",
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
                    text: "$unlockedCount",
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const TextSpan(
                    text: "   достижений",
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

class _AchievementCard extends StatelessWidget {
  final AchievementWithState achievement;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AchievementCard({
    required this.achievement,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const double collapsedWidth = 85.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth = (constraints.maxWidth - 80).clamp(
          collapsedWidth,
          constraints.maxWidth,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 122,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: const Offset(80, 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isExpanded ? expandedWidth : collapsedWidth,
                  height: 121,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightPink,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: isExpanded
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: const Offset(2, 0),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isExpanded)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 70,
                                  right: 1,
                                  top: 16,
                                  bottom: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Как получить",
                                      style: TextStyle(
                                        color: AppColors.whiteText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      achievement.howToGet,
                                      style: TextStyle(
                                        color: AppColors.primaryRed.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        height: 1.3,
                                      ),
                                      maxLines: achievement.isUnlocked ? 4 : 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (!achievement.isUnlocked) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: achievement.progress,
                                          backgroundColor: AppColors.darkPink,
                                          color: AppColors.darkRed,
                                          minHeight: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${achievement.currentValue}/${achievement.maxProgress}",
                                        style: AppTextStyles.blueText8,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 40,
                            child: Center(
                              child: Icon(
                                isExpanded
                                    ? Icons.arrow_back_ios
                                    : Icons.arrow_forward_ios,
                                color: const Color(0xFF9E3435),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 135,
                  height: 121,
                  decoration: BoxDecoration(
                    gradient: achievement.isUnlocked
                        ? AppColors.redGradient
                        : null,
                    color: achievement.isUnlocked ? null : AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        achievement.isUnlocked
                            ? Icons.emoji_events
                            : Icons.lock_outline,
                        color: AppColors.whiteText,
                        size: 35,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          achievement.name,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body11,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          achievement.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body8,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

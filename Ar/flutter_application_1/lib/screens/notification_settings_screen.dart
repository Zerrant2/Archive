// lib/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _newAchievementsEnabled = true;
  bool _rewardsAndCoinsEnabled = true;
  bool _nearbyLocationsEnabled = true;
  bool _appUpdatesEnabled = true;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.loadSettings();
    setState(() {
      _newAchievementsEnabled = settings['newAchievements']!;
      _rewardsAndCoinsEnabled = settings['rewardsAndCoins']!;
      _nearbyLocationsEnabled = settings['nearbyLocations']!;
      _appUpdatesEnabled = settings['appUpdates']!;
    });
  }

  void _saveSettings() async {
    await NotificationService.saveSettings(
      newAchievements: _newAchievementsEnabled,
      rewardsAndCoins: _rewardsAndCoinsEnabled,
      nearbyLocations: _nearbyLocationsEnabled,
      appUpdates: _appUpdatesEnabled,
    );
  }

  void _showSuccessMessage(String message) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 407,
            height: 61,
            decoration: BoxDecoration(
              color: AppColors.beigeBackground,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 10,
                  offset: Offset(0, 22),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 42,
                  top: 21,
                  child: SizedBox(
                    width: 277,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline15,
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 16,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryRed, width: 1),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.primaryRed,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _SettingsHeader(),

          Expanded(
            child: Container(
              color: AppColors.beigeBackground,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  _SettingsGroup(
                    title: "Типы уведомлений",
                    children: [
                      _SettingsToggle(
                        title: "Новые достижения",
                        subtitle: "Уведомления о разблокированных достижениях",
                        value: _newAchievementsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _newAchievementsEnabled = value;
                            _saveSettings();
                          });
                          _showSuccessMessage(
                            "Достижения ${value ? "включены" : "выключены"}",
                          );
                        },
                        icon: Icons.emoji_events,
                      ),
                      _SettingsToggle(
                        title: "Награды и монеты",
                        subtitle: "Уведомления о получении монет и наград",
                        value: _rewardsAndCoinsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _rewardsAndCoinsEnabled = value;
                            _saveSettings();
                          });
                          _showSuccessMessage(
                            "Награды ${value ? "включены" : "выключены"}",
                          );
                        },
                        icon: Icons.monetization_on,
                      ),
                      _SettingsToggle(
                        title: "Локации рядом",
                        subtitle: "Уведомления о близких исторических местах",
                        value: _nearbyLocationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _nearbyLocationsEnabled = value;
                            _saveSettings();
                          });
                          _showSuccessMessage(
                            "Локации ${value ? "включены" : "выключены"}",
                          );
                        },
                        icon: Icons.location_on,
                      ),
                      _SettingsToggle(
                        title: "Обновления приложения",
                        subtitle: "Уведомления о новых функциях и моделях",
                        value: _appUpdatesEnabled,
                        onChanged: (value) {
                          setState(() {
                            _appUpdatesEnabled = value;
                            _saveSettings();
                          });
                          _showSuccessMessage(
                            "Обновления ${value ? "включены" : "выключены"}",
                          );
                        },
                        icon: Icons.update,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

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
            left: 39,
            top: 33 + topInset,
            child: const Text(
              "Настройки уведомлений",
              style: AppTextStyles.headline25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(title, style: AppTextStyles.headline15),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: AppDecorations.redGradientSquare,
            child: Icon(icon, color: AppColors.whiteText, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headline15),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.body12),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.whiteText,
            activeTrackColor: AppColors.darkRed,
            inactiveThumbColor: AppColors.whiteText,
            inactiveTrackColor: AppColors.darkPink,
          ),
        ],
      ),
    );
  }
}

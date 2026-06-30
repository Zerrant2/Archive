// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'object_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'notifications_screen.dart';
import '../core/providers/user_provider.dart';
import '../core/providers/objects_provider.dart';
import '../core/services/achievement_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isWifiOnly = true;
  bool _isVibrationEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;
    final displayName = profile?.displayName ?? "Пользователь";
    final coins = userProvider.coins;
    final scansCount = userProvider.scansCount;

    return SingleChildScrollView(
      child: Column(
        children: [
          HeaderBlock(displayName: displayName, coins: coins),
          ContentBlock(
            isWifiOnly: _isWifiOnly,
            isVibrationEnabled: _isVibrationEnabled,
            onWifiChanged: (value) {
              setState(() {
                _isWifiOnly = value;
              });
            },
            onVibrationChanged: (value) {
              setState(() {
                _isVibrationEnabled = value;
              });
            },
            scansCount: scansCount,
          ),
        ],
      ),
    );
  }
}

class HeaderBlock extends StatelessWidget {
  final String displayName;
  final int coins;

  const HeaderBlock({super.key, required this.displayName, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          Positioned(
            left: 27,
            top: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.person, size: 45, color: AppColors.whiteText),
            ),
          ),
          Positioned(
            left: 115,
            top: 35,
            child: Text(
              displayName,
              style: const TextStyle(
                color: AppColors.whiteText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Positioned(
            left: 115,
            top: 60,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: "Мой баланс: ", style: TextStyle(fontSize: 11, fontFamily: 'Montserrat')),
                  TextSpan(text: "$coins", style: const TextStyle(fontSize: 16, fontFamily: 'Montserrat')),
                ],
              ),
              style: const TextStyle(color: AppColors.whiteText, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
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
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContentBlock extends StatelessWidget {
  final bool isWifiOnly;
  final bool isVibrationEnabled;
  final ValueChanged<bool> onWifiChanged;
  final ValueChanged<bool> onVibrationChanged;
  final int scansCount;

  const ContentBlock({
    super.key,
    required this.isWifiOnly,
    required this.isVibrationEnabled,
    required this.onWifiChanged,
    required this.onVibrationChanged,
    required this.scansCount,
  });

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выход из аккаунта"),
        content: const Text("Вы уверены, что хотите выйти?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Выйти"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удаление аккаунта"),
        content: const Text(
          "Все ваши данные будут удалены без возможности восстановления.\n\nВы уверены?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Удалить"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await Supabase.instance.client.rpc('delete_user_account');
        await Supabase.instance.client.auth.signOut();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Аккаунт успешно удален"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Ошибка удаления: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beigeBackground,
      child: Column(
        children: [
          StatsRow(scansCount: scansCount),
          const SizedBox(height: 16),
          const CoinsBlock(),
          const SizedBox(height: 20),
          const SectionTitle(title: "Мои сканирования"),
          const SizedBox(height: 10),
          const PlacesRow(),
          const SizedBox(height: 20),
          const SectionTitle(title: "Мои достижения"),
          const SizedBox(height: 10),
          const AchievementsRow(),
          const SizedBox(height: 30),
          const SectionTitle(title: "Настройки"),
          const SizedBox(height: 10),
          SettingsToggleCard(
            title: "Только Wi-Fi",
            subtitle: "Загрузка моделей",
            isOn: isWifiOnly,
            onChanged: onWifiChanged,
          ),
          const SizedBox(height: 15),
          SettingsToggleCard(
            title: "Вибрация",
            subtitle: "Тактильная обратная связь",
            isOn: isVibrationEnabled,
            onChanged: onVibrationChanged,
          ),
          const SizedBox(height: 30),
          _LogoutButton(onLogout: () => _logout(context)),
          const SizedBox(height: 15),
          _DeleteAccountButton(onDelete: () => _deleteAccount(context)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.darkRed,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primaryRed, width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.whiteText, size: 20),
            SizedBox(width: 10),
            Text(
              "Выйти из аккаунта",
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  final VoidCallback onDelete;

  const _DeleteAccountButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade400, width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever, color: AppColors.whiteText, size: 20),
            SizedBox(width: 10),
            Text(
              "Удалить аккаунт",
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final int scansCount;

  const StatsRow({super.key, required this.scansCount});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final unlockedAchievementsCount = userProvider.achievements.length;
    final totalAchievementsCount = AchievementService.allAchievements.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatItem(value: "$scansCount", label: "Сканирований"),
          StatItem(value: "$scansCount", label: "Загружено"),
          StatItem(
            value: "$unlockedAchievementsCount/$totalAchievementsCount", 
            label: "Достижений",
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String value;
  final String label;

  const StatItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.blueText36),
        const SizedBox(height: 5),
        Text(label, style: AppTextStyles.headline12),
      ],
    );
  }
}

class CoinsBlock extends StatelessWidget {
  const CoinsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<UserProvider>().coins;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ваши монеты", style: AppTextStyles.headline15),
              const SizedBox(height: 5),
              Text("$coins", style: AppTextStyles.blueText30),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9E3435),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: AppColors.whiteText, size: 20),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.headline15),
      ),
    );
  }
}

class PlacesRow extends StatelessWidget {
  const PlacesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final scannedPlaces = userProvider.scannedPlaces;
    final objectsProvider = context.watch<ObjectsProvider>();
    
    final scannedObjects = objectsProvider.allObjects
        .where((obj) => scannedPlaces.contains(obj.name))
        .toList();

    if (objectsProvider.allObjects.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (scannedObjects.isEmpty) {
      return Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera, size: 50, color: AppColors.greyBackground),
              const SizedBox(height: 10),
              Text(
                "Вы пока ничего не отсканировали",
                style: TextStyle(color: AppColors.blueText, fontSize: 14, fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 5),
              Text(
                "Отсканируйте QR-код у исторического объекта",
                style: TextStyle(color: AppColors.blueText.withValues(alpha: 0.7), fontSize: 12, fontFamily: 'Montserrat'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: scannedObjects.length,
        itemBuilder: (context, index) {
          final object = scannedObjects[index];
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ObjectDetailScreen(objectName: object.name),
                ),
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.redGradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.photo_camera,
                        color: AppColors.whiteText,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 110,
                    child: Text(
                      object.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.blueText11,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AchievementsRow extends StatelessWidget {
  const AchievementsRow({super.key});

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

    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();

    if (unlockedAchievements.isEmpty) {
      return Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 50, color: AppColors.greyBackground),
              const SizedBox(height: 10),
              Text(
                "У вас пока нет достижений",
                style: TextStyle(color: AppColors.blueText, fontSize: 14, fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 5),
              Text(
                "Сканируйте объекты и проходите тесты",
                style: TextStyle(color: AppColors.blueText.withValues(alpha: 0.7), fontSize: 12, fontFamily: 'Montserrat'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: unlockedAchievements.map((achievement) {
          return Container(
            width: 135,
            height: 140,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: AppColors.redGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.whiteText,
                  size: 35,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body11,
                ),
                const SizedBox(height: 5),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFBCB0B0),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


class SettingsToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const SettingsToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headline20),
              Text(subtitle, style: AppTextStyles.headline12),
            ],
          ),
          Switch(
            value: isOn,
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
// lib/core/services/achievement_service.dart
import '../../services/notification_service.dart';

class AchievementService {
  static final List<AchievementDefinition> allAchievements = [
    AchievementDefinition(
      id: 'first_scan',
      name: 'Первооткрыватель',
      description: 'Первое сканирование выполнено',
      howToGet: 'Отсканируйте QR-код любого исторического здания',
      checkCondition: (scannedPlaces, completedTests, coins) => scannedPlaces.isNotEmpty,
      maxProgress: 1,
      getCurrentValue: (scannedPlaces, completedTests, coins) => scannedPlaces.isNotEmpty ? 1 : 0,
    ),
    AchievementDefinition(
      id: 'historian',
      name: 'Историк',
      description: 'Сканировано 5 зданий',
      howToGet: 'Отсканируйте 5 различных исторических зданий',
      checkCondition: (scannedPlaces, completedTests, coins) => scannedPlaces.length >= 5,
      maxProgress: 5,
      getCurrentValue: (scannedPlaces, completedTests, coins) => scannedPlaces.length,
    ),
    AchievementDefinition(
      id: 'expert',
      name: 'Эксперт',
      description: 'Сканировано 10 зданий',
      howToGet: 'Отсканируйте 10 различных исторических зданий',
      checkCondition: (scannedPlaces, completedTests, coins) => scannedPlaces.length >= 10,
      maxProgress: 10,
      getCurrentValue: (scannedPlaces, completedTests, coins) => scannedPlaces.length,
    ),
    AchievementDefinition(
      id: 'connoisseur',
      name: 'Знаток',
      description: 'Пройдено 5 тестов',
      howToGet: 'Пройдите 5 тестов об исторических местах',
      checkCondition: (scannedPlaces, completedTests, coins) => completedTests.length >= 5,
      maxProgress: 5,
      getCurrentValue: (scannedPlaces, completedTests, coins) => completedTests.length,
    ),
    AchievementDefinition(
      id: 'millionaire',
      name: 'Миллионер',
      description: 'Накоплено 1000 монет',
      howToGet: 'Соберите 1000 монет',
      checkCondition: (scannedPlaces, completedTests, coins) => coins >= 1000,
      maxProgress: 1000,
      getCurrentValue: (scannedPlaces, completedTests, coins) => coins,
    ),
  ];

  static int calculateAchievementsCount({
    required List<String> scannedPlaces,
    required List<String> completedTests,
    required int coins,
  }) {
    int count = 0;
    for (var achievement in allAchievements) {
      if (achievement.checkCondition(scannedPlaces, completedTests, coins)) {
        count++;
      }
    }
    return count;
  }

  static List<AchievementWithState> getAllAchievementsWithState({
    required List<String> scannedPlaces,
    required List<String> completedTests,
    required int coins,
    required Map<String, bool> unlockedAchievements,
  }) {
    return allAchievements.map((achievement) {
      final isUnlocked = unlockedAchievements[achievement.id] ?? 
                         achievement.checkCondition(scannedPlaces, completedTests, coins);
      final currentValue = achievement.getCurrentValue(scannedPlaces, completedTests, coins);
      final progress = (currentValue / achievement.maxProgress).clamp(0.0, 1.0);
      
      return AchievementWithState(
        definition: achievement,
        isUnlocked: isUnlocked,
        progress: progress,
        currentValue: currentValue,
      );
    }).toList();
  }

  static List<AchievementDefinition> getNewAchievements({
    required List<String> oldScannedPlaces,
    required List<String> oldCompletedTests,
    required int oldCoins,
    required List<String> newScannedPlaces,
    required List<String> newCompletedTests,
    required int newCoins,
  }) {
    final newAchievements = <AchievementDefinition>[];
    
    for (var achievement in allAchievements) {
      final wasUnlocked = achievement.checkCondition(oldScannedPlaces, oldCompletedTests, oldCoins);
      final isUnlocked = achievement.checkCondition(newScannedPlaces, newCompletedTests, newCoins);
      
      if (!wasUnlocked && isUnlocked) {
        newAchievements.add(achievement);
      }
    }
    
    return newAchievements;
  }

  static Future<void> notifyNewAchievements(List<AchievementDefinition> achievements) async {
    for (var achievement in achievements) {
      await NotificationService.addNotification(
        title: "Новое достижение!",
        message: "Вы разблокировали достижение \"${achievement.name}\"",
        type: NotificationType.achievement,
      );
    }
  }
}

class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String howToGet;
  final bool Function(List<String>, List<String>, int) checkCondition;
  final int maxProgress;
  final int Function(List<String>, List<String>, int) getCurrentValue;

  AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.howToGet,
    required this.checkCondition,
    required this.maxProgress,
    required this.getCurrentValue,
  });
}

class AchievementWithState {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final double progress;
  final int currentValue;

  AchievementWithState({
    required this.definition,
    required this.isUnlocked,
    required this.progress,
    required this.currentValue,
  });

  String get id => definition.id;
  String get name => definition.name;
  String get description => definition.description;
  String get howToGet => definition.howToGet;
  int get maxProgress => definition.maxProgress;
}
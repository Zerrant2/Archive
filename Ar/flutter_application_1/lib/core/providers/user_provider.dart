// lib/core/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/notification_service.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import '../models/achievement.dart';

/// Провайдер для управления данными пользователя
class UserProvider extends ChangeNotifier {
  UserProfile? _profile;
  UserStats? _stats;
  final Map<String, Achievement> _achievements = {};
  
  bool _isLoading = false;
  String? _error;
  DateTime? _lastLoadTime;
  
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Геттеры
  UserProfile? get profile => _profile;
  UserStats? get stats => _stats;
  
  int get coins => _stats?.coins ?? 0;
  int get scansCount => _stats?.scansCount ?? 0;
  int get achievementsCount => _stats?.achievementsCount ?? 0;
  
  List<String> get scannedPlaces => _stats?.scannedPlaces ?? [];
  List<String> get completedTests => _stats?.completedTests ?? [];
  Map<String, Achievement> get achievements => Map.unmodifiable(_achievements);
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _profile != null;
  
  bool isPlaceScanned(String placeName) => _stats?.scannedPlacesSet.contains(placeName) ?? false;
  bool isTestCompleted(String testKey) => _stats?.completedTestsSet.contains(testKey) ?? false;
  bool isAchievementUnlocked(String achievementId) => _achievements.containsKey(achievementId);
  
  _UserStateSnapshot _captureState() => _UserStateSnapshot(
    profile: _profile,
    stats: _stats,
    achievements: Map.from(_achievements),
  );
  
  void _restoreState(_UserStateSnapshot snapshot) {
    _profile = snapshot.profile;
    _stats = snapshot.stats;
    _achievements.clear();
    _achievements.addAll(snapshot.achievements);
    notifyListeners();
  }
  
  /// Загрузка всех данных пользователя
  Future<bool> loadUserData({bool forceRefresh = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    // Проверка кеша
    if (!forceRefresh && _lastLoadTime != null) {
      final cacheAge = DateTime.now().difference(_lastLoadTime!);
      if (cacheAge < _cacheDuration && _profile != null && _stats != null) {
        if (kDebugMode) debugPrint('Using cached user data (age: ${cacheAge.inSeconds}s)');
        return true;
      }
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadDataSeparately(user.id);
      
      _lastLoadTime = DateTime.now();
      _error = null;
      
      
      if (kDebugMode) {
        debugPrint('Loaded user data: ${_profile?.displayName ?? "unknown"}, coins=${_stats?.coins ?? 0}, '
                  'scans=${_stats?.scansCount ?? 0}, achievements=${_achievements.length}');
        debugPrint('Completed tests: ${_stats?.completedTests ?? []}');
      }
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('Error loading user data: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Загрузка данных по отдельности
  Future<void> _loadDataSeparately(String userId) async {
    // Загружаем профиль
    try {
      final profileResult = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (profileResult != null) {
        _profile = UserProfile.fromJson(profileResult);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading profile: $e');
    }
    
    // Загружаем статистику
    try {
      final statsResult = await Supabase.instance.client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (statsResult != null) {
        _stats = UserStats.fromJson(statsResult);
      } else {
        await _createUserStats(userId);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading stats: $e');
      _stats ??= UserStats.empty(userId);
    }
    
    // Загружаем достижения
    try {
      final achievementsResult = await Supabase.instance.client
          .from('user_achievements')
          .select()
          .eq('user_id', userId);
      
      _achievements.clear();
      for (final ach in achievementsResult) {
        final achievement = Achievement.fromJson(ach);
        _achievements[achievement.id] = achievement;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading achievements: $e');
    }
  }
  
  Future<void> _createUserStats(String userId) async {
    try {
      await Supabase.instance.client.from('user_stats').insert({
        'user_id': userId,
        'coins': 0,
        'scans_count': 0,
        'achievements_count': 0,
        'scanned_places': [],
        'completed_tests': [],
      });
      _stats = UserStats.empty(userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating user stats: $e');
      _stats = UserStats.empty(userId);
    }
  }
  
  /// Сканирование места с optimistic update
  Future<ScanResult> addScannedPlace({
    required String placeName,
    required String objectId,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return ScanResult.failure('Пользователь не авторизован');
    }
    
    if (isPlaceScanned(placeName)) {
      return ScanResult.failure('Место уже отсканировано', isDuplicate: true);
    }
    
    final previousState = _captureState();
    
    _applyOptimisticScan(placeName);
    notifyListeners();
    
    try {
      final result = await Supabase.instance.client.rpc(
        'save_scan',
        params: {
          'p_user_id': user.id,
          'p_object_id': objectId,
          'p_object_name': placeName,
          'p_earned_coins': 50,
        },
      ).timeout(const Duration(seconds: 10));
      
      if (result != null && result['success'] == true) {
        _syncWithServerScanResult(result, placeName);
        _lastLoadTime = null;
        
        await NotificationService.addNotification(
          title: "Новое место открыто!",
          message: "Вы получили 50 монет за открытие $placeName",
          type: NotificationType.reward,
        );
        
        return ScanResult.success(coinsEarned: 50, totalCoins: _stats?.coins ?? 0);
      } else {
        _restoreState(previousState);
        final message = result?['message'] ?? 'Ошибка при сохранении сканирования';
        return ScanResult.failure(message);
      }
    } catch (e) {
      _restoreState(previousState);
      if (kDebugMode) debugPrint('Error adding scanned place: $e');
      return ScanResult.failure('Ошибка сети: ${e.toString()}');
    }
  }
  
  void _applyOptimisticScan(String placeName) {
    if (_stats == null) return;
    
    final updatedScannedPlaces = List<String>.from(_stats!.scannedPlaces)..add(placeName);
    
    _stats = _stats!.copyWith(
      coins: _stats!.coins + 50,
      scansCount: _stats!.scansCount + 1,
      scannedPlaces: updatedScannedPlaces,
    );
  }
  
  void _syncWithServerScanResult(Map<String, dynamic> result, String placeName) {
    final newCoins = result['total_coins'] ?? result['coins_earned'];
    final newAchievements = result['new_achievements'] as List? ?? [];
    
    if (_stats != null && newCoins != null) {
      _stats = _stats!.copyWith(
        coins: newCoins is int ? newCoins : _stats!.coins + 50,
        scansCount: result['scans_count'] ?? _stats!.scansCount,
      );
    }
    
    for (final ach in newAchievements) {
      final achievement = Achievement(
        id: ach['ach_id'],
        name: ach['ach_name'],
        unlockedAt: DateTime.now(),
      );
      _achievements[achievement.id] = achievement;
    }
  }
  
  /// Сохранение результата теста
  Future<TestResult> addCompletedTest({
    required String testKey,
    required String objectName,
    required String testType,
    required int earnedCoins,
    int score = 100,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return TestResult.failure('Пользователь не авторизован');
    }
    
    // Принудительно обновляем данные перед проверкой
    await loadUserData(forceRefresh: true);
    
    // Проверка на повторное прохождение
    if (isTestCompleted(testKey)) {
      if (kDebugMode) debugPrint('Test already completed: $testKey');
      return TestResult.failure('Тест уже пройден', isDuplicate: true);
    }
    
    final previousState = _captureState();
    
    // Optimistic update
    _applyOptimisticTest(testKey, earnedCoins);
    notifyListeners();
    
    try {
      final result = await Supabase.instance.client.rpc(
        'save_test_result',
        params: {
          'p_user_id': user.id,
          'p_test_key': testKey,
          'p_object_name': objectName,
          'p_test_type': testType,
          'p_score': score,
          'p_earned_coins': earnedCoins,
        },
      ).timeout(const Duration(seconds: 10));
      
      if (kDebugMode) {
        debugPrint('Save test result response: $result');
      }
      
      if (result != null && result['success'] == true) {
        _syncWithServerTestResult(result, testKey);
        _lastLoadTime = null;
        
        await NotificationService.addNotification(
          title: "Тест пройден!",
          message: "Вы заработали $earnedCoins монет за тест по $objectName",
          type: NotificationType.reward,
        );
        
        return TestResult.success(
          coinsEarned: earnedCoins,
          totalCoins: _stats?.coins ?? 0,
        );
      } else {
        _restoreState(previousState);
        final errorMsg = result?['message'] ?? 'Ошибка при сохранении теста';
        if (errorMsg.contains('already') || errorMsg.contains('already completed')) {
          return TestResult.failure('Тест уже пройден', isDuplicate: true);
        }
        return TestResult.failure(errorMsg);
      }
    } catch (e) {
      _restoreState(previousState);
      if (kDebugMode) debugPrint('Error adding test result: $e');
      return TestResult.failure('Ошибка сети: ${e.toString()}');
    }
  }
  
  void _applyOptimisticTest(String testKey, int earnedCoins) {
    if (_stats == null) return;
    
    final updatedTests = List<String>.from(_stats!.completedTests)..add(testKey);
    
    _stats = _stats!.copyWith(
      coins: _stats!.coins + earnedCoins,
      completedTests: updatedTests,
    );
    
    if (kDebugMode) {
      debugPrint('Optimistic update: added test $testKey, new coins: ${_stats!.coins}');
    }
  }
  
  void _syncWithServerTestResult(Map<String, dynamic> result, String testKey) {
    final totalCoins = result['total_coins'];
    final newAchievements = result['new_achievements'] as List? ?? [];
    
    if (_stats != null && totalCoins != null) {
      _stats = _stats!.copyWith(
        coins: totalCoins is int ? totalCoins : _stats!.coins,
      );
    }
    
    // Убеждаемся, что тест отмечен как пройденный
    if (_stats != null && !_stats!.completedTests.contains(testKey)) {
      final updatedTests = List<String>.from(_stats!.completedTests)..add(testKey);
      _stats = _stats!.copyWith(completedTests: updatedTests);
    }
    
    for (final ach in newAchievements) {
      final achievement = Achievement(
        id: ach['ach_id'],
        name: ach['ach_name'],
        unlockedAt: DateTime.now(),
      );
      _achievements[achievement.id] = achievement;
    }
    
    if (kDebugMode) {
      debugPrint('After sync: completed tests = ${_stats?.completedTests}');
    }
  }
  
  /// Обновление профиля пользователя
  Future<bool> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    final previousProfile = _profile;
    
    if (_profile != null) {
      _profile = _profile!.copyWith(
        displayName: displayName ?? _profile!.displayName,
        username: username ?? _profile!.username,
        avatarUrl: avatarUrl ?? _profile!.avatarUrl,
      );
      notifyListeners();
    }
    
    try {
      final result = await Supabase.instance.client.rpc(
        'update_profile',
        params: {
          'p_user_id': user.id,
          'p_display_name': displayName,
          'p_username': username,
          'p_avatar_url': avatarUrl,
        },
      );
      
      if (result != null && result is Map<String, dynamic>) {
        _profile = UserProfile.fromJson(result);
        _lastLoadTime = null;
        return true;
      } else {
        _profile = previousProfile;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _profile = previousProfile;
      notifyListeners();
      if (kDebugMode) debugPrint('Error updating profile: $e');
      return false;
    }
  }
  
  void logout() {
    _profile = null;
    _stats = null;
    _achievements.clear();
    _lastLoadTime = null;
    _error = null;
    notifyListeners();
  }
  
  void invalidateCache() {
    _lastLoadTime = null;
  }
}

class _UserStateSnapshot {
  final UserProfile? profile;
  final UserStats? stats;
  final Map<String, Achievement> achievements;
  
  _UserStateSnapshot({
    this.profile,
    this.stats,
    required this.achievements,
  });
}

class ScanResult {
  final bool success;
  final int? coinsEarned;
  final int? totalCoins;
  final String? error;
  final bool isDuplicate;
  
  ScanResult._({
    required this.success,
    this.coinsEarned,
    this.totalCoins,
    this.error,
    this.isDuplicate = false,
  });
  
  factory ScanResult.success({required int coinsEarned, required int totalCoins}) {
    return ScanResult._(
      success: true,
      coinsEarned: coinsEarned,
      totalCoins: totalCoins,
    );
  }
  
  factory ScanResult.failure(String error, {bool isDuplicate = false}) {
    return ScanResult._(
      success: false,
      error: error,
      isDuplicate: isDuplicate,
    );
  }
}

class TestResult {
  final bool success;
  final int? coinsEarned;
  final int? totalCoins;
  final String? error;
  final bool isDuplicate;
  
  TestResult._({
    required this.success,
    this.coinsEarned,
    this.totalCoins,
    this.error,
    this.isDuplicate = false,
  });
  
  factory TestResult.success({required int coinsEarned, required int totalCoins}) {
    return TestResult._(
      success: true,
      coinsEarned: coinsEarned,
      totalCoins: totalCoins,
    );
  }
  
  factory TestResult.failure(String error, {bool isDuplicate = false}) {
    return TestResult._(
      success: false,
      error: error,
      isDuplicate: isDuplicate,
    );
  }
}

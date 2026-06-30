// lib/services/notification_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_item.dart';

enum NotificationType {
  achievement,
  reward,
  location,
  update,
}

class NotificationService {
  static const String _keyNewAchievements = 'notif_new_achievements';
  static const String _keyRewardsAndCoins = 'notif_rewards_coins';
  static const String _keyNearbyLocations = 'notif_nearby_locations';
  static const String _keyAppUpdates = 'notif_app_updates';
  static const String _keyNotificationsList = 'notifications_list';
  
  static List<NotificationItem> _notifications = [];

  static Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_keyNotificationsList);
    
    if (notificationsJson != null && notificationsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications = decoded.map((item) {
          return NotificationItem.fromJson(item as Map<String, dynamic>);
        }).toList();
      } catch (e) {
        _notifications = [];
      }
    } else {
      _notifications = [];
    }
  }

  static Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_keyNotificationsList, notificationsJson);
  }

  static Future<Map<String, bool>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'newAchievements': prefs.getBool(_keyNewAchievements) ?? true,
      'rewardsAndCoins': prefs.getBool(_keyRewardsAndCoins) ?? true,
      'nearbyLocations': prefs.getBool(_keyNearbyLocations) ?? true,
      'appUpdates': prefs.getBool(_keyAppUpdates) ?? true,
    };
  }
  
  static Future<void> saveSettings({
    required bool newAchievements,
    required bool rewardsAndCoins,
    required bool nearbyLocations,
    required bool appUpdates,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNewAchievements, newAchievements);
    await prefs.setBool(_keyRewardsAndCoins, rewardsAndCoins);
    await prefs.setBool(_keyNearbyLocations, nearbyLocations);
    await prefs.setBool(_keyAppUpdates, appUpdates);
  }
  
  static Future<bool> addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    await _loadNotifications();
    
    final settings = await loadSettings();
    bool isEnabled = false;
    
    switch (type) {
      case NotificationType.achievement:
        isEnabled = settings['newAchievements']!;
        break;
      case NotificationType.reward:
        isEnabled = settings['rewardsAndCoins']!;
        break;
      case NotificationType.location:
        isEnabled = settings['nearbyLocations']!;
        break;
      case NotificationType.update:
        isEnabled = settings['appUpdates']!;
        break;
    }
    
    if (!isEnabled) {
      return false;
    }
    
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      message: message,
      time: _getTimeAgo(),
      isRead: false,
      type: type,
    );
    
    _notifications.insert(0, notification);
    await _saveNotifications();
    
    return true;
  }
  
  static Future<List<NotificationItem>> getNotifications() async {
    await _loadNotifications();
    return List.from(_notifications);
  }
  
  static Future<void> markAsRead(int id) async {
    await _loadNotifications();
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
    }
  }
  
  static Future<void> markAllAsRead() async {
    await _loadNotifications();
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await _saveNotifications();
  }
  
  static String _getTimeAgo() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day}.${now.month}.${now.year}";
  }
}

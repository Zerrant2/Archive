// lib/core/services/coins_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';

class CoinsService {
  static Future<int?> addCoins({
    required String userId,
    required int currentCoins,
    required int amount,
    String? reason,
  }) async {
    final newCoins = currentCoins + amount;
    
    try {
      await Supabase.instance.client
          .from('user_stats')
          .upsert({
            'user_id': userId,
            'coins': newCoins,
          });
      
      if (reason != null) {
        await notifyReward(amount, reason);
      }
      
      return newCoins;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding coins: $e');
      }
      return null;
    }
  }

  static Future<int?> subtractCoins({
    required String userId,
    required int currentCoins,
    required int amount,
    String? reason,
  }) async {
    if (currentCoins < amount) return null;
    
    final newCoins = currentCoins - amount;
    
    try {
      await Supabase.instance.client
          .from('user_stats')
          .upsert({
            'user_id': userId,
            'coins': newCoins,
          });
      
      return newCoins;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subtracting coins: $e');
      }
      return null;
    }
  }

  static bool hasEnoughCoins(int currentCoins, int requiredAmount) {
    return currentCoins >= requiredAmount;
  }

  static Future<void> notifyReward(int coins, String reason) async {
    await NotificationService.addNotification(
      title: "+$coins монет!",
      message: "Награда за $reason",
      type: NotificationType.reward,
    );
  }
}
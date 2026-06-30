// lib/services/scan_history_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanHistoryService {
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('scans')
          .select('object_name, scanned_at, earned_coins')
          .eq('user_id', user.id)
          .order('scanned_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading scan history: $e');
      }
      return [];
    }
  }
  
  static Future<DateTime?> getScanDate(String objectName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('scans')
          .select('scanned_at')
          .eq('user_id', user.id)
          .eq('object_name', objectName)
          .maybeSingle();
      
      if (response != null && response['scanned_at'] != null) {
        return DateTime.parse(response['scanned_at']);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting scan date: $e');
      }
      return null;
    }
  }
}
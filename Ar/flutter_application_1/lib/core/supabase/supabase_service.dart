// lib/core/supabase/supabase_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await dotenv.load(fileName: "assets/.env");
    
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Отправить код подтверждения на email
  static Future<void> sendVerificationCode(String email) async {
    // Здесь будет запрос к вашей функции на Supabase
    await client.functions.invoke(
      'send-verification-code',
      body: {'email': email},
    );
  }
  
  // Проверить код подтверждения
  static Future<bool> verifyCode(String email, String code) async {
    final response = await client.functions.invoke(
      'verify-code',
      body: {'email': email, 'code': code},
    );
    return response.data['valid'] == true;
  }
}
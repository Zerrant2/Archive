// lib/services/llm7_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LLM7Service {
  static const String _apiKey = "unused";
  static const String _baseUrl = "https://api.llm7.io/v1/chat/completions";
  
  static String _buildPrompt({
    required String objectName,
    required String shortDescription,
    required String detailedDescription,
    required String userQuestion,
    required bool isFirstQuestion,
  }) {
    final greetingPart = isFirstQuestion 
        ? "Ты - дружелюбный AI-гид. Сначала тепло поприветствуй пользователя, представься как 'Исторический ассистент [$objectName]'. "
        : "";
    
    return """
$greetingPart
Ты - дружелюбный AI-гид по историческим достопримечательностям Волгограда.

О достопримечательности "$objectName" ты знаешь следующее:
Краткая справка: $shortDescription
Подробная информация: $detailedDescription

Правила:
1. Будь очень доброжелательным
2. Отвечай на вопросы пользователя, используя ТОЛЬКО информацию из справки выше
3. Если вопрос выходит за рамки известной информации, вежливо скажи: "К сожалению, в моей исторической справке нет информации об этом. Но я могу рассказать о том, что знаю!"
4. Отвечай кратко и по делу (2-4 предложения)
5. Общайся на русском языке

Вопрос пользователя: $userQuestion

Твой ответ:""";
  }
  
  static Future<String> askQuestion({
    required String objectName,
    required String shortDescription,
    required String detailedDescription,
    required String userQuestion,
    bool isFirstQuestion = false,
  }) async {
    try {
      final prompt = _buildPrompt(
        objectName: objectName,
        shortDescription: shortDescription,
        detailedDescription: detailedDescription,
        userQuestion: userQuestion,
        isFirstQuestion: isFirstQuestion,
      );
      
      final response = await _callLLM7Api(prompt);
      return response;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint("LLM7 Service Error: $e");
      }
      return "Извините, сейчас я немного устал. Попробуйте спросить еще раз через минуту!";
    }
  }
  
  static Future<String> _callLLM7Api(String prompt) async {
    try {
      final client = http.Client();
      
      final requestBody = {
        "model": "default",
        "messages": [
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 0.7,
        "max_tokens": 300,
      };
      
      if (kDebugMode) {
        debugPrint("Sending request to LLM7...");
      }
      
      final response = await client.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      if (kDebugMode) {
        debugPrint("Response status: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] as String? ?? 
                 "Извините, не удалось получить ответ";
        }
        return "Извините, формат ответа неожиданный";
      } else {
        if (kDebugMode) {
          debugPrint("LLM7 API Error: ${response.statusCode} - ${response.body}");
        }
        return "Извините, произошла ошибка на сервере. Попробуйте позже!";
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("LLM7 API Exception: $e");
      }
      return "Извините, не удалось соединиться с сервером. Проверьте интернет-соединение!";
    }
  }
}
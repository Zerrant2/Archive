// lib/services/ai_assistant_service.dart
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIAssistantService {
  static const String _apiKey = "AIzaSyCML466_K3K9HZIyI81NBfuhuvy4NX1GWQ";
  
  static GenerativeModel? _model;
  
  static GenerativeModel get _getModel {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
    );
    return _model!;
  }
  
  static String _buildPrompt(String objectName, String shortDescription, String detailedDescription, String userQuestion) {
    return """
Ты - дружелюбный AI-гид по историческим достопримечательностям Волгограда.
Твое имя: "Исторический ассистент [$objectName]"

О достопримечательности "$objectName" ты знаешь следующее:
Краткая справка: $shortDescription
Подробная информация: $detailedDescription

Твоя роль:
1. Приветствуй пользователя тепло и доброжелательно (если это первый вопрос в диалоге)
2. Отвечай на вопросы пользователя, используя ТОЛЬКО информацию из справки выше
3. Если вопрос выходит за рамки известной информации, вежливо скажи: "К сожалению, в моей исторической справке нет информации об этом. Но я могу рассказать о том, что знаю!"
4. Будь очень доброжелательным
5. Отвечай кратко и по делу (2-3 предложения)

Вопрос пользователя: $userQuestion

Твой ответ (дружелюбно и информативно):""";
  }
  
  static Future<String> askQuestion({
    required String objectName,
    required String shortDescription,
    required String detailedDescription,
    required String userQuestion,
    bool isFirstQuestion = false,
  }) async {
    try {
      final model = _getModel;
      
      String prompt;
      if (isFirstQuestion) {
        prompt = _buildPromptWithGreeting(objectName, shortDescription, detailedDescription, userQuestion);
      } else {
        prompt = _buildPrompt(objectName, shortDescription, detailedDescription, userQuestion);
      }
      
      final response = await model.generateContent([
        Content.text(prompt),
      ]);
      
      return response.text?.trim() ?? "Извините, я не смог сформулировать ответ. Попробуйте спросить по-другому!";
    } catch (e) {
      if (kDebugMode) {
        debugPrint("AI Assistant Error: $e");
      }
      return "Извините, сейчас я немного устал. Попробуйте спросить еще раз через минуту!";
    }
  }
  
  static String _buildPromptWithGreeting(String objectName, String shortDescription, String detailedDescription, String userQuestion) {
    return """
Ты - дружелюбный AI-гид по историческим достопримечательностям Волгограда.
Твое имя: "Исторический ассистент [$objectName]"

О достопримечательности "$objectName" ты знаешь следующее:
Краткая справка: $shortDescription
Подробная информация: $detailedDescription

Твоя роль:
1. Сначала тепло поприветствуй пользователя!
   Пример: "Здравствуйте! Я исторический ассистент «$objectName». Рад помочь вам узнать больше об этом удивительном месте! Задавайте любые вопросы"
2. Затем ответь на вопрос пользователя, используя информацию из справки
3. Будь очень доброжелательным, используй смайлики
4. Отвечай кратко

Вопрос пользователя: $userQuestion

Твой ответ (сначала приветствие, потом ответ на вопрос):""";
  }
}
// lib/screens/detailed_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'test_screen.dart';
import 'ai_chat_screen.dart';
import '../core/providers/objects_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../models/historical_object.dart';

class DetailedHistoryScreen extends StatelessWidget {
  final String objectName;

  const DetailedHistoryScreen({super.key, required this.objectName});

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final object = objectsProvider.getObjectByName(objectName);
    
    if (object == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Объект не найден",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Назад"),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              object.name,
              style: AppTextStyles.headline25,
            ),
            const Text(
              "Подробная информация",
              style: TextStyle(
                color: Color(0xBDFFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat'
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.asset(
                object.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFA69797),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 60, color: AppColors.whiteText),
                          SizedBox(height: 10),
                          Text(
                            "Фото недоступно",
                            style: TextStyle(color: AppColors.whiteText, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Container(
              color: AppColors.beigeBackground,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildDetailedDescription(object.detailedDescription),
                  ),

                  const Divider(
                    color: Color(0xFFDFBEC7),
                    thickness: 1,
                    height: 32,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    child: Text(
                      "Проверьте свои знания, пройдя сложный тест по истории этого места",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline15,
                    ),
                  ),

                  _TestBlock(objectName: object.name),
                  const SizedBox(height: 20),
                  _AIAssistantBlock(object: object),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedDescription(String text) {
    final paragraphs = text.split('\n\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph,
            style: const TextStyle(
              color: Color(0xBF870C0E),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TestBlock extends StatelessWidget {
  final String objectName;
  const _TestBlock({required this.objectName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestScreen(
              objectName: objectName,
              rewardCoins: 40,
              isHardTest: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 21),
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.pinkPanel(hasShadow: false),
        child: Row(
          children: [
            Container(
              width: 59,
              height: 53,
              decoration: AppDecorations.redGradientSquare,
              child: const Icon(Icons.quiz, color: AppColors.whiteText, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Сложный тест",
                    style: AppTextStyles.headline15,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Проверьте углубленные знания ",
                          style: TextStyle(color: Color(0xFF9E3435), fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: "+40",
                          style: AppTextStyles.blueText15,
                        ),
                        const TextSpan(
                          text: " монет",
                          style: TextStyle(color: Color(0xFF9E3435), fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF9E3435), size: 16),
          ],
        ),
      ),
    );
  }
}

class _AIAssistantBlock extends StatelessWidget {
  final HistoricalObject object;
  const _AIAssistantBlock({required this.object});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIChatScreen(object: object),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 21),
        padding: const EdgeInsets.all(15),
        decoration: AppDecorations.pinkPanel(hasShadow: false),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 59,
              height: 59,
              decoration: AppDecorations.redGradientSquare,
              child: const Icon(Icons.assistant, color: AppColors.whiteText, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI-Ассистент",
                    style: AppTextStyles.headline15,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkPink,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "Задайте свой вопрос об этом месте",
                      style: TextStyle(
                        color: Color(0xFFF2E3E3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 47,
              height: 47,
              decoration: AppDecorations.redGradientSquare,
              child: const Icon(Icons.send, color: AppColors.whiteText, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

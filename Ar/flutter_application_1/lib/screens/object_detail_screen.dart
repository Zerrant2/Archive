// lib/screens/object_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'detailed_history_screen.dart';
import 'test_screen.dart';
import 'ai_chat_screen.dart';
import 'historical_experience_screen.dart';
import '../core/providers/objects_provider.dart';
import '../models/historical_object.dart';
import '../services/historical_experience_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class ObjectDetailScreen extends StatelessWidget {
  final String objectName;

  const ObjectDetailScreen({super.key, required this.objectName});

  @override
  Widget build(BuildContext context) {
    final objectsProvider = Provider.of<ObjectsProvider>(context);
    final object = objectsProvider.getObjectByName(objectName);

    if (object == null) {
      return Scaffold(
        body: Center(child: Text("Объект '$objectName' не найден")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.beigeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          object.name,
          style: const TextStyle(
            color: AppColors.whiteText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icon(
                            Icons.image,
                            size: 60,
                            color: AppColors.whiteText,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Фото недоступно",
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkRed,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      object.century,
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkPink,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      object.architectureType,
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _HistoricalExperienceButton(object: object),

            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: AppDecorations.historyCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Историческая сводка",
                        style: AppTextStyles.headline15,
                      ),
                      _DetailButton(objectName: object.name),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(object.shortDescription, style: AppTextStyles.body12),
                  const SizedBox(height: 15),
                  const Divider(color: Color(0xFFA33D3E)),
                  const SizedBox(height: 10),

                  _InfoRow(label: "Адрес:", value: object.address),
                  const SizedBox(height: 8),

                  _InfoRow(
                    label: "Годы существования:",
                    value: object.yearsOfExistence,
                  ),
                  const SizedBox(height: 8),

                  _InfoRow(label: "Источники:", value: object.sources),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Аудиогид в разработке"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: AppDecorations.pinkPanel(hasShadow: false),
                child: Row(
                  children: [
                    Container(
                      width: 59,
                      height: 59,
                      decoration: AppDecorations.redGradientSquare,
                      child: const Icon(
                        Icons.headphones,
                        color: AppColors.whiteText,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Аудиогид",
                            style: AppTextStyles.headline15,
                          ),
                          const Text(
                            "Длительность: 3:45",
                            style: AppTextStyles.blueText12,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Слушать",
                        style: AppTextStyles.whiteText12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestScreen(
                      objectName: object.name,
                      rewardCoins: 20,
                      isHardTest: false,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: AppDecorations.pinkPanel(hasShadow: false),
                child: Row(
                  children: [
                    Container(
                      width: 59,
                      height: 59,
                      decoration: AppDecorations.redGradientSquare,
                      child: const Icon(
                        Icons.quiz,
                        color: AppColors.whiteText,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Пройти тест",
                            style: AppTextStyles.headline15,
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Заработайте ",
                                  style: TextStyle(
                                    color: Color(0xFF9E3435),
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: "+20",
                                  style: AppTextStyles.blueText15,
                                ),
                                const TextSpan(
                                  text: " монет",
                                  style: TextStyle(
                                    color: Color(0xFF9E3435),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF9E3435),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIChatScreen(object: object),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: AppDecorations.pinkPanel(hasShadow: false),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 59,
                      height: 59,
                      decoration: AppDecorations.redGradientSquare,
                      child: const Icon(
                        Icons.assistant,
                        color: AppColors.whiteText,
                        size: 30,
                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
                      child: const Icon(
                        Icons.send,
                        color: AppColors.whiteText,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _HistoricalExperienceButton extends StatelessWidget {
  final HistoricalObject object;

  const _HistoricalExperienceButton({required this.object});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HistoricalExperienceAvailability>(
      future: HistoricalExperienceService.availabilityFor(object),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final availability = snapshot.data;
        final isAvailable = availability?.canOpen == true;
        final has3dMode = availability?.has3dMode == true;
        final label = isLoading
            ? "Проверяем материалы"
            : isAvailable
            ? "Исторический опыт"
            : "Материалы готовятся";

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isLoading
              ? null
              : () {
                  if (!isAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          availability?.unavailableMessageFor(object.name) ??
                              "Для объекта \"${object.name}\" пока нет готовых материалов",
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HistoricalExperienceScreen(object: object),
                    ),
                  );
                },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            decoration: isAvailable || isLoading
                ? AppDecorations.redGradientSquare
                : BoxDecoration(
                    color: const Color(0xFFCBA9A9),
                    borderRadius: BorderRadius.circular(15),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.whiteText,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    isAvailable
                        ? has3dMode
                              ? Icons.travel_explore
                              : Icons.public
                        : Icons.lock_clock,
                    color: AppColors.whiteText,
                    size: 22,
                  ),
                const SizedBox(width: 10),
                Text(label, style: AppTextStyles.whiteText18),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Experimental3DButton extends StatelessWidget {
  final String objectName;

  const Experimental3DButton({super.key, required this.objectName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("3D-режим для $objectName будет добавлен позже"),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.darkRed, width: 1.4),
          color: const Color(0xFFFFF8F3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_in_ar, color: AppColors.darkRed, size: 20),
            SizedBox(width: 8),
            Text(
              "3D-режим экспериментальный",
              style: TextStyle(
                color: AppColors.darkRed,
                fontSize: 14,
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

class _DetailButton extends StatelessWidget {
  final String objectName;
  const _DetailButton({required this.objectName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedHistoryScreen(objectName: objectName),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Подробнее", style: AppTextStyles.whiteText12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: AppTextStyles.blueText12),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.whiteText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

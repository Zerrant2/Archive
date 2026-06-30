// lib/models/question.dart
class Question {
  final String text;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'] as String,
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}
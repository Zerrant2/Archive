// lib/models/historical_object.dart
import 'question.dart';
import 'panorama_year.dart';
import 'ar_experience.dart';

class HistoricalObject {
  final String id;
  final String name;
  final String century;
  final String architectureType;
  final String address;
  final String yearsOfExistence;
  final String sources;
  final String shortDescription;
  final String detailedDescription;
  final String imageAsset;
  final double latitude;
  final double longitude;
  final List<Question> simpleQuestions;
  final List<Question> hardQuestions;
  final List<PanoramaYear> panoramas;
  final ArExperience? arExperience;
  final List<ArExperience> arExperiences;

  const HistoricalObject({
    required this.id,
    required this.name,
    required this.century,
    required this.architectureType,
    required this.address,
    required this.yearsOfExistence,
    required this.sources,
    required this.shortDescription,
    required this.detailedDescription,
    required this.imageAsset,
    required this.latitude,
    required this.longitude,
    required this.simpleQuestions,
    required this.hardQuestions,
    required this.panoramas,
    this.arExperience,
    this.arExperiences = const [],
  });

  factory HistoricalObject.fromJson(Map<String, dynamic> json) {
    return HistoricalObject(
      id: json['id'] as String,
      name: json['name'] as String,
      century: json['century'] as String,
      architectureType: json['architectureType'] as String,
      address: json['address'] as String,
      yearsOfExistence: json['yearsOfExistence'] as String,
      sources: json['sources'] as String,
      shortDescription: json['shortDescription'] as String,
      detailedDescription: json['detailedDescription'] as String,
      imageAsset: json['imageAsset'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      simpleQuestions: _parseQuestions(json['simpleQuestions'] ?? []),
      hardQuestions: _parseQuestions(json['hardQuestions'] ?? []),
      panoramas: _parsePanoramas(json['panoramas'] ?? []),
      arExperience: _parseArExperience(json),
      arExperiences: _parseArExperiences(json),
    );
  }

  static List<Question> _parseQuestions(List<dynamic> questionsJson) {
    return questionsJson
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  static List<PanoramaYear> _parsePanoramas(List<dynamic> panoramasJson) {
    return panoramasJson
        .map((p) => PanoramaYear.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  static ArExperience? _parseArExperience(Map<String, dynamic> json) {
    final rawExperience = json['arExperience'] ?? json['arAssets'];
    if (rawExperience is! Map<String, dynamic>) return null;

    return ArExperience.fromJson(rawExperience);
  }

  static List<ArExperience> _parseArExperiences(Map<String, dynamic> json) {
    final rawExperiences = json['arExperiences'];
    if (rawExperiences is! List) return const [];

    return rawExperiences
        .whereType<Map>()
        .map(
          (experience) =>
              ArExperience.fromJson(Map<String, dynamic>.from(experience)),
        )
        .toList();
  }

  List<ArExperience> get allArExperiences {
    final experiences = <ArExperience>[?arExperience, ...arExperiences];

    final seen = <String>{};
    return experiences.where((experience) {
      final key = [
        experience.epochYear ?? '',
        experience.glbUrl ?? '',
        experience.usdzUrl ?? '',
        experience.glbAssetPath ?? '',
        experience.usdzAssetPath ?? '',
      ].join('|');
      return seen.add(key);
    }).toList();
  }

  ArExperience? arExperienceForYear(String? year) {
    final experiences = allArExperiences;
    if (experiences.isEmpty) return null;

    final cleanYear = year?.trim();
    if (cleanYear != null && cleanYear.isNotEmpty) {
      for (final experience in experiences) {
        if (experience.epochYear?.trim() == cleanYear) return experience;
      }
    }

    for (final experience in experiences) {
      final epochYear = experience.epochYear?.trim();
      if (epochYear == null || epochYear.isEmpty) return experience;
    }

    return experiences.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'century': century,
      'architectureType': architectureType,
      'address': address,
      'yearsOfExistence': yearsOfExistence,
      'sources': sources,
      'shortDescription': shortDescription,
      'detailedDescription': detailedDescription,
      'imageAsset': imageAsset,
      'latitude': latitude,
      'longitude': longitude,
      'simpleQuestions': simpleQuestions.map((q) => q.toJson()).toList(),
      'hardQuestions': hardQuestions.map((q) => q.toJson()).toList(),
      'panoramas': panoramas.map((p) => p.toJson()).toList(),
      if (arExperience != null) 'arExperience': arExperience!.toJson(),
      if (arExperiences.isNotEmpty)
        'arExperiences': arExperiences.map((e) => e.toJson()).toList(),
    };
  }
}

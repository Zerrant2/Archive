// lib/core/models/achievement.dart
class Achievement {
  final String id;
  final String name;
  final DateTime unlockedAt;
  
  const Achievement({
    required this.id,
    required this.name,
    required this.unlockedAt,
  });
  
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['achievement_id'] as String? ?? json['id'] as String? ?? '',
      name: json['achievement_name'] as String? ?? json['name'] as String? ?? '',
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'achievement_id': id,
      'achievement_name': name,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}
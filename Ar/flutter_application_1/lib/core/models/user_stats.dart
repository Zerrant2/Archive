// lib/core/models/user_stats.dart
class UserStats {
  final String userId;
  final int coins;
  final int scansCount;
  final int achievementsCount;
  final List<String> scannedPlaces;
  final List<String> completedTests;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Быстрый доступ как Set
  Set<String> get scannedPlacesSet => scannedPlaces.toSet();
  Set<String> get completedTestsSet => completedTests.toSet();
  
  const UserStats({
    required this.userId,
    required this.coins,
    required this.scansCount,
    required this.achievementsCount,
    required this.scannedPlaces,
    required this.completedTests,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserStats.empty(String userId) {
    return UserStats(
      userId: userId,
      coins: 0,
      scansCount: 0,
      achievementsCount: 0,
      scannedPlaces: [],
      completedTests: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      coins: json['coins'] as int? ?? 0,
      scansCount: json['scans_count'] as int? ?? 0,
      achievementsCount: json['achievements_count'] as int? ?? 0,
      scannedPlaces: _parseStringList(json['scanned_places']),
      completedTests: _parseStringList(json['completed_tests']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
  
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
  
  UserStats copyWith({
    int? coins,
    int? scansCount,
    int? achievementsCount,
    List<String>? scannedPlaces,
    List<String>? completedTests,
  }) {
    return UserStats(
      userId: userId,
      coins: coins ?? this.coins,
      scansCount: scansCount ?? this.scansCount,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      scannedPlaces: scannedPlaces ?? this.scannedPlaces,
      completedTests: completedTests ?? this.completedTests,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
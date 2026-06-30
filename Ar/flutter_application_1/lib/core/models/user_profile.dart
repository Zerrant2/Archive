// lib/core/models/user_profile.dart
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['username'] as String? ?? 'Пользователь',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
  
  UserProfile copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
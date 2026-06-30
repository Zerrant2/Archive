// lib/models/notification_item.dart
import '../services/notification_service.dart';

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String time;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time,
      'isRead': isRead,
      'type': type.index,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      time: json['time'],
      isRead: json['isRead'],
      type: NotificationType.values[json['type']],
    );
  }
}
// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../services/notification_service.dart';
import '../models/notification_item.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await NotificationService.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _showMessage(String message) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 407,
            height: 61,
            decoration: BoxDecoration(
              color: AppColors.beigeBackground,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 10,
                  offset: Offset(0, 22),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 42,
                  top: 21,
                  child: SizedBox(
                    width: 277,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline15,
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 16,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryRed, width: 1),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.primaryRed,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Future<void> _markAllAsRead() async {
    bool hasUnread = _notifications.any((n) => !n.isRead);

    if (!hasUnread) {
      _showMessage("Нет непрочитанных уведомлений");
      return;
    }

    await NotificationService.markAllAsRead();
    await _loadNotifications();
    _showMessage("Все уведомления прочитаны!");
  }

  Future<void> _markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      await NotificationService.markAsRead(id);
      await _loadNotifications();
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _NotificationsHeader(
            unreadCount: unreadCount,
            onMarkAllRead: _markAllAsRead,
          ),

          Expanded(
            child: Container(
              color: AppColors.beigeBackground,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "Нет уведомлений",
                        style: AppTextStyles.headline15,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 20),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _NotificationCard(
                          notification: notification,
                          onTap: () => _markAsRead(notification.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;

  const _NotificationsHeader({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      height: 105 + topInset,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 9 + topInset,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.39),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.whiteText,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            left: 39,
            top: 30 + topInset,
            child: const Text("Уведомления", style: AppTextStyles.headline25),
          ),
          Positioned(
            left: 38,
            top: 64 + topInset,
            child: Text(
              "$unreadCount непрочитанных",
              style: TextStyle(
                color: AppColors.whiteText.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: 80,
            top: 20 + topInset,
            child: GestureDetector(
              onTap: onMarkAllRead,
              child: Container(
                width: 100,
                height: 69,
                decoration: AppDecorations.redGradientSquare,
                child: const Center(
                  child: Text(
                    "Прочитать все",
                    style: TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20 + topInset,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 69,
                decoration: AppDecorations.redGradientSquare,
                child: const Center(
                  child: Icon(
                    Icons.settings,
                    color: AppColors.whiteText,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.greyBackground
              : AppColors.lightPink,
          borderRadius: BorderRadius.circular(15),
          border: notification.isRead
              ? null
              : Border.all(color: AppColors.primaryRed, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 59,
              decoration: AppDecorations.redGradientSquare,
              child: Icon(
                _getIconForType(notification.type),
                color: AppColors.whiteText,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTextStyles.headline15),
                  const SizedBox(height: 4),
                  Text(notification.message, style: AppTextStyles.body12),
                  const SizedBox(height: 8),
                  Text(notification.time, style: AppTextStyles.blueText12),
                ],
              ),
            ),
            if (!notification.isRead)
              const SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.reward:
        return Icons.monetization_on;
      case NotificationType.location:
        return Icons.location_on;
      case NotificationType.update:
        return Icons.update;
    }
  }
}

enum NotificationType { exam, result, violation }

class AppNotification {
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}

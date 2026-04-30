import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService {
  static Future<List<AppNotification>> fetchNotifications() async {
    final List<AppNotification> notifications = [];

    // Run all 3 independently so one failure doesn't kill the rest
    final exams = await ApiService.getExams();
    final examResults = await ApiService.getMyResults();
    final violations = await ApiService.getMyViolations();

    for (final exam in exams) {
      notifications.add(AppNotification(
        title: 'New Exam Available',
        body: exam['title'] ?? 'An exam has been issued for you.',
        type: NotificationType.exam,
        time: DateTime.now(),
      ));
    }

    for (final result in examResults) {
      notifications.add(AppNotification(
        title: 'Result Published',
        body: result['examTitle'] ?? 'Your exam result is now available.',
        type: NotificationType.result,
        time: DateTime.now(),
      ));
    }

    for (final violation in violations) {
      notifications.add(AppNotification(
        title: 'Violation Flagged',
        body: violation['examTitle'] ?? 'A violation was detected during your exam.',
        type: NotificationType.violation,
        time: DateTime.now(),
      ));
    }

    return notifications;
  }
}
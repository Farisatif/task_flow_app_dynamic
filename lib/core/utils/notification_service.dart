import 'package:flutter/foundation.dart';

import '../database/tables.dart';
import '../models/smart_notification.dart';

class NotificationService {
  NotificationService._();

  static Future<void> initialize() async {
    // لاحقًا يمكن ربط flutter_local_notifications هنا
    // مع إعداد قنوات Android / iOS.
    if (kDebugMode) {
      debugPrint('NotificationService initialized');
    }
  }

  /// يبني "صندوق إشعارات ذكي" من المهام الحالية
  /// ويعيد قائمة إشعارات مرتبة حسب الأهمية.
  static List<SmartNotification> buildSmartInbox(
    List<Task> tasks, {
    DateTime? now,
  }) {
    return SmartNotificationEngine.buildForTasks(
      tasks,
      now: now,
    );
  }

  /// إشعارات مهمة واحدة فقط
  static SmartNotification? buildTaskReminder(Task task, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return SmartNotificationEngine.buildForTasks(
      [task],
      now: current,
    ).isEmpty
        ? null
        : SmartNotificationEngine.buildForTasks(
            [task],
            now: current,
          ).first;
  }

  static Future<void> scheduleTaskReminder(
    int taskId,
    String title,
    DateTime scheduledTime,
  ) async {
    // لاحقًا يمكن جدولة إشعار محلي هنا.
    if (kDebugMode) {
      debugPrint(
        'Scheduled reminder -> taskId: $taskId, title: $title, time: $scheduledTime',
      );
    }
  }

  static Future<void> cancelReminder(int taskId) async {
    // لاحقًا يمكن إلغاء الإشعار المجدول هنا.
    if (kDebugMode) {
      debugPrint('Canceled reminder -> taskId: $taskId');
    }
  }

  static Future<void> showInstantNotification(
    String title,
    String body,
  ) async {
    // لاحقًا يمكن عرض إشعار فوري حقيقي هنا.
    if (kDebugMode) {
      debugPrint('Instant notification -> $title | $body');
    }
  }

  /// رسالة سريعة مفيدة لعرضها داخل التطبيق
  static String buildSummaryText(List<Task> tasks) {
    final smart = buildSmartInbox(tasks);
    if (smart.isEmpty) return 'لا توجد إشعارات ذكية الآن.';

    final top = smart.first;
    return '${top.title} — ${top.body}';
  }
}

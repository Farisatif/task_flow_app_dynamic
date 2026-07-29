import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/tables.dart';

enum SmartNotificationType {
  taskDueSoon,
  taskOverdue,
  taskStartingSoon,
  dailySummary,
  morningPlan,
}

enum SmartNotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class SmartNotification {
  final String id;
  final SmartNotificationType type;
  final SmartNotificationPriority priority;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final int? taskId;
  final String? route;
  final String? actionLabel;
  final bool isRead;
  final bool allowSnooze;
  final DateTime createdAt;

  const SmartNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.taskId,
    this.route,
    this.actionLabel,
    this.isRead = false,
    this.allowSnooze = true,
    required this.createdAt,
  });

  factory SmartNotification.taskDueSoon({
    required int taskId,
    required String taskTitle,
    required DateTime scheduledAt,
    String? route,
  }) {
    return SmartNotification(
      id: 'due_soon_$taskId_${scheduledAt.millisecondsSinceEpoch}',
      type: SmartNotificationType.taskDueSoon,
      priority: SmartNotificationPriority.high,
      title: 'المهمة تقترب من موعدها',
      body: 'المهمة "$taskTitle" ستبدأ أو تنتهي قريبًا. راجعها الآن.',
      scheduledAt: scheduledAt,
      taskId: taskId,
      route: route ?? '/task-details/$taskId',
      actionLabel: 'عرض المهمة',
      createdAt: DateTime.now(),
    );
  }

  factory SmartNotification.taskStartingSoon({
    required int taskId,
    required String taskTitle,
    required DateTime scheduledAt,
    String? route,
  }) {
    return SmartNotification(
      id: 'start_soon_$taskId_${scheduledAt.millisecondsSinceEpoch}',
      type: SmartNotificationType.taskStartingSoon,
      priority: SmartNotificationPriority.medium,
      title: 'موعد المهمة يقترب',
      body: 'المهمة "$taskTitle" ستبدأ بعد قليل. جهّز نفسك.',
      scheduledAt: scheduledAt,
      taskId: taskId,
      route: route ?? '/task-details/$taskId',
      actionLabel: 'فتح المهمة',
      createdAt: DateTime.now(),
    );
  }

  factory SmartNotification.taskOverdue({
    required int taskId,
    required String taskTitle,
    required DateTime scheduledAt,
    String? route,
  }) {
    return SmartNotification(
      id: 'overdue_$taskId_${scheduledAt.millisecondsSinceEpoch}',
      type: SmartNotificationType.taskOverdue,
      priority: SmartNotificationPriority.urgent,
      title: 'مهمة متأخرة',
      body: 'المهمة "$taskTitle" تجاوزت وقتها المحدد. يُفضّل مراجعتها الآن.',
      scheduledAt: scheduledAt,
      taskId: taskId,
      route: route ?? '/task-details/$taskId',
      actionLabel: 'مراجعة المهمة',
      createdAt: DateTime.now(),
      allowSnooze: false,
    );
  }

  factory SmartNotification.dailySummary({
    required int total,
    required int completed,
    required int pending,
    required DateTime scheduledAt,
  }) {
    return SmartNotification(
      id: 'daily_summary_${scheduledAt.millisecondsSinceEpoch}',
      type: SmartNotificationType.dailySummary,
      priority: SmartNotificationPriority.medium,
      title: 'ملخص يومك',
      body: total == 0
          ? 'لا توجد مهام اليوم. يمكنك إضافة مهمة جديدة لبدء يومك.'
          : 'أكملت $completed من أصل $total مهمة، وما زال لديك $pending مهمة بانتظار التنفيذ.',
      scheduledAt: scheduledAt,
      route: '/today',
      actionLabel: 'عرض اليوم',
      createdAt: DateTime.now(),
    );
  }

  factory SmartNotification.morningPlan({
    required int total,
    required int upcoming,
    required DateTime scheduledAt,
  }) {
    return SmartNotification(
      id: 'morning_plan_${scheduledAt.millisecondsSinceEpoch}',
      type: SmartNotificationType.morningPlan,
      priority: SmartNotificationPriority.low,
      title: 'خطة صباحية سريعة',
      body: total == 0
          ? 'ابدأ اليوم بإضافة أول مهمة، وابدأ بزخم خفيف.'
          : 'لديك $upcoming مهمة قادمة اليوم من أصل $total مهمة. رتّب أولوياتك الآن.',
      scheduledAt: scheduledAt,
      route: '/today',
      actionLabel: 'تنظيم اليوم',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'body': body,
      'scheduledAt': scheduledAt.toIso8601String(),
      'taskId': taskId,
      'route': route,
      'actionLabel': actionLabel,
      'isRead': isRead,
      'allowSnooze': allowSnooze,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    SmartNotificationType parseType(String value) {
      return SmartNotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SmartNotificationType.dailySummary,
      );
    }

    SmartNotificationPriority parsePriority(String value) {
      return SmartNotificationPriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SmartNotificationPriority.medium,
      );
    }

    return SmartNotification(
      id: json['id'] as String,
      type: parseType(
        json['type'] as String? ?? SmartNotificationType.dailySummary.name,
      ),
      priority: parsePriority(
        json['priority'] as String? ?? SmartNotificationPriority.medium.name,
      ),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      taskId: json['taskId'] as int?,
      route: json['route'] as String?,
      actionLabel: json['actionLabel'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      allowSnooze: json['allowSnooze'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SmartNotificationEngine {
  SmartNotificationEngine._();

  static List<SmartNotification> buildForTasks(
    List<Task> tasks, {
    DateTime? now,
    int startSoonMinutes = 15,
    int dueSoonMinutes = 60,
    int summaryHour = 20,
  }) {
    final current = now ?? DateTime.now();
    final today = DateUtils.dateOnly(current);

    final notifications = <SmartNotification>[];

    final todayTasks = tasks
        .where((t) => !t.isDeleted && DateUtils.dateOnly(t.date) == today)
        .toList();

    for (final task in todayTasks) {
      if (task.status == TaskStatus.completed) continue;

      final startTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.startMinutes ~/ 60,
        task.startMinutes % 60,
      );

      final endTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.endMinutes ~/ 60,
        task.endMinutes % 60,
      );

      final startDiff = startTime.difference(current).inMinutes;
      final endDiff = endTime.difference(current).inMinutes;

      if (startDiff <= 0 && endDiff < 0) {
        notifications.add(
          SmartNotification.taskOverdue(
            taskId: task.id,
            taskTitle: task.title,
            scheduledAt: endTime,
          ),
        );
        continue;
      }

      if (startDiff >= 0 && startDiff <= startSoonMinutes) {
        notifications.add(
          SmartNotification.taskStartingSoon(
            taskId: task.id,
            taskTitle: task.title,
            scheduledAt: startTime,
          ),
        );
        continue;
      }

      if (endDiff >= 0 && endDiff <= dueSoonMinutes) {
        notifications.add(
          SmartNotification.taskDueSoon(
            taskId: task.id,
            taskTitle: task.title,
            scheduledAt: endTime,
          ),
        );
      }
    }

    final completedCount = todayTasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final pendingCount = todayTasks
        .where((t) => t.status == TaskStatus.pending)
        .length;

    if (current.hour >= summaryHour) {
      notifications.add(
        SmartNotification.dailySummary(
          total: todayTasks.length,
          completed: completedCount,
          pending: pendingCount,
          scheduledAt: current,
        ),
      );
    } else if (current.hour <= 9 && todayTasks.isNotEmpty) {
      final upcoming = todayTasks
          .where((t) => t.status != TaskStatus.completed)
          .length;

      notifications.add(
        SmartNotification.morningPlan(
          total: todayTasks.length,
          upcoming: upcoming,
          scheduledAt: current,
        ),
      );
    }

    notifications.sort((a, b) {
      final priorityDiff = _priorityWeight(b.priority) - _priorityWeight(a.priority);
      if (priorityDiff != 0) return priorityDiff;
      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    return _dedupe(notifications);
  }

  static List<SmartNotification> _dedupe(List<SmartNotification> items) {
    final seen = <String>{};
    final result = <SmartNotification>[];

    for (final item in items) {
      if (seen.add(item.id)) {
        result.add(item);
      }
    }

    return result;
  }

  static int _priorityWeight(SmartNotificationPriority priority) {
    switch (priority) {
      case SmartNotificationPriority.low:
        return 1;
      case SmartNotificationPriority.medium:
        return 2;
      case SmartNotificationPriority.high:
        return 3;
      case SmartNotificationPriority.urgent:
        return 4;
    }
  }
}

class NotificationService {
  NotificationService._();

  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('NotificationService initialized');
    }
  }

  static List<SmartNotification> buildSmartInbox(
    List<Task> tasks, {
    DateTime? now,
  }) {
    return SmartNotificationEngine.buildForTasks(tasks, now: now);
  }

  static SmartNotification? buildTaskReminder(
    Task task, {
    DateTime? now,
  }) {
    final items = SmartNotificationEngine.buildForTasks(
      [task],
      now: now ?? DateTime.now(),
    );

    return items.isEmpty ? null : items.first;
  }

  static Future<void> scheduleTaskReminder(
    int taskId,
    String title,
    DateTime scheduledTime,
  ) async {
    if (kDebugMode) {
      debugPrint(
        'Scheduled reminder -> taskId: $taskId, title: $title, time: $scheduledTime',
      );
    }
  }

  static Future<void> cancelReminder(int taskId) async {
    if (kDebugMode) {
      debugPrint('Canceled reminder -> taskId: $taskId');
    }
  }

  static Future<void> showInstantNotification(
    String title,
    String body,
  ) async {
    if (kDebugMode) {
      debugPrint('Instant notification -> $title | $body');
    }
  }

  static String buildSummaryText(List<Task> tasks) {
    final smart = buildSmartInbox(tasks);
    if (smart.isEmpty) return 'لا توجد إشعارات ذكية الآن.';

    final top = smart.first;
    return '${top.title} — ${top.body}';
  }
}

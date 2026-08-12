import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'statistics_dao.g.dart';

/// نموذج لإحصائيات المهام
class TaskStatistics {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final int overdue;

  TaskStatistics({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.overdue,
  });

  double get completionPercentage => total == 0 ? 0.0 : (completed / total) * 100;
}

/// نموذج لإحصائيات التركيز
class FocusStatistics {
  final int sessionsCount;
  final int totalMinutes;
  final int averageMinutesPerSession;
  final List<FocusSession> sessions;

  FocusStatistics({
    required this.sessionsCount,
    required this.totalMinutes,
    required this.averageMinutesPerSession,
    required this.sessions,
  });
}

/// نموذج لإحصائيات العادات
class HabitStatistics {
  final int totalHabits;
  final int completedToday;
  final double completionPercentage;

  HabitStatistics({
    required this.totalHabits,
    required this.completedToday,
    required this.completionPercentage,
  });
}

@DriftAccessor(tables: [Tasks, FocusSessions, Habits, HabitLogs, Categories])
class StatisticsDao extends DatabaseAccessor<AppDatabase> with _$StatisticsDaoMixin {
  StatisticsDao(super.db);

  /// احصائيات المهام لليوم الحالي (تحديث فوري)
  Stream<TaskStatistics> watchTaskStatisticsForToday() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final next = day.add(const Duration(days: 1));

    return (select(tasks)..where((t) => t.isDeleted.equals(false)))
        .watch()
        .map((allTasks) {
      final taskList = allTasks
          .where((t) => !t.date.isBefore(day) && t.date.isBefore(next))
          .toList();
      final total = taskList.length;
      final completed = taskList.where((t) => t.status == TaskStatus.completed).length;
      final inProgress = taskList.where((t) => t.status == TaskStatus.inProgress).length;
      final pending = taskList.where((t) => t.status == TaskStatus.pending).length;
      final overdue = allTasks.where((t) => t.date.isBefore(day) && t.status != TaskStatus.completed).length;

      return TaskStatistics(
        total: total,
        completed: completed,
        inProgress: inProgress,
        pending: pending,
        overdue: overdue,
      );
    });
  }

  /// احصائيات المهام لفترة محددة
  Stream<TaskStatistics> watchTaskStatisticsForDateRange(DateTime startDate, DateTime endDate) {
    final day = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    return (select(tasks)..where((t) => t.isDeleted.equals(false)))
        .watch()
        .map((allTasks) {
      final taskList = allTasks
          .where((t) => !t.date.isBefore(day) && t.date.isBefore(end))
          .toList();
      final total = taskList.length;
      final completed = taskList.where((t) => t.status == TaskStatus.completed).length;
      final inProgress = taskList.where((t) => t.status == TaskStatus.inProgress).length;
      final pending = taskList.where((t) => t.status == TaskStatus.pending).length;
      final overdue = allTasks.where((t) => t.date.isBefore(day) && t.status != TaskStatus.completed).length;

      return TaskStatistics(
        total: total,
        completed: completed,
        inProgress: inProgress,
        pending: pending,
        overdue: overdue,
      );
    });
  }

  /// احصائيات التركيز لليوم (تحديث فوري)
  Stream<FocusStatistics> watchFocusStatisticsForToday() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final next = day.add(const Duration(days: 1));

    return (select(focusSessions)
          ..where((f) => f.startTime.isBiggerOrEqualValue(day) & f.startTime.isSmallerThanValue(next))
          ..orderBy([(f) => OrderingTerm.asc(f.startTime)]))
        .watch()
        .map((sessions) {
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      final totalSeconds = completedSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
      final totalMinutes = totalSeconds ~/ 60;
      final avgMinutes = completedSessions.isEmpty ? 0 : totalMinutes ~/ completedSessions.length;

      return FocusStatistics(
        sessionsCount: completedSessions.length,
        totalMinutes: totalMinutes,
        averageMinutesPerSession: avgMinutes,
        sessions: sessions,
      );
    });
  }

  /// احصائيات العادات لليوم
  Stream<HabitStatistics> watchHabitStatisticsForToday() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final next = day.add(const Duration(days: 1));

    return customSelect(
      'SELECT 1 FROM habits LEFT JOIN habit_logs ON habit_logs.habit_id = habits.id WHERE habits.is_deleted = 0',
      readsFrom: {habits, habitLogs},
    ).watch().asyncMap((_) async {
      final habitList = await (select(habits)..where((h) => h.isDeleted.equals(false))).get();
      if (habitList.isEmpty) {
        return HabitStatistics(totalHabits: 0, completedToday: 0, completionPercentage: 0.0);
      }

      int completedCount = 0;
      for (final habit in habitList) {
        final logs = await (select(habitLogs)
              ..where((l) => l.habitId.equals(habit.id) & l.logDate.isBiggerOrEqualValue(day) & l.logDate.isSmallerThanValue(next)))
            .get();
        if (logs.isNotEmpty && logs.first.isCompleted) {
          completedCount++;
        }
      }

      final percentage = habitList.isEmpty ? 0.0 : (completedCount / habitList.length) * 100;

      return HabitStatistics(
        totalHabits: habitList.length,
        completedToday: completedCount,
        completionPercentage: percentage,
      );
    });
  }

  /// احصائيات المهام حسب الفئة، باستعلام تجميعي واحد لتقليل كلفة القراءة.
  Stream<Map<String, int>> watchTaskCountByCategory() {
    return customSelect(
      '''
      SELECT categories.name AS category_name, COUNT(tasks.id) AS task_count
      FROM tasks
      INNER JOIN categories ON categories.id = tasks.category_id
      WHERE tasks.is_deleted = 0 AND categories.is_deleted = 0
      GROUP BY categories.id, categories.name
      ORDER BY task_count DESC
      ''',
      readsFrom: {tasks, categories},
    ).watch().map((rows) {
      return {
        for (final row in rows)
          row.read<String>('category_name'): row.read<int>('task_count'),
      };
    });
  }

  /// احصائيات الإنتاجية الأسبوعية (عدد المهام المكتملة يومياً)
  Stream<List<double>> watchWeeklyProductivity() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return (select(tasks)..where((t) => t.isDeleted.equals(false))).watch().map((taskList) {
      final List<double> weeklyData = List.filled(7, 0.0);

      for (int i = 0; i < 7; i++) {
        final dayToCheck = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: i));
        final nextDay = dayToCheck.add(const Duration(days: 1));

        final completedCount = taskList
            .where((t) =>
                !t.date.isBefore(dayToCheck) &&
                t.date.isBefore(nextDay) &&
                t.status == TaskStatus.completed &&
                !t.isDeleted)
            .length;

        weeklyData[i] = completedCount.toDouble();
      }

      return weeklyData;
    });
  }

  /// احصائيات أفضل أوقات الإنتاجية (الساعة التي تم فيها إكمال أكثر المهام)
  Stream<String> watchBestProductivityHour() {
    return (select(tasks)..where((t) => t.isDeleted.equals(false))).watch().map((taskList) {
      final completedTasks = taskList.where((t) => t.status == TaskStatus.completed).toList();

      if (completedTasks.isEmpty) {
        return '09:00 - 12:00';
      }

      final hourCounts = <int, int>{};
      for (final task in completedTasks) {
        final hour = task.startMinutes ~/ 60;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      final bestHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final endHour = (bestHour + 3) % 24;

      return '${bestHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
    });
  }

  /// عدد المهام المتأخرة
  Stream<int> watchOverdueTasksCount() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    return (select(tasks)
          ..where((t) =>
              t.date.isSmallerThanValue(day) &
              t.status.equals(TaskStatus.completed.index).not() &
              t.isDeleted.equals(false)))
        .watch()
        .map((taskList) => taskList.length);
  }

  /// احصائيات المهام لتاريخ محدد
  Stream<TaskStatistics> watchTaskStatisticsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final next = day.add(const Duration(days: 1));

    return (select(tasks)
          ..where((t) => t.date.isBiggerOrEqualValue(day) & t.date.isSmallerThanValue(next) & t.isDeleted.equals(false)))
        .watch()
        .map((taskList) {
      final total = taskList.length;
      final completed = taskList.where((t) => t.status == TaskStatus.completed).length;
      final inProgress = taskList.where((t) => t.status == TaskStatus.inProgress).length;
      final pending = taskList.where((t) => t.status == TaskStatus.pending).length;
      final overdue = taskList.where((t) => t.date.isBefore(day) && t.status != TaskStatus.completed).length;

      return TaskStatistics(
        total: total,
        completed: completed,
        inProgress: inProgress,
        pending: pending,
        overdue: overdue,
      );
    });
  }

  /// احصائيات التركيز لتاريخ محدد
  Stream<FocusStatistics> watchFocusStatisticsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final next = day.add(const Duration(days: 1));

    return (select(focusSessions)
          ..where((f) => f.startTime.isBiggerOrEqualValue(day) & f.startTime.isSmallerThanValue(next))
          ..orderBy([(f) => OrderingTerm.asc(f.startTime)]))
        .watch()
        .map((sessions) {
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      final totalSeconds = completedSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
      final totalMinutes = totalSeconds ~/ 60;
      final avgMinutes = completedSessions.isEmpty ? 0 : totalMinutes ~/ completedSessions.length;

      return FocusStatistics(
        sessionsCount: completedSessions.length,
        totalMinutes: totalMinutes,
        averageMinutesPerSession: avgMinutes,
        sessions: sessions,
      );
    });
  }
}

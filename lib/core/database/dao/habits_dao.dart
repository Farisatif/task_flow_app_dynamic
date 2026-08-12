import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'habits_dao.g.dart';

/// عادة مع سجل آخر 7 أيام (true = أنجزت في ذلك اليوم)
class HabitWithWeek {
  final Habit habit;
  final List<bool> last7Days;
  HabitWithWeek({required this.habit, required this.last7Days});

  int get doneCount => last7Days.where((d) => d).length;
}

@DriftAccessor(tables: [Habits, HabitLogs])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Stream<List<Habit>> watchAll() {
    return (select(habits)..where((h) => h.isDeleted.equals(false) & h.isArchived.equals(false))).watch();
  }

  /// يبث كل عادة مع حالة آخر 7 أيام باستعلام واحد للّوغات، مع مراقبة الجداول معًا.
  Stream<List<HabitWithWeek>> watchAllWithWeek() {
    final invalidation = customSelect(
      'SELECT h.id FROM habits h LEFT JOIN habit_logs l ON l.habit_id = h.id',
      readsFrom: {habits, habitLogs},
    ).watch();

    return invalidation.asyncMap((_) async {
      final habitRows = await (select(habits)
            ..where((h) => h.isDeleted.equals(false) & h.isArchived.equals(false)))
          .get();
      if (habitRows.isEmpty) return <HabitWithWeek>[];

      final today = _dateOnly(DateTime.now());
      final start = today.subtract(const Duration(days: 6));
      final end = today.add(const Duration(days: 1));
      final ids = habitRows.map((h) => h.id).join(',');
      final logRows = await customSelect(
        'SELECT habit_id, log_date, is_completed FROM habit_logs '
        'WHERE habit_id IN ($ids) AND log_date >= ? AND log_date < ?',
        variables: [
          Variable.withDateTime(start),
          Variable.withDateTime(end),
        ],
        readsFrom: {habitLogs},
      ).get();

      final completedByHabitAndDay = <int, Set<String>>{};
      for (final row in logRows) {
        if (row.read<bool>('is_completed')) {
          completedByHabitAndDay
              .putIfAbsent(row.read<int>('habit_id'), () => <String>{})
              .add(row.read<String>('log_date'));
        }
      }

      return [
        for (final habit in habitRows)
          HabitWithWeek(
            habit: habit,
            last7Days: [
              for (int i = 6; i >= 0; i--)
                completedByHabitAndDay[habit.id]?.contains(
                      today.subtract(Duration(days: i)).toIso8601String(),
                    ) ??
                    false,
            ],
          ),
      ];
    });
  }

  Future<int> insertHabit(HabitsCompanion entry) => into(habits).insert(entry);

  /// يبدّل حالة إنجاز عادة في يوم معيّن (يُنشئ السجل إن لم يكن موجودًا)
  Future<void> toggleDay(int habitId, DateTime date, bool completed) async {
    final day = _dateOnly(date);
    final existing = await (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.logDate.equals(day)))
        .getSingleOrNull();
    if (existing == null) {
      await into(habitLogs).insert(HabitLogsCompanion.insert(habitId: habitId, logDate: day, isCompleted: Value(completed)));
    } else {
      await (update(habitLogs)..where((l) => l.id.equals(existing.id)))
          .write(HabitLogsCompanion(isCompleted: Value(completed)));
    }
  }

  Future<int> softDelete(int id) =>
      (update(habits)..where((h) => h.id.equals(id))).write(const HabitsCompanion(isDeleted: Value(true)));
}

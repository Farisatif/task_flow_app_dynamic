import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// يبث كل مهام يوم محدد (غير المحذوفة)، مرتّبة حسب وقت البدء
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final day = _dateOnly(date);
    final next = day.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) => t.date.isBiggerOrEqualValue(day) & t.date.isSmallerThanValue(next) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startMinutes)]))
        .watch();
  }

  Stream<List<Task>> watchAll() {
    return (select(tasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.asc(t.startMinutes)]))
        .watch();
  }

  Stream<Task?> watchById(int id) => (select(tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<List<Task>> getTasksByProject(int projectId) =>
      (select(tasks)..where((t) => t.projectId.equals(projectId) & t.isDeleted.equals(false))).get();

  Future<int> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  Future<bool> updateTask(Task entry) => update(tasks).replace(entry);

  Future<int> setStatus(int id, TaskStatus status) => (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
      );

  Future<int> softDelete(int id) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(const TasksCompanion(isDeleted: Value(true)));

  Stream<List<Task>> watchSubtasks(int parentId) {
    return (select(tasks)
          ..where((t) => t.parentTaskId.equals(parentId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startMinutes)]))
        .watch();
  }

  Future<int> insertSubtask(TasksCompanion entry, int parentId) {
    return into(tasks).insert(entry.copyWith(parentTaskId: Value(parentId)));
  }

  /// عدد المهام حسب الحالة، لبطاقات الإحصائيات السريعة في الرئيسية
  Future<Map<TaskStatus, int>> countByStatusForDate(DateTime date) async {
    final day = _dateOnly(date);
    final next = day.add(const Duration(days: 1));
    final rows = await (select(tasks)
          ..where((t) => t.date.isBiggerOrEqualValue(day) & t.date.isSmallerThanValue(next) & t.isDeleted.equals(false)))
        .get();
    final map = <TaskStatus, int>{for (final s in TaskStatus.values) s: 0};
    for (final r in rows) {
      map[r.status] = (map[r.status] ?? 0) + 1;
    }
    return map;
  }
}

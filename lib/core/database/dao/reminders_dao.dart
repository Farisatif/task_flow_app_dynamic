import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'reminders_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase> with _$RemindersDaoMixin {
  RemindersDao(super.db);

  Stream<List<Reminder>> watchAll() {
    return (select(reminders)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();
  }

  Future<int> insertReminder(RemindersCompanion entry) => into(reminders).insert(entry);

  Future<int> setActive(int id, bool active) =>
      (update(reminders)..where((r) => r.id.equals(id))).write(RemindersCompanion(isActive: Value(active)));

  Future<int> deleteReminder(int id) => (delete(reminders)..where((r) => r.id.equals(id))).go();
}

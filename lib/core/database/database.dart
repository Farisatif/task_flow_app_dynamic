import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dao/attachments_dao.dart';
import 'dao/categories_dao.dart';
import 'dao/focus_sessions_dao.dart';
import 'dao/goals_dao.dart';
import 'dao/habits_dao.dart';
import 'dao/notes_dao.dart';
import 'dao/profile_dao.dart';
import 'dao/projects_dao.dart';
import 'dao/reminders_dao.dart';
import 'dao/statistics_dao.dart';
import 'dao/tasks_dao.dart';
import 'tables.dart';

part 'database.g.dart';

/// قاعدة البيانات الرئيسية للتطبيق (SQLite محلي عبر Drift).
/// بعد `flutter pub get` شغّل:
/// `dart run build_runner build --delete-conflicting-outputs`
@DriftDatabase(
  tables: [
    Profile,
    AppSettings,
    Categories,
    Goals,
    SubGoals,
    Projects,
    Tasks,
    Reminders,
    Notes,
    Attachments,
    Habits,
    HabitLogs,
    FocusSessions,
  ],
  daos: [
    CategoriesDao,
    GoalsDao,
    ProjectsDao,
    TasksDao,
    HabitsDao,
    NotesDao,
    AttachmentsDao,
    RemindersDao,
    FocusSessionsDao,
    ProfileDao,
    StatisticsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// منشئ مفيد للاختبارات أو لحقن اتصال مخصص.
  AppDatabase.forTesting(super.connection);

  /// يحذف كل بيانات المستخدم مع الإبقاء على بنية قاعدة البيانات سليمة.
  /// تُحذف الجداول التابعة أولًا لأن SQLite يعمل مع تفعيل foreign keys.
  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(habitLogs).go();
      await delete(focusSessions).go();
      await delete(attachments).go();
      await delete(reminders).go();
      await delete(notes).go();
      await delete(tasks).go();
      await delete(subGoals).go();
      await delete(goals).go();
      await delete(projects).go();
      await delete(categories).go();
      await delete(habits).go();
      await delete(profile).go();
      await delete(appSettings).go();
    });
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // عند رفع schemaVersion مستقبلًا أضف الترحيل هنا.
          // مثال:
          // if (from < 2) {
          //   await m.addColumn(tasks, tasks.someNewColumn);
          // }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tasks_date_deleted '
            'ON tasks(date, is_deleted)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tasks_project_deleted '
            'ON tasks(project_id, is_deleted)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tasks_category_deleted '
            'ON tasks(category_id, is_deleted)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_reminders_active '
            'ON reminders(is_active, task_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_habit_logs_habit_date '
            'ON habit_logs(habit_id, log_date)',
          );
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'task_flow.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

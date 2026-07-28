// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$FocusSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $GoalsTable get goals => attachedDatabase.goals;
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  $FocusSessionsTable get focusSessions => attachedDatabase.focusSessions;
  FocusSessionsDaoManager get managers => FocusSessionsDaoManager(this);
}

class FocusSessionsDaoManager {
  final _$FocusSessionsDaoMixin _db;
  FocusSessionsDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db.attachedDatabase, _db.focusSessions);
}

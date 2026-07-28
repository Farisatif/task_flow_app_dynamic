// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_dao.dart';

// ignore_for_file: type=lint
mixin _$TasksDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $GoalsTable get goals => attachedDatabase.goals;
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  TasksDaoManager get managers => TasksDaoManager(this);
}

class TasksDaoManager {
  final _$TasksDaoMixin _db;
  TasksDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
}

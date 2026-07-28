// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projects_dao.dart';

// ignore_for_file: type=lint
mixin _$ProjectsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoalsTable get goals => attachedDatabase.goals;
  $ProjectsTable get projects => attachedDatabase.projects;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TasksTable get tasks => attachedDatabase.tasks;
  ProjectsDaoManager get managers => ProjectsDaoManager(this);
}

class ProjectsDaoManager {
  final _$ProjectsDaoMixin _db;
  ProjectsDaoManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
}

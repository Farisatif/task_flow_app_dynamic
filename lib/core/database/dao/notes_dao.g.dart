// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_dao.dart';

// ignore_for_file: type=lint
mixin _$NotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $GoalsTable get goals => attachedDatabase.goals;
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  $NotesTable get notes => attachedDatabase.notes;
  NotesDaoManager get managers => NotesDaoManager(this);
}

class NotesDaoManager {
  final _$NotesDaoMixin _db;
  NotesDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
}

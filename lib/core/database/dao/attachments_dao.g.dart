// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachments_dao.dart';

// ignore_for_file: type=lint
mixin _$AttachmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $GoalsTable get goals => attachedDatabase.goals;
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  $AttachmentsTable get attachments => attachedDatabase.attachments;
  AttachmentsDaoManager get managers => AttachmentsDaoManager(this);
}

class AttachmentsDaoManager {
  final _$AttachmentsDaoMixin _db;
  AttachmentsDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db.attachedDatabase, _db.attachments);
}

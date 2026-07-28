// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_dao.dart';

// ignore_for_file: type=lint
mixin _$GoalsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoalsTable get goals => attachedDatabase.goals;
  $SubGoalsTable get subGoals => attachedDatabase.subGoals;
  GoalsDaoManager get managers => GoalsDaoManager(this);
}

class GoalsDaoManager {
  final _$GoalsDaoMixin _db;
  GoalsDaoManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$SubGoalsTableTableManager get subGoals =>
      $$SubGoalsTableTableManager(_db.attachedDatabase, _db.subGoals);
}

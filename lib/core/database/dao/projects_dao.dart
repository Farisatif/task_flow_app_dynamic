import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'projects_dao.g.dart';

/// نتيجة مشروع مع إحصائيات مهامه (للاستخدام المباشر في الواجهة)
class ProjectWithStats {
  final Project project;
  final int totalTasks;
  final int completedTasks;
  ProjectWithStats({required this.project, required this.totalTasks, required this.completedTasks});

  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;
  int get progressPercent => (progress * 100).round();
}

@DriftAccessor(tables: [Projects, Tasks])
class ProjectsDao extends DatabaseAccessor<AppDatabase> with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  Stream<List<Project>> watchAll() {
    return (select(projects)
          ..where((p) => p.isDeleted.equals(false) & p.isArchived.equals(false)))
        .watch();
  }

  /// يبث قائمة المشاريع مع إحصاءاتها باستعلامين ثابتين بدل استعلام لكل مشروع.
  Stream<List<ProjectWithStats>> watchAllWithStats() {
    return customSelect(
      'SELECT 1 FROM projects LEFT JOIN tasks ON tasks.project_id = projects.id',
      readsFrom: {projects, tasks},
    ).watch().asyncMap((_) async {
      final projectRows = await (select(projects)
            ..where((p) => p.isDeleted.equals(false) & p.isArchived.equals(false)))
          .get();
      final statsRows = await customSelect(
        '''
        SELECT project_id,
               COUNT(id) AS total_tasks,
               SUM(CASE WHEN status = ${TaskStatus.completed.index} THEN 1 ELSE 0 END)
                 AS completed_tasks
        FROM tasks
        WHERE is_deleted = 0 AND project_id IS NOT NULL
        GROUP BY project_id
        ''',
        readsFrom: {tasks},
      ).get();
      final stats = <int, (int total, int completed)>{
        for (final row in statsRows)
          row.read<int>('project_id'): (
            row.read<int>('total_tasks'),
            row.read<int>('completed_tasks'),
          ),
      };

      return [
        for (final project in projectRows)
          ProjectWithStats(
            project: project,
            totalTasks: stats[project.id]?.$1 ?? 0,
            completedTasks: stats[project.id]?.$2 ?? 0,
          ),
      ];
    });
  }

  Future<int> insertProject(ProjectsCompanion entry) => into(projects).insert(entry);

  Future<bool> updateProject(Project entry) => update(projects).replace(entry);

  Future<int> softDelete(int id) => (update(projects)..where((p) => p.id.equals(id)))
      .write(const ProjectsCompanion(isDeleted: Value(true)));
}

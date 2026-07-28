import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/utils/sound_service.dart';
import 'task_tile.dart';

class ReorderableTaskList extends StatefulWidget {
  final List<Task> tasks;
  const ReorderableTaskList({super.key, required this.tasks});

  @override
  State<ReorderableTaskList> createState() => _ReorderableTaskListState();
}

class _ReorderableTaskListState extends State<ReorderableTaskList> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);
  }

  @override
  void didUpdateWidget(ReorderableTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tasks = List.from(widget.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final t = _tasks[index];
        return Padding(
          key: ValueKey(t.id),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TaskTile(
            task: t,
            onTap: () => context.push('/task-details/${t.id}'),
            onCheck: (v) {
              if (v == true) SoundService.playTaskComplete(context);
              db.tasksDao.setStatus(t.id, v == true ? TaskStatus.completed : TaskStatus.pending);
            },
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _tasks.removeAt(oldIndex);
          _tasks.insert(newIndex, item);
        });
        // In a real app, we would update the position in the database
      },
    );
  }
}

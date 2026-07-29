import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/sound_service.dart';
import 'task_tile.dart';

class ReorderableTaskList extends StatefulWidget {
  final List<Task> tasks;

  const ReorderableTaskList({
    super.key,
    required this.tasks,
  });

  @override
  State<ReorderableTaskList> createState() => _ReorderableTaskListState();
}

class _ReorderableTaskListState extends State<ReorderableTaskList> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant ReorderableTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tasks = List<Task>.from(widget.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final theme = Theme.of(context);

    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اسحب لإعادة الترتيب',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${_tasks.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _tasks.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                final item = _tasks.removeAt(oldIndex);
                _tasks.insert(newIndex, item);
              });

              // لاحقًا يمكن حفظ الترتيب داخل قاعدة البيانات
            },
            itemBuilder: (context, index) {
              final task = _tasks[index];

              return Container(
                key: ValueKey(task.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 44),
                      child: TaskTile(
                        task: task,
                        onTap: () => context.push('/task-details/${task.id}'),
                        onCheck: (checked) {
                          final done = checked == true;

                          if (done) {
                            SoundService.playTaskComplete(context);
                          }

                          db.tasksDao.setStatus(
                            task.id,
                            done ? TaskStatus.completed : TaskStatus.pending,
                          );
                        },
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      top: 0,
                      bottom: 10,
                      child: Center(
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 20,
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

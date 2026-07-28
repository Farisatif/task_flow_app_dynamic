import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:drift/drift.dart' show Value;
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/utils/task_extensions.dart';
import '../widgets/app_scaffold.dart';


class TaskDetailsScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return StreamBuilder<Task?>(
      stream: db.tasksDao.watchById(taskId),
      builder: (context, snapshot) {
        final task = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting && task == null) {
          return const AppScaffold(title: 'تفاصيل المهمة', showNav: false, body: Center(child: CircularProgressIndicator()));
        }
        if (task == null) {
          return AppScaffold(
            title: 'تفاصيل المهمة',
            showNav: false,
            body: Center(child: Text('تم حذف هذه المهمة', style: Theme.of(context).textTheme.bodyMedium)),
          );
        }

        return AppScaffold(
          title: 'تفاصيل المهمة',
          showNav: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/task-form/${task.id}'),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.status == TaskStatus.completed,
                    onChanged: (v) => db.tasksDao.setStatus(task.id, v == true ? TaskStatus.completed : TaskStatus.pending),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                                color: task.status == TaskStatus.completed ? Colors.grey : null,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            _chip(context, Icons.calendar_today, intl.DateFormat('d MMM', 'ar').format(task.date)),
                            _chip(context, Icons.access_time, task.timeRange),
                            _chip(context, Icons.flag, task.priorityLabel(), color: task.priorityColor()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              _sectionHeader(context, 'المهام الفرعية', Icons.account_tree_outlined),
              StreamBuilder<List<Task>>(
                stream: db.tasksDao.watchSubtasks(taskId),
                builder: (context, snapshot) {
                  final subtasks = snapshot.data ?? [];
                  return Column(
                    children: [
                      ...subtasks.map((st) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: st.status == TaskStatus.completed,
                              onChanged: (v) => db.tasksDao.setStatus(st.id, v == true ? TaskStatus.completed : TaskStatus.pending),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            title: Text(
                              st.title,
                              style: TextStyle(
                                decoration: st.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                                color: st.status == TaskStatus.completed ? Colors.grey : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              onPressed: () => db.tasksDao.softDelete(st.id),
                            ),
                          )),
                      _addSubtaskField(context, db),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'ملاحظات', Icons.notes),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  task.notes?.isNotEmpty == true ? task.notes! : 'لا توجد ملاحظات إضافية...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('حذف المهمة'),
                      content: const Text('هل أنت متأكد من حذف هذه المهمة بالكامل؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    db.tasksDao.softDelete(taskId);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('حذف المهمة بالكامل', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey)),
      ],
    );
  }

  Widget _addSubtaskField(BuildContext context, AppDatabase db) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'إضافة مهمة فرعية...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.add, size: 20),
        ),
        onSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            db.tasksDao.insertSubtask(
              TasksCompanion.insert(
                title: val.trim(),
                date: DateTime.now(),
                startMinutes: 0,
                endMinutes: 0,
                priority: TaskPriority.medium,
                status: const Value(TaskStatus.pending),
              ),
              taskId,
            );
            controller.clear();
          }
        },
      ),
    );
  }
}

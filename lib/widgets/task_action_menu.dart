import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/notification_service.dart';
import '../core/utils/task_extensions.dart';

class TaskActionMenu extends StatelessWidget {
  final Task task;

  const TaskActionMenu({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => TaskActionMenu(task: task),
    );
  }

  DateTime _taskReminderTime() {
    return DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.startMinutes ~/ 60,
      task.startMinutes % 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final router = GoRouter.of(context);
    final isCompleted = task.isDone;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            _Header(
              title: task.title,
              subtitle: task.timeRange,
              priorityLabel: task.priorityLabel(),
              priorityColor: task.priorityColor(),
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'تعديل المهمة',
              onTap: () {
                Navigator.of(context).pop();
                router.push('/task-form/${task.id}');
              },
            ),
            _ActionTile(
              icon: isCompleted
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              label: isCompleted
                  ? 'إعادة تعيين كغير مكتملة'
                  : 'تحديد كمكتملة',
              iconColor:
                  isCompleted ? theme.iconTheme.color : AppColors.accentGreen,
              onTap: () async {
                await db.tasksDao.setStatus(
                  task.id,
                  isCompleted ? TaskStatus.pending : TaskStatus.completed,
                );

                if (isCompleted) {
                  await NotificationService.scheduleTaskReminder(
                    taskId: task.id,
                    title: task.title,
                    scheduledTime: _taskReminderTime(),
                    body: 'من ${task.timeRange}',
                  );
                } else {
                  await NotificationService.cancelReminder(task.id);
                }

                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            _ActionTile(
              icon: Icons.copy_outlined,
              label: 'تكرار المهمة',
              onTap: () async {
                final newTaskId = await db.tasksDao.insertTask(
                  TasksCompanion.insert(
                    title: '${task.title} (نسخة)',
                    date: task.date,
                    startMinutes: task.startMinutes,
                    endMinutes: task.endMinutes,
                    priority: task.priority,
                    status: const drift.Value(TaskStatus.pending),
                    categoryId: drift.Value.absentIfNull(task.categoryId),
                    projectId: drift.Value.absentIfNull(task.projectId),
                    notes: drift.Value.absentIfNull(task.notes),
                    createdAt: drift.Value(DateTime.now()),
                    updatedAt: drift.Value(DateTime.now()),
                  ),
                );

                await NotificationService.scheduleTaskReminder(
                  taskId: newTaskId,
                  title: '${task.title} (نسخة)',
                  scheduledTime: _taskReminderTime(),
                  body: 'من ${task.timeRange}',
                );

                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.10)),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'حذف المهمة',
              iconColor: AppColors.priorityHigh,
              labelColor: AppColors.priorityHigh,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('حذف المهمة'),
                    content: Text('هل تريد حذف "${task.title}"؟'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.priorityHigh,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await NotificationService.cancelReminder(task.id);
                  await db.tasksDao.softDelete(task.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priorityLabel;
  final Color priorityColor;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.priorityLabel,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'الأولوية: $priorityLabel',
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ic = iconColor ?? AppColors.primary;
    final tc = labelColor ?? theme.textTheme.bodyMedium?.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ic.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: ic, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tc,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

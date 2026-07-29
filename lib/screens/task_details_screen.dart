import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/task_extensions.dart';
import '../widgets/app_scaffold.dart';

class TaskDetailsScreen extends StatelessWidget {
  final int taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return StreamBuilder<Task?>(
      stream: db.tasksDao.watchById(taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppScaffold(
            title: 'تفاصيل المهمة',
            showNav: false,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final task = snapshot.data;
        if (task == null) {
          return AppScaffold(
            title: 'تفاصيل المهمة',
            showNav: false,
            body: Center(
              child: Text(
                'تم حذف هذه المهمة',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final isDone = task.status == TaskStatus.completed;

        return AppScaffold(
          title: 'تفاصيل المهمة',
          showNav: false,
          actions: [
            IconButton(
              tooltip: 'تعديل المهمة',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/task-form/${task.id}'),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _TaskHeroCard(
                task: task,
                onToggleDone: (value) {
                  db.tasksDao.setStatus(
                    task.id,
                    value ? TaskStatus.completed : TaskStatus.pending,
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'معلومات المهمة',
                subtitle: 'تفاصيل سريعة عن الوقت والأولوية',
              ),
              const SizedBox(height: 10),
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'التاريخ',
                    value: intl.DateFormat('d MMMM yyyy', 'ar').format(task.date),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'الوقت',
                    value: task.timeRange,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'الأولوية',
                    value: task.priorityLabel(),
                    color: task.priorityColor(),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: isDone
                        ? Icons.check_circle_rounded
                        : Icons.timelapse_rounded,
                    label: 'الحالة',
                    value: _statusLabel(task.status),
                    color: isDone ? AppColors.accentGreen : AppColors.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'المهام الفرعية',
                subtitle: 'راقب التقدم على مستوى أصغر وأكثر وضوحًا',
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Task>>(
                stream: db.tasksDao.watchSubtasks(taskId),
                builder: (context, subtasksSnapshot) {
                  final subtasks = subtasksSnapshot.data ?? [];
                  final completedCount = subtasks
                      .where((s) => s.status == TaskStatus.completed)
                      .length;
                  final totalCount = subtasks.length;
                  final progress =
                      totalCount == 0 ? 0.0 : completedCount / totalCount;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubtasksSummary(
                        completed: completedCount,
                        total: totalCount,
                        progress: progress,
                      ),
                      const SizedBox(height: 12),
                      if (subtasks.isEmpty)
                        _EmptySubtasks(
                          onAdd: () => _showAddSubtaskSheet(context, db),
                        )
                      else
                        ...subtasks.map((subtask) {
                          final done = subtask.status == TaskStatus.completed;
                          final priorityColor = done
                              ? AppColors.accentGreen
                              : subtask.priorityColor();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SubtaskCard(
                              subtask: subtask,
                              onToggle: (value) {
                                db.tasksDao.setStatus(
                                  subtask.id,
                                  value
                                      ? TaskStatus.completed
                                      : TaskStatus.pending,
                                );
                              },
                              onDelete: () => db.tasksDao.softDelete(subtask.id),
                              accentColor: priorityColor,
                            ),
                          );
                        }),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _showAddSubtaskSheet(context, db),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('إضافة مهمة فرعية'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'الملاحظات',
                subtitle: 'أي تفاصيل إضافية تهمك',
              ),
              const SizedBox(height: 10),
              _NotesCard(
                text: task.notes?.isNotEmpty == true
                    ? task.notes!
                    : 'لا توجد ملاحظات إضافية...',
              ),
              const SizedBox(height: 20),
              _DangerAction(
                title: 'حذف المهمة بالكامل',
                subtitle: 'سيتم إخفاء المهمة من قائمتك',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('حذف المهمة'),
                      content: const Text(
                        'هل أنت متأكد من حذف هذه المهمة بالكامل؟',
                      ),
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
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await db.tasksDao.softDelete(taskId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddSubtaskSheet(
    BuildContext context,
    AppDatabase db,
  ) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة مهمة فرعية',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'قسّم المهمة الرئيسية إلى خطوات أصغر',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'عنوان المهمة الفرعية',
                      labelText: 'العنوان',
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceContainerHighest.withOpacity(
                        0.35,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) async {
                      await _saveSubtask(context, db, controller, sheetContext);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SubtaskPreview(
                    title: controller.text.trim().isEmpty
                        ? 'معاينة المهمة الفرعية'
                        : controller.text.trim(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await _saveSubtask(
                              context,
                              db,
                              controller,
                              sheetContext,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('إضافة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _saveSubtask(
    BuildContext context,
    AppDatabase db,
    TextEditingController controller,
    BuildContext sheetContext,
  ) async {
    final title = controller.text.trim();
    if (title.isEmpty) return;

    await db.tasksDao.insertSubtask(
      TasksCompanion.insert(
        title: title,
        date: DateTime.now(),
        startMinutes: 0,
        endMinutes: 0,
        priority: TaskPriority.medium,
        status: const Value(TaskStatus.pending),
      ),
      taskId,
    );

    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return 'مكتملة';
      case TaskStatus.inProgress:
        return 'قيد التنفيذ';
      case TaskStatus.pending:
        return 'قيد الانتظار';
    }
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TaskHeroCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggleDone;

  const _TaskHeroCard({
    required this.task,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.status == TaskStatus.completed;
    final color = done ? AppColors.accentGreen : task.priorityColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Checkbox(
                  value: done,
                  onChanged: (v) => onToggleDone(v == true),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: const BorderSide(color: Colors.white70),
                  activeColor: Colors.white,
                  checkColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      done
                          ? 'هذه المهمة مكتملة الآن'
                          : 'تابع التقدم خطوة بخطوة',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: Icons.calendar_today_outlined,
                label: intl.DateFormat('d MMM', 'ar').format(task.date),
              ),
              _HeroChip(
                icon: Icons.access_time_rounded,
                label: task.timeRange,
              ),
              _HeroChip(
                icon: Icons.flag_outlined,
                label: task.priorityLabel(),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _HeroChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubtasksSummary extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _SubtasksSummary({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0
                ? 'لا توجد مهام فرعية بعد'
                : 'اكتمل $completed من $total',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.dividerColor.withOpacity(0.10),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% من المهام الفرعية مكتملة',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SubtaskCard extends StatelessWidget {
  final Task subtask;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final Color accentColor;

  const _SubtaskCard({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = subtask.status == TaskStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: Checkbox(
          value: done,
          onChanged: (v) => onToggle(v == true),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          activeColor: accentColor,
        ),
        title: Text(
          subtask.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? theme.hintColor : null,
          ),
        ),
        subtitle: Text(
          subtask.priorityLabel(),
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: AppColors.priorityHigh,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _SubtaskPreview extends StatelessWidget {
  final String title;

  const _SubtaskPreview({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(
          theme.brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String text;

  const _NotesCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }
}

class _EmptySubtasks extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptySubtasks({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد مهام فرعية بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قسّم المهمة إلى خطوات أصغر لتتبع الإنجاز بسهولة.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مهمة فرعية'),
          ),
        ],
      ),
    );
  }
}

class _DangerAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.priorityHigh,
        side: BorderSide(color: AppColors.priorityHigh.withOpacity(0.25)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.delete_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

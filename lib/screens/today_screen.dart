import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_state_view.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dateStr = intl.DateFormat('EEEE، d MMMM', 'ar').format(today);

    const startHour = 7;
    const endHour = 21;
    final hours = List.generate(endHour - startHour + 1, (i) => i + startHour);

    return AppScaffold(
      title: 'اليوم',
      navIndex: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/task-form'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'مهمة جديدة',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchTasksForDate(today),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const AppLoadingState(label: 'جارٍ تحميل خطة اليوم…');
          }
          if (snapshot.hasError) {
            return const AppErrorState(
              title: 'تعذر تحميل خطة اليوم',
              message:
                  'سيحاول التطبيق استعادة البيانات تلقائيًا عند عودة الاتصال بقاعدة البيانات.',
            );
          }

          final tasks = snapshot.data ?? [];

          final completed = tasks
              .where((t) => t.status == TaskStatus.completed)
              .length;
          final inProgress = tasks
              .where((t) => t.status == TaskStatus.inProgress)
              .length;
          final pending = tasks
              .where((t) => t.status == TaskStatus.pending)
              .length;

          final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

          final Map<int, List<Task>> byHour = {};
          for (final task in tasks) {
            byHour.putIfAbsent(task.startMinutes ~/ 60, () => []).add(task);
          }

          for (final list in byHour.values) {
            list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _HeaderCard(
                dateStr: dateStr,
                total: tasks.length,
                completed: completed,
                inProgress: inProgress,
                pending: pending,
                progress: progress,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'ملخص سريع',
                subtitle: 'مؤشرات يومك في لمحة واحدة',
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _MetricCard(
                    title: 'إجمالي المهام',
                    value: '${tasks.length}',
                    icon: Icons.event_note_rounded,
                    color: AppColors.primary,
                  ),
                  _MetricCard(
                    title: 'المكتملة',
                    value: '$completed',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.accentGreen,
                  ),
                  _MetricCard(
                    title: 'قيد التنفيذ',
                    value: '$inProgress',
                    icon: Icons.timelapse_rounded,
                    color: AppColors.accentOrange,
                  ),
                  _MetricCard(
                    title: 'منتظرة',
                    value: '$pending',
                    icon: Icons.schedule_rounded,
                    color: AppColors.priorityHigh,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'تقدّم اليوم',
                subtitle: 'نسبة الإنجاز بالنسبة لمهام هذا اليوم',
              ),
              const SizedBox(height: 10),
              _ProgressCard(
                total: tasks.length,
                completed: completed,
                progress: progress,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'الجدول الزمني',
                subtitle: 'المهام موزعة حسب وقت البداية',
              ),
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                _EmptyState(onAdd: () => context.push('/task-form'))
              else
                ...hours.map((hour) {
                  final tasksAtHour = byHour[hour] ?? [];
                  final isCurrentHour = today.hour == hour;

                  return _TimelineHourBlock(
                    hour: hour,
                    isCurrentHour: isCurrentHour,
                    tasks: tasksAtHour,
                    onTaskTap: (task) => context.push('/task-details/${task.id}'),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String dateStr;
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final double progress;

  const _HeaderCard({
    required this.dateStr,
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.today_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'مهام اليوم',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            dateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tasksSummary(total, completed),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.22),
                      color: Colors.white,
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: 'الإجمالي', value: '$total'),
                    _Pill(label: 'منجزة', value: '$completed'),
                    _Pill(label: 'قيد التنفيذ', value: '$inProgress'),
                    _Pill(label: 'منتظرة', value: '$pending'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String tasksSummary(int total, int completed) {
    if (total == 0) return 'لا توجد مهام لليوم، يمكنك البدء بإضافة مهمة جديدة.';
    return 'أنجزت $completed من أصل $total مهمة اليوم.';
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int total;
  final int completed;
  final double progress;

  const _ProgressCard({
    required this.total,
    required this.completed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: theme.dividerColor.withOpacity(0.12),
                  color: AppColors.primary,
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'لا يوجد تقدم بعد' : 'تقدمك اليوم',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'أضف مهامك الأولى لبدء تتبع الإنجاز.'
                      : 'أنت أنجزت $completed من أصل $total مهمة.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  progress >= 0.75
                      ? 'ممتاز، أنت قريب جدًا من الإنهاء.'
                      : progress >= 0.4
                          ? 'تقدم جيد، استمر على هذا النسق.'
                          : 'ابدأ أول مهمة لتحريك المؤشر.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineHourBlock extends StatelessWidget {
  final int hour;
  final bool isCurrentHour;
  final List<Task> tasks;
  final ValueChanged<Task> onTaskTap;

  const _TimelineHourBlock({
    required this.hour,
    required this.isCurrentHour,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hourLabel = '${hour.toString().padLeft(2, '0')}:00';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hourLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCurrentHour ? AppColors.primary : null,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 2,
                height: 8,
                color: theme.dividerColor,
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCurrentHour ? AppColors.primary : theme.dividerColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: theme.dividerColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: tasks.isEmpty
                  ? Container(
                      height: 20,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'لا توجد مهام في هذا الوقت',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    )
                  : Column(
                      children: tasks
                          .map(
                            (task) => InkWell(
                              onTap: () => onTaskTap(task),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _priorityColor(task.priority)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border(
                                    right: BorderSide(
                                      color: _priorityColor(task.priority),
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        _PriorityBadge(priority: task.priority),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatMinutes(task.startMinutes)} - ${_formatMinutes(task.endMinutes)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high => AppColors.priorityHigh,
      TaskPriority.medium => AppColors.priorityMedium,
      TaskPriority.low => AppColors.priorityLow,
    };

    final label = switch (priority) {
      TaskPriority.high => 'عالية',
      TaskPriority.medium => 'متوسطة',
      TaskPriority.low => 'منخفضة',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد مهام لليوم',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ابدأ بإضافة أول مهمة لتنظيم يومك بشكل أفضل.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مهمة'),
            ),
          ],
        ),
      ),
    );
  }
}

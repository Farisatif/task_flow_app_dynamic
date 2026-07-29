import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class WeeklyPlannerScreen extends StatelessWidget {
  const WeeklyPlannerScreen({super.key});

  static const dayLabels = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final today = DateTime(now.year, now.month, now.day);

    final dateRangeStr =
        '${DateFormat('d MMM', 'ar').format(startOfWeek)} - ${DateFormat('d MMMM yyyy', 'ar').format(endOfWeek)}';

    return AppScaffold(
      title: 'المخطط الأسبوعي',
      showNav: false,
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل المهام الأسبوعية',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final allTasks = snapshot.data ?? [];
          final visibleTasks = allTasks.where((t) => !t.isDeleted).toList();

          final weekTasks = visibleTasks.where((t) {
            final d = DateTime(t.date.year, t.date.month, t.date.day);
            return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
          }).toList();

          final weekCompleted =
              weekTasks.where((t) => t.status == TaskStatus.completed).length;
          final weekInProgress =
              weekTasks.where((t) => t.status == TaskStatus.inProgress).length;
          final weekPending =
              weekTasks.where((t) => t.status == TaskStatus.pending).length;

          final weekCompletionRate =
              weekTasks.isEmpty ? 0.0 : weekCompleted / weekTasks.length;

          final dayCounts = List<int>.generate(7, (index) {
            final dayDate = startOfWeek.add(Duration(days: index));
            return visibleTasks.where((t) {
              final d = DateTime(t.date.year, t.date.month, t.date.day);
              return d.year == dayDate.year &&
                  d.month == dayDate.month &&
                  d.day == dayDate.day;
            }).length;
          });

          final completedPerDay = List<int>.generate(7, (index) {
            final dayDate = startOfWeek.add(Duration(days: index));
            return visibleTasks.where((t) {
              final d = DateTime(t.date.year, t.date.month, t.date.day);
              return d.year == dayDate.year &&
                  d.month == dayDate.month &&
                  d.day == dayDate.day &&
                  t.status == TaskStatus.completed;
            }).length;
          });

          final maxDayCount = math.max(1, dayCounts.fold<int>(0, math.max));

          final priorityCounts = {
            TaskPriority.high:
                visibleTasks.where((t) => t.priority == TaskPriority.high).length,
            TaskPriority.medium: visibleTasks
                .where((t) => t.priority == TaskPriority.medium)
                .length,
            TaskPriority.low:
                visibleTasks.where((t) => t.priority == TaskPriority.low).length,
          };

          final todayTasks = visibleTasks.where((t) {
            final d = DateTime(t.date.year, t.date.month, t.date.day);
            return d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }).length;

          final activeDays = dayCounts.where((c) => c > 0).length;
          final busiestDayIndex = _bestIndex(dayCounts);
          final bestDayLabel = dayLabels[busiestDayIndex];
          final bestDayCount = dayCounts[busiestDayIndex];

          final quietDayIndex = _lowestNonZeroIndex(dayCounts);
          final quietDayLabel =
              quietDayIndex == null ? 'لا يوجد' : dayLabels[quietDayIndex];

          final nextSuggestion = weekCompletionRate >= 0.75
              ? 'أنت تسير بشكل ممتاز هذا الأسبوع. حافظ على نفس النسق ولا تكدّس المهام في آخر الأسبوع.'
              : weekCompletionRate >= 0.4
                  ? 'أداء جيد، لكن حاول توزيع المهام على أيام أكثر لتخفيف الضغط.'
                  : 'ابدأ بتحديد 2–3 مهام أساسية يوميًا حتى يتضح لك إيقاع الأسبوع.';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _HeaderCard(
                title: 'المخطط الأسبوعي',
                subtitle: dateRangeStr,
                icon: Icons.dashboard_rounded,
                completionRate: weekCompletionRate,
                weekTasks: weekTasks.length,
                completed: weekCompleted,
                activeDays: activeDays,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'ملخص أسبوعك',
                subtitle: 'أرقام تساعدك على قراءة أداءك بسرعة',
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.65,
                children: [
                  _StatCard(
                    title: 'إجمالي الأسبوع',
                    value: weekTasks.length.toString(),
                    icon: Icons.assignment_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  _StatCard(
                    title: 'مهام اليوم',
                    value: todayTasks.toString(),
                    icon: Icons.today_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'أيام نشطة',
                    value: activeDays.toString(),
                    icon: Icons.event_available_rounded,
                    color: AppColors.accentGreen,
                  ),
                  _StatCard(
                    title: 'منجزة هذا الأسبوع',
                    value: weekCompleted.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.priorityHigh,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InsightCard(
                title: 'قراءة سريعة',
                body:
                    'هذا الأسبوع لديك ${weekTasks.length} مهمة إجمالًا، منها $weekCompleted مكتملة و$weekInProgress قيد التنفيذ و$weekPending بانتظار التنفيذ. '
                    'نسبة الإنجاز الحالية بلغت ${(weekCompletionRate * 100).toStringAsFixed(0)}%، وهو مؤشر جيد لمعرفة مدى توازن أسبوعك.',
                icon: Icons.insights_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _InsightCard(
                title: 'أفضل يوم وأهدأ يوم',
                body:
                    'اليوم الأكثر ازدحامًا كان "$bestDayLabel" بعدد $bestDayCount مهمة. '
                    '${quietDayIndex == null ? 'لم يظهر يوم هادئ واضح هذا الأسبوع.' : 'أما اليوم الأقل ضغطًا فهو "$quietDayLabel"، ويمكن استخدامه للمهام العميقة أو المراجعة.'}',
                icon: Icons.event_note_rounded,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'مخطط المهام الأسبوعي',
                subtitle: 'كم مهمة أُضيفت في كل يوم',
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(7, (index) {
                      final count = dayCounts[index];
                      final completedCount = completedPerDay[index];
                      final ratio = count / maxDayCount;
                      final isToday = index == now.weekday - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 86,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayLabels[index],
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight:
                                          isToday ? FontWeight.w800 : FontWeight.w600,
                                      color: isToday
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$completedCount مكتملة',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 12,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: ratio == 0 ? 0.03 : ratio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.tertiary,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 34,
                              child: Text(
                                '$count',
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'تقدم الإنجاز اليومي داخل الأسبوع',
                subtitle: 'مقارنة بين عدد المهام وعدد المكتمل منها',
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(7, (index) {
                      final total = dayCounts[index];
                      final done = completedPerDay[index];
                      final rate = total == 0 ? 0.0 : done / total;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dayLabels[index],
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$done / $total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : rate,
                                minHeight: 10,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'توزيع الأولويات',
                subtitle: 'كيف يتوزع جهدك بين المهم والعاجل؟',
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PriorityRow(
                        label: 'عالية',
                        count: priorityCounts[TaskPriority.high] ?? 0,
                        total: visibleTasks.length,
                        color: AppColors.priorityHigh,
                      ),
                      const SizedBox(height: 12),
                      _PriorityRow(
                        label: 'متوسطة',
                        count: priorityCounts[TaskPriority.medium] ?? 0,
                        total: visibleTasks.length,
                        color: AppColors.priorityMedium,
                      ),
                      const SizedBox(height: 12),
                      _PriorityRow(
                        label: 'منخفضة',
                        count: priorityCounts[TaskPriority.low] ?? 0,
                        total: visibleTasks.length,
                        color: AppColors.priorityLow,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'ملخص الأسبوع النصي',
                subtitle: 'قراءة مختصرة تساعدك على اتخاذ القرار',
              ),
              const SizedBox(height: 10),
              _InsightCard(
                title: 'توصية الأسبوع',
                body: nextSuggestion,
                icon: Icons.lightbulb_outline_rounded,
                color: AppColors.accentOrange,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'مهام كل يوم',
                subtitle: 'عرض تفصيلي لأيام الأسبوع الحالي',
              ),
              const SizedBox(height: 10),
              ...List.generate(7, (index) {
                final dayDate = startOfWeek.add(Duration(days: index));

                final dayTasks = visibleTasks.where((t) {
                  final d = DateTime(t.date.year, t.date.month, t.date.day);
                  return d.year == dayDate.year &&
                      d.month == dayDate.month &&
                      d.day == dayDate.day;
                }).toList();

                final isToday = dayDate.year == today.year &&
                    dayDate.month == today.month &&
                    dayDate.day == today.day;

                final completedCount = dayTasks
                    .where((t) => t.status == TaskStatus.completed)
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dayLabels[index],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'اليوم',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('d MMMM', 'ar').format(dayDate)} • $completedCount مكتملة',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (dayTasks.isEmpty)
                          Text(
                            'لا توجد مهام في هذا اليوم',
                            style: theme.textTheme.bodySmall,
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: dayTasks.map((task) {
                              final color = _priorityColor(task.priority);
                              final completed =
                                  task.status == TaskStatus.completed;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: completed
                                            ? AppColors.accentGreen
                                            : color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        task.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  int _bestIndex(List<int> data) {
    if (data.isEmpty) return 0;
    var bestIndex = 0;
    var bestValue = data.first;
    for (var i = 1; i < data.length; i++) {
      if (data[i] > bestValue) {
        bestValue = data[i];
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int? _lowestNonZeroIndex(List<int> data) {
    int? index;
    int? lowest;
    for (var i = 0; i < data.length; i++) {
      final v = data[i];
      if (v <= 0) continue;
      if (lowest == null || v < lowest) {
        lowest = v;
        index = i;
      }
    }
    return index;
  }

  Color _priorityColor(TaskPriority p) {
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

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double completionRate;
  final int weekTasks;
  final int completed;
  final int activeDays;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.completionRate,
    required this.weekTasks,
    required this.completed,
    required this.activeDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'هذا الأسبوع: $weekTasks مهمة، منها $completed مكتملة، ونشاطك موزع على $activeDays يومًا.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: completionRate,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  color: Colors.white,
                ),
                Text(
                  '${(completionRate * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
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

class _PriorityRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _PriorityRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 11,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio == 0 ? 0.02 : ratio,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
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
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

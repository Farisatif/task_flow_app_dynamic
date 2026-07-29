import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
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
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final dateRangeStr =
        '${DateFormat('d', 'ar').format(startOfWeek)} - ${DateFormat('d MMMM yyyy', 'ar').format(endOfWeek)}';

    return AppScaffold(
      title: 'الداشبورد الأسبوعي',
      showNav: false,
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل المهام',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          final allTasks = snapshot.data ?? [];
          final visibleTasks = allTasks.where((t) => !t.isDeleted).toList();

          final weekTasks = visibleTasks.where((t) {
            final d = t.date;
            return !d.isBefore(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)) &&
                !d.isAfter(DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59));
          }).toList();

          final dayCounts = List<int>.generate(7, (index) {
            final dayDate = DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day,
            ).add(Duration(days: index));

            return visibleTasks.where((t) {
              final d = t.date;
              return d.year == dayDate.year &&
                  d.month == dayDate.month &&
                  d.day == dayDate.day;
            }).length;
          });

          final maxDayCount = math.max(1, dayCounts.fold<int>(0, math.max));

          final priorityCounts = {
            'high': visibleTasks.where((t) => _priorityKey(t.priority) == 'high').length,
            'medium': visibleTasks.where((t) => _priorityKey(t.priority) == 'medium').length,
            'low': visibleTasks.where((t) => _priorityKey(t.priority) == 'low').length,
            'unknown': visibleTasks.where((t) => _priorityKey(t.priority) == 'unknown').length,
          };

          final todayTasks = visibleTasks.where((t) {
            final d = t.date;
            return d.year == now.year && d.month == now.month && d.day == now.day;
          }).length;

          final activeDays = dayCounts.where((c) => c > 0).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                title: 'المخطط الأسبوعي',
                subtitle: dateRangeStr,
                icon: Icons.dashboard_rounded,
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _StatCard(
                    title: 'إجمالي الأسبوع',
                    value: weekTasks.length.toString(),
                    icon: Icons.assignment_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _StatCard(
                    title: 'مهام اليوم',
                    value: todayTasks.toString(),
                    icon: Icons.today_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'أيام نشطة',
                    value: activeDays.toString(),
                    icon: Icons.event_available_rounded,
                    color: AppColors.priorityMedium,
                  ),
                  _StatCard(
                    title: 'أعلى أولوية',
                    value: priorityCounts['high'].toString(),
                    icon: Icons.priority_high_rounded,
                    color: AppColors.priorityHigh,
                  ),
                ],
              ),

              const SizedBox(height: 18),
              _SectionTitle(
                title: 'مخطط المهام الأسبوعي',
                subtitle: 'عدد المهام لكل يوم',
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
                      final ratio = count / maxDayCount;
                      final isToday = index == now.weekday - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 72,
                              child: Text(
                                dayLabels[index],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 12,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: ratio == 0 ? 0.03 : ratio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.tertiary,
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
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _SectionTitle(
                title: 'توزيع الأولويات',
                subtitle: 'تحليل سريع حسب مستوى الأهمية',
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
                        count: priorityCounts['high']!,
                        total: visibleTasks.length,
                        color: AppColors.priorityHigh,
                      ),
                      const SizedBox(height: 12),
                      _PriorityRow(
                        label: 'متوسطة',
                        count: priorityCounts['medium']!,
                        total: visibleTasks.length,
                        color: AppColors.priorityMedium,
                      ),
                      const SizedBox(height: 12),
                      _PriorityRow(
                        label: 'منخفضة',
                        count: priorityCounts['low']!,
                        total: visibleTasks.length,
                        color: AppColors.priorityLow,
                      ),
                      const SizedBox(height: 12),
                      _PriorityRow(
                        label: 'غير محددة',
                        count: priorityCounts['unknown']!,
                        total: visibleTasks.length,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _SectionTitle(
                title: 'مهام كل يوم',
                subtitle: 'عرض تفصيلي للأسبوع الحالي',
              ),
              const SizedBox(height: 10),

              ...List.generate(7, (index) {
                final dayDate = DateTime(
                  startOfWeek.year,
                  startOfWeek.month,
                  startOfWeek.day,
                ).add(Duration(days: index));

                final dayTasks = visibleTasks.where((t) {
                  final d = t.date;
                  return d.year == dayDate.year &&
                      d.month == dayDate.month &&
                      d.day == dayDate.day;
                }).toList();

                final isToday = dayDate.year == now.year &&
                    dayDate.month == now.month &&
                    dayDate.day == now.day;

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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'اليوم',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (dayTasks.isEmpty)
                          Text(
                            'لا توجد مهام',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: dayTasks.map((t) {
                              final color = _priorityColor(t.priority);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        t.title,
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

  String _priorityKey(Object? priority) {
    if (priority == null) return 'unknown';

    final raw = priority.toString().toLowerCase();
    final value = raw.contains('.') ? raw.split('.').last : raw;

    if (value.contains('high') || value.contains('عالية') || value.contains('مرتفع')) {
      return 'high';
    }
    if (value.contains('medium') || value.contains('normal') || value.contains('متوسطة')) {
      return 'medium';
    }
    if (value.contains('low') || value.contains('منخفض')) {
      return 'low';
    }
    return 'unknown';
  }

  Color _priorityColor(Object? priority) {
    switch (_priorityKey(priority)) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityLow.withOpacity(0.7);
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
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

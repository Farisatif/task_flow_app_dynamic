import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class PerformanceReportsScreen extends StatelessWidget {
  const PerformanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'تقارير الأداء',
      showNav: false,
      body: StreamBuilder<TaskStatistics>(
        stream: db.statisticsDao.watchTaskStatisticsForToday(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في تحميل تقارير المهام',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return StreamBuilder<FocusStatistics>(
            stream: db.statisticsDao.watchFocusStatisticsForToday(),
            builder: (context, focusSnapshot) {
              if (focusSnapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ في تحميل تقارير التركيز',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              if (!taskSnapshot.hasData || !focusSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final taskStats = taskSnapshot.data!;
              final focusStats = focusSnapshot.data!;

              final completionRate =
                  taskStats.completionPercentage.clamp(0, 100).toDouble();

              String performanceText = 'جيد';
              if (completionRate >= 80) {
                performanceText = 'أداء رائع';
              } else if (completionRate >= 50) {
                performanceText = 'أداء متوسط';
              } else {
                performanceText = 'يحتاج تحسين';
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeaderCard(
                    completionRate: completionRate,
                    performanceText: performanceText,
                    completedTasks: taskStats.completed,
                    totalTasks: taskStats.total,
                    overdueTasks: taskStats.overdue,
                    focusMinutes: focusStats.totalMinutes,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'ملخص اليوم',
                    subtitle: 'مؤشرات سريعة عن مهامك وتركيزك',
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
                        title: 'المهام المكتملة',
                        value: '${taskStats.completed}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                      _MetricCard(
                        title: 'قيد التنفيذ',
                        value: '${taskStats.inProgress}',
                        icon: Icons.timelapse_rounded,
                        color: AppColors.accentOrange,
                      ),
                      _MetricCard(
                        title: 'دقائق التركيز',
                        value: '${focusStats.totalMinutes}',
                        icon: Icons.timer_outlined,
                        color: AppColors.accentGreen,
                      ),
                      _MetricCard(
                        title: 'المتأخرة',
                        value: '${taskStats.overdue}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.priorityHigh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'تفاصيل الأداء',
                    subtitle: 'نظرة أوضح على مؤشرات اليوم',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'الإجمالي',
                          value: '${taskStats.total}',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'نسبة الإنجاز',
                          value: '${completionRate.toInt()}%',
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'المكتملة',
                          value: '${taskStats.completed}',
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'التركيز',
                          value: '${focusStats.totalMinutes} دقيقة',
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final double completionRate;
  final String performanceText;
  final int completedTasks;
  final int totalTasks;
  final int overdueTasks;
  final int focusMinutes;

  const _HeaderCard({
    required this.completionRate,
    required this.performanceText,
    required this.completedTasks,
    required this.totalTasks,
    required this.overdueTasks,
    required this.focusMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: completionRate / 100,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  color: Colors.white,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${completionRate.toInt()}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      performanceText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
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
                  'تقارير اليوم',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أكملت $completedTasks من $totalTasks مهمة',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'دقائق التركيز: $focusMinutes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المهام المتأخرة: $overdueTasks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

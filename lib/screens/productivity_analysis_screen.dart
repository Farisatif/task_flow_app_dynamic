import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class ProductivityAnalysisScreen extends StatelessWidget {
  const ProductivityAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'تحليل الإنتاجية',
      showNav: false,
      body: StreamBuilder<TaskStatistics>(
        stream: db.statisticsDao.watchTaskStatisticsForToday(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.hasError) {
            return Center(
              child: Text(
                'تعذر تحميل بيانات المهام',
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
                    'تعذر تحميل بيانات التركيز',
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
                  taskStats.total == 0 ? 0.0 : (taskStats.completed / taskStats.total) * 100;

              String performanceText = 'بحاجة إلى تحسين';
              if (completionRate >= 80) {
                performanceText = 'أداء رائع';
              } else if (completionRate >= 50) {
                performanceText = 'أداء جيد';
              }

              final focusMinutes = focusStats.totalMinutes;
              final focusProgress =
                  (focusMinutes / 150.0).clamp(0.0, 1.0);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _HeroCard(
                    completionRate: completionRate,
                    performanceText: performanceText,
                    completedTasks: taskStats.completed,
                    totalTasks: taskStats.total,
                    overdueTasks: taskStats.overdue,
                    focusMinutes: focusMinutes,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'ملخص اليوم',
                    subtitle: 'نظرة سريعة على المهام والتركيز',
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
                        value: '$focusMinutes',
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
                    title: 'التركيز اليومي',
                    subtitle: 'كم اقتربت من هدف التركيز اليومي',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 86,
                            height: 86,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: focusProgress,
                                  strokeWidth: 9,
                                  backgroundColor: theme.dividerColor.withOpacity(0.12),
                                  color: AppColors.accentGreen,
                                ),
                                Text(
                                  '${(focusProgress * 100).round()}%',
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
                                  'متوسط التركيز اليومي',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatMinutes(focusMinutes),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'الهدف المرجعي: 150 دقيقة',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'الإنتاجية الأسبوعية',
                    subtitle: 'مقارنة سريعة بين أيام الأسبوع',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
                      child: SizedBox(
                        height: 220,
                        child: StreamBuilder<List<double>>(
                          stream: db.statisticsDao.watchWeeklyProductivity(),
                          builder: (context, snapshot) {
                            final data = snapshot.data ?? List.filled(7, 0.0);

                            return BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _findMaxY(data),
                                minY: 0,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 20,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: theme.dividerColor.withOpacity(0.10),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= 7) {
                                          return const SizedBox.shrink();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _dayLabel(index),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(
                                  data.length,
                                  (i) {
                                    final barValue = data[i].clamp(0.0, 100.0);
                                    final isToday = i == DateTime.now().weekday % 7;

                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: barValue,
                                          width: 18,
                                          borderRadius: BorderRadius.circular(8),
                                          gradient: LinearGradient(
                                            colors: isToday
                                                ? [
                                                    AppColors.primary,
                                                    AppColors.accentGreen,
                                                  ]
                                                : [
                                                    AppColors.primary.withOpacity(0.85),
                                                    AppColors.primary.withOpacity(0.55),
                                                  ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'أفضل أوقات الإنتاجية',
                    subtitle: 'النافذة الزمنية الأكثر نشاطًا لك',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: StreamBuilder<String>(
                        stream: db.statisticsDao.watchBestProductivityHour(),
                        builder: (context, snapshot) {
                          final bestTime = snapshot.data ?? '09:00 - 12:00';

                          return Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'أفضل الأوقات',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bestTime,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'أعلى تركيز',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'ملخص المهام',
                    subtitle: 'حالة المهام خلال اليوم',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'إجمالي',
                            value: '${taskStats.total}',
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'مكتملة',
                            value: '${taskStats.completed}',
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'جارية',
                            value: '${taskStats.inProgress}',
                            color: AppColors.accentOrange,
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'منتظرة',
                            value: '${taskStats.pending}',
                            color: AppColors.priorityHigh,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours ساعة $mins دقيقة';
    }
    return '$mins دقيقة';
  }

  static String _dayLabel(int index) {
    const labels = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return labels[index % 7];
  }

  static double _findMaxY(List<double> values) {
    if (values.isEmpty) return 100;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue < 20) return 20;
    return ((maxValue / 10).ceil() * 10).toDouble();
  }
}

class _HeroCard extends StatelessWidget {
  final double completionRate;
  final String performanceText;
  final int completedTasks;
  final int totalTasks;
  final int overdueTasks;
  final int focusMinutes;

  const _HeroCard({
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
                  'تحليل اليوم',
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

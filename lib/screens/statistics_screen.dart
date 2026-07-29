import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/stats_utils.dart';
import '../widgets/app_scaffold.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'الإحصائيات العامة',
      navIndex: 3,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          StreamBuilder<TaskStatistics>(
            stream: db.statisticsDao.watchTaskStatisticsForDate(DateTime.now()),
            builder: (context, taskSnapshot) {
              if (taskSnapshot.hasError) {
                return Center(
                  child: Text(
                    'تعذر تحميل إحصائيات المهام',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              return StreamBuilder<List<double>>(
                stream: db.statisticsDao.watchWeeklyProductivity(),
                builder: (context, weeklySnapshot) {
                  final weeklyData = weeklySnapshot.data ?? List.filled(7, 0.0);

                  if (!taskSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = taskSnapshot.data!;
                  final completionRate = stats.total == 0
                      ? 0.0
                      : (stats.completed / stats.total) * 100;

                  final weeklyAverage = weeklyData.isEmpty
                      ? 0.0
                      : StatsUtils.mean(weeklyData).toDouble();

                  final bestDayIndex = _bestDayIndex(weeklyData);
                  final bestDayLabel = _dayLabel(bestDayIndex);
                  final bestDayValue = weeklyData.isEmpty
                      ? 0.0
                      : weeklyData[bestDayIndex].toDouble();

                  String performanceText = 'يحتاج إلى تحسين';
                  if (completionRate >= 85) {
                    performanceText = 'أداء ممتاز';
                  } else if (completionRate >= 60) {
                    performanceText = 'أداء جيد';
                  } else if (completionRate >= 35) {
                    performanceText = 'أداء متوسط';
                  }

                  final focusMinutesToday = 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(
                        completionRate: completionRate,
                        performanceText: performanceText,
                        completedTasks: stats.completed,
                        totalTasks: stats.total,
                        overdueTasks: stats.overdue,
                        inProgressTasks: stats.inProgress,
                        weeklyAverage: weeklyAverage,
                        bestDayLabel: bestDayLabel,
                        bestDayValue: bestDayValue,
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'ملخص اليوم',
                        subtitle: 'أرقام سريعة تكشف أين أنت الآن',
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
                            value: '${stats.total}',
                            icon: Icons.event_note_rounded,
                            color: AppColors.primary,
                          ),
                          _MetricCard(
                            title: 'المكتملة',
                            value: '${stats.completed}',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.accentGreen,
                          ),
                          _MetricCard(
                            title: 'قيد التنفيذ',
                            value: '${stats.inProgress}',
                            icon: Icons.timelapse_rounded,
                            color: AppColors.accentOrange,
                          ),
                          _MetricCard(
                            title: 'المتأخرة',
                            value: '${stats.overdue}',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.priorityHigh,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'قراءة سريعة للأداء',
                        subtitle: 'ماذا تعني هذه الأرقام؟',
                      ),
                      const SizedBox(height: 10),
                      _InsightCard(
                        title: performanceText,
                        body:
                            'نسبة الإنجاز اليوم بلغت ${completionRate.toStringAsFixed(0)}%. '
                            'هذا يعني أنك أنجزت ${stats.completed} من أصل ${stats.total} مهمة. '
                            'الأفضل هذا الأسبوع كان يوم $bestDayLabel بمتوسط ${bestDayValue.toStringAsFixed(1)} مهمة.',
                        icon: Icons.auto_graph_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      _InsightCard(
                        title: 'مقارنة الأسبوع',
                        body:
                            'متوسط الإنتاجية الأسبوعية الحالي هو ${weeklyAverage.toStringAsFixed(1)} مهمة يوميًا. '
                            'إذا كان اليوم أعلى من هذا المتوسط، فأنت فوق مستواك المعتاد. '
                            'أما إذا كان أقل، فهناك فرصة لتحسين توزيع الجهد.',
                        icon: Icons.insights_rounded,
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'نسبة الإنجاز الأسبوعي',
                        subtitle: 'منحنى يوضح كيف يتغير أداؤك خلال الأسبوع',
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 20, 20, 14),
                          child: SizedBox(
                            height: 220,
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: _findMaxY(weeklyData),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: theme.dividerColor.withOpacity(0.08),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (v, meta) {
                                        final i = v.toInt();
                                        if (i < 0 || i >= 7) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _dayLabel(i),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      weeklyData.length,
                                      (i) => FlSpot(i.toDouble(), weeklyData[i]),
                                    ),
                                    isCurved: true,
                                    barWidth: 3,
                                    color: AppColors.primary,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.primary.withOpacity(0.12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MiniNarration(
                        text:
                            'أعلى نقطة في الأسبوع كانت يوم $bestDayLabel، وهذا يساعدك على معرفة الأيام التي تعمل فيها بشكل أفضل.',
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'توزيع الوقت حسب التصنيفات',
                        subtitle: 'الرسم الدائري يوضح أين يذهب وقتك أكثر',
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<Map<String, int>>(
                        stream: db.statisticsDao.watchTaskCountByCategory(),
                        builder: (context, categorySnapshot) {
                          final categoryMap = categorySnapshot.data ?? {};

                          if (categoryMap.isEmpty) {
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'لا توجد بيانات للتصنيفات بعد',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            );
                          }

                          final total = categoryMap.values.fold<int>(
                            0,
                            (sum, value) => sum + value,
                          );

                          final colors = AppColors.chartPalette;
                          final entries = categoryMap.entries.toList();

                          final sections = entries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final count = entry.value.value;
                            final percentage =
                                total == 0 ? 0.0 : (count / total) * 100;

                            return PieChartSectionData(
                              value: percentage,
                              color: colors[index % colors.length],
                              title: '',
                              radius: 26,
                            );
                          }).toList();

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 150,
                                    width: 150,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 3,
                                        centerSpaceRadius: 38,
                                        sections: sections,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'التفاصيل',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ...entries.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final category = entry.value.key;
                                          final count = entry.value.value;
                                          final pct = total == 0
                                              ? 0
                                              : ((count / total) * 100).round();

                                          return _LegendRow(
                                            label: category,
                                            value: '$count • $pct%',
                                            color: colors[index % colors.length],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'أفضل أوقات الإنتاجية',
                        subtitle: 'الفترة الزمنية التي تعمل فيها بأفضل أداء',
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<String>(
                        stream: db.statisticsDao.watchBestProductivityHour(),
                        builder: (context, snapshot) {
                          final bestTime = snapshot.data ?? 'لا توجد بيانات بعد';

                          return _InfoBlock(
                            icon: Icons.access_time_filled_rounded,
                            title: 'أفضل وقت لك',
                            body: bestTime,
                            color: AppColors.accentGreen,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'إحصائيات مدة المهام',
                        subtitle: 'كيف تتوزع مهامك حسب الوقت المطلوب لإنجازها',
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<Task>>(
                        stream: db.tasksDao.watchAll(),
                        builder: (context, tasksSnapshot) {
                          final allTasks = tasksSnapshot.data ?? [];
                          final durations = allTasks
                              .where((t) => t.endMinutes > t.startMinutes)
                              .map<double>((t) => (t.endMinutes - t.startMinutes).toDouble())
                              .toList();

                          if (durations.isEmpty) {
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'لا توجد بيانات كافية بعد',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            );
                          }

                          final durationAverage = StatsUtils.mean(durations).toDouble();
                          final durationMedian = StatsUtils.median(durations).toDouble();
                          final durationMode = StatsUtils.mode(durations);
                          final durationStd = StatsUtils.standardDeviation(durations).toDouble();

                          final buckets = _durationBuckets(durations);

                          return Column(
                            children: [
                              _StatCardsRow(
                                items: [
                                  _StatMini(
                                    label: 'المتوسط',
                                    value: durationAverage.toStringAsFixed(1),
                                    color: AppColors.primary,
                                  ),
                                  _StatMini(
                                    label: 'الوسيط',
                                    value: durationMedian.toStringAsFixed(1),
                                    color: AppColors.accentBlue,
                                  ),
                                  _StatMini(
                                    label: 'المنوال',
                                    value: durationMode == null
                                        ? '—'
                                        : durationMode.toDouble().toStringAsFixed(0),
                                    color: AppColors.accentGreen,
                                  ),
                                  _StatMini(
                                    label: 'الانحراف',
                                    value: durationStd.toStringAsFixed(2),
                                    color: AppColors.accentOrange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 14),
                                  child: SizedBox(
                                    height: 180,
                                    child: BarChart(
                                      BarChartData(
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 28,
                                              getTitlesWidget: (v, meta) {
                                                final i = v.toInt();
                                                if (i < 0 || i >= buckets.labels.length) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    buckets.labels[i],
                                                    style: theme.textTheme.bodySmall
                                                        ?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        barGroups: List.generate(
                                          buckets.counts.length,
                                          (i) => BarChartGroupData(
                                            x: i,
                                            barRods: [
                                              BarChartRodData(
                                                toY: buckets.counts[i].toDouble(),
                                                width: 16,
                                                borderRadius: BorderRadius.circular(8),
                                                color: AppColors.chartPalette[
                                                    i % AppColors.chartPalette.length],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MiniNarration(
                                text:
                                    'بناءً على هذه الفئات، يمكنك معرفة إن كانت مهامك قصيرة ومتكررة أو طويلة وتحتاج جلسات تركيز أعمق.',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'إحصائيات جلسات التركيز',
                        subtitle: 'مقاييس الجلسات المكتملة وكيف تتوزع',
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<FocusSession>>(
                        stream: db.focusSessionsDao.watchAll(),
                        builder: (context, sessionsSnapshot) {
                          final sessions = (sessionsSnapshot.data ?? [])
                              .where((s) => s.isCompleted)
                              .toList();

                          final sessionMinutes = sessions
                              .map<double>((s) => s.durationSeconds / 60)
                              .toList();

                          if (sessionMinutes.isEmpty) {
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'لا توجد جلسات تركيز مكتملة بعد',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            );
                          }

                          final focusAverage = StatsUtils.mean(sessionMinutes).toDouble();
                          final focusMedian = StatsUtils.median(sessionMinutes).toDouble();
                          final focusMode = StatsUtils.mode(sessionMinutes);
                          final focusStd = StatsUtils.standardDeviation(sessionMinutes).toDouble();
                          final focusBuckets = _durationBuckets(sessionMinutes);

                          return Column(
                            children: [
                              _StatCardsRow(
                                items: [
                                  _StatMini(
                                    label: 'المتوسط',
                                    value: focusAverage.toStringAsFixed(1),
                                    color: AppColors.primary,
                                  ),
                                  _StatMini(
                                    label: 'الوسيط',
                                    value: focusMedian.toStringAsFixed(1),
                                    color: AppColors.accentBlue,
                                  ),
                                  _StatMini(
                                    label: 'المنوال',
                                    value: focusMode == null
                                        ? '—'
                                        : focusMode.toDouble().toStringAsFixed(0),
                                    color: AppColors.accentGreen,
                                  ),
                                  _StatMini(
                                    label: 'الانحراف',
                                    value: focusStd.toStringAsFixed(2),
                                    color: AppColors.accentOrange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 14),
                                  child: SizedBox(
                                    height: 180,
                                    child: BarChart(
                                      BarChartData(
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 28,
                                              getTitlesWidget: (v, meta) {
                                                final i = v.toInt();
                                                if (i < 0 || i >= focusBuckets.labels.length) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    focusBuckets.labels[i],
                                                    style: theme.textTheme.bodySmall
                                                        ?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        barGroups: List.generate(
                                          focusBuckets.counts.length,
                                          (i) => BarChartGroupData(
                                            x: i,
                                            barRods: [
                                              BarChartRodData(
                                                toY: focusBuckets.counts[i].toDouble(),
                                                width: 16,
                                                borderRadius: BorderRadius.circular(8),
                                                color: AppColors.chartPalette[
                                                    i % AppColors.chartPalette.length],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MiniNarration(
                                text:
                                    'إذا كانت جلساتك تتجمع في فئة 25–45 دقيقة، فهذا يعني أن رتمك مناسب للبومودورو. أما لو زادت الفئات الطويلة فربما تحتاج فترات راحة أطول.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static int _bestDayIndex(List<double> data) {
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

  static double _findMaxY(List<double> data) {
    if (data.isEmpty) return 1;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 1) return 1.5;
    return (maxValue + 1).ceilToDouble();
  }

  static String _dayLabel(int index) {
    const labels = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return labels[index % labels.length];
  }

  static _BucketResult _durationBuckets(List<double> durations) {
    const labels = ['<15', '15-30', '30-60', '60-90', '90-120', '>120'];
    const edges = [15.0, 30.0, 60.0, 90.0, 120.0];

    final counts = List<int>.filled(labels.length, 0);
    for (final d in durations) {
      var index = labels.length - 1;
      for (var i = 0; i < edges.length; i++) {
        if (d < edges[i]) {
          index = i;
          break;
        }
      }
      counts[index]++;
    }

    return _BucketResult(labels: labels, counts: counts);
  }
}

class _HeroCard extends StatelessWidget {
  final double completionRate;
  final String performanceText;
  final int completedTasks;
  final int totalTasks;
  final int overdueTasks;
  final int inProgressTasks;
  final double weeklyAverage;
  final String bestDayLabel;
  final double bestDayValue;

  const _HeroCard({
    required this.completionRate,
    required this.performanceText,
    required this.completedTasks,
    required this.totalTasks,
    required this.overdueTasks,
    required this.inProgressTasks,
    required this.weeklyAverage,
    required this.bestDayLabel,
    required this.bestDayValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.analytics_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لوحة الإحصائيات',
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
            'هذه الصفحة تلخص أداءك اليومي والأسبوعي، وتكشف أين يتحسن الإيقاع وأين يحتاج إلى ضبط.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _HeroPill(
                            label: 'المكتملة',
                            value: '$completedTasks',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeroPill(
                            label: 'المتأخرة',
                            value: '$overdueTasks',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroPill(
                            label: 'قيد التنفيذ',
                            value: '$inProgressTasks',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeroPill(
                            label: 'متوسط الأسبوع',
                            value: weeklyAverage.toStringAsFixed(1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'أفضل يوم هذا الأسبوع: $bestDayLabel بمتوسط ${bestDayValue.toStringAsFixed(1)} مهمة',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أنت أنجزت $completedTasks من أصل $totalTasks مهمة اليوم.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroPill({
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
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
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

class _MiniNarration extends StatelessWidget {
  final String text;

  const _MiniNarration({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
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

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardsRow extends StatelessWidget {
  final List<Widget> items;

  const _StatCardsRow({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: item,
            )),
          )
          .toList(),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMini({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketResult {
  final List<String> labels;
  final List<int> counts;

  const _BucketResult({
    required this.labels,
    required this.counts,
  });
}

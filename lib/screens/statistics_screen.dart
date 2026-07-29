import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_measures_card.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/database/dao/statistics_dao.dart';
import '../core/utils/stats_utils.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return AppScaffold(
      title: 'الإحصائيات العامة',
      navIndex: 3,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // إحصائيات المهام لليوم
          StreamBuilder<TaskStatistics>(
            stream: db.statisticsDao.watchTaskStatisticsForDate(DateTime.now()),
            builder: (context, snapshot) {
              final stats = snapshot.data;

              if (stats == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return Row(
                children: [
                  Expanded(child: StatCard(value: '${stats.total}', label: 'إجمالي', color: AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: StatCard(value: '${stats.completed}', label: 'منجزة', color: AppColors.accentGreen)),
                  const SizedBox(width: 8),
                  Expanded(child: StatCard(value: '${stats.overdue}', label: 'متأخرة', color: AppColors.accentOrange)),
                  const SizedBox(width: 8),
                  Expanded(child: StatCard(value: '${stats.inProgress}', label: 'مستمرة', color: AppColors.priorityHigh)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text('نسبة الإنجاز - هذا الأسبوع', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
              child: SizedBox(
                height: 180,
                child: StreamBuilder<List<double>>(
                  stream: db.statisticsDao.watchWeeklyProductivity(),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? List.filled(7, 0.0);

                    return LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
                                if (v.toInt() < 0 || v.toInt() >= days.length) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(days[v.toInt()], style: Theme.of(context).textTheme.bodySmall),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<double>>(
            stream: db.statisticsDao.watchWeeklyProductivity(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? List.filled(7, 0.0);
              final modeValue = StatsUtils.mode(data);

              return StatMeasuresCard(
                title: 'المقاييس الإحصائية - الإنجاز الأسبوعي',
                subtitle: 'عدد المهام المُنجزة يوميًا خلال الأسبوع الحالي',
                measures: [
                  StatMeasure(label: 'المتوسط', value: StatsUtils.mean(data).toStringAsFixed(1)),
                  StatMeasure(label: 'الوسيط', value: StatsUtils.median(data).toStringAsFixed(1), color: AppColors.accentBlue),
                  StatMeasure(
                    label: 'المنوال',
                    value: modeValue == null ? '—' : modeValue.toStringAsFixed(0),
                    color: AppColors.accentGreen,
                  ),
                  StatMeasure(
                    label: 'الانحراف المعياري',
                    value: StatsUtils.standardDeviation(data).toStringAsFixed(2),
                    color: AppColors.accentOrange,
                  ),
                  StatMeasure(label: 'المدى', value: StatsUtils.range(data).toStringAsFixed(0), color: AppColors.accentPink),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text('توزيع الوقت حسب التصنيفات', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<Map<String, int>>(
                stream: db.statisticsDao.watchTaskCountByCategory(),
                builder: (context, snapshot) {
                  final categoryMap = snapshot.data ?? {};

                  if (categoryMap.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('لا توجد بيانات', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    );
                  }

                  final colors = [
                    AppColors.primary,
                    AppColors.accentBlue,
                    AppColors.accentGreen,
                    AppColors.accentOrange,
                    AppColors.accentPink,
                  ];

                  final sections = categoryMap.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final count = entry.value.value;
                    final total = categoryMap.values.fold<int>(0, (sum, c) => sum + c);
                    final percentage = total == 0 ? 0.0 : (count / total) * 100;

                    return PieChartSectionData(
                      value: percentage,
                      color: colors[index % colors.length],
                      title: '',
                      radius: 24,
                    );
                  }).toList();

                  return Row(
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 36,
                            sections: sections,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: categoryMap.entries.toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final category = entry.value.key;
                            final count = entry.value.value;
                            final total = categoryMap.values.fold<int>(0, (sum, c) => sum + c);
                            final percentage = total == 0 ? 0 : ((count / total) * 100).toInt();

                            return _legend(context, category, percentage, colors[index % colors.length]);
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('أفضل أوقات الإنتاجية', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<String>(
                stream: db.statisticsDao.watchBestProductivityHour(),
                builder: (context, snapshot) {
                  final bestTime = snapshot.data ?? 'لا توجد بيانات';

                  return Row(
                    children: [
                      const Icon(Icons.access_time_filled, color: AppColors.accentGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('أفضل الأوقات', style: Theme.of(context).textTheme.bodyMedium),
                            Text(bestTime, style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                      ),
                      Text('أكثر وقت إنتاجية', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('إحصائيات مدة المهام', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          StreamBuilder<List<Task>>(
            stream: db.tasksDao.watchAll(),
            builder: (context, snapshot) {
              final allTasks = snapshot.data ?? [];
              final durations = allTasks
                  .where((t) => t.endMinutes > t.startMinutes)
                  .map<num>((t) => t.endMinutes - t.startMinutes)
                  .toList();

              if (allTasks.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('لا توجد بيانات كافية بعد', style: Theme.of(context).textTheme.bodyMedium)),
                  ),
                );
              }

              final modeValue = StatsUtils.mode(durations);

              // تجميع المدد الزمنية ضمن فئات (بالدقائق) لعرضها كرسم بياني
              const bucketEdges = [15, 30, 60, 90, 120];
              const bucketLabels = ['<15', '15-30', '30-60', '60-90', '90-120', '>120'];
              final bucketCounts = List<int>.filled(bucketLabels.length, 0);
              for (final d in durations) {
                var idx = bucketLabels.length - 1;
                for (var i = 0; i < bucketEdges.length; i++) {
                  if (d < bucketEdges[i]) {
                    idx = i;
                    break;
                  }
                }
                bucketCounts[idx]++;
              }

              // توزيع المهام حسب الأولوية + المنوال
              final priorityCounts = <TaskPriority, int>{for (final p in TaskPriority.values) p: 0};
              for (final t in allTasks) {
                priorityCounts[t.priority] = (priorityCounts[t.priority] ?? 0) + 1;
              }
              TaskPriority modePriority = TaskPriority.medium;
              var maxPriorityCount = -1;
              priorityCounts.forEach((p, c) {
                if (c > maxPriorityCount) {
                  maxPriorityCount = c;
                  modePriority = p;
                }
              });
              final priorityLabelOf = <TaskPriority, String>{
                TaskPriority.high: 'عالية',
                TaskPriority.medium: 'متوسطة',
                TaskPriority.low: 'منخفضة',
              };
              final priorityColorOf = <TaskPriority, Color>{
                TaskPriority.high: AppColors.priorityHigh,
                TaskPriority.medium: AppColors.priorityMedium,
                TaskPriority.low: AppColors.priorityLow,
              };

              return Column(
                children: [
                  if (durations.isNotEmpty)
                    StatMeasuresCard(
                      title: 'مقاييس مدة المهام (بالدقائق)',
                      subtitle: 'محسوبة من ${durations.length} مهمة تحتوي وقت بداية ونهاية',
                      measures: [
                        StatMeasure(label: 'المتوسط', value: StatsUtils.mean(durations).toStringAsFixed(1)),
                        StatMeasure(
                            label: 'الوسيط', value: StatsUtils.median(durations).toStringAsFixed(1), color: AppColors.accentBlue),
                        StatMeasure(
                          label: 'المنوال',
                          value: modeValue == null ? '—' : modeValue.toStringAsFixed(0),
                          color: AppColors.accentGreen,
                        ),
                        StatMeasure(
                          label: 'الانحراف المعياري',
                          value: StatsUtils.standardDeviation(durations).toStringAsFixed(2),
                          color: AppColors.accentOrange,
                        ),
                        StatMeasure(
                            label: 'المدى', value: StatsUtils.range(durations).toStringAsFixed(0), color: AppColors.accentPink),
                      ],
                    ),
                  if (durations.isNotEmpty) const SizedBox(height: 12),
                  if (durations.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                        child: SizedBox(
                          height: 170,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, meta) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= bucketLabels.length) return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(bucketLabels[i], style: Theme.of(context).textTheme.bodySmall),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(
                                bucketCounts.length,
                                (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: bucketCounts[i].toDouble(),
                                      color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                                      width: 16,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('توزيع المهام حسب الأولوية', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 12),
                          ...TaskPriority.values.map((p) {
                            final count = priorityCounts[p] ?? 0;
                            final pct = allTasks.isEmpty ? 0.0 : count / allTasks.length;
                            final color = priorityColorOf[p]!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(priorityLabelOf[p]!, style: Theme.of(context).textTheme.bodyMedium),
                                      Text('$count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 8,
                                      backgroundColor: Theme.of(context).dividerColor,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Text(
                            'المنوال: الأولوية الأكثر تكرارًا هي "${priorityLabelOf[modePriority]}"',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: priorityColorOf[modePriority]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text('إحصائيات جلسات التركيز', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          StreamBuilder<List<FocusSession>>(
            stream: db.focusSessionsDao.watchAll(),
            builder: (context, snapshot) {
              final sessions = (snapshot.data ?? []).where((s) => s.isCompleted).toList();
              final sessionMinutes = sessions.map<num>((s) => s.durationSeconds / 60).toList();

              if (sessionMinutes.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('لا توجد جلسات تركيز مكتملة بعد', style: Theme.of(context).textTheme.bodyMedium)),
                  ),
                );
              }

              final modeValue = StatsUtils.mode(sessionMinutes);

              return StatMeasuresCard(
                title: 'مقاييس جلسات التركيز (بالدقائق)',
                subtitle: 'محسوبة من ${sessionMinutes.length} جلسة مكتملة',
                measures: [
                  StatMeasure(label: 'المتوسط', value: StatsUtils.mean(sessionMinutes).toStringAsFixed(1)),
                  StatMeasure(
                      label: 'الوسيط', value: StatsUtils.median(sessionMinutes).toStringAsFixed(1), color: AppColors.accentBlue),
                  StatMeasure(
                    label: 'المنوال',
                    value: modeValue == null ? '—' : modeValue.toStringAsFixed(0),
                    color: AppColors.accentGreen,
                  ),
                  StatMeasure(
                    label: 'الانحراف المعياري',
                    value: StatsUtils.standardDeviation(sessionMinutes).toStringAsFixed(2),
                    color: AppColors.accentOrange,
                  ),
                  StatMeasure(
                      label: 'المدى', value: StatsUtils.range(sessionMinutes).toStringAsFixed(0), color: AppColors.accentPink),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text('$value%', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

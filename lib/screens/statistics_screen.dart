import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/stat_card.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';

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
            stream: db.statisticsDao.watchTaskStatisticsForToday(),
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
                    final category = entry.value.key;
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
                  final bestTime = snapshot.data ?? '09:00 - 12:00';

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

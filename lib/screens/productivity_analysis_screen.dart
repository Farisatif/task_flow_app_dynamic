import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';

class ProductivityAnalysisScreen extends StatelessWidget {
  const ProductivityAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return AppScaffold(
      title: 'تحليل الإنتاجية',
      showNav: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // متوسط التركيز اليومي
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<FocusStatistics>(
                stream: db.statisticsDao.watchFocusStatisticsForToday(),
                builder: (context, snapshot) {
                  final stats = snapshot.data;

                  if (stats == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final focusPercentage = stats.totalMinutes > 0 ? (stats.totalMinutes / 150).clamp(0.0, 1.0) : 0.0;
                  final hours = stats.totalMinutes ~/ 60;
                  final minutes = stats.totalMinutes % 60;
                  final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

                  return Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: focusPercentage,
                              strokeWidth: 8,
                              backgroundColor: Theme.of(context).dividerColor,
                              color: AppColors.accentGreen,
                            ),
                            Text('${(focusPercentage * 100).toInt()}%', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('متوسط التركيز اليومي', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(timeString, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // الإنتاجية الأسبوعية
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
              child: SizedBox(
                height: 180,
                child: StreamBuilder<List<double>>(
                  stream: db.statisticsDao.watchWeeklyProductivity(),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? List.filled(7, 0.0);

                    return BarChart(
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
                              getTitlesWidget: (v, meta) => Text(days[v.toInt() % 7], style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ),
                        ),
                        barGroups: List.generate(
                          data.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: data[i],
                                color: AppColors.primary,
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // أفضل أوقات الإنتاجية
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
          const SizedBox(height: 16),
          // ملخص المهام
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<TaskStatistics>(
                stream: db.statisticsDao.watchTaskStatisticsForToday(),
                builder: (context, snapshot) {
                  final stats = snapshot.data;

                  if (stats == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملخص المهام اليومية', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('إجمالي:', style: Theme.of(context).textTheme.bodyMedium),
                          Text('${stats.total}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مكتملة:', style: Theme.of(context).textTheme.bodyMedium),
                          Text('${stats.completed}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.accentGreen)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('جارية:', style: Theme.of(context).textTheme.bodyMedium),
                          Text('${stats.inProgress}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.accentOrange)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('منتظرة:', style: Theme.of(context).textTheme.bodyMedium),
                          Text('${stats.pending}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.priorityHigh)),
                        ],
                      ),
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
}

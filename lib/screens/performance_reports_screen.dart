import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/stat_card.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';

class PerformanceReportsScreen extends StatelessWidget {
  const PerformanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return AppScaffold(
      title: 'تقارير الأداء',
      showNav: false,
      body: StreamBuilder<TaskStatistics>(
        stream: db.statisticsDao.watchTaskStatisticsForToday(),
        builder: (context, taskSnapshot) {
          return StreamBuilder<FocusStatistics>(
            stream: db.statisticsDao.watchFocusStatisticsForToday(),
            builder: (context, focusSnapshot) {
              final taskStats = taskSnapshot.data;
              final focusStats = focusSnapshot.data;

              if (taskStats == null || focusStats == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final completionRate = taskStats.completionPercentage;
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(child: Text('اليوم', style: Theme.of(context).textTheme.titleMedium)),
                      const Icon(Icons.calendar_today, size: 16),
                    ]),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                                  backgroundColor: Theme.of(context).dividerColor,
                                  color: AppColors.accentGreen,
                                ),
                                Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text('${completionRate.toInt()}%', style: Theme.of(context).textTheme.titleMedium),
                                  Text(performanceText, style: Theme.of(context).textTheme.bodySmall),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Wrap(
                              runSpacing: 10,
                              children: [
                                _metric(context, '${taskStats.completed}', 'المهام المكتملة'),
                                _metric(context, '${focusStats.totalMinutes}', 'دقائق التركيز'),
                                _metric(context, '${taskStats.total}', 'إجمالي المهام'),
                                _metric(context, '${taskStats.overdue}', 'المهام المتأخرة'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: StatCard(value: '${taskStats.completed}', label: 'منجز اليوم', color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: StatCard(value: '${taskStats.inProgress}', label: 'قيد التنفيذ', color: AppColors.accentOrange)),
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

  Widget _metric(BuildContext context, String value, String label) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

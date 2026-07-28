import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';

class FocusDashboardScreen extends StatelessWidget {
  const FocusDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return AppScaffold(
      title: 'لوحة التركيز',
      showNav: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<ProfileRow?>(
            stream: db.profileDao.watchProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final userName = profile?.name ?? 'المستخدم';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const Icon(Icons.wb_twilight, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    Text('مرحبًا $userName', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('التركيز هو جسر بين الهدف والإنجاز',
                        style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<FocusStatistics>(
            stream: db.statisticsDao.watchFocusStatisticsForDate(DateTime.now()),
            builder: (context, snapshot) {
              final stats = snapshot.data;

              if (stats == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final hours = stats.totalMinutes ~/ 60;
              final minutes = stats.totalMinutes % 60;
              final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

              return Row(
                children: [
                  Expanded(child: _stat(context, timeString, 'ساعات مكتملة')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat(context, '${stats.sessionsCount}', 'جلسات تركيز')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat(context, '${stats.averageMinutesPerSession}m', 'طول الجلسة')),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/focus-timer'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.play_arrow),
            label: const Text('ابدأ جلسة تركيز'),
          ),
          const SizedBox(height: 20),
          Text('آخر جلسات التركيز', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          StreamBuilder<FocusStatistics>(
            stream: db.statisticsDao.watchFocusStatisticsForDate(DateTime.now()),
            builder: (context, snapshot) {
              final stats = snapshot.data;

              if (stats == null || stats.sessions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('لا توجد جلسات تركيز بعد', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              }

              return Column(
                children: stats.sessions.take(5).map((session) {
                  final duration = session.durationSeconds ~/ 60;
                  final startTime = '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';
                  final status = session.isCompleted ? 'مكتملة' : 'جارية';
                  final statusColor = session.isCompleted ? AppColors.accentGreen : AppColors.accentOrange;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.timer, color: statusColor),
                      title: Text('جلسة تركيز - $startTime'),
                      subtitle: Text('$duration دقيقة - $status'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

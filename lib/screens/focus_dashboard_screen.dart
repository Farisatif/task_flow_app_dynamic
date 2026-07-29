import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class FocusDashboardScreen extends StatelessWidget {
  const FocusDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'لوحة التركيز',
      showNav: false,
      body: StreamBuilder<ProfileRow?>(
        stream: db.profileDao.watchProfile(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;
          final userName = profile?.name ?? 'المستخدم';

          return StreamBuilder<FocusStatistics>(
            stream: db.statisticsDao.watchFocusStatisticsForDate(DateTime.now()),
            builder: (context, statsSnapshot) {
              final stats = statsSnapshot.data;

              if (stats == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final sessions = stats.sessions;
              final totalMinutes = stats.totalMinutes;
              final completedSessions =
                  sessions.where((s) => s.isCompleted == true).length;
              final completionRate = sessions.isEmpty
                  ? 0.0
                  : completedSessions / sessions.length;

              final hours = totalMinutes ~/ 60;
              final minutes = totalMinutes % 60;
              final totalTimeText =
                  hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

              final longestSessionMinutes = sessions.isEmpty
                  ? 0
                  : sessions
                      .map((s) => (s.durationSeconds as int) ~/ 60)
                      .reduce(math.max);

              final avgSessionMinutes = stats.averageMinutesPerSession;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroCard(
                    userName: userName,
                    totalTimeText: totalTimeText,
                    completionRate: completionRate,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _MetricCard(
                        title: 'إجمالي التركيز',
                        value: totalTimeText,
                        icon: Icons.schedule_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      _MetricCard(
                        title: 'الجلسات',
                        value: '${stats.sessionsCount}',
                        icon: Icons.timer_rounded,
                        color: AppColors.accentGreen,
                      ),
                      _MetricCard(
                        title: 'متوسط الجلسة',
                        value: '${avgSessionMinutes}m',
                        icon: Icons.analytics_rounded,
                        color: AppColors.accentOrange,
                      ),
                      _MetricCard(
                        title: 'أطول جلسة',
                        value: '${longestSessionMinutes}m',
                        icon: Icons.rocket_launch_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'مؤشر الإنجاز اليومي',
                    subtitle: 'نظرة سريعة على تقدمك',
                  ),
                  const SizedBox(height: 10),
                  _ProgressCard(
                    completedSessions: completedSessions,
                    totalSessions: sessions.length,
                    completionRate: completionRate,
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'تحليل الجلسات',
                    subtitle: 'رسم بسيط يوضح مدة كل جلسة',
                  ),
                  const SizedBox(height: 10),
                  _SessionsChartCard(sessions: sessions),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'آخر الجلسات',
                    subtitle: 'آخر 5 جلسات تركيز',
                  ),
                  const SizedBox(height: 10),
                  if (sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'لا توجد جلسات تركيز بعد',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...sessions.take(5).map((session) {
                      final durationMinutes =
                          (session.durationSeconds as int) ~/ 60;
                      final startTime = _formatTime(session.startTime);
                      final status = session.isCompleted == true
                          ? 'مكتملة'
                          : 'جارية';
                      final statusColor = session.isCompleted == true
                          ? AppColors.accentGreen
                          : AppColors.accentOrange;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.14),
                            child: Icon(
                              Icons.timer_rounded,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            'جلسة تركيز - $startTime',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text('$durationMinutes دقيقة'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => context.push('/focus-timer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('ابدأ جلسة تركيز'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HeroCard extends StatelessWidget {
  final String userName;
  final String totalTimeText;
  final double completionRate;

  const _HeroCard({
    required this.userName,
    required this.totalTimeText,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (completionRate * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.wb_twilight_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبًا $userName',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'التركيز هو الجسر بين الفكرة والإنجاز',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'اليوم ركّزت لمدة $totalTimeText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 6),
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
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

class _ProgressCard extends StatelessWidget {
  final int completedSessions;
  final int totalSessions;
  final double completionRate;

  const _ProgressCard({
    required this.completedSessions,
    required this.totalSessions,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (completionRate * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completionRate,
                    strokeWidth: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    'إنجاز جلسات اليوم',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedSessions من $totalSessions جلسات مكتملة',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completionRate >= 0.75
                        ? 'أداء ممتاز، استمر بهذا النسق.'
                        : completionRate >= 0.4
                            ? 'أنت على الطريق الصحيح.'
                            : 'ابدأ أول جلسة لتحريك المؤشر.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsChartCard extends StatelessWidget {
  final List<dynamic> sessions;

  const _SessionsChartCard({
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final durations = sessions
        .take(7)
        .map<int>((s) => (s.durationSeconds as int) ~/ 60)
        .toList();

    final maxValue = durations.isEmpty ? 1 : math.max(1, durations.reduce(math.max));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: durations.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد بيانات كافية للرسم بعد',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: durations.map((value) {
                    final heightFactor = value / maxValue;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$value',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              height: 120 * heightFactor.clamp(0.08, 1.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.tertiary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 4,
                              width: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
}

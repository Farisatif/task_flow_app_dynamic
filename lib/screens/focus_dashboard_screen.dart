import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/dao/statistics_dao.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_state_view.dart';

class FocusDashboardScreen extends StatefulWidget {
  const FocusDashboardScreen({super.key});

  @override
  State<FocusDashboardScreen> createState() => _FocusDashboardScreenState();
}

class _FocusDashboardScreenState extends State<FocusDashboardScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  void _setToday() {
    setState(() {
      _selectedDate = DateUtils.dateOnly(DateTime.now());
    });
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

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
            stream: db.statisticsDao.watchFocusStatisticsForDate(_selectedDate),
            builder: (context, statsSnapshot) {
              if (statsSnapshot.hasError) {
                return const AppErrorState(
                  title: 'تعذر تحميل جلسات التركيز',
                  message: 'تحقق من بيانات التطبيق ثم أعد فتح هذه الصفحة.',
                );
              }

              if (!statsSnapshot.hasData) {
                return const AppLoadingState(label: 'جارٍ تحميل جلسات التركيز…');
              }

              final stats = statsSnapshot.data!;
              final sessions = stats.sessions;
              final completedSessions =
                  sessions.where((s) => _sessionIsCompleted(s)).length;

              final completionRate = sessions.isEmpty
                  ? 0.0
                  : (completedSessions / sessions.length).clamp(0.0, 1.0);

              final totalMinutes = stats.totalMinutes;
              final totalTimeText = _formatDurationArabic(totalMinutes);

              final longestSessionMinutes = sessions.isEmpty
                  ? 0
                  : sessions
                      .map<int>(_sessionMinutes)
                      .reduce(math.max);

              final avgSessionMinutes =
                  stats.averageMinutesPerSession.round();

              final selectedDateLabel =
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DateNavigatorCard(
                    selectedDateLabel: selectedDateLabel,
                    onPrevious: _previousDay,
                    onToday: _setToday,
                    onNext: _nextDay,
                  ),
                  const SizedBox(height: 14),
                  _HeroCard(
                    userName: userName,
                    selectedDateLabel: selectedDateLabel,
                    totalTimeText: totalTimeText,
                    completionRate: completionRate,
                    sessionsCount: stats.sessionsCount,
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
                        value: '$avgSessionMinutes دقيقة',
                        icon: Icons.analytics_rounded,
                        color: AppColors.accentOrange,
                      ),
                      _MetricCard(
                        title: 'أطول جلسة',
                        value: '$longestSessionMinutes دقيقة',
                        icon: Icons.rocket_launch_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'مؤشر الإنجاز اليومي',
                    subtitle: 'نظرة سريعة على تقدمك اليوم',
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
                    subtitle: 'رسم يوضح مدة الجلسات الأخيرة',
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
                    AppEmptyState(
                      icon: Icons.timer_outlined,
                      title: 'لا توجد جلسات تركيز بعد',
                      message:
                          'ابدأ جلسة قصيرة الآن لتظهر إحصاءات تركيزك هنا.',
                      actionLabel: 'ابدأ جلسة',
                      onAction: () => context.push('/focus-timer'),
                    )
                  else
                    ...sessions.take(5).map((session) {
                      final durationMinutes = _sessionMinutes(session);
                      final startTime = _formatTime(_sessionStartTime(session));
                      final isCompleted = _sessionIsCompleted(session);
                      final status = isCompleted ? 'مكتملة' : 'جارية';
                      final statusColor = isCompleted
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
                            backgroundColor: statusColor.withValues(alpha: 0.14),
                            child: Icon(
                              Icons.timer_rounded,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            'جلسة تركيز - $startTime',
                            style: GoogleFonts.tajawal(
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
                              color: statusColor.withValues(alpha: 0.12),
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

  static String _formatDurationArabic(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours ساعة $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }

  static int _sessionMinutes(dynamic session) {
    return (session.durationSeconds as int) ~/ 60;
  }

  static bool _sessionIsCompleted(dynamic session) {
    return session.isCompleted == true;
  }

  static DateTime _sessionStartTime(dynamic session) {
    return session.startTime as DateTime;
  }
}

class _DateNavigatorCard extends StatelessWidget {
  final String selectedDateLabel;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  const _DateNavigatorCard({
    required this.selectedDateLabel,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'عرض بيانات اليوم',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDateLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onToday,
              child: const Text('اليوم'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String userName;
  final String selectedDateLabel;
  final String totalTimeText;
  final double completionRate;
  final int sessionsCount;

  const _HeroCard({
    required this.userName,
    required this.selectedDateLabel,
    required this.totalTimeText,
    required this.completionRate,
    required this.sessionsCount,
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
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
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
          const SizedBox(height: 16),
          Text(
            selectedDateLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroChip(
                icon: Icons.auto_graph_rounded,
                label: 'الجلسات: $sessionsCount',
              ),
              const SizedBox(width: 10),
              _HeroChip(
                icon: Icons.bolt_rounded,
                label: 'الإنجاز: $percent%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
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
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
          style: GoogleFonts.tajawal(
            fontSize: 18,
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
            CircularPercentIndicator(
              radius: 46,
              lineWidth: 10,
              percent: completionRate.clamp(0.0, 1.0),
              animation: true,
              animationDuration: 500,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              progressColor: Theme.of(context).colorScheme.primary,
              center: Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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

    if (durations.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'لا توجد بيانات كافية للرسم بعد',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final maxValue = math.max(1, durations.reduce(math.max)).toDouble();
    final chartTheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue + 10,
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
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
                      if (index < 0 || index >= durations.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(durations.length, (index) {
                final value = durations[index].toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      width: 18,
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          chartTheme.primary,
                          chartTheme.tertiary,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

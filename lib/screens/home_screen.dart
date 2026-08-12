import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/sound_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_state_view.dart';
import '../widgets/quick_add_modal.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final today = DateUtils.dateOnly(DateTime.now());
    final dateStr = intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(today);

    return AppScaffold(
      title: '',
      navIndex: 0,
      showNav: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickAddModal.show(context),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchTasksForDate(today),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.connectionState == ConnectionState.waiting &&
              !taskSnapshot.hasData) {
            return const AppLoadingState(label: 'جارٍ تجهيز لوحة التحكم…');
          }
          if (taskSnapshot.hasError) {
            return const AppErrorState(
              title: 'تعذر تحميل لوحة التحكم',
              message:
                  'تعذر الوصول إلى مهام اليوم الآن. لن تُفقد بياناتك المحفوظة.',
            );
          }

          final tasks = taskSnapshot.data ?? [];
          final total = tasks.length;
          final completed =
              tasks.where((t) => t.status == TaskStatus.completed).length;
          final inProgress =
              tasks.where((t) => t.status == TaskStatus.inProgress).length;
          final pending =
              tasks.where((t) => t.status == TaskStatus.pending).length;
          final progress = total == 0 ? 0.0 : completed / total;

          final upcoming = _nextTask(tasks);
          final firstTask = tasks.isEmpty ? null : tasks.first;
          final lastTask = tasks.isEmpty ? null : tasks.last;

          return StreamBuilder<ProfileRow?>(
            stream: db.profileDao.watchProfile(),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              final userName = profile?.name ?? 'المستخدم';

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _TopBar(
                    userName: userName,
                    onSearch: () => context.push('/search'),
                    onNotifications: () => context.push('/reminders'),
                  ),
                  const SizedBox(height: 16),
                  _HeroCard(
                    dateStr: dateStr,
                    progress: progress,
                    total: total,
                    completed: completed,
                    inProgress: inProgress,
                    pending: pending,
                    upcoming: upcoming,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MiniStat(
                        value: '$total',
                        label: 'المهام',
                        color: AppColors.primary,
                      ),
                      _MiniStat(
                        value: '$completed',
                        label: 'منجزة',
                        color: AppColors.accentGreen,
                      ),
                      _MiniStat(
                        value: '$inProgress',
                        label: 'مستمرة',
                        color: AppColors.accentOrange,
                      ),
                      _MiniStat(
                        value: '$pending',
                        label: 'منتظرة',
                        color: AppColors.accentPink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InsightCard(
                    title: total == 0
                        ? 'ابدأ يومك بقوة'
                        : progress >= 0.75
                            ? 'أنت قريب من الإكمال'
                            : progress >= 0.4
                                ? 'تقدم ثابت'
                                : 'ابدأ بتحريك المؤشر',
                    body: total == 0
                        ? 'لا توجد مهام مسجلة لليوم. أضف أول مهمة أو استخدم الإضافة السريعة.'
                        : 'أنجزت $completed من أصل $total مهمة اليوم. ${
                            upcoming == null
                                ? 'لا توجد مهمة قادمة الآن.'
                                : 'المهمة القادمة: ${upcoming.title} عند ${HomeScreen._formatMinutes(upcoming.startMinutes)}.'
                          }',
                    icon: Icons.auto_graph_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'خطة اليوم',
                    actionLabel: 'عرض الكل',
                    onAction: () => context.push('/today'),
                  ),
                  const SizedBox(height: 10),
                  if (tasks.isEmpty)
                    _EmptyState(onAdd: () => QuickAddModal.show(context))
                  else
                    ...tasks.take(6).map(
                      (task) => TaskTile(
                        task: task,
                        onTap: () => context.push('/task-details/${task.id}'),
                        onCheck: (checked) {
                          final done = checked ?? false;
                          if (done) SoundService.playTaskComplete(context);
                          db.tasksDao.setStatus(
                            task.id,
                            done ? TaskStatus.completed : TaskStatus.pending,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'أدوات الإنتاجية',
                    actionLabel: '',
                    onAction: null,
                  ),
                  const SizedBox(height: 10),
                  _QuickAccessGrid(
                    onTapItem: (route) => context.push(route),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'ملاحظات اليوم',
                    actionLabel: '',
                    onAction: null,
                  ),
                  const SizedBox(height: 10),
                  _TodaySummaryCard(
                    total: total,
                    completed: completed,
                    inProgress: inProgress,
                    pending: pending,
                    firstTask: firstTask,
                    lastTask: lastTask,
                  ),
                  const SizedBox(height: 18),
                  StreamBuilder<int>(
                    stream: db.statisticsDao.watchOverdueTasksCount(),
                    builder: (context, overdueSnapshot) {
                      final overdueCount = overdueSnapshot.data ?? 0;
                      if (overdueCount == 0) return const SizedBox.shrink();

                      return _OverdueBanner(
                        overdueCount: overdueCount,
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static Task? _nextTask(List<Task> tasks) {
    if (tasks.isEmpty) return null;
    final nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;

    final sorted = [...tasks]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    for (final task in sorted) {
      if (task.startMinutes >= nowMinutes) return task;
    }

    return sorted.first;
  }

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _TopBar extends StatelessWidget {
  final String userName;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;

  const _TopBar({
    required this.userName,
    required this.onSearch,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.14),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحبًا $userName 👋',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'جاهز ليوم منتج؟',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
          tooltip: 'بحث',
        ),
        IconButton(
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'التنبيهات',
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String dateStr;
  final double progress;
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final Task? upcoming;

  const _HeroCard({
    required this.dateStr,
    required this.progress,
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircularPercentIndicator(
                radius: 42,
                lineWidth: 8,
                percent: progress.clamp(0.0, 1.0),
                animation: true,
                animationDuration: 500,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.white.withOpacity(0.22),
                progressColor: Colors.white,
                center: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنجاز اليوم',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      total == 0
                          ? 'لا توجد مهام اليوم، أضف أول مهمة الآن'
                          : 'أكملت $completed من $total مهام حتى الآن',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      upcoming == null
                          ? 'لا توجد مهمة قادمة الآن'
                          : 'المهمة القادمة: ${upcoming!.title} • ${HomeScreen._formatMinutes(upcoming!.startMinutes)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(label: 'مكتملة', value: '$completed'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroPill(label: 'مستمرة', value: '$inProgress'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroPill(label: 'منتظرة', value: '$pending'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'يومك هادئ.. لا توجد مهام حالياً',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط + لإضافة أول مهمة وابدأ اليوم بقوة',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مهمة'),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final void Function(String route) onTapItem;

  const _QuickAccessGrid({
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({String title, IconData icon, Color color, String route})>[
      (
        title: 'الأهداف',
        icon: Icons.flag_outlined,
        color: AppColors.primary,
        route: '/goals',
      ),
      (
        title: 'العادات',
        icon: Icons.repeat_rounded,
        color: AppColors.accentGreen,
        route: '/habits',
      ),
      (
        title: 'المشاريع',
        icon: Icons.folder_outlined,
        color: AppColors.accentBlue,
        route: '/projects',
      ),
      (
        title: 'مؤقت التركيز',
        icon: Icons.timer_outlined,
        color: AppColors.accentOrange,
        route: '/focus-timer',
      ),
      (
        title: 'الملاحظات',
        icon: Icons.sticky_note_2_outlined,
        color: AppColors.accentPink,
        route: '/notes',
      ),
      (
        title: 'الإحصائيات',
        icon: Icons.insights_outlined,
        color: AppColors.secondary,
        route: '/statistics',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, i) {
        final item = items[i];

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTapItem(item.route),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final int overdueCount;

  const _OverdueBanner({
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentOrange.withOpacity(0.24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accentOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مهام متأخرة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'لديك $overdueCount مهام متأخرة تحتاج مراجعة',
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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

class _TodaySummaryCard extends StatelessWidget {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final Task? firstTask;
  final Task? lastTask;

  const _TodaySummaryCard({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.firstTask,
    required this.lastTask,
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0 ? 'لا توجد بيانات اليوم' : 'ملخص اليوم',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'ابدأ بإضافة مهامك لترى الملخص هنا.'
                : 'منجزة: $completed • جارية: $inProgress • منتظرة: $pending',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          if (firstTask != null) ...[
            Text(
              'أول مهمة: ${firstTask!.title} • ${_formatMinutes(firstTask!.startMinutes)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (lastTask != null) ...[
            const SizedBox(height: 4),
            Text(
              'آخر مهمة: ${lastTask!.title} • ${_formatMinutes(lastTask!.endMinutes)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

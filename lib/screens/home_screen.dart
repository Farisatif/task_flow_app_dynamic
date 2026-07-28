import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart' as intl;
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/task_tile.dart';
import '../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final dateStr = intl.DateFormat('d MMMM yyyy', 'ar').format(DateTime.now());

    return AppScaffold(
      title: '',
      navIndex: 0,
      showNav: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/quick-add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchTasksForDate(DateTime.now()),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final total = tasks.length;
          final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
          final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
          final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
          final progress = total == 0 ? 0.0 : completed / total;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Dynamic greeting with profile name
              StreamBuilder<ProfileRow?>(
                stream: db.profileDao.watchProfile(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final userName = profile?.name ?? 'المستخدم';

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحبًا $userName 👋', style: Theme.of(context).textTheme.titleLarge),
                            Text('جاهز ليوم منتج؟', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
                      IconButton(onPressed: () => context.push('/reminders'), icon: const Icon(Icons.notifications_outlined)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 40,
                      lineWidth: 8,
                      percent: progress.clamp(0, 1),
                      animation: true,
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      progressColor: Colors.white,
                      center: Text('${(progress * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إنجاز اليوم', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _miniStat(context, '$total', 'المهام', AppColors.primary),
                  _miniStat(context, '$completed', 'منجزة', AppColors.accentGreen),
                  _miniStat(context, '$inProgress', 'مستمرة', AppColors.accentOrange),
                  _miniStat(context, '$pending', 'منتظرة', AppColors.accentPink),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مهام اليوم', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(onPressed: () => context.push('/today'), child: const Text('عرض الكل')),
                ],
              ),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('لا توجد مهام اليوم بعد', style: Theme.of(context).textTheme.bodyMedium)),
                )
              else
                ...tasks.take(4).map((t) => TaskTile(
                      task: t,
                      onTap: () => context.push('/task-details/${t.id}'),
                      onCheck: (v) => db.tasksDao.setStatus(t.id, v == true ? TaskStatus.completed : TaskStatus.pending),
                    )),
              const SizedBox(height: 8),
              _quickAccessGrid(context),
              const SizedBox(height: 20),
              // Overdue tasks warning
              StreamBuilder<int>(
                stream: db.statisticsDao.watchOverdueTasksCount(),
                builder: (context, snapshot) {
                  final overdueCount = snapshot.data ?? 0;
                  if (overdueCount == 0) return const SizedBox();

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppColors.accentOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مهام متأخرة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accentOrange)),
                              Text('لديك $overdueCount مهام متأخرة', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessGrid(BuildContext context) {
    final items = [
      ('الأهداف', Icons.flag_outlined, AppColors.primary, '/goals'),
      ('العادات', Icons.repeat, AppColors.accentGreen, '/habits'),
      ('المشاريع', Icons.folder_outlined, AppColors.accentBlue, '/projects'),
      ('مؤقت التركيز', Icons.timer_outlined, AppColors.accentOrange, '/focus-timer'),
      ('الملاحظات', Icons.sticky_note_2_outlined, AppColors.accentPink, '/notes'),
      ('الإحصائيات', Icons.insights_outlined, AppColors.secondary, '/statistics'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(it.$4),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: it.$3.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(it.$2, color: it.$3),
                ),
                const SizedBox(height: 8),
                Text(it.$1, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

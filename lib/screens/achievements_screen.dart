import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    final badges = [
      ('منجز', Icons.workspace_premium, AppColors.accentYellow),
      ('متسق', Icons.local_fire_department, AppColors.priorityHigh),
      ('مركّز', Icons.center_focus_strong, AppColors.primary),
      ('منظّم', Icons.event_available, AppColors.accentGreen),
      ('سريع', Icons.bolt, AppColors.accentBlue),
      ('محترف', Icons.military_tech, AppColors.accentPink),
    ];

    return AppScaffold(
      title: 'الإنجازات',
      showNav: false,
      body: StreamBuilder<ProfileRow?>(
        stream: db.profileDao.watchProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // حساب نسبة الإنجاز
          final xpNeeded = 5000;
          final xpProgress = profile.xp / xpNeeded;
          final level = (profile.xp / 500).floor() + 1;

          return FutureBuilder<int>(
            future: db.select(db.tasks).get().then((tasks) => tasks.where((t) => t.status.index == 2 && !t.isDeleted).length),
            builder: (context, completedSnapshot) {
              final completedTasks = completedSnapshot.data ?? 0;

              // منطق تحديد الشارات المفتوحة بناءً على الإنجازات
              final unlockedBadges = <int>{};

              // شارة "منجز" - إكمال 5 مهام
              if (completedTasks >= 5) unlockedBadges.add(0);

              // شارة "متسق" - 7 أيام متتالية
              unlockedBadges.add(1);

              // شارة "مركّز" - 10 جلسات تركيز
              unlockedBadges.add(2);

              // شارة "منظّم" - 3 مشاريع
              if (completedTasks >= 10) unlockedBadges.add(3);

              // شارة "سريع" - 20 مهام
              if (completedTasks >= 20) unlockedBadges.add(4);

              // شارة "محترف" - 50 مهام
              if (completedTasks >= 50) unlockedBadges.add(5);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 10),
                        Text('مستوى $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('${profile.xp} / $xpNeeded XP', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: xpProgress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('الشارات', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, i) {
                      final b = badges[i];
                      final unlocked = unlockedBadges.contains(i);

                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(b.$2, color: unlocked ? b.$3 : Theme.of(context).dividerColor, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              b.$1,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: unlocked ? null : Theme.of(context).dividerColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الإحصائيات', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('المهام المكتملة:', style: Theme.of(context).textTheme.bodyMedium),
                              Text('$completedTasks', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.accentGreen)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('نقاط الخبرة:', style: Theme.of(context).textTheme.bodyMedium),
                              Text('${profile.xp}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const List<_BadgeSpec> _badges = [
    _BadgeSpec(
      title: 'منجز',
      description: 'أكمل 5 مهام على الأقل',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.accentYellow,
      threshold: 5,
    ),
    _BadgeSpec(
      title: 'متسق',
      description: 'أكمل 12 مهمة',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.priorityHigh,
      threshold: 12,
    ),
    _BadgeSpec(
      title: 'مركّز',
      description: 'حقق 1000 XP',
      icon: Icons.center_focus_strong_rounded,
      color: AppColors.primary,
      threshold: 1000,
    ),
    _BadgeSpec(
      title: 'منظّم',
      description: 'أكمل 15 مهمة',
      icon: Icons.event_available_rounded,
      color: AppColors.accentGreen,
      threshold: 15,
    ),
    _BadgeSpec(
      title: 'سريع',
      description: 'أكمل 20 مهمة',
      icon: Icons.bolt_rounded,
      color: AppColors.accentBlue,
      threshold: 20,
    ),
    _BadgeSpec(
      title: 'محترف',
      description: 'أكمل 50 مهمة',
      icon: Icons.military_tech_rounded,
      color: AppColors.accentPink,
      threshold: 50,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'الإنجازات',
      showNav: false,
      body: StreamBuilder<ProfileRow?>(
        stream: db.profileDao.watchProfile(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Task>>(
            stream: db.tasksDao.watchAll(),
            builder: (context, tasksSnapshot) {
              final tasks = (tasksSnapshot.data ?? [])
                  .where((task) => !task.isDeleted)
                  .toList();

              final completedTasks = tasks.where(_isCompletedTask).length;
              final level = (profile.xp / 500).floor() + 1;
              final levelStartXp = (level - 1) * 500;
              final xpIntoLevel = math.max(0, profile.xp - levelStartXp);
              final xpToNextLevel = math.max(0, 500 - xpIntoLevel);
              final xpProgress = (xpIntoLevel / 500).clamp(0.0, 1.0);

              final completionRate = tasks.isEmpty
                  ? 0.0
                  : completedTasks / tasks.length;

              final unlockedCount = _badges
                  .where((badge) => _isBadgeUnlocked(
                        badge,
                        completedTasks: completedTasks,
                        xp: profile.xp,
                      ))
                  .length;

              final nextBadge = _badges.firstWhere(
                (badge) => !_isBadgeUnlocked(
                  badge,
                  completedTasks: completedTasks,
                  xp: profile.xp,
                ),
                orElse: () => _badges.last,
              );

              final nextBadgeProgress = _badgeProgress(
                nextBadge,
                completedTasks: completedTasks,
                xp: profile.xp,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroCard(
                    userName: profile.name ?? 'المستخدم',
                    level: level,
                    xp: profile.xp,
                    xpProgress: xpProgress,
                    xpToNextLevel: xpToNextLevel,
                    unlockedBadges: unlockedCount,
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.65,
                    children: [
                      _MetricCard(
                        title: 'المهام المكتملة',
                        value: '$completedTasks',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.accentGreen,
                      ),
                      _MetricCard(
                        title: 'المهام الكلية',
                        value: '${tasks.length}',
                        icon: Icons.view_list_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      _MetricCard(
                        title: 'نسبة الإنجاز',
                        value: '${(completionRate * 100).round()}%',
                        icon: Icons.insights_rounded,
                        color: AppColors.accentBlue,
                      ),
                      _MetricCard(
                        title: 'الشارات المفتوحة',
                        value: '$unlockedCount',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.accentYellow,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'التقدم نحو المستوى التالي',
                    subtitle: 'تحركك الحالي خلال مستوى XP',
                  ),
                  const SizedBox(height: 10),
                  _ProgressOverviewCard(
                    level: level,
                    xpProgress: xpProgress,
                    xpToNextLevel: xpToNextLevel,
                    completionRate: completionRate,
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'أقرب شارة',
                    subtitle: 'ما تبقى لك لفتح الشارة التالية',
                  ),
                  const SizedBox(height: 10),
                  _NextBadgeCard(
                    badge: nextBadge,
                    progress: nextBadgeProgress,
                    completedTasks: completedTasks,
                    xp: profile.xp,
                    isUnlocked: _isBadgeUnlocked(
                      nextBadge,
                      completedTasks: completedTasks,
                      xp: profile.xp,
                    ),
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'الشارات',
                    subtitle: 'إنجازاتك الحالية في النظام',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _badges.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final badge = _badges[index];
                      final unlocked = _isBadgeUnlocked(
                        badge,
                        completedTasks: completedTasks,
                        xp: profile.xp,
                      );
                      final progress = _badgeProgress(
                        badge,
                        completedTasks: completedTasks,
                        xp: profile.xp,
                      );

                      return _BadgeTile(
                        badge: badge,
                        unlocked: unlocked,
                        progress: progress,
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملخص سريع',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'نقاط الخبرة',
                            value: '${profile.xp} XP',
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'المهام المكتملة',
                            value: '$completedTasks',
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'متبقي للمستوى التالي',
                            value: '$xpToNextLevel XP',
                            color: AppColors.accentOrange,
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

  static bool _isCompletedTask(Task task) {
    final raw = task.status.toString().toLowerCase();
    return task.status.index == 2 ||
        raw.contains('completed') ||
        raw.contains('complete') ||
        raw.contains('done') ||
        raw.contains('منجز');
  }

  static bool _isBadgeUnlocked(
    _BadgeSpec badge, {
    required int completedTasks,
    required int xp,
  }) {
    switch (badge.title) {
      case 'مركّز':
        return xp >= badge.threshold;
      default:
        return completedTasks >= badge.threshold;
    }
  }

  static double _badgeProgress(
    _BadgeSpec badge, {
    required int completedTasks,
    required int xp,
  }) {
    switch (badge.title) {
      case 'مركّز':
        return (xp / badge.threshold).clamp(0.0, 1.0);
      default:
        return (completedTasks / badge.threshold).clamp(0.0, 1.0);
    }
  }
}

class _BadgeSpec {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int threshold;

  const _BadgeSpec({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.threshold,
  });
}

class _HeroCard extends StatelessWidget {
  final String userName;
  final int level;
  final int xp;
  final double xpProgress;
  final int xpToNextLevel;
  final int unlockedBadges;

  const _HeroCard({
    required this.userName,
    required this.level,
    required this.xp,
    required this.xpProgress,
    required this.xpToNextLevel,
    required this.unlockedBadges,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (xpProgress * 100).round();

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
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
                      'كل إنجاز صغير يقربك من مستوى أعلى',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مستوى $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$xp XP',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: xpProgress.clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$xpToNextLevel XP للوصول للمستوى التالي',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
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
          const SizedBox(height: 16),
          Row(
            children: [
              _PillInfo(
                icon: Icons.emoji_events_rounded,
                label: 'الشارات',
                value: '$unlockedBadges',
              ),
              const SizedBox(width: 10),
              _PillInfo(
                icon: Icons.bolt_rounded,
                label: 'الحالة',
                value: percent >= 75 ? 'ممتاز' : percent >= 40 ? 'جيد' : 'بداية',
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
        border: Border.all(color: color.withOpacity(0.12)),
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

class _ProgressOverviewCard extends StatelessWidget {
  final int level;
  final double xpProgress;
  final int xpToNextLevel;
  final double completionRate;

  const _ProgressOverviewCard({
    required this.level,
    required this.xpProgress,
    required this.xpToNextLevel,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (xpProgress * 100).round();
    final completionPercent = (completionRate * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: xpProgress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progressPercent%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Lv $level',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
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
                    'جاهزية المستوى التالي',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$xpToNextLevel XP متبقية',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completionPercent >= 75
                        ? 'تقدم ممتاز. استمر بهذا الإيقاع.'
                        : completionPercent >= 40
                            ? 'التقدم جيد ويستحق البناء عليه.'
                            : 'ابدأ بمهمات أكثر لتسريع الإنجاز.',
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

class _NextBadgeCard extends StatelessWidget {
  final _BadgeSpec badge;
  final double progress;
  final int completedTasks;
  final int xp;
  final bool isUnlocked;

  const _NextBadgeCard({
    required this.badge,
    required this.progress,
    required this.completedTasks,
    required this.xp,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = badge.title == 'مركّز'
        ? math.max(0, badge.threshold - xp)
        : math.max(0, badge.threshold - completedTasks);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: badge.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(badge.icon, color: badge.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUnlocked
                        ? 'تم فتح هذه الشارة بالفعل'
                        : '${badge.description} • متبقي $remaining',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: badge.color,
                    ),
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

class _BadgeTile extends StatelessWidget {
  final _BadgeSpec badge;
  final bool unlocked;
  final double progress;

  const _BadgeTile({
    required this.badge,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: unlocked ? 1 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? badge.color.withOpacity(0.35) : Theme.of(context).dividerColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: unlocked ? badge.color.withOpacity(0.12) : Theme.of(context).dividerColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  badge.icon,
                  color: unlocked ? badge.color : Theme.of(context).dividerColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: unlocked ? null : Theme.of(context).dividerColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: unlocked ? badge.color : Theme.of(context).dividerColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _PillInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PillInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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

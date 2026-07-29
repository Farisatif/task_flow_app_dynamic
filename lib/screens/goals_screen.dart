import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

enum _GoalFilter { all, active, completed }

extension on _GoalFilter {
  String get label {
    switch (this) {
      case _GoalFilter.all:
        return 'الكل';
      case _GoalFilter.active:
        return 'قيد التنفيذ';
      case _GoalFilter.completed:
        return 'مكتملة';
    }
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _GoalFilter _selectedFilter = _GoalFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Goal goal) {
    switch (_selectedFilter) {
      case _GoalFilter.all:
        return true;
      case _GoalFilter.active:
        return goal.progress < 1;
      case _GoalFilter.completed:
        return goal.progress >= 1;
    }
  }

  List<Goal> _applyFilters(List<Goal> goals) {
    final query = _searchController.text.trim().toLowerCase();

    return goals.where((goal) {
      final matchesSearch = query.isEmpty ||
          goal.title.toLowerCase().contains(query);
      return matchesSearch && _matchesFilter(goal);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'الأهداف',
      showNav: false,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddGoalSheet(context, db),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'هدف جديد',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Goal>>(
        stream: db.goalsDao.watchAll(),
        builder: (context, snapshot) {
          final goals = snapshot.data ?? [];
          final filteredGoals = _applyFilters(goals);

          final totalGoals = goals.length;
          final completedGoals = goals.where((g) => g.progress >= 1).length;
          final activeGoals = totalGoals - completedGoals;
          final overallProgress = totalGoals == 0
              ? 0.0
              : goals.map((g) => g.progress).fold<double>(0, (a, b) => a + b) /
                  totalGoals;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  totalGoals: totalGoals,
                  activeGoals: activeGoals,
                  completedGoals: completedGoals,
                  overallProgress: overallProgress,
                ),
                const SizedBox(height: 14),
                _SearchBar(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  _EmptyState(
                    onAdd: () => _showAddGoalSheet(context, db),
                  )
                else if (filteredGoals.isEmpty)
                  _EmptyState(
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب تعديل البحث أو الفلتر',
                    icon: Icons.search_off_rounded,
                    onAdd: () => _showAddGoalSheet(context, db),
                  )
                else
                  ...filteredGoals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _GoalCard(
                        goal: goal,
                        db: db,
                        onAddSubGoal: () => _showAddSubGoalSheet(
                          context,
                          db,
                          goal.id,
                        ),
                      ),
                    ),
                  ),
                if (filteredGoals.isEmpty && goals.isNotEmpty) const SizedBox(),
                if (theme.platform == TargetPlatform.iOS) const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddGoalSheet(BuildContext context, AppDatabase db) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).dividerColor.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'هدف جديد',
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أضف هدفًا واضحًا وابدأ تقسيمه إلى خطوات أصغر.',
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'عنوان الهدف',
                        hintText: 'مثال: حفظ 30 صفحة يوميًا',
                        filled: true,
                        fillColor: Theme.of(sheetContext)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final title = controller.text.trim();
                              if (title.isEmpty) return;

                              await db.goalsDao.insertGoal(
                                GoalsCompanion.insert(title: title),
                              );

                              if (!mounted) return;
                              Navigator.of(sheetContext).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('إضافة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _showAddSubGoalSheet(
    BuildContext context,
    AppDatabase db,
    int goalId,
  ) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).dividerColor.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'هدف فرعي جديد',
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'قسّم الهدف إلى خطوات صغيرة وأسهل في الإنجاز.',
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'عنوان الهدف الفرعي',
                        hintText: 'مثال: قراءة 10 صفحات',
                        filled: true,
                        fillColor: Theme.of(sheetContext)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final title = controller.text.trim();
                              if (title.isEmpty) return;

                              await db.goalsDao.insertSubGoal(
                                SubGoalsCompanion.insert(
                                  goalId: goalId,
                                  title: title,
                                ),
                              );

                              if (!mounted) return;
                              Navigator.of(sheetContext).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('إضافة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final double overallProgress;

  const _HeaderCard({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.overallProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (overallProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.flag_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'الأهداف',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'تابع أهدافك الكبيرة وحولها إلى خطوات صغيرة مثل TickTick',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'إجمالي',
                  value: '$totalGoals',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'قيد التنفيذ',
                  value: '$activeGoals',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'مكتملة',
                  value: '$completedGoals',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'ابحث عن هدف...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.08),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final _GoalFilter selectedFilter;
  final ValueChanged<_GoalFilter> onSelected;

  const _FilterChips({
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = _GoalFilter.values[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            onSelected: (_) => onSelected(filter),
            selectedColor: AppColors.primary.withOpacity(0.16),
            labelStyle: TextStyle(
              color: selected ? AppColors.primary : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: selected
                    ? AppColors.primary
                    : theme.dividerColor.withOpacity(0.10),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _GoalFilter.values.length,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onAdd;

  const _EmptyState({
    this.title,
    this.subtitle,
    this.icon = Icons.flag_outlined,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final mainTitle = title ?? 'لا توجد أهداف بعد';
    final mainSubtitle = subtitle ?? 'أضف هدفك الأول وابدأ بتقسيمه إلى خطوات أصغر';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            mainTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            mainSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
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
            label: const Text('إضافة هدف'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final AppDatabase db;
  final VoidCallback onAddSubGoal;

  const _GoalCard({
    required this.goal,
    required this.db,
    required this.onAddSubGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progress.clamp(0.0, 1.0);
    final isCompleted = progress >= 1;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted
              ? AppColors.accentGreen.withOpacity(0.18)
              : theme.dividerColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [
                              AppColors.accentGreen.withOpacity(0.20),
                              AppColors.accentGreen.withOpacity(0.08),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.18),
                              AppColors.primary.withOpacity(0.08),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
                    color: isCompleted ? AppColors.accentGreen : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted ? 'مكتمل' : 'قيد التنفيذ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCompleted ? AppColors.accentGreen : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'حذف الهدف',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.priorityHigh,
                  onPressed: () => db.goalsDao.softDelete(goal.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: theme.dividerColor.withOpacity(0.12),
                color: isCompleted ? AppColors.accentGreen : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isCompleted ? AppColors.accentGreen : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  isCompleted ? 'اكتمل الهدف' : 'تابع التقدم',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'الأهداف الفرعية',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<SubGoal>>(
              stream: db.goalsDao.watchSubGoals(goal.id),
              builder: (context, snapshot) {
                final subGoals = snapshot.data ?? [];

                if (subGoals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'لا توجد أهداف فرعية بعد',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }

                return Column(
                  children: [
                    ...subGoals.map(
                      (subGoal) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                value: subGoal.progress.clamp(0.0, 1.0),
                                strokeWidth: 3,
                                backgroundColor:
                                    theme.dividerColor.withOpacity(0.14),
                                color: subGoal.progress >= 1
                                    ? AppColors.accentGreen
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subGoal.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(subGoal.progress * 100).round()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAddSubGoal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة هدف فرعي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

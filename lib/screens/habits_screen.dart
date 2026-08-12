import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/dao/habits_dao.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/icon_map.dart';
import '../widgets/app_scaffold.dart';

enum _HabitFilter { all, active, completed }

extension on _HabitFilter {
  String get label {
    switch (this) {
      case _HabitFilter.all:
        return 'الكل';
      case _HabitFilter.active:
        return 'نشطة';
      case _HabitFilter.completed:
        return 'مكتملة';
    }
  }
}

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

  final TextEditingController _searchController = TextEditingController();
  _HabitFilter _selectedFilter = _HabitFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HabitWithWeek> _applyFilters(List<HabitWithWeek> habits) {
    final query = _searchController.text.trim().toLowerCase();

    return habits.where((hw) {
      final title = hw.habit.title.toLowerCase();
      final matchesSearch = query.isEmpty || title.contains(query);

      final doneCount = hw.doneCount;
      final target = hw.habit.targetDaysPerWeek.clamp(1, 7).toInt();
      final matchesFilter = switch (_selectedFilter) {
        _HabitFilter.all => true,
        _HabitFilter.active => doneCount < target,
        _HabitFilter.completed => doneCount >= target,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'العادات',
      showNav: false,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddHabitSheet(context, db),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'عادة جديدة',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<HabitWithWeek>>(
        stream: db.habitsDao.watchAllWithWeek(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تعذر تحميل العادات الآن',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'حاول العودة للشاشة لاحقًا، وستبقى بياناتك المحلية كما هي.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          final habits = snapshot.data ?? [];
          final filteredHabits = _applyFilters(habits);

          final total = habits.length;
          final completed = habits
              .where(
                (h) =>
                    h.doneCount >= h.habit.targetDaysPerWeek.clamp(1, 7).toInt(),
              )
              .length;
          final active = total - completed;
          final overallProgress = total == 0
              ? 0.0
              : habits
                      .map(
                        (h) {
                          final target =
                              h.habit.targetDaysPerWeek.clamp(1, 7).toInt();
                          return (h.doneCount / target).clamp(0.0, 1.0).toDouble();
                        },
                      )
                      .fold<double>(0.0, (a, b) => a + b) /
                  total;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  totalHabits: total,
                  activeHabits: active,
                  completedHabits: completed,
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
                if (habits.isEmpty)
                  _EmptyState(
                    onAdd: () => _showAddHabitSheet(context, db),
                  )
                else if (filteredHabits.isEmpty)
                  _EmptyState(
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب البحث باسم عادة مختلف أو غيّر الفلتر',
                    icon: Icons.search_off_rounded,
                    onAdd: () => _showAddHabitSheet(context, db),
                  )
                else
                  ...filteredHabits.map(
                    (hw) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HabitCard(
                        habitWithWeek: hw,
                        db: db,
                        days: days,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'حذف',
              style: TextStyle(color: AppColors.priorityHigh),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddHabitSheet(BuildContext context, AppDatabase db) async {
    final controller = TextEditingController();
    String iconName = availableIconChoices.first.$1;
    int color = availableColorChoices.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
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
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'عادة جديدة',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اختر اسمًا واضحًا، ثم حدّد الأيقونة واللون المناسبين.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'اسم العادة',
                            hintText: 'مثال: قراءة 20 دقيقة',
                            filled: true,
                            fillColor: Theme.of(context)
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
                        Text(
                          'الأيقونة',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableIconChoices.map((opt) {
                            final selected = opt.$1 == iconName;
                            return InkWell(
                              onTap: () =>
                                  setSheetState(() => iconName = opt.$1),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Theme.of(context).dividerColor
                                          .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.08),
                                  ),
                                ),
                                child: Icon(
                                  opt.$2,
                                  color:
                                      selected ? Colors.white : themeColor(context),
                                  size: 19,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'اللون',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableColorChoices.map((c) {
                            final selected = c == color;
                            return InkWell(
                              onTap: () => setSheetState(() => color = c),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Color(c),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color:
                                                Color(c).withOpacity(0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  final title = controller.text.trim();
                                  if (title.isEmpty) return;

                                  await db.habitsDao.insertHabit(
                                    HabitsCompanion.insert(
                                      title: title,
                                      color: color,
                                      iconName: iconName,
                                    ),
                                  );

                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop();
                                },
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
      },
    );

    controller.dispose();
  }

  Color themeColor(BuildContext context) {
    return Theme.of(context).iconTheme.color ??
        Theme.of(context).colorScheme.onSurface;
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalHabits;
  final int activeHabits;
  final int completedHabits;
  final double overallProgress;

  const _HeaderCard({
    required this.totalHabits,
    required this.activeHabits,
    required this.completedHabits,
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
                child: Icon(Icons.local_fire_department_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'العادات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            'ابنِ روتينك اليومي وراقب الاستمرارية بطريقة بسيطة وواضحة.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(label: 'إجمالي', value: '$totalHabits'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(label: 'نشطة', value: '$activeHabits'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(label: 'مكتملة', value: '$completedHabits'),
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
        hintText: 'ابحث عن عادة...',
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
  final _HabitFilter selectedFilter;
  final ValueChanged<_HabitFilter> onSelected;

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
          final filter = _HabitFilter.values[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            onSelected: (_) => onSelected(filter),
            selectedColor: AppColors.primary.withOpacity(0.16),
            labelStyle: TextStyle(
              color: selected
                  ? AppColors.primary
                  : theme.textTheme.bodyMedium?.color,
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
        itemCount: _HabitFilter.values.length,
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
    this.icon = Icons.inbox_outlined,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final mainTitle = title ?? 'لا توجد عادات بعد';
    final mainSubtitle =
        subtitle ?? 'أضف أول عادة وابدأ في بناء سلسلة يومية ثابتة';

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة عادة'),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitWithWeek habitWithWeek;
  final AppDatabase db;
  final List<String> days;

  const _HabitCard({
    required this.habitWithWeek,
    required this.db,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = habitWithWeek.habit;
    final color = Color(habit.color);
    final icon = iconFromName(habit.iconName);
    final today = DateTime.now();
    final doneCount = habitWithWeek.doneCount;
    final targetDays = habit.targetDaysPerWeek.clamp(1, 7).toInt();
    final progress = (doneCount / targetDays).clamp(0.0, 1.0).toDouble();
    final isCompleted = doneCount >= targetDays;

    return Dismissible(
      key: ValueKey('habit-${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.priorityHigh,
        ),
      ),
      confirmDismiss: (_) =>
          context.findAncestorStateOfType<_HabitsScreenState>()!
              ._confirmDelete(context, 'حذف العادة "${habit.title}"؟'),
      onDismissed: (_) async {
        try {
          await db.habitsDao.softDelete(habit.id);
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر حذف العادة، حاول مرة أخرى.'),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? AppColors.accentGreen.withOpacity(0.16)
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted ? 'سلسلة مكتملة' : 'تابع الاستمرارية',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCompleted
                                ? AppColors.accentGreen
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$doneCount/$targetDays',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 11,
                  backgroundColor: theme.dividerColor.withOpacity(0.12),
                  color: isCompleted ? AppColors.accentGreen : color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.accentGreen : color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isCompleted ? 'ممتاز' : 'استمر يومًا بيوم',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayDate = DateTime(today.year, today.month, today.day)
                      .subtract(Duration(days: 6 - i));
                  final done = i < habitWithWeek.last7Days.length &&
                      habitWithWeek.last7Days[i];

                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () async {
                      try {
                        await db.habitsDao.toggleDay(habit.id, dayDate, !done);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر تحديث العادة، حاول مرة أخرى.'),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: done ? color : theme.dividerColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          days[i],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

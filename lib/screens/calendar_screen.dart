import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/task_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'التقويم',
      navIndex: -1,
      showNav: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/task-form'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'مهمة جديدة',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل التقويم',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final allTasks = (snapshot.data ?? [])
              .where((t) => !t.isDeleted)
              .toList(growable: false);

          final tasksByDay = _groupTasksByDay(allTasks);
          final selectedKey = _dateOnly(_selectedDay ?? _focusedDay);
          final selectedTasks = tasksByDay[selectedKey] ?? const [];

          final selectedCompleted =
              selectedTasks.where((t) => _isCompleted(t)).length;
          final selectedPending = selectedTasks.length - selectedCompleted;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              final calendar = _CalendarCard(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                tasksByDay: tasksByDay,
                allTasks: allTasks,
              );

              final agenda = _AgendaCard(
                selectedDay: _selectedDay ?? _focusedDay,
                selectedTasks: selectedTasks,
                completedCount: selectedCompleted,
                pendingCount: selectedPending,
                onToggleStatus: (task, checked) async {
                  await db.tasksDao.setStatus(
                    task.id,
                    checked == true
                        ? TaskStatus.completed
                        : TaskStatus.pending,
                  );
                },
                onOpenDetails: (task) {
                  context.push('/task-details/${task.id}');
                },
              );

              if (isWide) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: calendar),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: agenda),
                      ],
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  calendar,
                  const SizedBox(height: 16),
                  agenda,
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _isCompleted(Task task) {
    final raw = task.status.toString().toLowerCase();
    return task.status.index == 2 ||
        raw.contains('completed') ||
        raw.contains('done') ||
        raw.contains('complete') ||
        raw.contains('منجز');
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  LinkedHashMap<DateTime, List<Task>> _groupTasksByDay(List<Task> tasks) {
    final map = LinkedHashMap<DateTime, List<Task>>(
      equals: isSameDay,
      hashCode: _getHashCode,
    );

    for (final task in tasks) {
      final key = _dateOnly(task.date);
      map.putIfAbsent(key, () => <Task>[]).add(task);
    }

    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.date.compareTo(b.date));
    }

    return map;
  }

  int _getHashCode(DateTime key) => key.day * 1000000 + key.month * 10000 + key.year;
}

class _CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final LinkedHashMap<DateTime, List<Task>> tasksByDay;
  final List<Task> allTasks;

  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.tasksByDay,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalCount = allTasks.length;
    final completedCount = allTasks.where(_isCompleted).length;
    final selectedKey = DateTime(
      selectedDay?.year ?? focusedDay.year,
      selectedDay?.month ?? focusedDay.month,
      selectedDay?.day ?? focusedDay.day,
    );
    final selectedCount = tasksByDay[selectedKey]?.length ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSummary(
              totalCount: totalCount,
              completedCount: completedCount,
              selectedCount: selectedCount,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TableCalendar<Task>(
                key: const PageStorageKey('task-calendar'),
                locale: 'ar',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: onDaySelected,
                eventLoader: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  return tasksByDay[key] ?? const [];
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  markersMaxCount: 1,
                  cellMargin: const EdgeInsets.all(4),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_right_rounded),
                  rightChevronIcon: Icon(Icons.chevron_left_rounded),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.w700),
                  weekendStyle: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCompleted(Task task) {
    final raw = task.status.toString().toLowerCase();
    return task.status.index == 2 ||
        raw.contains('completed') ||
        raw.contains('done') ||
        raw.contains('complete') ||
        raw.contains('منجز');
  }
}

class _AgendaCard extends StatelessWidget {
  final DateTime selectedDay;
  final List<Task> selectedTasks;
  final int completedCount;
  final int pendingCount;
  final Future<void> Function(Task task, bool? checked) onToggleStatus;
  final void Function(Task task) onOpenDetails;

  const _AgendaCard({
    required this.selectedDay,
    required this.selectedTasks,
    required this.completedCount,
    required this.pendingCount,
    required this.onToggleStatus,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayTitle = _formatDay(selectedDay);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مهام $dayTitle',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedTasks.isEmpty
                  ? 'لا توجد مهام في هذا اليوم'
                  : 'المهام المجدولة لهذا اليوم',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'إجمالي',
                    value: '${selectedTasks.length}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'مكتملة',
                    value: '$completedCount',
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'معلقة',
                    value: '$pendingCount',
                    color: AppColors.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (selectedTasks.isEmpty)
              _EmptyAgenda(onAdd: () {})
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = selectedTasks[index];
                  final completed = _isCompleted(task);

                  return Material(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onOpenDetails(task),
                      child: TaskTile(
                        task: task,
                        onTap: () => onOpenDetails(task),
                        onCheck: (v) => onToggleStatus(task, v),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isCompleted(Task task) {
    final raw = task.status.toString().toLowerCase();
    return task.status.index == 2 ||
        raw.contains('completed') ||
        raw.contains('done') ||
        raw.contains('complete') ||
        raw.contains('منجز');
  }

  String _formatDay(DateTime date) {
    const weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    final weekday = weekdays[(date.weekday - 1).clamp(0, 6)];
    return '$weekday، ${date.day}/${date.month}/${date.year}';
  }
}

class _HeaderSummary extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final int selectedCount;

  const _HeaderSummary({
    required this.totalCount,
    required this.completedCount,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التقويم الذكي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إجمالي المهام: $totalCount · المكتملة: $completedCount · في اليوم المحدد: $selectedCount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAgenda({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد مهام لهذا اليوم',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'أضف مهمة جديدة حتى تظهر مباشرة في التقويم.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مهمة'),
          ),
        ],
      ),
    );
  }
}

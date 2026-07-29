import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/task_tile.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'الكل';
  String _query = '';

  static const List<String> _filters = ['الكل', 'اليوم', 'الأسبوع'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() => _query = _searchController.text);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _applyFilters(List<Task> source) {
    final now = DateTime.now();
    final query = _query.trim().toLowerCase();

    final filtered = source.where((task) {
      final matchSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query);

      final matchFilter = switch (_filter) {
        'الكل' => true,
        'اليوم' => _isSameDay(task.date, now),
        'الأسبوع' =>
          task.date.isAfter(now.subtract(const Duration(days: 1))) &&
          task.date.isBefore(now.add(const Duration(days: 7))),
        _ => true,
      };

      return matchSearch && matchFilter;
    }).toList();

    filtered.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return a.startMinutes.compareTo(b.startMinutes);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'قائمة المهام',
      navIndex: 2,
      showNav: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task-form'),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.tasksDao.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل المهام',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final allTasks = snapshot.data ?? [];
          final tasks = _applyFilters(allTasks);

          final total = tasks.length;
          final completed =
              tasks.where((t) => t.status == TaskStatus.completed).length;
          final inProgress =
              tasks.where((t) => t.status == TaskStatus.inProgress).length;
          final pending =
              tasks.where((t) => t.status == TaskStatus.pending).length;

          final high = tasks
              .where((t) => t.priority == TaskPriority.high)
              .toList();
          final medium = tasks
              .where((t) => t.priority == TaskPriority.medium)
              .toList();
          final low = tasks
              .where((t) => t.priority == TaskPriority.low)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _HeaderCard(
                  total: total,
                  completed: completed,
                  inProgress: inProgress,
                  pending: pending,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث في المهام...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
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
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    final selected = _filter == f;

                    return ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primary.withOpacity(0.16),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : null,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
                ),
              ),
              const SizedBox(height: 12),
              _FilterSummaryBar(
                total: total,
                completed: completed,
                inProgress: inProgress,
                pending: pending,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: tasks.isEmpty
                    ? _buildEmptyState(context)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        children: [
                          if (high.isNotEmpty) ...[
                            _priorityHeader(
                              context,
                              'الأولوية العالية',
                              AppColors.priorityHigh,
                              high.length,
                            ),
                            const SizedBox(height: 8),
                            ...high.map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskTile(
                                  task: t,
                                  onTap: () =>
                                      context.push('/task-details/${t.id}'),
                                  onCheck: (v) => db.tasksDao.setStatus(
                                    t.id,
                                    v == true
                                        ? TaskStatus.completed
                                        : TaskStatus.pending,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (medium.isNotEmpty) ...[
                            _priorityHeader(
                              context,
                              'الأولوية المتوسطة',
                              AppColors.priorityMedium,
                              medium.length,
                            ),
                            const SizedBox(height: 8),
                            ...medium.map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskTile(
                                  task: t,
                                  onTap: () =>
                                      context.push('/task-details/${t.id}'),
                                  onCheck: (v) => db.tasksDao.setStatus(
                                    t.id,
                                    v == true
                                        ? TaskStatus.completed
                                        : TaskStatus.pending,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (low.isNotEmpty) ...[
                            _priorityHeader(
                              context,
                              'الأولوية المنخفضة',
                              AppColors.priorityLow,
                              low.length,
                            ),
                            const SizedBox(height: 8),
                            ...low.map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskTile(
                                  task: t,
                                  onTap: () =>
                                      context.push('/task-details/${t.id}'),
                                  onCheck: (v) => db.tasksDao.setStatus(
                                    t.id,
                                    v == true
                                        ? TaskStatus.completed
                                        : TaskStatus.pending,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilters =
        _filter != 'الكل' || _query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters ? 'لا توجد مهام مطابقة' : 'لا توجد مهام هنا',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'جرّب تغيير الفلتر أو البحث بكلمة أخرى.'
                  : 'ابدأ بإضافة أول مهمة لتنظيم يومك.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.push('/task-form'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مهمة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityHeader(
    BuildContext context,
    String label,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;

  const _HeaderCard({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                child: Icon(Icons.checklist_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'قائمة المهام',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'كل ما تحتاجه لإنجاز يومك في مكان واحد، مع ترتيب واضح حسب الأولوية.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.22),
                      color: Colors.white,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: 'الإجمالي', value: '$total'),
                    _Pill(label: 'منجزة', value: '$completed'),
                    _Pill(label: 'مستمرة', value: '$inProgress'),
                    _Pill(label: 'منتظرة', value: '$pending'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({
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
          const SizedBox(height: 3),
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

class _FilterSummaryBar extends StatelessWidget {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;

  const _FilterSummaryBar({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الإجمالي: $total',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              'منجزة: $completed',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              'جارية: $inProgress',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              'منتظرة: $pending',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

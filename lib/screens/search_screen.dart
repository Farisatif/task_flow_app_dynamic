import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/task_tile.dart';

enum _SearchFilterType { priority, status, category }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  TaskPriority? _priorityFilter;
  TaskStatus? _statusFilter;
  int? _categoryFilter;

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

  void _clearFilter(_SearchFilterType type) {
    setState(() {
      switch (type) {
        case _SearchFilterType.priority:
          _priorityFilter = null;
          break;
        case _SearchFilterType.status:
          _statusFilter = null;
          break;
        case _SearchFilterType.category:
          _categoryFilter = null;
          break;
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _priorityFilter = null;
      _statusFilter = null;
      _categoryFilter = null;
    });
  }

  List<Task> _applyFilters(List<Task> tasks) {
    final q = _query.trim().toLowerCase();

    return tasks.where((task) {
      final matchQuery = q.isEmpty ||
          task.title.toLowerCase().contains(q);

      final matchPriority =
          _priorityFilter == null || task.priority == _priorityFilter;

      final matchStatus =
          _statusFilter == null || task.status == _statusFilter;

      final matchCategory =
          _categoryFilter == null || task.categoryId == _categoryFilter;

      return matchQuery && matchPriority && matchStatus && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'البحث والفلترة',
      showNav: false,
      body: SafeArea(
        child: StreamBuilder<List<Task>>(
          stream: db.tasksDao.watchAll(),
          builder: (context, tasksSnapshot) {
            if (tasksSnapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء تحميل المهام',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            final allTasks = tasksSnapshot.data ?? [];
            final results = _applyFilters(allTasks);

            final activeFiltersCount = [
              if (_priorityFilter != null) 1,
              if (_statusFilter != null) 1,
              if (_categoryFilter != null) 1,
            ].length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _HeaderCard(
                    resultsCount: results.length,
                    totalCount: allTasks.length,
                    activeFiltersCount: activeFiltersCount,
                    onClearAll: _clearAllFilters,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: _priorityFilter == null
                            ? 'الأولوية'
                            : 'الأولوية: ${_priorityLabel(_priorityFilter!)}',
                        isSelected: _priorityFilter != null,
                        onTap: _showPriorityPicker,
                        onClear: () => _clearFilter(_SearchFilterType.priority),
                      ),
                      _FilterChip(
                        label: _statusFilter == null
                            ? 'الحالة'
                            : 'الحالة: ${_statusLabel(_statusFilter!)}',
                        isSelected: _statusFilter != null,
                        onTap: _showStatusPicker,
                        onClear: () => _clearFilter(_SearchFilterType.status),
                      ),
                      _FilterChip(
                        label: _categoryFilter == null
                            ? 'التصنيف'
                            : 'التصنيف: محدد',
                        isSelected: _categoryFilter != null,
                        onTap: () => _showCategoryPicker(db),
                        onClear: () => _clearFilter(_SearchFilterType.category),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _FilterSummaryBar(
                  priorityLabel: _priorityFilter == null
                      ? 'كل الأولويات'
                      : _priorityLabel(_priorityFilter!),
                  statusLabel: _statusFilter == null
                      ? 'كل الحالات'
                      : _statusLabel(_statusFilter!),
                  categoryActive: _categoryFilter != null,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: results.isEmpty
                      ? _EmptyState(
                          onClear: _clearAllFilters,
                          hasFilters: activeFiltersCount > 0 ||
                              _query.trim().isNotEmpty,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final task = results[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TaskTile(
                                task: task,
                                onTap: () => context.push(
                                  '/task-details/${task.id}',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showPriorityPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('كل الأولويات'),
                onTap: () {
                  setState(() => _priorityFilter = null);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(height: 1),
              ...TaskPriority.values.map((priority) {
                return ListTile(
                  leading: Icon(
                    _priorityIcon(priority),
                    color: _priorityColor(priority),
                  ),
                  title: Text(_priorityLabel(priority)),
                  onTap: () {
                    setState(() => _priorityFilter = priority);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatusPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('كل الحالات'),
                onTap: () {
                  setState(() => _statusFilter = null);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(height: 1),
              ...TaskStatus.values.map((status) {
                return ListTile(
                  leading: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                  ),
                  title: Text(_statusLabel(status)),
                  onTap: () {
                    setState(() => _statusFilter = status);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategoryPicker(AppDatabase db) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StreamBuilder<List<Category>>(
          stream: db.categoriesDao.watchAll(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];

            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.all_inclusive_rounded),
                    title: const Text('كل التصنيفات'),
                    onTap: () {
                      setState(() => _categoryFilter = null);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  const Divider(height: 1),
                  ...categories.map(
                    (category) => ListTile(
                      leading: Icon(
                        Icons.circle_rounded,
                        color: Color(category.color),
                        size: 16,
                      ),
                      title: Text(category.name),
                      onTap: () {
                        setState(() => _categoryFilter = category.id);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.low:
        return 'منخفضة';
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.completed:
        return 'مكتملة';
      case TaskStatus.inProgress:
        return 'قيد التنفيذ';
      case TaskStatus.pending:
        return 'قيد الانتظار';
    }
  }

  IconData _priorityIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Icons.priority_high_rounded;
      case TaskPriority.medium:
        return Icons.drag_handle_rounded;
      case TaskPriority.low:
        return Icons.keyboard_arrow_down_rounded;
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
      case TaskStatus.inProgress:
        return Icons.timelapse_rounded;
      case TaskStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.completed:
        return AppColors.accentGreen;
      case TaskStatus.inProgress:
        return AppColors.accentOrange;
      case TaskStatus.pending:
        return AppColors.priorityHigh;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final int resultsCount;
  final int totalCount;
  final int activeFiltersCount;
  final VoidCallback onClearAll;

  const _HeaderCard({
    required this.resultsCount,
    required this.totalCount,
    required this.activeFiltersCount,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.manage_search_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البحث والفلترة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اعثر على المهام بسرعة عبر البحث والفلاتر',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$resultsCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'نتيجة',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _FilterSummaryBar extends StatelessWidget {
  final String priorityLabel;
  final String statusLabel;
  final bool categoryActive;

  const _FilterSummaryBar({
    required this.priorityLabel,
    required this.statusLabel,
    required this.categoryActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الأولوية: $priorityLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الحالة: $statusLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            categoryActive ? 'تصنيف محدد' : 'كل التصنيفات',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (isSelected) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 14),
              ),
            ],
          ],
        ),
        onPressed: onTap,
        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.10) : null,
        side: isSelected
            ? const BorderSide(color: AppColors.primary)
            : BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters ? 'لا توجد نتائج مطابقة' : 'ابحث عن مهمة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'جرّب تعديل الكلمات أو الفلاتر الحالية.'
                  : 'اكتب كلمة للبحث أو استخدم الفلاتر للعثور بسرعة على المهمة المطلوبة.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('مسح الفلاتر'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

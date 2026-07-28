import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/database/database.dart';
import '../core/database/tables.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/task_tile.dart';
import '../core/theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  TaskPriority? _priorityFilter;
  TaskStatus? _statusFilter;
  int? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return AppScaffold(
      title: 'البحث والفلترة',
      showNav: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث في المهام...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'الأولوية',
                        isSelected: _priorityFilter != null,
                        onTap: () => _showPriorityPicker(),
                        onClear: () => setState(() => _priorityFilter = null),
                      ),
                      _FilterChip(
                        label: 'الحالة',
                        isSelected: _statusFilter != null,
                        onTap: () => _showStatusPicker(),
                        onClear: () => setState(() => _statusFilter = null),
                      ),
                      _FilterChip(
                        label: 'التصنيف',
                        isSelected: _categoryFilter != null,
                        onTap: () => _showCategoryPicker(db),
                        onClear: () => setState(() => _categoryFilter = null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: db.tasksDao.watchAll(),
              builder: (context, snapshot) {
                final all = snapshot.data ?? [];
                final results = all.where((t) {
                  final matchQuery = t.title.toLowerCase().contains(_query.toLowerCase());
                  final matchPriority = _priorityFilter == null || t.priority == _priorityFilter;
                  final matchStatus = _statusFilter == null || t.status == _statusFilter;
                  final matchCategory = _categoryFilter == null || t.categoryId == _categoryFilter;
                  return matchQuery && matchPriority && matchStatus && matchCategory;
                }).toList();

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('لا توجد نتائج مطابقة', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) => TaskTile(
                    task: results[index],
                    onTap: () => context.push('/task-details/${results[index].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: TaskPriority.values
            .map((p) => ListTile(
                  title: Text(_priorityLabel(p)),
                  onTap: () {
                    setState(() => _priorityFilter = p);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: TaskStatus.values
            .map((s) => ListTile(
                  title: Text(_statusLabel(s)),
                  onTap: () {
                    setState(() => _statusFilter = s);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showCategoryPicker(AppDatabase db) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StreamBuilder<List<Category>>(
        stream: db.categoriesDao.watchAll(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          return ListView(
            shrinkWrap: true,
            children: categories
                .map((c) => ListTile(
                      leading: Icon(Icons.circle, color: Color(c.color), size: 16),
                      title: Text(c.name),
                      onTap: () {
                        setState(() => _categoryFilter = c.id);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return 'عالية';
      case TaskPriority.medium: return 'متوسطة';
      case TaskPriority.low: return 'منخفضة';
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.completed: return 'مكتملة';
      case TaskStatus.inProgress: return 'قيد التنفيذ';
      case TaskStatus.pending: return 'قيد الانتظار';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, required this.onClear});

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
                child: const Icon(Icons.close, size: 14),
              ),
            ],
          ],
        ),
        onPressed: onTap,
        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        side: isSelected ? const BorderSide(color: AppColors.primary) : null,
        labelStyle: TextStyle(color: isSelected ? AppColors.primary : null, fontWeight: isSelected ? FontWeight.bold : null),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'التصنيفات',
      showNav: false,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddCategoryDialog(context, db),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'تصنيف جديد',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Category>>(
        stream: db.categoriesDao.watchAll(),
        builder: (context, categoriesSnapshot) {
          if (categoriesSnapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل التصنيفات',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final categories = (categoriesSnapshot.data ?? [])
              .toList(growable: false);

          return StreamBuilder<List<Task>>(
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

              final tasks = (tasksSnapshot.data ?? [])
                  .where((t) => !t.isDeleted)
                  .toList(growable: false);

              final countsByCategory = <int, int>{};
              for (final task in tasks) {
                final id = task.categoryId;
                if (id == null) continue;
                countsByCategory[id] = (countsByCategory[id] ?? 0) + 1;
              }

              final filteredCategories = categories
                  .where((category) {
                    final name = category.name.toLowerCase();
                    return _searchQuery.trim().isEmpty ||
                        name.contains(_searchQuery.trim().toLowerCase());
                  })
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              final totalCategories = categories.length;
              final categoriesWithTasks = categories
                  .where((c) => (countsByCategory[c.id] ?? 0) > 0)
                  .length;
              final emptyCategories = totalCategories - categoriesWithTasks;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroCard(
                    totalCategories: totalCategories,
                    tasksCount: tasks.length,
                    categoriesWithTasks: categoriesWithTasks,
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _MetricCard(
                        title: 'إجمالي التصنيفات',
                        value: '$totalCategories',
                        icon: Icons.category_rounded,
                        color: AppColors.primary,
                      ),
                      _MetricCard(
                        title: 'التصنيفات النشطة',
                        value: '$categoriesWithTasks',
                        icon: Icons.layers_rounded,
                        color: AppColors.accentGreen,
                      ),
                      _MetricCard(
                        title: 'تصنيفات فارغة',
                        value: '$emptyCategories',
                        icon: Icons.folder_open_rounded,
                        color: AppColors.accentOrange,
                      ),
                      _MetricCard(
                        title: 'المهام المصنّفة',
                        value: '${tasks.length}',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'البحث السريع',
                    subtitle: 'ابحث داخل أسماء التصنيفات',
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن تصنيف...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'قائمة التصنيفات',
                    subtitle: 'اضغط على أي تصنيف لعرض التفاصيل',
                  ),
                  const SizedBox(height: 10),

                  if (filteredCategories.isEmpty)
                    _EmptyState(
                      hasSearch: _searchQuery.trim().isNotEmpty,
                      onCreate: () => _showAddCategoryDialog(context, db),
                    )
                  else
                    ...filteredCategories.map((category) {
                      final categoryColor = Color(category.color);
                      final taskCount = countsByCategory[category.id] ?? 0;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _showCategoryDetailsDialog(
                            context,
                            db,
                            category,
                            taskCount,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category.iconName),
                                    color: categoryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        taskCount == 0
                                            ? 'لا توجد مهام مرتبطة'
                                            : '$taskCount مهمة مرتبطة',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$taskCount',
                                    style: TextStyle(
                                      color: categoryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'school':
        return Icons.school_outlined;
      case 'health':
        return Icons.favorite_border;
      case 'book':
        return Icons.menu_book_outlined;
      case 'home':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _showAddCategoryDialog(BuildContext context, AppDatabase db) async {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.primary;

    final colors = <Color>[
      AppColors.primary,
      AppColors.accentBlue,
      AppColors.accentGreen,
      AppColors.accentOrange,
      AppColors.accentPink,
      AppColors.accentYellow,
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('إضافة تصنيف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'اسم التصنيف',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر اللون',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                await db.categoriesDao.insertCategory(
                  CategoriesCompanion.insert(
                    name: name,
                    color: selectedColor.value,
                  ),
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryDetailsDialog(
    BuildContext context,
    AppDatabase db,
    Category category,
    int taskCount,
  ) async {
    final color = Color(category.color);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(category.iconName),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          taskCount == 0
                              ? 'تصنيف فارغ'
                              : '$taskCount مهمة مرتبطة',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _detailRow(context, 'اللون', color),
              const SizedBox(height: 10),
              _detailRow(
                context,
                'المهام',
                Text(
                  '$taskCount',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _detailRow(
                context,
                'الأيقونة',
                Text(
                  category.iconName ?? 'افتراضية',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('إغلاق'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.priorityHigh,
                      ),
                      onPressed: () async {
                        final confirm = await _confirmDeleteCategory(context);
                        if (confirm != true) return;

                        await db.categoriesDao.softDelete(category.id);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, Widget value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        value,
      ],
    );
  }

  Future<bool?> _confirmDeleteCategory(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف التصنيف'),
        content: const Text('هل تريد حذف هذا التصنيف؟ سيتم إخفاؤه من القائمة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.priorityHigh,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int totalCategories;
  final int tasksCount;
  final int categoriesWithTasks;

  const _HeroCard({
    required this.totalCategories,
    required this.tasksCount,
    required this.categoriesWithTasks,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalCategories == 0 ? 0 : ((categoriesWithTasks / totalCategories) * 100).round();

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
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.category_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة التصنيفات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'رتّب مهامك بذكاء، وراقب كيف تتوزع على التصنيفات المختلفة.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: 'التصنيفات',
                  value: '$totalCategories',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'المهام',
                  value: '$tasksCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'النشطة',
                  value: '$percentage%',
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
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

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreate;

  const _EmptyState({
    required this.hasSearch,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد تصنيفات بعد',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'جرّب تعديل كلمة البحث أو أضف تصنيفًا جديدًا.'
                : 'ابدأ بإنشاء أول تصنيف لتنظيم المهام.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة تصنيف'),
          ),
        ],
      ),
    );
  }
}

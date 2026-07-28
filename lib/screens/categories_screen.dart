import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return AppScaffold(
      title: 'التصنيفات',
      showNav: false,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddCategoryDialog(context, db),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Category>>(
        stream: db.categoriesDao.watchAll(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),
                    Text('لا توجد تصنيفات بعد', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text('اضغط + لإضافة تصنيف جديد', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: categories
                .map((category) {
                  return FutureBuilder<int>(
                    future: db.select(db.tasks).get().then(
                        (tasks) => tasks.where((t) => t.categoryId == category.id && !t.isDeleted).length),
                    builder: (context, snapshot) {
                      final taskCount = snapshot.data ?? 0;
                      final categoryColor = Color(category.color);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.iconName),
                              color: categoryColor,
                            ),
                          ),
                          title: Text(category.name, style: Theme.of(context).textTheme.titleSmall),
                          trailing: Text('$taskCount مهام', style: Theme.of(context).textTheme.bodySmall),
                          onTap: () => _showCategoryDetailsDialog(context, db, category),
                        ),
                      );
                    },
                  );
                })
                .toList(),
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

  void _showAddCategoryDialog(BuildContext context, AppDatabase db) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.primary;

    final colors = [
      AppColors.primary,
      AppColors.accentBlue,
      AppColors.accentGreen,
      AppColors.accentOrange,
      AppColors.accentPink,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة تصنيف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم التصنيف'),
                ),
                const SizedBox(height: 16),
                Text('اختر لون', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors
                      .map((color) => GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  db.categoriesDao.insertCategory(
                    CategoriesCompanion.insert(
                      name: nameController.text,
                      color: selectedColor.value,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetailsDialog(BuildContext context, AppDatabase db, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اللون: ', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(category.color),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              db.categoriesDao.softDelete(category.id);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

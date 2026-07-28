import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return AppScaffold(
      title: 'ملفي الشخصي',
      showNav: false,
      body: StreamBuilder<ProfileRow?>(
        stream: db.profileDao.watchProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // حساب عدد المشاريع والإنجازات من قاعدة البيانات
          return FutureBuilder<int>(
            future: db.select(db.projects).get().then((p) => p.where((pr) => !pr.isArchived && !pr.isDeleted).length),
            builder: (context, projectsSnapshot) {
              final projectsCount = projectsSnapshot.data ?? 0;

              return FutureBuilder<int>(
                future: db.select(db.goals).get().then((g) => g.where((go) => go.isCompleted && !go.isDeleted).length),
                builder: (context, goalsSnapshot) {
                  final completedGoals = goalsSnapshot.data ?? 0;

                  return FutureBuilder<int>(
                    future: db.select(db.tasks).get().then((t) => t.where((ta) => !ta.isDeleted).length),
                    builder: (context, tasksSnapshot) {
                      final totalTasks = tasksSnapshot.data ?? 0;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: const Icon(Icons.person, size: 44, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                                Text(profile.email ?? 'لا يوجد بريد إلكتروني', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    profile.levelLabel,
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _stat(context, '${profile.xp}', 'نقاط الخبرة')),
                              Expanded(child: _stat(context, '$totalTasks', 'إجمالي المهام')),
                              Expanded(child: _stat(context, '$projectsCount', 'مشاريع')),
                              Expanded(child: _stat(context, '$completedGoals', 'أهداف مكتملة')),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: const Text('تعديل الملف الشخصي'),
                                  trailing: const Icon(Icons.chevron_left),
                                  onTap: () => _showEditProfileDialog(context, db, profile),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.lock_outline),
                                  title: const Text('تغيير كلمة المرور'),
                                  trailing: const Icon(Icons.chevron_left),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.tune_outlined),
                                  title: const Text('تفضيلات الشخصية'),
                                  trailing: const Icon(Icons.chevron_left),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, AppDatabase db, ProfileRow profile) {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email ?? '');
    final levelController = TextEditingController(text: profile.levelLabel);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملف الشخصي'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(labelText: 'المستوى'),
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
              final updated = profile.copyWith(
                name: nameController.text,
                email: emailController.text,
                levelLabel: levelController.text,
              );
              db.profileDao.upsertProfile(updated.toCompanion(false));
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

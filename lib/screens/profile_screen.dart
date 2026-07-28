import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/database/database.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return AppScaffold(
      title: 'الملف الشخصي',
      showNav: false,
      body: StreamBuilder<ProfileRow?>(
        stream: db.profileDao.watchProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text(profile.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(profile.email ?? 'لا يوجد بريد إلكتروني', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            profile.levelLabel,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(context, '${profile.xp}', 'XP'),
                  _statItem(context, '12', 'أوسمة'),
                  _statItem(context, '85%', 'دقة'),
                ],
              ),
              const SizedBox(height: 32),
              Text('الحساب', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _menuItem(context, Icons.person_outline, 'تعديل الملف الشخصي', () => _showEditProfileDialog(context, db, profile)),
                _menuItem(context, Icons.security_outlined, 'الأمان والخصوصية', () {}),
                _menuItem(context, Icons.language_outlined, 'اللغة', () {}),
              ]),
              const SizedBox(height: 24),
              Text('الإحصائيات', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _menuItem(context, Icons.bar_chart_outlined, 'تقارير الإنتاجية', () => context.push('/statistics')),
                _menuItem(context, Icons.emoji_events_outlined, 'الإنجازات', () => context.push('/achievements')),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label),
      trailing: const Icon(Icons.chevron_left, size: 20),
      onTap: onTap,
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
                email: Value(emailController.text),
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

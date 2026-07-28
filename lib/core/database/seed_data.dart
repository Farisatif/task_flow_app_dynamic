import 'package:drift/drift.dart';
import 'database.dart';

/// يملأ قاعدة البيانات ببيانات تجريبية أول مرة فقط (عند عدم وجود أي مهام).
/// بهذا يفتح التطبيق ولديه محتوى فعلي بدل شاشات فارغة، وكل البيانات
/// المعروضة بعدها حقيقية ومخزّنة في SQLite ويمكن حذفها/تعديلها بشكل طبيعي.
/// 
/// ملاحظة: هذه الدالة اختيارية الآن ويمكن تعطيلها في database_provider.dart
Future<void> seedDatabaseIfEmpty(AppDatabase db) async {
  final existingTasks = await db.select(db.tasks).get();
  if (existingTasks.isNotEmpty) return; // البيانات موجودة بالفعل، لا تكرر البذر

  // --- الملف الشخصي (بيانات افتراضية) ---
  await db.into(db.profile).insertOnConflictUpdate(
        ProfileCompanion.insert(
          id: const Value(1),
          name: 'المستخدم',
          email: const Value('user@example.com'),
          levelLabel: const Value('مستوى 1'),
          xp: const Value(0),
        ),
      );

  // --- التصنيفات (اختيارية) ---
  final categoryIds = <String, int>{};
  final categorySeed = [
    ('العمل', 0xFF7B6FF0),
    ('الدراسة', 0xFF5B9DF9),
    ('الصحة', 0xFF4CD787),
    ('القراءة', 0xFFFFB258),
    ('المنزل', 0xFFFF7EB3),
  ];
  for (final c in categorySeed) {
    final id = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: c.$1, color: c.$2),
        );
    categoryIds[c.$1] = id;
  }

  // --- الأهداف (اختيارية) ---
  final goalId = await db.into(db.goals).insert(
        GoalsCompanion.insert(title: 'هدفي الأول', progress: const Value(0.0)),
      );
  await db.into(db.subGoals).insert(SubGoalsCompanion.insert(goalId: goalId, title: 'الخطوة الأولى', progress: const Value(0.0)));

  // --- المشاريع (اختيارية) ---
  final projectSeed = [
    ('مشروعي الأول', 0xFF7B6FF0),
  ];
  final projectIds = <String, int>{};
  for (final p in projectSeed) {
    final id = await db.into(db.projects).insert(
          ProjectsCompanion.insert(name: p.$1, color: p.$2, goalId: p.$1 == 'مشروعي الأول' ? Value(goalId) : const Value.absent()),
        );
    projectIds[p.$1] = id;
  }

  // --- العادات (اختيارية) ---
  final habitSeed = [
    ('شرب الماء', 0xFF5B9DF9, 'water_drop'),
    ('قراءة 30 دقيقة', 0xFFFFB258, 'menu_book'),
    ('تمرين رياضي', 0xFF4CD787, 'fitness_center'),
  ];
  for (final h in habitSeed) {
    final habitId = await db.into(db.habits).insert(HabitsCompanion.insert(title: h.$1, color: h.$2, iconName: h.$3));
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    for (int i = 0; i < 7; i++) {
      final d = day.subtract(Duration(days: 6 - i));
      final done = (i + h.$1.length) % 3 != 0;
      await db.into(db.habitLogs).insert(HabitLogsCompanion.insert(habitId: habitId, logDate: d, isCompleted: Value(done)));
    }
  }

  // --- الملاحظات (اختيارية) ---
  final noteSeed = [
    ('ملاحظتي الأولى', 'ابدأ بإضافة ملاحظاتك هنا', 0xFFFFF3D9),
  ];
  for (final n in noteSeed) {
    await db.into(db.notes).insert(NotesCompanion.insert(title: n.$1, content: n.$2, color: n.$3));
  }
}

/// دالة بديلة: تهيئة قاعدة بيانات نظيفة بدون بيانات تجريبية
Future<void> initializeEmptyDatabase(AppDatabase db) async {
  final existingProfile = await db.select(db.profile).get();
  if (existingProfile.isEmpty) {
    await db.into(db.profile).insertOnConflictUpdate(
          ProfileCompanion.insert(
            id: const Value(1),
            name: 'المستخدم',
            email: const Value('user@example.com'),
            levelLabel: const Value('مستوى 1'),
            xp: const Value(0),
          ),
        );
  }
}

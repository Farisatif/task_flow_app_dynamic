import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

/// نسخة SQLite محلية قابلة للاستعادة من داخل التطبيق.
class BackupSnapshot {
  final String path;
  final DateTime createdAt;
  final int sizeBytes;

  const BackupSnapshot({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get fileName => p.basename(path);
}

/// يدير نسخ قاعدة Task Flow داخل مساحة التطبيق فقط.
///
/// يستخدم `VACUUM INTO` لإنشاء لقطة SQLite متسقة حتى عندما تعمل القاعدة بوضع
/// WAL؛ لذلك لا يعتمد على نسخ الملف الخام أو ملفات journal المرافقة.
class LocalBackupService {
  final AppDatabase _database;

  LocalBackupService(this._database);

  Future<List<BackupSnapshot>> listBackups() async {
    final directory = await _backupDirectory();
    final snapshots = <BackupSnapshot>[];

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.sqlite')) continue;

      final stat = await entity.stat();
      snapshots.add(
        BackupSnapshot(
          path: entity.path,
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }

    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshots;
  }

  Future<BackupSnapshot> createBackup() async {
    final directory = await _backupDirectory();
    final now = DateTime.now();
    final stamp = [
      now.year.toString().padLeft(4, '0'),
      now.month.toString().padLeft(2, '0'),
      now.day.toString().padLeft(2, '0'),
      now.hour.toString().padLeft(2, '0'),
      now.minute.toString().padLeft(2, '0'),
      now.second.toString().padLeft(2, '0'),
    ].join();
    final target = File(p.join(directory.path, 'task_flow_$stamp.sqlite'));

    // VACUUM INTO ينشئ ملفًا جديدًا؛ لذلك لا نعطيه اسم ملف موجود.
    await _database.customStatement('VACUUM INTO ${_sqlString(target.path)}');
    final stat = await target.stat();

    return BackupSnapshot(
      path: target.path,
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<void> restoreBackup(BackupSnapshot snapshot) async {
    final source = File(snapshot.path);
    if (!await source.exists()) {
      throw StateError('لم تعد النسخة الاحتياطية متاحة على هذا الجهاز.');
    }

    await _database.customStatement(
      'ATTACH DATABASE ${_sqlString(source.path)} AS backup_source',
    );
    try {
      await _database.transaction(() async {
        await _database.customStatement('PRAGMA defer_foreign_keys = ON');
        // إزالة السجلات التابعة أولًا لحماية علاقات المفاتيح الخارجية.
        for (final table in _tablesForDeletion) {
          await _database.customStatement('DELETE FROM $table');
        }

        // الاستعادة من الجداول الأساسية إلى الجداول التابعة.
        for (final table in _tablesForRestore) {
          await _database.customStatement(
            'INSERT INTO $table SELECT * FROM backup_source.$table',
          );
        }
      });
    } finally {
      await _database.customStatement('DETACH DATABASE backup_source');
    }
  }

  Future<bool> deleteBackup(BackupSnapshot snapshot) async {
    final file = File(snapshot.path);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  Future<Directory> _backupDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final backups = Directory(p.join(documents.path, 'backups'));
    if (!await backups.exists()) {
      await backups.create(recursive: true);
    }
    return backups;
  }

  String _sqlString(String value) => "'${value.replaceAll("'", "''")}'";

  static const _tablesForDeletion = [
    'habit_logs',
    'focus_sessions',
    'attachments',
    'reminders',
    'notes',
    'tasks',
    'sub_goals',
    'projects',
    'goals',
    'categories',
    'habits',
    'profile',
    'app_settings',
  ];

  static const _tablesForRestore = [
    'profile',
    'app_settings',
    'categories',
    'goals',
    'sub_goals',
    'projects',
    'tasks',
    'reminders',
    'notes',
    'attachments',
    'habits',
    'habit_logs',
    'focus_sessions',
  ];
}

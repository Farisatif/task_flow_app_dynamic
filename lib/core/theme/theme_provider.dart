import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database.dart';
import '../database/tables.dart';

/// يدير حالة الوضع (نهاري / ليلي) في كامل التطبيق
class ThemeProvider extends ChangeNotifier {
  final AppDatabase? _db;
  ThemeMode _mode;

  ThemeProvider({ThemeMode initialMode = ThemeMode.system, AppDatabase? db})
      : _db = db,
        _mode = initialMode {
    if (_db != null) unawaited(_load());
  }

  ThemeMode get mode => _mode;
  bool get isDark {
    if (_mode == ThemeMode.dark) return true;
    if (_mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  bool get isLight => !isDark;
  bool get followsSystem => _mode == ThemeMode.system;

  void toggle() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  void setDark(bool value) {
    setMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    unawaited(_persist(mode));
    notifyListeners();
  }

  Future<void> _load() async {
    final rows = await _db!.select(_db.appSettings).get();
    String? value;
    for (final row in rows) {
      if (row.settingKey == 'theme_mode') {
        value = row.settingValue;
        break;
      }
    }
    ThemeMode? mode;
    for (final item in ThemeMode.values) {
      if (item.name == value) {
        mode = item;
        break;
      }
    }
    if (mode == null || mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  Future<void> _persist(ThemeMode mode) async {
    if (_db == null) return;
    await _db!.into(_db!.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            settingKey: 'theme_mode',
            settingValue: mode.name,
          ),
        );
  }
}

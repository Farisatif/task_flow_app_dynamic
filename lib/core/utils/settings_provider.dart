import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database.dart';
import '../database/tables.dart';
import 'notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const Color _defaultPrimaryColor = Color(0xFF7B6FF0);

  final AppDatabase? _db;

  SettingsProvider([this._db]) {
    if (_db != null) unawaited(_load());
  }

  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  Color _primaryColor = _defaultPrimaryColor;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  Color get primaryColor => _primaryColor;

  void setSoundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    NotificationService.setSoundEnabled(value);
    unawaited(_persist('sound_enabled', value ? 'true' : 'false'));
    notifyListeners();
  }

  void setHapticEnabled(bool value) {
    if (_hapticEnabled == value) return;
    _hapticEnabled = value;
    unawaited(_persist('haptic_enabled', value ? 'true' : 'false'));
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    if (_primaryColor.value == color.value) return;
    _primaryColor = color;
    unawaited(_persist('primary_color', color.value.toString()));
    notifyListeners();
  }

  void reset() {
    _soundEnabled = true;
    NotificationService.setSoundEnabled(true);
    _hapticEnabled = true;
    _primaryColor = _defaultPrimaryColor;
    unawaited(_persistAll());
    notifyListeners();
  }

  Future<void> _load() async {
    final rows = await _db!.select(_db.appSettings).get();
    final values = <String, String>{
      for (final row in rows) row.settingKey: row.settingValue,
    };
    _soundEnabled = values['sound_enabled'] != 'false';
    _hapticEnabled = values['haptic_enabled'] != 'false';
    final colorValue = int.tryParse(values['primary_color'] ?? '');
    if (colorValue != null) _primaryColor = Color(colorValue);
    NotificationService.setSoundEnabled(_soundEnabled);
    notifyListeners();
  }

  Future<void> _persist(String key, String value) async {
    if (_db == null) return;
    await _db!.into(_db!.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            settingKey: key,
            settingValue: value,
          ),
        );
  }

  Future<void> _persistAll() async {
    await Future.wait([
      _persist('sound_enabled', 'true'),
      _persist('haptic_enabled', 'true'),
      _persist('primary_color', _defaultPrimaryColor.value.toString()),
    ]);
  }
}

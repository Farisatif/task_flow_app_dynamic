import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  static const Color _defaultPrimaryColor = Color(0xFF7B6FF0);

  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  Color _primaryColor = _defaultPrimaryColor;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  Color get primaryColor => _primaryColor;

  void setSoundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
  }

  void setHapticEnabled(bool value) {
    if (_hapticEnabled == value) return;
    _hapticEnabled = value;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    if (_primaryColor.value == color.value) return;
    _primaryColor = color;
    notifyListeners();
  }

  void reset() {
    _soundEnabled = true;
    _hapticEnabled = true;
    _primaryColor = _defaultPrimaryColor;
    notifyListeners();
  }
}

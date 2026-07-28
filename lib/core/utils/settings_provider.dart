import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  Color _primaryColor = const Color(0xFF7B6FF0);

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  Color get primaryColor => _primaryColor;

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }

  void setHapticEnabled(bool value) {
    _hapticEnabled = value;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }
}

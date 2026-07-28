import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'package:flutter/widgets.dart';

class SoundService {
  SoundService._();

  static void playTaskComplete(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.soundEnabled) {
      // In a real app, we would use a package like audioplayers
      // For now, we simulate with system haptics if enabled
      if (settings.hapticEnabled) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  static void playTaskCreate(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.soundEnabled) {
      if (settings.hapticEnabled) {
        HapticFeedback.lightImpact();
      }
    }
  }

  static void playNotification(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.soundEnabled) {
      if (settings.hapticEnabled) {
        HapticFeedback.heavyImpact();
      }
    }
  }
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';

class SoundService {
  SoundService._();

  static Future<void> playTaskComplete(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (!settings.soundEnabled) return;

    if (settings.hapticEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> playTaskCreate(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (!settings.soundEnabled) return;

    if (settings.hapticEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> playNotification(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (!settings.soundEnabled) return;

    if (settings.hapticEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }
}

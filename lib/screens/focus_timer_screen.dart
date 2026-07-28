import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/sound_service.dart';
import '../core/utils/settings_provider.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  static const int totalSeconds = 25 * 60;
  int _remaining = totalSeconds;
  Timer? _timer;
  bool _running = false;

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 0) {
          t.cancel();
          setState(() => _running = false);
          SoundService.playNotification(context);
          return;
        }
        setState(() => _remaining--);
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = totalSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final percent = 1 - (_remaining / totalSeconds);
    final settings = context.watch<SettingsProvider>();

    return AppScaffold(
      title: 'مؤقت التركيز',
      showNav: false,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              settings.primaryColor.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _running ? 'حان وقت التركيز' : 'هل أنت مستعد؟',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'جلسة بومودورو (25 دقيقة)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const Spacer(),
            CircularPercentIndicator(
              radius: 140,
              lineWidth: 12,
              percent: percent.clamp(0, 1),
              animation: false,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
              progressColor: settings.primaryColor,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w200,
                          color: settings.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'دقيقة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('إعادة تعيين'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _toggle,
                      style: FilledButton.styleFrom(
                        backgroundColor: settings.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          const SizedBox(width: 8),
                          Text(_running ? 'إيقاف مؤقت' : 'ابدأ الآن'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

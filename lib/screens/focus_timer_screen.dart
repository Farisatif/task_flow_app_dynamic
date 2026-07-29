import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../core/utils/settings_provider.dart';
import '../core/utils/sound_service.dart';
import '../widgets/app_scaffold.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with WidgetsBindingObserver {
  static const int _defaultMinutes = 25;

  late int _totalSeconds;
  late int _remainingSeconds;

  Timer? _timer;
  bool _running = false;
  int _selectedMinutes = _defaultMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyMinutes(_defaultMinutes, resetProgress: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pause();
    }
  }

  void _applyMinutes(int minutes, {bool resetProgress = false}) {
    final safeMinutes = minutes.clamp(1, 180);
    setState(() {
      _selectedMinutes = safeMinutes;
      _totalSeconds = safeMinutes * 60;
      _remainingSeconds = resetProgress
          ? _totalSeconds
          : _remainingSeconds.clamp(0, _totalSeconds);
      if (resetProgress) {
        _running = false;
      }
    });
  }

  void _start() {
    if (_running) return;

    if (_remainingSeconds <= 0) {
      _remainingSeconds = _totalSeconds;
    }

    setState(() => _running = true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _running = false;
        });

        SoundService.playNotification(context);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'انتهت جلسة التركيز',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _pause() {
    if (!_running) return;
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _toggle() {
    if (_running) {
      _pause();
    } else {
      _start();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  String get _label {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _subtitle {
    if (_running) return 'جلسة بومودورو نشطة';
    if (_remainingSeconds == _totalSeconds) return 'اضغط ابدأ للتركيز';
    if (_remainingSeconds == 0) return 'تمت الجلسة بنجاح';
    return 'الجلسة متوقفة مؤقتًا';
  }

  double get _percentCompleted {
    if (_totalSeconds <= 0) return 0;
    final value = 1 - (_remainingSeconds / _totalSeconds);
    return value.clamp(0.0, 1.0);
  }

  int get _elapsedSeconds => _totalSeconds - _remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final primary = settings.primaryColor;

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
              primary.withOpacity(0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              _HeaderCard(
                title: _running ? 'حان وقت التركيز' : 'جاهز لجلسة جديدة؟',
                subtitle: _subtitle,
                primaryColor: primary,
                elapsedMinutes: _elapsedSeconds ~/ 60,
                totalMinutes: _totalSeconds ~/ 60,
              ),
              const SizedBox(height: 16),
              _PresetSelector(
                selectedMinutes: _selectedMinutes,
                primaryColor: primary,
                onSelected: (minutes) {
                  _timer?.cancel();
                  setState(() {
                    _running = false;
                  });
                  _applyMinutes(minutes, resetProgress: true);
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 310,
                          height: 310,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.12),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        CircularPercentIndicator(
                          radius: 140,
                          lineWidth: 14,
                          percent: _percentCompleted,
                          animation: true,
                          animationDuration: 350,
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: theme.dividerColor.withOpacity(0.12),
                          progressColor: primary,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _label,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w200,
                                  color: primary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'دقيقة / ثانية',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    LinearPercentIndicator(
                      lineHeight: 10,
                      percent: _percentCompleted,
                      animation: true,
                      animationDuration: 300,
                      barRadius: const Radius.circular(999),
                      backgroundColor: theme.dividerColor.withOpacity(0.10),
                      progressColor: primary,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'متقدم: ${(_percentCompleted * 100).round()}%',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'متبقي: ${_remainingSeconds ~/ 60} دقيقة',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _toggle,
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          _running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_running ? 'إيقاف مؤقت' : 'ابدأ الآن'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final int elapsedMinutes;
  final int totalMinutes;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.elapsedMinutes,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.cardColor,
          border: Border.all(
            color: primaryColor.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'تم إنجاز $elapsedMinutes من $totalMinutes دقيقة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final int selectedMinutes;
  final Color primaryColor;
  final ValueChanged<int> onSelected;

  const _PresetSelector({
    required this.selectedMinutes,
    required this.primaryColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const presets = [15, 25, 45, 60];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final minutes = presets[index];
          final selected = minutes == selectedMinutes;

          return ChoiceChip(
            label: Text('$minutes دقيقة'),
            selected: selected,
            onSelected: (_) => onSelected(minutes),
            selectedColor: primaryColor.withOpacity(0.16),
            labelStyle: TextStyle(
              color: selected
                  ? primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: selected
                    ? primaryColor
                    : Theme.of(context).dividerColor.withOpacity(0.10),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: presets.length,
      ),
    );
  }
}

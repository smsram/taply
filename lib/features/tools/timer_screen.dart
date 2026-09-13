import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _totalSeconds = 300; // default 5 minutes
  int _remainingSeconds = 300;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_remainingSeconds <= 0) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _pauseTimer();
        context.showSnackBar('Timer finished!');
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => _remainingSeconds = _totalSeconds);
  }

  void _setPreset(int seconds) {
    _pauseTimer();
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final hours = totalSecs ~/ 3600;
    final minutes = (totalSecs % 3600) ~/ 60;
    final seconds = totalSecs % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0
        ? _remainingSeconds / _totalSeconds
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Circular Countdown Display
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: context.isDarkMode
                              ? AppColors.darkBorder
                              : AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.isDarkMode
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(_remainingSeconds),
                            style: context.textTheme.headlineLarge?.copyWith(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _isRunning
                                ? 'Counting down'
                                : (_remainingSeconds == 0
                                      ? 'Completed'
                                      : 'Paused'),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: _isRunning ? AppColors.secondary : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Presets
              Text(
                'QUICK PRESETS',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  _buildPresetChip('1 min', 60),
                  _buildPresetChip('5 min', 300),
                  _buildPresetChip('10 min', 600),
                  _buildPresetChip('15 min', 900),
                  _buildPresetChip('30 min', 1800),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Control Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      icon: Icon(
                        _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(_isRunning ? 'Pause' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? AppColors.accent : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int seconds) {
    final isSelected = _totalSeconds == seconds && !_isRunning;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setPreset(seconds),
      selectedColor:
          (context.isDarkMode ? AppColors.darkPrimary : AppColors.primary)
              .withOpacity(0.2),
    );
  }
}

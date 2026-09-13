import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];

  void _startStopwatch() {
    setState(() {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {});
      });
    });
  }

  void _pauseStopwatch() {
    setState(() {
      _stopwatch.stop();
      _timer?.cancel();
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _timer?.cancel();
      _laps.clear();
    });
  }

  void _recordLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _stopwatch.elapsed);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;

    return Scaffold(
      appBar: AppBar(title: const Text('Stopwatch')),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              alignment: Alignment.center,
              child: Text(
                _formatElapsed(_stopwatch.elapsed),
                style: context.textTheme.headlineLarge?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isRunning ? _recordLap : _resetStopwatch,
                      child: Text(isRunning ? 'Lap' : 'Reset'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isRunning ? _pauseStopwatch : _startStopwatch,
                      icon: Icon(
                        isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(isRunning ? 'Stop' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),

            // Lap List
            Expanded(
              child: _laps.isEmpty
                  ? Center(
                      child: Text(
                        'No laps recorded',
                        style: context.textTheme.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      itemCount: _laps.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lapIndex = _laps.length - index;
                        final duration = _laps[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lap $lapIndex',
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatElapsed(duration),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontFeatures: [
                                    const FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

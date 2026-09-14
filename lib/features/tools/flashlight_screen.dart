import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen>
    with WidgetsBindingObserver {
  bool _isOn = false;
  bool _isScreenLight = false;
  double _strobeFrequency = 0.0;
  Timer? _strobeTimer;
  bool _strobePulse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStrobe();
    // Safely turn off torch on screen exit if it was active
    NativeBridge.instance.setTorch(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_strobeTimer != null) {
        _stopStrobe();
        setState(() => _strobeFrequency = 0.0);
      }
      NativeBridge.instance.setTorch(false);
      setState(() => _isOn = false);
    }
  }

  Future<void> _checkInitialState() async {
    final torch = await NativeBridge.instance.isFlashlightOn();
    if (mounted) {
      setState(() => _isOn = torch);
    }
  }

  void _stopStrobe() {
    _strobeTimer?.cancel();
    _strobeTimer = null;
    _strobePulse = false;
  }

  void _updateStrobe(double frequency) {
    setState(() => _strobeFrequency = frequency);
    _stopStrobe();

    if (frequency <= 0.0) {
      NativeBridge.instance.setTorch(_isOn);
      return;
    }

    // Interval in milliseconds for half-cycle (on/off)
    final intervalMs = (1000.0 / (frequency * 2)).round().clamp(50, 1000);
    _strobeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _strobePulse = !_strobePulse;
      NativeBridge.instance.setTorch(_strobePulse);
      if (mounted) {
        setState(() => _isOn = _strobePulse);
      }
    });
  }

  Future<void> _toggleTorch() async {
    if (_strobeFrequency > 0) {
      _stopStrobe();
      setState(() => _strobeFrequency = 0.0);
    }
    final nextState = !_isOn;
    final ok = await NativeBridge.instance.setTorch(nextState);
    if (!mounted) return;
    if (ok) {
      setState(() => _isOn = nextState);
      context.showSnackBar(
        _isOn ? 'Flashlight enabled' : 'Flashlight turned off',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScreenLight) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: InkWell(
          onTap: () => setState(() => _isScreenLight = false),
          child: const Center(
            child: Text(
              'Tap anywhere to exit screen light',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Flashlight')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Big Flashlight Toggle Button
              GestureDetector(
                onTap: _toggleTorch,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOn
                        ? AppColors.accent
                        : context.colorScheme.surface,
                    border: Border.all(
                      color: _isOn
                          ? AppColors.accent
                          : context.colorScheme.outline,
                      width: 3,
                    ),
                    boxShadow: _isOn
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.5),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    size: 56,
                    color: _isOn
                        ? Colors.white
                        : context.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _strobeFrequency > 0
                    ? 'STROBE ACTIVE (${_strobeFrequency.toInt()} Hz)'
                    : (_isOn ? 'TORCH ON' : 'TORCH OFF'),
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _isOn ? AppColors.accent : null,
                ),
              ),
              const Spacer(),

              // Strobe & Screen Light Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.flash_on_rounded,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Hardware Strobe Blinking',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _strobeFrequency > 0
                                ? '${_strobeFrequency.toInt()} Hz'
                                : 'Off',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _strobeFrequency > 0
                                  ? AppColors.accent
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _strobeFrequency,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _strobeFrequency > 0
                            ? '${_strobeFrequency.toInt()} Hz'
                            : 'Off',
                        onChanged: _updateStrobe,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: const Text('Use Screen as White Lantern'),
                        subtitle: const Text(
                          'Maximum brightness white display',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        onTap: () => setState(() => _isScreenLight = true),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

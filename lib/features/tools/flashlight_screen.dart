import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  bool _isOn = false;
  bool _isScreenLight = false;
  double _strobeFrequency = 0.0;

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
                onTap: () {
                  setState(() => _isOn = !_isOn);
                  context.showSnackBar(
                    _isOn
                        ? 'Flashlight enabled (Hardware torch in Phase 2)'
                        : 'Flashlight turned off',
                  );
                },
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
                _isOn ? 'TORCH ON' : 'TORCH OFF',
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
                          Text(
                            'Strobe Frequency',
                            style: context.textTheme.bodyMedium,
                          ),
                          Text(
                            '${_strobeFrequency.toInt()} Hz',
                            style: context.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      Slider(
                        value: _strobeFrequency,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (val) =>
                            setState(() => _strobeFrequency = val),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: const Text('Use Screen as White Lantern'),
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

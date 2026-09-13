import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class ScreenMagnifierScreen extends StatefulWidget {
  const ScreenMagnifierScreen({super.key});

  @override
  State<ScreenMagnifierScreen> createState() => _ScreenMagnifierScreenState();
}

class _ScreenMagnifierScreenState extends State<ScreenMagnifierScreen> {
  double _zoomLevel = 2.0;
  bool _isTorchOn = false;
  bool _isFrozen = false;
  int _contrastMode = 0; // 0: Normal, 1: High Contrast, 2: Inverted

  @override
  void dispose() {
    if (_isTorchOn) {
      NativeBridge.instance.toggleFlashlight();
    }
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    HapticFeedback.lightImpact();
    final ok = await NativeBridge.instance.toggleFlashlight();
    if (mounted && ok) {
      setState(() => _isTorchOn = !_isTorchOn);
      context.showSnackBar(
        _isTorchOn ? 'Torch illuminated' : 'Torch turned off',
      );
    }
  }

  void _cycleContrast() {
    HapticFeedback.lightImpact();
    setState(() {
      _contrastMode = (_contrastMode + 1) % 3;
    });
    final modeNames = ['Normal View', 'High Contrast', 'Inverted Mono'];
    context.showSnackBar('Filter: ${modeNames[_contrastMode]}');
  }

  void _toggleFreeze() {
    HapticFeedback.mediumImpact();
    setState(() => _isFrozen = !_isFrozen);
    context.showSnackBar(
      _isFrozen ? 'Frame frozen for reading' : 'Live magnifier resumed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Magnifier'),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              color: _isTorchOn ? AppColors.accent : null,
            ),
            tooltip: _isTorchOn ? 'Turn Torch Off' : 'Turn Torch On',
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Icon(
              _isFrozen ? Icons.play_arrow_rounded : Icons.pause_circle_rounded,
              color: _isFrozen ? AppColors.warning : null,
            ),
            tooltip: _isFrozen ? 'Resume Live Preview' : 'Freeze Frame',
            onPressed: _toggleFreeze,
          ),
          IconButton(
            icon: const Icon(Icons.contrast_rounded),
            tooltip: 'Cycle Contrast Filter',
            onPressed: _cycleContrast,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Magnifier Viewport
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: _contrastMode == 2
                      ? Colors.white
                      : (_contrastMode == 1
                            ? Colors.black
                            : (isDark
                                  ? AppColors.darkSurface
                                  : const Color(0xFFF1F5F9))),
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(
                    color: _isFrozen ? AppColors.warning : AppColors.primary,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 2),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder Grid & Target
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MagnifierGridPainter(
                            isDark: isDark,
                            contrastMode: _contrastMode,
                          ),
                        ),
                      ),

                      // Center Magnified Target Simulation
                      Transform.scale(
                        scale: _zoomLevel,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              size: 56,
                              color: _contrastMode == 2
                                  ? Colors.black87
                                  : (_contrastMode == 1
                                        ? Colors.yellowAccent
                                        : AppColors.primary.withOpacity(0.7)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MAGNIFIED TARGET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: _contrastMode == 2
                                    ? Colors.black
                                    : (_contrastMode == 1
                                          ? Colors.yellowAccent
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black54)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Overlay HUD Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_zoomLevel.toStringAsFixed(1)}× ZOOM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      if (_isFrozen)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pause_rounded,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'FROZEN',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Zoom Controls Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Optical Zoom',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_zoomLevel.toStringAsFixed(1)}×',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('1.0×', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _zoomLevel,
                              min: 1.0,
                              max: 8.0,
                              divisions: 28,
                              onChanged: (val) {
                                setState(() => _zoomLevel = val);
                              },
                            ),
                          ),
                          const Text('8.0×', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Android System Magnifier Integration Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System-Wide Magnification',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Magnify any app or screen with Android accessibility shortcut.',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          NativeBridge.instance.openSystemSetting(
                            'accessibility',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text(
                          'Open Settings',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
        ),
      ),
    );
  }
}

class _MagnifierGridPainter extends CustomPainter {
  final bool isDark;
  final int contrastMode;

  _MagnifierGridPainter({required this.isDark, required this.contrastMode});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = contrastMode == 2
          ? Colors.black12
          : (contrastMode == 1
                ? Colors.white12
                : (isDark ? Colors.white10 : Colors.black12))
      ..strokeWidth = 1;

    // Draw alignment crosshairs
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Corner guides
    final cornerPaint = Paint()
      ..color = contrastMode == 1 ? Colors.yellowAccent : AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cornerSize = 24.0;
    const margin = 20.0;

    // Top-left
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + cornerSize, margin),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin, margin + cornerSize),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerSize, margin),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerSize),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerSize, size.height - margin),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerSize),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerSize, size.height - margin),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MagnifierGridPainter oldDelegate) {
    return oldDelegate.contrastMode != contrastMode ||
        oldDelegate.isDark != isDark;
  }
}

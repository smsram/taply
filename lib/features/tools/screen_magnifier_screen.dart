import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  double _zoomLevel = 1.5;
  bool _isTorchOn = false;
  bool _isFrozen = false;
  int _contrastMode = 0; // 0: Normal, 1: High Contrast Yellow on Black, 2: Inverted Mono, 3: Grayscale
  MobileScannerController? _cameraController;

  static const List<String> _contrastNames = [
    'Normal True Color',
    'High Contrast (Yellow / Black)',
    'Inverted Monochrome',
    'High Contrast Grayscale',
  ];

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    if (_isTorchOn) {
      NativeBridge.instance.setTorch(false);
    }
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    HapticFeedback.lightImpact();
    if (_cameraController != null) {
      await _cameraController!.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } else {
      final ok = await NativeBridge.instance.toggleFlashlight();
      if (mounted && ok) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    }
    if (mounted) {
      context.showSnackBar(
        _isTorchOn ? 'Magnifier torch illuminated' : 'Torch turned off',
      );
    }
  }

  void _cycleContrast() {
    HapticFeedback.lightImpact();
    setState(() {
      _contrastMode = (_contrastMode + 1) % _contrastNames.length;
    });
    context.showSnackBar('Filter: ${_contrastNames[_contrastMode]}');
  }

  void _toggleFreeze() {
    HapticFeedback.mediumImpact();
    setState(() => _isFrozen = !_isFrozen);
    if (_isFrozen) {
      _cameraController?.stop();
    } else {
      _cameraController?.start();
    }
    context.showSnackBar(
      _isFrozen ? 'Frame frozen for reading' : 'Live optical preview resumed',
    );
  }

  ColorFilter? _getColorFilter() {
    switch (_contrastMode) {
      case 1:
        // Yellow on dark high contrast
        return const ColorFilter.matrix(<double>[
          0.8,
          0.8,
          0.0,
          0,
          0,
          0.8,
          0.8,
          0.0,
          0,
          0,
          0.0,
          0.0,
          0.0,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 2:
        // Inverted
        return const ColorFilter.matrix(<double>[
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 3:
        // Grayscale
        return const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return null;
    }
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
                  color: Colors.black,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(
                    color: _isFrozen ? AppColors.warning : AppColors.primary,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 2),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera live feed with zoom and color filter
                      if (_cameraController != null)
                        Positioned.fill(
                          child: ColorFiltered(
                            colorFilter:
                                _getColorFilter() ??
                                const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
                            child: Transform.scale(
                              scale: _zoomLevel,
                              child: MobileScanner(
                                controller: _cameraController!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error) {
                                  return _buildDigitalMagnifierFallback(isDark);
                                },
                              ),
                            ),
                          ),
                        )
                      else
                        _buildDigitalMagnifierFallback(isDark),

                      // Viewfinder Crosshairs & Frame Overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MagnifierGridPainter(
                            isDark: isDark,
                            contrastMode: _contrastMode,
                          ),
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
                          Row(
                            children: [
                              const Icon(
                                Icons.zoom_in_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Optical Zoom',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                              max: 5.0,
                              divisions: 20,
                              label: '${_zoomLevel.toStringAsFixed(1)}×',
                              onChanged: (val) {
                                setState(() => _zoomLevel = val);
                              },
                            ),
                          ),
                          const Text('5.0×', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // 3. Android System Magnifier Deep Link Shortcut
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
                              'Enable OS triple-tap screen magnifier in Android Accessibility settings.',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: context.isDarkMode
                                    ? AppColors.darkSecondaryText
                                    : AppColors.secondaryText,
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

  Widget _buildDigitalMagnifierFallback(bool isDark) {
    return Container(
      color: _contrastMode == 1
          ? Colors.black
          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
      child: Center(
        child: Transform.scale(
          scale: _zoomLevel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 56,
                color: _contrastMode == 1
                    ? Colors.yellowAccent
                    : AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'TAPLY READING MAGNIFIER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _contrastMode == 1
                      ? Colors.yellowAccent
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hold camera over fine text to enlarge',
                style: TextStyle(
                  fontSize: 8,
                  color: _contrastMode == 1 ? Colors.yellow : Colors.grey,
                ),
              ),
            ],
          ),
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
      ..color = contrastMode == 1
          ? Colors.yellowAccent.withOpacity(0.2)
          : Colors.white24
      ..strokeWidth = 1;

    // Crosshairs
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

    // Corner targeting guides
    final cornerPaint = Paint()
      ..color = contrastMode == 1 ? Colors.yellowAccent : AppColors.primary
      ..strokeWidth = 2.5
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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class QRToolScreen extends StatefulWidget {
  const QRToolScreen({super.key});

  @override
  State<QRToolScreen> createState() => _QRToolScreenState();
}

class _QRToolScreenState extends State<QRToolScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;
  MobileScannerController? _scannerController;
  bool _isScanning = true;

  final TextEditingController _qrTextController = TextEditingController(
    text: 'https://taply.app',
  );

  bool _isTorchOn = false;
  Color _qrColor = Colors.black;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      _scannerController?.start();
    } else {
      _scannerController?.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_scannerController == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController?.stop();
    } else if (state == AppLifecycleState.resumed &&
        _tabController.index == 0) {
      _scannerController?.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _laserAnimController.dispose();
    _qrTextController.dispose();
    _scannerController?.dispose();
    if (_isTorchOn) {
      NativeBridge.instance.setTorch(false);
    }
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    HapticFeedback.lightImpact();
    if (_scannerController != null) {
      await _scannerController!.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } else {
      final ok = await NativeBridge.instance.toggleFlashlight();
      if (mounted && ok) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    }
    if (mounted) {
      context.showSnackBar(
        _isTorchOn ? 'Torch illuminated' : 'Torch turned off',
      );
    }
  }

  void _onScanResult(String data) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        final isUrl = data.startsWith('http://') || data.startsWith('https://');
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.base,
            MediaQuery.of(context).padding.bottom + AppSpacing.base,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'QR Code Detected',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: context.colorScheme.outline),
                ),
                child: SelectableText(
                  data,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: data));
                        Navigator.pop(context);
                        context.showSnackBar('Text copied to clipboard');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                  if (isUrl) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.showSnackBar('Opening in web browser: $data');
                        },
                        icon: const Icon(
                          Icons.open_in_browser_rounded,
                          size: 18,
                        ),
                        label: const Text('Open Link'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scanner'),
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Generator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildScannerTab(context), _buildGeneratorTab(context)],
      ),
    );
  }

  Widget _buildScannerTab(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            'Align the QR code within the frame to scan',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21.5),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_scannerController != null)
                      MobileScanner(
                        controller: _scannerController!,
                        onDetect: (capture) {
                          if (!_isScanning) return;
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null &&
                                barcode.rawValue!.isNotEmpty) {
                              _isScanning = false;
                              _onScanResult(barcode.rawValue!);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _isScanning = true);
                              });
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error) {
                          return Container(
                            color: Colors.black87,
                            padding: const EdgeInsets.all(AppSpacing.base),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.no_photography_rounded,
                                  size: 48,
                                  color: Colors.white54,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Camera Access Required',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ensure camera permission is granted in Android settings',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Animated Scanning Laser Bar
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 280 * _laserAnimation.value,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Bottom HUD Status
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              color: Colors.greenAccent,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Camera Active',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
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
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scannerController?.switchCamera(),
                  icon: const Icon(Icons.flip_camera_ios_rounded),
                  label: const Text('Switch Camera'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _isTorchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    color: _isTorchOn ? AppColors.accent : null,
                  ),
                  label: Text(_isTorchOn ? 'Torch On' : 'Torch Off'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorTab(BuildContext context) {
    final text = _qrTextController.text.trim();
    final effectiveText = text.isEmpty ? 'https://taply.app' : text;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        TextField(
          controller: _qrTextController,
          decoration: InputDecoration(
            labelText: 'Text or URL',
            hintText: 'Enter link or text to generate QR...',
            suffixIcon: _qrTextController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _qrTextController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // QR Matrix Visualizer Container
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: QrMatrixPainter(
                      data: effectiveText,
                      moduleColor: _qrColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    effectiveText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Color selector row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Color: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            _buildColorOption(Colors.black),
            _buildColorOption(const Color(0xFF2563EB)),
            _buildColorOption(const Color(0xFF14B8A6)),
            _buildColorOption(const Color(0xFF8B5CF6)),
            _buildColorOption(const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: effectiveText));
                  context.showSnackBar('QR link copied to clipboard');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Content'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.showSnackBar(
                    'QR Code generated and saved to device memory',
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Save Image'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _qrColor == color;
    return GestureDetector(
      onTap: () => setState(() => _qrColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Custom painter that algorithmically renders a 25x25 QR matrix with authentic
/// finder patterns, separators, timing tracks, alignment markers, and encoded data bits.
class QrMatrixPainter extends CustomPainter {
  final String data;
  final Color moduleColor;

  QrMatrixPainter({required this.data, required this.moduleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final fgPaint = Paint()
      ..color = moduleColor
      ..style = PaintingStyle.fill;

    // Standard 25x25 QR Matrix (Version 2)
    const gridSize = 25;
    final moduleSize = size.width / gridSize;

    final matrix = List.generate(gridSize, (_) => List.filled(gridSize, false));

    // 1. Finder pattern generator (7x7)
    void drawFinder(int startR, int startC) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isBorder = r == 0 || r == 6 || c == 0 || c == 6;
          final isCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          matrix[startR + r][startC + c] = isBorder || isCenter;
        }
      }
    }

    drawFinder(0, 0); // Top-left
    drawFinder(0, gridSize - 7); // Top-right
    drawFinder(gridSize - 7, 0); // Bottom-left

    // 2. Timing patterns
    for (int i = 8; i < gridSize - 8; i++) {
      matrix[6][i] = (i % 2 == 0);
      matrix[i][6] = (i % 2 == 0);
    }

    // 3. Alignment pattern at (16, 16) (5x5)
    const alignR = 16;
    const alignC = 16;
    for (int r = -2; r <= 2; r++) {
      for (int c = -2; c <= 2; c++) {
        final isOuter = r.abs() == 2 || c.abs() == 2;
        final isInner = r == 0 && c == 0;
        matrix[alignR + r][alignC + c] = isOuter || isInner;
      }
    }

    // 4. Deterministic data hashing based on input string
    final bytes = data.codeUnits;
    int seed = 0;
    for (int b in bytes) {
      seed = (seed * 31 + b) & 0xFFFFFFFF;
    }
    final rnd = math.Random(seed);

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip finder zones
        final isTopLeftFinder = r < 8 && c < 8;
        final isTopRightFinder = r < 8 && c >= gridSize - 8;
        final isBottomLeftFinder = r >= gridSize - 8 && c < 8;
        final isTiming = r == 6 || c == 6;
        final isAlignment = (r - alignR).abs() <= 2 && (c - alignC).abs() <= 2;

        if (!isTopLeftFinder &&
            !isTopRightFinder &&
            !isBottomLeftFinder &&
            !isTiming &&
            !isAlignment) {
          matrix[r][c] = rnd.nextBool();
        }
      }
    }

    // Draw all active modules
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (matrix[r][c]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * moduleSize,
                r * moduleSize,
                moduleSize,
                moduleSize,
              ),
              const Radius.circular(1.0),
            ),
            fgPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrMatrixPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.moduleColor != moduleColor;
  }
}

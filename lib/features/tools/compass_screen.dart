import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double _heading = 0.0;
  bool _isAvailable = true;
  String _accuracy = 'High';
  Timer? _sensorTimer;

  @override
  void initState() {
    super.initState();
    _startCompassTracking();
  }

  void _startCompassTracking() {
    NativeBridge.instance.startCompass();
    _sensorTimer = Timer.periodic(const Duration(milliseconds: 60), (_) async {
      final data = await NativeBridge.instance.getCompassHeading();
      if (mounted) {
        final avail = data['available'] as bool? ?? false;
        final rawHeading = (data['heading'] as num?)?.toDouble() ?? 0.0;
        final acc = data['accuracy']?.toString() ?? 'High';

        setState(() {
          _isAvailable = avail;
          _accuracy = acc;
          if (avail) {
            _heading = rawHeading;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    NativeBridge.instance.stopCompass();
    super.dispose();
  }

  void _calibrate() {
    HapticFeedback.mediumImpact();
    context.showSnackBar(
      'Wave phone in a figure-8 pattern to calibrate magnetic sensor',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardinal = _getCardinalDirection(_heading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Compass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Calibrate Sensor',
            onPressed: _calibrate,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            final isLandscape = availableWidth > availableHeight;
            final dialSize = math
                .min(
                  availableWidth * 0.75,
                  isLandscape ? availableHeight * 0.55 : availableHeight * 0.38,
                )
                .clamp(160.0, 280.0);
            final needleSize = dialSize * (220.0 / 280.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Calibration & Accuracy status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isAvailable
                              ? (_accuracy == 'High'
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.warning.withOpacity(0.12))
                              : AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isAvailable
                                ? (_accuracy == 'High'
                                      ? AppColors.success
                                      : AppColors.warning)
                                : AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAvailable
                                  ? (_accuracy == 'High'
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_rounded)
                                  : Icons.sensors_off_rounded,
                              size: 14,
                              color: _isAvailable
                                  ? (_accuracy == 'High'
                                        ? AppColors.success
                                        : AppColors.warning)
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isAvailable
                                  ? 'Accuracy: $_accuracy'
                                  : 'Magnetometer Sensor Unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isAvailable
                                    ? (_accuracy == 'High'
                                          ? AppColors.success
                                          : AppColors.warning)
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!_isAvailable) ...[
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.explore_off_rounded,
                                    size: 56,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Sensor Unavailable',
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'This device does not have a physical magnetometer or rotation sensor. Compass heading requires real hardware orientation sensors.',
                                    textAlign: TextAlign.center,
                                    style: context.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ] else ...[
                        const SizedBox(height: AppSpacing.md),

                        // Heading & Cardinal Display
                        Text(
                          '${_heading.toInt()}°',
                          style: context.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          cardinal,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.primaryText,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Compass Rose / Dial
                        Center(
                          child: SizedBox(
                            width: dialSize,
                            height: dialSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Degree Ring
                                CustomPaint(
                                  size: Size(dialSize, dialSize),
                                  painter: _CompassDialPainter(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.2),
                                    textColor: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.secondaryText,
                                  ),
                                ),

                                // Rotating Compass Needle
                                Transform.rotate(
                                  angle: -_heading * (math.pi / 180),
                                  child: CustomPaint(
                                    size: Size(needleSize, needleSize),
                                    painter: _CompassNeedlePainter(),
                                  ),
                                ),

                                // Center Hub
                                Container(
                                  width: dialSize * 0.086,
                                  height: dialSize * 0.086,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),
                        const Spacer(),

                        // Live Telemetry Row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTelemetryCard(
                                  context,
                                  'AZIMUTH',
                                  '${_heading.toStringAsFixed(1)}°',
                                  Icons.navigation_rounded,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildTelemetryCard(
                                  context,
                                  'BEARING',
                                  cardinal,
                                  Icons.explore_rounded,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildTelemetryCard(
                                  context,
                                  'CALIBRATION',
                                  _accuracy,
                                  Icons.tune_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.base),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _getCardinalDirection(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'North';
    if (deg >= 22.5 && deg < 67.5) return 'North-East';
    if (deg >= 67.5 && deg < 112.5) return 'East';
    if (deg >= 112.5 && deg < 157.5) return 'South-East';
    if (deg >= 157.5 && deg < 202.5) return 'South';
    if (deg >= 202.5 && deg < 247.5) return 'South-West';
    if (deg >= 247.5 && deg < 292.5) return 'West';
    return 'North-West';
  }
}

class _CompassDialPainter extends CustomPainter {
  final Color color;
  final Color textColor;

  _CompassDialPainter({required this.color, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    for (int i = 0; i < 360; i += 15) {
      final angle = i * (math.pi / 180);
      final isMajor = i % 90 == 0;
      final isMedium = i % 45 == 0;
      final tickLength = isMajor ? 14.0 : (isMedium ? 10.0 : 6.0);

      final p1 = Offset(
        center.dx + (radius - tickLength) * math.sin(angle),
        center.dy - (radius - tickLength) * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      tickPaint.strokeWidth = isMajor ? 2.5 : 1.5;
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final halfLen = size.height / 2 - 20;

    // North Needle (Red)
    final northPath = Path()
      ..moveTo(center.dx, center.dy - halfLen)
      ..lineTo(center.dx - 10, center.dy)
      ..lineTo(center.dx + 10, center.dy)
      ..close();

    final northPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawPath(northPath, northPaint);

    // South Needle (Slate)
    final southPath = Path()
      ..moveTo(center.dx, center.dy + halfLen)
      ..lineTo(center.dx - 10, center.dy)
      ..lineTo(center.dx + 10, center.dy)
      ..close();

    final southPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(southPath, southPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/floating_button_config.dart';

class FloatingButtonPreview extends StatefulWidget {
  final FloatingButtonConfig config;
  final bool isEnabled;
  final VoidCallback? onCustomizeTap;
  final VoidCallback? onButtonTap;

  const FloatingButtonPreview({
    super.key,
    required this.config,
    this.isEnabled = true,
    this.onCustomizeTap,
    this.onButtonTap,
  });

  @override
  State<FloatingButtonPreview> createState() => _FloatingButtonPreviewState();
}

class _FloatingButtonPreviewState extends State<FloatingButtonPreview> {
  // Relative position within the container: (0.0, 0.0) top-left, (1.0, 1.0) bottom-right
  Offset _buttonPosition = const Offset(0.85, 0.5);
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.darkSurface
            : const Color(0xFFF1F5F9),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: context.colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonSize = widget.config.size;
            final maxX =
                constraints.maxWidth - buttonSize - (AppSpacing.md * 2);
            final maxY = constraints.maxHeight - buttonSize - 50;
            final left =
                AppSpacing.md + (_buttonPosition.dx * maxX).clamp(0.0, maxX);
            final top = 36.0 + (_buttonPosition.dy * maxY).clamp(0.0, maxY);

            return Stack(
              children: [
                // Subtle phone/screen simulation background
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: CustomPaint(
                      painter: _GridPatternPainter(
                        gridColor: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                // Top Header within preview card
                Positioned(
                  left: AppSpacing.base,
                  top: AppSpacing.md,
                  right: AppSpacing.base,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.preview_rounded,
                            size: 16,
                            color: context.isDarkMode
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'FLOATING BUTTON PREVIEW',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onCustomizeTap != null)
                        InkWell(
                          onTap: widget.onCustomizeTap,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Customize appearance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.isDarkMode
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: context.isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Help caption at bottom
                Positioned(
                  left: AppSpacing.base,
                  bottom: AppSpacing.sm,
                  right: AppSpacing.base,
                  child: Center(
                    child: Text(
                      widget.isEnabled
                          ? 'Drag the button around to test screen edge snapping'
                          : 'Floating assistant is currently disabled',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: context.isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),

                // Draggable Interactive Floating Button
                Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onPanDown: (_) => setState(() => _isPressed = true),
                    onPanEnd: (_) {
                      setState(() {
                        _isPressed = false;
                        if (widget.config.edgeSnapping) {
                          // Snap horizontally to nearest edge (0.0 or 1.0)
                          final snapX = _buttonPosition.dx > 0.5 ? 1.0 : 0.0;
                          _buttonPosition = Offset(snapX, _buttonPosition.dy);
                        }
                      });
                    },
                    onPanCancel: () => setState(() => _isPressed = false),
                    onPanUpdate: (details) {
                      if (!widget.isEnabled) return;
                      setState(() {
                        final newX =
                            (_buttonPosition.dx + details.delta.dx / maxX)
                                .clamp(0.0, 1.0);
                        final newY =
                            (_buttonPosition.dy + details.delta.dy / maxY)
                                .clamp(0.0, 1.0);
                        _buttonPosition = Offset(newX, newY);
                      });
                    },
                    onTap: widget.isEnabled ? widget.onButtonTap : null,
                    child: Semantics(
                      button: true,
                      label: 'Taply Floating Assistant Button',
                      child: _buildButtonWidget(context, buttonSize),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonWidget(BuildContext context, double buttonSize) {
    final effectiveOpacity = widget.isEnabled
        ? (_isPressed ? 1.0 : widget.config.opacity)
        : 0.35;

    final shape = _getShapeForIconStyle(widget.config.iconStyle);

    return Opacity(
      opacity: effectiveOpacity,
      child: Transform.scale(
        scale: _isPressed ? 0.94 : 1.0,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(AppSpacing.radiusMd)
                : null,
            color: widget.config.customColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              widget.config.iconStyle.icon,
              color: Colors.white,
              size: buttonSize * 0.52,
            ),
          ),
        ),
      ),
    );
  }

  BoxShape _getShapeForIconStyle(ButtonIconStyle style) {
    switch (style) {
      case ButtonIconStyle.square:
        return BoxShape.rectangle;
      case ButtonIconStyle.defaultDot:
      case ButtonIconStyle.minimal:
      case ButtonIconStyle.circle:
      case ButtonIconStyle.custom:
        return BoxShape.circle;
    }
  }
}

class _GridPatternPainter extends CustomPainter {
  final Color gridColor;

  _GridPatternPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

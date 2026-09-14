import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The official Taply App Branding Icon Component.
/// Renders `assets/branding/taply_icon.png` with flexible sizing, optional Taply blue background,
/// circular or rounded corner treatments, and theme compatibility.
class TaplyAppIcon extends StatelessWidget {
  final double size;
  final bool hasBackground;
  final Color? backgroundColor;
  final bool isCircular;
  final double? borderRadius;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;

  const TaplyAppIcon({
    super.key,
    this.size = 56.0,
    this.hasBackground = true,
    this.backgroundColor,
    this.isCircular = false,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(AppSpacing.xs),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final effectiveRadius = isCircular
        ? size / 2
        : (borderRadius ?? (size * 0.22));

    Widget imageWidget = Image.asset(
      'assets/branding/taply_icon.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.touch_app_rounded,
          size: size * 0.65,
          color: Colors.white,
        );
      },
    );

    if (!hasBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: imageWidget),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: [
          BoxShadow(
            color: effectiveBg.withOpacity(0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(child: imageWidget),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppIcon extends StatelessWidget {
  final String appName;
  final IconData? iconData;
  final Color? color;
  final Uint8List? iconBytes;
  final double size;
  final double borderRadius;

  const AppIcon({
    super.key,
    required this.appName,
    this.iconData,
    this.color,
    this.iconBytes,
    this.size = 44.0,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    if (iconBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          iconBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        ),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF2563EB);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveColor.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: iconData != null
            ? Icon(iconData, color: effectiveColor, size: size * 0.55)
            : Text(
                appName.isNotEmpty ? appName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: effectiveColor,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.45,
                ),
              ),
      ),
    );
  }
}

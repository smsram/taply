import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/panel_config.dart';

/// Live interactive preview of the Assistive Floating Panel.
/// Reacts dynamically to layout style changes (3x3 grid, 4x2 grid, wheel, list)
/// and color/labels preferences.
class FloatingPanelPreview extends StatelessWidget {
  final PanelConfig panelConfig;
  final Color primaryColor;

  const FloatingPanelPreview({
    super.key,
    required this.panelConfig,
    this.primaryColor = AppColors.primary,
  });

  static const List<_PreviewAction> _previewActions = [
    _PreviewAction('Back', Icons.arrow_back_rounded, Color(0xFF64748B)),
    _PreviewAction('Home', Icons.home_rounded, AppColors.primary),
    _PreviewAction('Recents', Icons.view_carousel_rounded, Color(0xFF06B6D4)),
    _PreviewAction('Lock', Icons.lock_outline_rounded, Color(0xFFEF4444)),
    _PreviewAction('Screenshot', Icons.screenshot_rounded, Color(0xFF8B5CF6)),
    _PreviewAction('Volume', Icons.volume_up_rounded, Color(0xFF10B981)),
    _PreviewAction('Brightness', Icons.brightness_6_rounded, Color(0xFFF59E0B)),
    _PreviewAction('Apps', Icons.apps_rounded, Color(0xFF14B8A6)),
    _PreviewAction('Torch', Icons.flashlight_on_rounded, Color(0xFFEAB308)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFF8FAFC),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Panel Preview',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  panelConfig.layoutStyle.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Render Selected Layout Style
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _buildLayoutContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutContent(BuildContext context) {
    switch (panelConfig.layoutStyle) {
      case PanelLayoutStyle.multiPage:
      case PanelLayoutStyle.grid4x2:
        return _build4x2Grid(context);
      case PanelLayoutStyle.grid3x3:
        return _build3x3Grid(context);
      case PanelLayoutStyle.compactWheel:
        return _buildWheelLayout(context);
      case PanelLayoutStyle.verticalList:
        return _buildVerticalList(context);
    }
  }

  Widget _build3x3Grid(BuildContext context) {
    final actions = _previewActions
        .take(panelConfig.maxActions.clamp(1, 9))
        .toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return _buildTile(context, a);
      },
    );
  }

  Widget _build4x2Grid(BuildContext context) {
    final actions = _previewActions
        .take(panelConfig.maxActions.clamp(1, 8))
        .toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return _buildTile(context, a);
      },
    );
  }

  Widget _buildWheelLayout(BuildContext context) {
    const size = 180.0;
    const centerSize = 44.0;
    final actions = _previewActions.take(6).toList();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Assistive Icon
          Container(
            width: centerSize,
            height: centerSize,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          // Radial tiles
          ...List.generate(actions.length, (i) {
            final angle = (i * 2 * math.pi / actions.length) - (math.pi / 2);
            final radius = 64.0;
            final x = radius * math.cos(angle);
            final y = radius * math.sin(angle);
            final a = actions[i];

            return Transform.translate(
              offset: Offset(x, y),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: a.color.withOpacity(0.4)),
                ),
                child: Icon(a.icon, size: 18, color: a.color),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVerticalList(BuildContext context) {
    final actions = _previewActions.take(4).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((a) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a.icon, size: 16, color: a.color),
              ),
              const SizedBox(width: 10),
              Text(
                a.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTile(BuildContext context, _PreviewAction a) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(a.icon, size: 22, color: a.color),
          if (panelConfig.showLabels) ...[
            const SizedBox(height: 4),
            Text(
              a.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewAction {
  final String name;
  final IconData icon;
  final Color color;

  const _PreviewAction(this.name, this.icon, this.color);
}

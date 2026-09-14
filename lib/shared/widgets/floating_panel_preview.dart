import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/panel_config.dart';
import '../models/system_action_catalog.dart';

/// Live interactive preview of the Assistive Floating Panel.
/// Reacts dynamically to layout style changes (3x3 grid, 4x2 grid, wheel, list)
/// and color/labels preferences.
/// and actual action order and color preferences.
class FloatingPanelPreview extends StatelessWidget {
  final PanelConfig panelConfig;
  final Color primaryColor;

  const FloatingPanelPreview({
    super.key,
    required this.panelConfig,
    this.primaryColor = AppColors.primary,
  });

  List<_PreviewAction> _getActions() {
    final rawOrder = panelConfig.actionOrder.isNotEmpty
        ? panelConfig.actionOrder
        : const [
            'back',
            'home',
            'recent_apps',
            'lock_screen',
            'screenshot',
            'volume',
            'brightness',
            'flashlight',
          ];
    return rawOrder.map((id) {
      final action = SystemActionCatalog.getAction(id);
      return _PreviewAction(action.title, action.icon, action.color);
    }).toList();
  }

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
        return _buildMultiPageCarousel(context);
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

  Widget _buildMultiPageCarousel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tabs Header
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabPill('Actions', isSelected: true),
              const SizedBox(width: 4),
              _buildTabPill('Apps', isSelected: false),
              const SizedBox(width: 4),
              _buildTabPill('Tools', isSelected: false),
              const SizedBox(width: 4),
              _buildTabPill('Controls', isSelected: false),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _build4x2Grid(context),
        const SizedBox(height: 8),
        // Footer navigation pills
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'All Apps',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Controls',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabPill(String title, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _build3x3Grid(BuildContext context) {
    final actions = _getActions()
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
    final actions = _getActions()
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
    final actions = _getActions().take(6).toList();

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
            const radius = 64.0;
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
    final actions = _getActions()
        .take(panelConfig.maxActions.clamp(1, 6))
        .toList();
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

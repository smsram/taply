import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isCompact;
  final bool isShortcut;

  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.isActive = false,
    this.isCompact = false,
    this.isShortcut = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        iconColor ??
        (isActive
            ? AppColors.secondary
            : (context.isDarkMode ? AppColors.darkPrimary : AppColors.primary));

    return Semantics(
      button: true,
      label: isShortcut ? '$title (Settings shortcut)' : title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: isCompact ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color:
                  backgroundColor ??
                  (isActive
                      ? effectiveColor.withOpacity(0.12)
                      : context.colorScheme.surface),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: isActive
                    ? effectiveColor.withOpacity(0.5)
                    : context.colorScheme.outline,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isCompact ? 36 : 42,
                  height: isCompact ? 36 : 42,
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: isCompact ? 20 : 22,
                    color: effectiveColor,
                  ),
                ),
                SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 11 : 12,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isShortcut) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 11,
                        color: AppColors.secondaryText.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

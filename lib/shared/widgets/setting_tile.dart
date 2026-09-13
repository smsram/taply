import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class SettingTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool enabled;

  const SettingTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          iconBackgroundColor ??
                          (context.isDarkMode
                              ? AppColors.darkElevatedSurface
                              : const Color(0xFFEFF6FF)),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      icon,
                      size: AppSpacing.iconMd,
                      color:
                          iconColor ??
                          (context.isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? context.colorScheme.onSurface
                              : context.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? null
                                : context.colorScheme.onSurface.withOpacity(
                                    0.3,
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.isDarkMode
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: icon != null ? 72 : AppSpacing.base,
            endIndent: AppSpacing.base,
          ),
      ],
    );
  }
}

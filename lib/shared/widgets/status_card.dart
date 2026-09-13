import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class StatusCard extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onSettingsTap;

  const StatusCard({
    super.key,
    required this.isEnabled,
    required this.onToggle,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isEnabled
            ? (context.isDarkMode
                  ? const Color(0xFF0D233A)
                  : const Color(0xFFEFF6FF))
            : context.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isEnabled
              ? (context.isDarkMode
                    ? AppColors.darkPrimary.withOpacity(0.5)
                    : AppColors.primary.withOpacity(0.35))
              : context.colorScheme.outline,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isEnabled
                  ? (context.isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.primary)
                  : context.colorScheme.onSurface.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled ? Icons.touch_app_rounded : Icons.touch_app_outlined,
              color: isEnabled
                  ? Colors.white
                  : context.colorScheme.onSurface.withOpacity(0.4),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Floating Assistant',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppColors.success.withOpacity(0.15)
                            : context.colorScheme.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isEnabled ? 'ACTIVE' : 'IDLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isEnabled
                              ? AppColors.success
                              : context.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled ? 'Taply is active' : 'Taply is disabled',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: isEnabled
                        ? (context.isDarkMode
                              ? const Color(0xFF93C5FD)
                              : AppColors.primaryDark)
                        : (context.isDarkMode
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: isEnabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

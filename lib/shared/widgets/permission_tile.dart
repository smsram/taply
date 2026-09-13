import 'package:flutter/material.dart';

import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/permission_item.dart';

class PermissionTile extends StatelessWidget {
  final PermissionItem item;
  final VoidCallback onRequest;

  const PermissionTile({
    super.key,
    required this.item,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = item.status == PermissionStatus.granted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isGranted
              ? AppColors.success.withOpacity(0.3)
              : context.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.success.withOpacity(0.12)
                      : (context.isDarkMode
                            ? AppColors.darkElevatedSurface
                            : const Color(0xFFEFF6FF)),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  item.icon,
                  size: AppSpacing.iconMd,
                  color: isGranted
                      ? AppColors.success
                      : (context.isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: context.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildStatusBadge(context, isGranted),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.description,
            style: context.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: isGranted
                ? OutlinedButton.icon(
                    onPressed: onRequest,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    label: const Text(
                      'Access Granted (Manage)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(
                        color: AppColors.success.withOpacity(0.4),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isMandatory
                          ? AppColors.primary
                          : null,
                    ),
                    child: Text(
                      item.isMandatory
                          ? 'Grant Required Access'
                          : 'Enable Access',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isGranted) {
    if (isGranted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Active',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: item.isMandatory
            ? AppColors.warning.withOpacity(0.12)
            : context.colorScheme.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.isMandatory ? 'Required' : 'Optional',
        style: TextStyle(
          color: item.isMandatory
              ? AppColors.warning
              : context.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

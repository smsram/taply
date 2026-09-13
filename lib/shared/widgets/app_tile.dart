import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/installed_app.dart';
import 'app_icon.dart';

class AppTile extends StatelessWidget {
  final InstalledApp app;
  final bool isGrid;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMoreOptions;

  const AppTile({
    super.key,
    required this.app,
    this.isGrid = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  AppIcon(
                    appName: app.appName,
                    iconData: app.defaultIcon,
                    color: app.iconColor,
                    size: 48,
                  ),
                  if (app.isFavorite)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                app.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List view tile
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            AppIcon(
              appName: app.appName,
              iconData: app.defaultIcon,
              color: app.iconColor,
              size: 42,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (app.isSystemApp) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? AppColors.darkElevatedSurface
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SYS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: context.isDarkMode
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.isDarkMode
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onFavoriteToggle != null)
              IconButton(
                icon: Icon(
                  app.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: app.isFavorite
                      ? AppColors.accent
                      : context.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: onFavoriteToggle,
                tooltip: app.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
              ),
            if (onMoreOptions != null)
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: onMoreOptions,
                tooltip: 'More options',
              ),
          ],
        ),
      ),
    );
  }
}

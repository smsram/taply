import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/native_bridge.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/installed_app.dart';
import 'app_icon.dart';

/// Modal bottom sheet providing clear distinction between Normal Launch
/// and supported Floating / Multi-window behavior.
class AppLaunchModal extends ConsumerWidget {
  final InstalledApp app;

  const AppLaunchModal({super.key, required this.app});

  static Future<void> show(BuildContext context, InstalledApp app) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppLaunchModal(app: app),
    );
  }

  void _launchNormal(BuildContext context, WidgetRef ref) {
    ref.read(appsProvider.notifier).recordLaunch(app.packageName);
    NativeBridge.instance.launchApp(app.packageName);
    Navigator.pop(context);
    context.showSnackBar('Opening ${app.appName}...');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border.all(color: context.colorScheme.outline),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        MediaQuery.of(context).padding.bottom + AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // App Header
          Row(
            children: [
              AppIcon(
                appName: app.appName,
                iconData: app.defaultIcon,
                color: app.iconColor,
                iconBytes: app.iconBytes,
                size: 52,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      app.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  app.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: app.isFavorite
                      ? AppColors.accent
                      : AppColors.secondaryText,
                  size: 26,
                ),
                tooltip: app.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () {
                  ref
                      .read(appsProvider.notifier)
                      .toggleFavorite(app.packageName);
                  Navigator.pop(context);
                  context.showSnackBar(
                    app.isFavorite
                        ? '${app.appName} removed from favorites'
                        : '${app.appName} added to favorites',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Launch Button
          ElevatedButton.icon(
            onPressed: () => _launchNormal(context, ref),
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            label: const Text('Open App'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),

          // Action Grid: Favorite, App Info, Hide, Uninstall
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(appsProvider.notifier)
                        .toggleFavorite(app.packageName);
                    Navigator.pop(context);
                    context.showSnackBar(
                      app.isFavorite
                          ? '${app.appName} removed from favorites'
                          : '${app.appName} added to favorites',
                    );
                  },
                  icon: Icon(
                    app.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: app.isFavorite ? AppColors.accent : null,
                  ),
                  label: Text(
                    app.isFavorite ? 'Unfavorite' : 'Favorite',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    NativeBridge.instance.openAppDetails(app.packageName);
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('App Info', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(appsProvider.notifier)
                        .toggleHidden(app.packageName);
                    Navigator.pop(context);
                    context.showSnackBar('${app.appName} hidden from drawer');
                  },
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Hide App', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    NativeBridge.instance.uninstallApp(app.packageName);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Uninstall',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

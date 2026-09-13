import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_launch_modal.dart';
import '../../shared/widgets/app_section.dart';

class AppOpenerScreen extends ConsumerWidget {
  const AppOpenerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appsAsync = ref.watch(appsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Launch Behavior')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // Clear Disclaimer Banner per specification
          Container(
            margin: const EdgeInsets.all(AppSpacing.base),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1E2638)
                  : const Color(0xFFFEF3C7),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: context.isDarkMode
                    ? AppColors.darkBorder
                    : AppColors.warning.withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Floating Window Support Notice',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.isDarkMode
                              ? Colors.white
                              : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Freeform floating window mode depends strictly on your Android version, OEM skin (MIUI, OneUI, ColorOS, Pixel), and whether target apps allow resizable activity flags. Fullscreen mode is always universally supported.',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Default Launch Behavior Section
          AppSection(
            title: 'Default Launch Mode',
            subtitle:
                'Default window mode applied when tapping any app in Taply',
            isCard: true,
            children: [
              RadioListTile<AppLaunchMode>(
                value: AppLaunchMode.normal,
                groupValue: settings.defaultLaunchMode,
                title: const Text(
                  'Normal (Full Screen)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Standard Android fullscreen application opening (universal compatibility)',
                ),
                onChanged: (mode) {
                  if (mode != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setDefaultLaunchMode(mode);
                  }
                },
              ),
              const Divider(),
              RadioListTile<AppLaunchMode>(
                value: AppLaunchMode.floating,
                groupValue: settings.defaultLaunchMode,
                title: const Text(
                  'Supported Floating Mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Attempts to launch app inside an Android freeform window if device supports it',
                ),
                onChanged: (mode) {
                  if (mode != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setDefaultLaunchMode(mode);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Per-Application Overrides
          AppSection(
            title: 'Per-Application Overrides',
            subtitle: 'Configure custom opening behavior for specific apps',
            children: [
              appsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (apps) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: apps.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return ListTile(
                        onTap: () => AppLaunchModal.show(context, app),
                        leading: AppIcon(
                          appName: app.appName,
                          iconData: app.defaultIcon,
                          color: app.iconColor,
                          iconBytes: app.iconBytes,
                          size: 38,
                        ),
                        title: Text(
                          app.appName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          app.launchMode == AppLaunchMode.floating
                              ? 'Floating Window (Supported)'
                              : 'Normal Full Screen',
                          style: TextStyle(
                            fontSize: 12,
                            color: app.launchMode == AppLaunchMode.floating
                                ? AppColors.secondary
                                : null,
                          ),
                        ),
                        trailing: DropdownButton<AppLaunchMode>(
                          value: app.launchMode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: AppLaunchMode.normal,
                              child: Text(
                                'Normal',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: AppLaunchMode.floating,
                              child: Text(
                                'Floating',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (newMode) {
                            if (newMode != null) {
                              ref
                                  .read(appsProvider.notifier)
                                  .updateLaunchMode(app.packageName, newMode);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

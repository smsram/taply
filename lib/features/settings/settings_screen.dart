import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/panel_config.dart';
import '../../shared/widgets/app_section.dart';
import '../../shared/widgets/setting_tile.dart';
import '../../shared/widgets/toggle_row.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Appearance & Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.system,
                groupValue: currentMode,
                title: const Text('System Default'),
                subtitle: const Text('Follows Android OS system theme'),
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.light,
                groupValue: currentMode,
                title: const Text('Light Theme'),
                subtitle: const Text('Clean daylight surface colors'),
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.dark,
                groupValue: currentMode,
                title: const Text('Dark Theme'),
                subtitle: const Text('Deep navy surface for low light'),
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.amoled,
                groupValue: currentMode,
                title: const Text('AMOLED Black'),
                subtitle: const Text('Pure #000000 pixels for battery saving'),
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final languages = [
      'System default',
      'English (US)',
      'Español',
      'Français',
      'Deutsch',
      '日本語',
      '한국어',
      'Português',
    ];
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                return ListTile(
                  title: Text(lang),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage(lang);
                    Navigator.pop(dialogContext);
                    context.showSnackBar('Language set to $lang');
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // 1. GENERAL
          AppSection(
            title: 'General',
            subtitle: 'Core application behavior and preferences',
            isCard: true,
            children: [
              ToggleRow(
                title: 'Enable Taply',
                subtitle: 'Activate the floating assistive assistant',
                icon: Icons.power_settings_new_rounded,
                value: settings.isAssistantEnabled,
                onChanged: (val) =>
                    ref.read(settingsProvider.notifier).toggleAssistant(val),
              ),
              const Divider(),
              ToggleRow(
                title: 'Start with Device',
                subtitle: 'Launch assistant automatically on system reboot',
                icon: Icons.phonelink_setup_rounded,
                value: settings.startWithDevice,
                onChanged: (val) =>
                    ref.read(settingsProvider.notifier).setStartWithDevice(val),
              ),
              const Divider(),
              SettingTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: settings.language,
                onTap: () => _showLanguageDialog(context, ref),
              ),
              SettingTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle: settings.hapticFeedback ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: settings.hapticFeedback,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .setHapticFeedback(val),
                ),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. FLOATING ASSISTANT
          AppSection(
            title: 'Floating Assistant',
            subtitle: 'Button appearance, sizing, and position snapping',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.tune_rounded,
                title: 'Button Appearance & Size',
                subtitle:
                    'Size (${settings.buttonConfig.size.toInt()}px), Opacity (${(settings.buttonConfig.opacity * 100).toInt()}%)',
                onTap: () => context.push('/customize'),
              ),
              SettingTile(
                icon: Icons.border_outer_rounded,
                title: 'Edge Snapping & Physics',
                subtitle: settings.buttonConfig.edgeSnapping
                    ? 'Snaps to screen borders'
                    : 'Free floating anywhere',
                onTap: () => context.push('/customize'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. QUICK PANEL
          AppSection(
            title: 'Quick Panel',
            subtitle: 'Customize grid dimensions and reorder tiles',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.grid_view_rounded,
                title: 'Panel Layout',
                subtitle: settings.panelConfig.layoutStyle.displayName,
                onTap: () => context.push('/customize'),
              ),
              SettingTile(
                icon: Icons.reorder_rounded,
                title: 'Action Order & App Shortcuts',
                subtitle: 'Drag and reorder items inside the floating panel',
                onTap: () => context.push('/customize'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. APPS
          AppSection(
            title: 'Applications',
            subtitle: 'App drawer options and launch behavior',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.star_rounded,
                iconColor: AppColors.accent,
                title: 'Manage Favorite Apps',
                subtitle: 'Choose apps pinned on Home and Quick Panel',
                onTap: () => context.push('/apps'),
              ),
              SettingTile(
                icon: Icons.open_in_new_rounded,
                title: 'Default Launch Behavior',
                subtitle: settings.defaultLaunchMode.name.toUpperCase(),
                onTap: () => context.push('/app-opener'),
              ),
              SettingTile(
                icon: Icons.apps_rounded,
                title: 'Open Full App Drawer',
                subtitle: 'View all installed apps with alphabetical search',
                onTap: () => context.push('/app-drawer'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. GESTURES
          AppSection(
            title: 'Gestures',
            subtitle: 'Tap, double-tap, long-press, and directional swipes',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.gesture_rounded,
                title: 'Configure Button Gestures',
                subtitle:
                    'Map single tap, double tap, and flick swipes to actions',
                onTap: () => context.push('/gestures'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 6. APPEARANCE
          AppSection(
            title: 'Appearance',
            subtitle: 'Color schemes and display modes',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.palette_rounded,
                title: 'Theme Mode',
                subtitle: _getThemeName(settings.themeMode),
                onTap: () => _showThemeDialog(context, ref, settings.themeMode),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 7. PERMISSIONS
          AppSection(
            title: 'Permissions',
            subtitle: 'Manage floating overlay and accessibility privileges',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.security_rounded,
                title: 'Permission Center',
                subtitle: 'Check and grant required Android privileges',
                onTap: () => context.push('/permissions'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 8. ABOUT
          AppSection(
            title: 'About Taply',
            subtitle: 'Version and legal information',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: AppConstants.appVersion,
                onTap: () => context.showSnackBar(
                  'Taply v${AppConstants.appVersion} (Build ${AppConstants.buildNumber})',
                ),
              ),
              SettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'No analytics tracking or data collection',
                onTap: () => context.showSnackBar(
                  'Opening Privacy Policy: ${AppConstants.privacyPolicyUrl}',
                ),
              ),
              SettingTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Standard utility terms and conditions',
                onTap: () => context.showSnackBar(
                  'Opening Terms: ${AppConstants.termsOfServiceUrl}',
                ),
              ),
              SettingTile(
                icon: Icons.code_rounded,
                title: 'Open Source Licenses',
                subtitle: 'Flutter, Material 3, Riverpod, Google Fonts',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                    applicationLegalese: 'Copyright © 2026 Taply Open Source Project.\n"Everything, one tap away."',
                  );
                },
              ),
              SettingTile(
                icon: Icons.mail_outline_rounded,
                title: 'Contact & Support',
                subtitle: AppConstants.contactEmail,
                onTap: () => context.showSnackBar(
                  'Contact email: ${AppConstants.contactEmail}',
                ),
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Theme';
      case AppThemeMode.amoled:
        return 'AMOLED Black';
    }
  }
}

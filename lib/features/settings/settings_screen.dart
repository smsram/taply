import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/widgets/app_section.dart';
import '../../shared/widgets/setting_tile.dart';
import '../../shared/widgets/taply_brand_icon.dart';
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
    final packageInfo = ref.watch(packageInfoProvider);
    final versionStr = packageInfo.when(
      data: (info) => 'Version ${info.version} • Build ${info.buildNumber}',
      loading: () =>
          'Version ${AppConstants.appVersion} • Build ${AppConstants.buildNumber}',
      error: (err, stack) =>
          'Version ${AppConstants.appVersion} • Build ${AppConstants.buildNumber}',
    );

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
                subtitle: settings.hapticFeedback
                    ? 'Subtle click vibrations on action'
                    : 'Haptics disabled',
                trailing: Switch(
                  value: settings.hapticFeedback,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .setHapticFeedback(val),
                ),
              ),
              SettingTile(
                icon: Icons.school_rounded,
                title: 'Welcome Tutorial',
                subtitle: 'Replay the 4-step introductory walkthrough',
                onTap: () => context.push('/onboarding'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. FLOATING ASSISTANT
          AppSection(
            title: 'Floating Assistant',
            subtitle: 'Control how Taply appears over other apps',
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
                    ? 'Snaps to screen borders smoothly'
                    : 'Free floating anywhere',
                onTap: () => context.push('/customize'),
              ),
              SettingTile(
                icon: Icons.open_in_browser_rounded,
                title: 'Open Floating Panel',
                subtitle: 'Preview and test the floating assistant panel',
                onTap: () => context.push('/floating-panel'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. ACCESSIBILITY & SYSTEM ACTIONS
          AppSection(
            title: 'Accessibility',
            subtitle: 'Enable supported system actions',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.accessibility_new_rounded,
                title: 'System Actions Access',
                subtitle: 'Required for Back, Home, Recents, and Lock Screen',
                onTap: () => context.push('/permissions'),
              ),
              SettingTile(
                icon: Icons.gesture_rounded,
                title: 'Button Gestures',
                subtitle: 'Map single tap, double tap, and flick swipes',
                onTap: () => context.push('/gestures'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. BATTERY & RELIABILITY
          AppSection(
            title: 'Battery',
            subtitle: 'Improve reliability on some devices',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.battery_saver_rounded,
                title: 'Battery Optimization Exemption',
                subtitle:
                    'Prevents Android OS from killing the floating service',
                onTap: () => context.push('/permissions'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. APPLICATIONS
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
                title: 'App Opener UX',
                subtitle: settings.defaultLaunchMode == AppLaunchMode.normal
                    ? 'Normal Full Screen (Universal)'
                    : 'Supported Floating Mode',
                onTap: () => context.push('/app-opener'),
              ),
              SettingTile(
                icon: Icons.apps_rounded,
                title: 'Open Full App Drawer',
                subtitle: 'Mini launcher with search and A–Z index',
                onTap: () => context.push('/app-drawer'),
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

          // 7. PRIVACY & PERMISSIONS
          AppSection(
            title: 'Privacy & Permissions',
            subtitle: 'Transparent on-device security guarantee',
            isCard: true,
            children: [
              SettingTile(
                icon: Icons.verified_user_rounded,
                title: 'Privacy Policy & Data Notice',
                subtitle: '100% on-device operation. No analytics or tracking.',
                onTap: () => context.push('/privacy-policy'),
              ),
              SettingTile(
                icon: Icons.security_rounded,
                title: 'Permission Center',
                subtitle: 'Check and manage Android OS privileges',
                onTap: () => context.push('/permissions'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 8. ABOUT TAPLY
          AppSection(
            title: 'About Taply',
            subtitle: 'Version and legal information',
            isCard: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    const TaplyAppIcon(size: 48, borderRadius: 12),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appDisplayName,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            AppConstants.appTagline,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(versionStr, style: context.textTheme.labelSmall),
                          Text(
                            'Developer: Taply Open Source Team',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.policy_rounded,
                title: 'Privacy Policy',
                subtitle: 'Zero data collection • 100% on-device',
                onTap: () => context.push('/privacy-policy'),
              ),
              SettingTile(
                icon: Icons.code_rounded,
                title: 'Open Source Licenses',
                subtitle: 'Explore dependencies and open source notices',
                onTap: () => context.push('/licenses'),
              ),
              SettingTile(
                icon: Icons.mail_outline_rounded,
                title: 'Contact & Support',
                subtitle: AppConstants.contactEmail,
                onTap: () => context.showSnackBar(
                  'Contact: ${AppConstants.contactEmail}',
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

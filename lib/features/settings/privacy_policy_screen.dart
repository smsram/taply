import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        children: [
          Center(
            child: Image.asset(
              'assets/illustrations/privacy.png',
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your Privacy is Absolute',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppConstants.appName} is designed from the ground up to respect your digital privacy.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Core Privacy Commitment Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppConstants.appName} does not require, request, or declare internet permissions (android.permission.INTERNET). It does not connect to any servers, transmit user telemetry, record analytics, or share data with third parties.',
                        style: context.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'Permissions Explained in Plain English',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Android requires special permissions for system utility features. Here is exactly what each permission does and why it is needed:',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildPermissionTile(
            context,
            icon: Icons.layers_rounded,
            title: 'Display Over Other Apps (SYSTEM_ALERT_WINDOW)',
            subtitle: 'Used solely to draw the floating assistive touch button and show the quick action panel on top of any active app. It does not inspect the contents of other apps.',
          ),
          _buildPermissionTile(
            context,
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility Service (BIND_ACCESSIBILITY_SERVICE)',
            subtitle: 'Used strictly to execute user-invoked navigation commands: Back, Home, Recent Apps, and Lock Screen. Taply NEVER reads screen text, logs keystrokes, monitors passwords, or tracks user activities.',
          ),
          _buildPermissionTile(
            context,
            icon: Icons.notifications_active_rounded,
            title: 'Notifications (POST_NOTIFICATIONS)',
            subtitle: 'Allows Android to run Taply as a foreground service with a persistent notification. This prevents the operating system from abruptly terminating the floating assistant during heavy memory pressure.',
          ),
          _buildPermissionTile(
            context,
            icon: Icons.brightness_6_rounded,
            title: 'Modify System Settings (WRITE_SETTINGS)',
            subtitle: 'Required on Android to allow the brightness slider in Quick Controls to directly alter screen brightness without opening system settings.',
          ),
          _buildPermissionTile(
            context,
            icon: Icons.battery_saver_rounded,
            title: 'Ignore Battery Optimization (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)',
            subtitle: 'Allows Taply to stay active while the device is in low-power or doze modes, ensuring the floating button responds immediately when tapped.',
          ),
          _buildPermissionTile(
            context,
            icon: Icons.camera_alt_rounded,
            title: 'Camera (CAMERA)',
            subtitle: 'Only requested when you explicitly open the QR Scanner or Screen Magnifier tool. Video frames are processed in real-time in memory and are never saved, recorded, or sent anywhere.',
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            'Local Storage & Preferences',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All configuration options, customized gestures, favorite app shortcuts, and notes are stored exclusively on your device in standard Android SharedPreferences and private app sandboxed storage. Clearing app storage or uninstalling Taply permanently removes all data.',
            style: context.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? AppColors.darkElevatedSurface
                  : const Color(0xFFF1F5F9),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Source & Auditability',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Taply is built transparently with modern standard Android architecture. You can audit the permissions requested at any time in Android System Settings.',
                  style: context.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.darkElevatedSurface
            : Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: context.isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.4,
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
    );
  }
}

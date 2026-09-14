import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  static const List<Map<String, String>> _corePackages = [
    {
      'name': 'Flutter SDK',
      'version': '3.24+',
      'license': 'BSD-3-Clause',
      'description':
          'Google UI toolkit for crafting natively compiled applications.',
    },
    {
      'name': 'flutter_riverpod',
      'version': '^2.5.1',
      'license': 'MIT',
      'description':
          'A reactive caching and state-management framework for Flutter.',
    },
    {
      'name': 'go_router',
      'version': '^14.2.0',
      'license': 'BSD-3-Clause',
      'description':
          'Declarative routing package for Flutter with deep linking support.',
    },
    {
      'name': 'shared_preferences',
      'version': '^2.2.3',
      'license': 'BSD-3-Clause',
      'description':
          'Flutter plugin for reading and writing simple key-value pairs.',
    },
    {
      'name': 'package_info_plus',
      'version': '^10.2.1',
      'license': 'BSD-3-Clause',
      'description': 'Flutter plugin for querying application package information on Android.',
    },
    {
      'name': 'mobile_scanner',
      'version': '^7.4.1',
      'license': 'BSD-3-Clause',
      'description':
          'Universal barcode and QR scanner using CameraX and ML Kit.',
    },
    {
      'name': 'qr_flutter',
      'version': '^4.1.0',
      'license': 'BSD-3-Clause',
      'description':
          'Offline QR code rendering and image generation for Flutter.',
    },
    {
      'name': 'sensors_plus',
      'version': '^6.0.0',
      'license': 'BSD-3-Clause',
      'description': 'Flutter plugin for accessing accelerometer and magnetometer sensors.',
    },
    {
      'name': 'vibration',
      'version': '^2.0.1',
      'license': 'Apache-2.0',
      'description':
          'Plugin for controlling device vibration and haptic feedback.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.source_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Built With Open Source Software',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppConstants.appName} is made possible thanks to these exceptional open source projects.',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
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
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Core Libraries',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._corePackages.map((pkg) => _buildPackageCard(context, pkg)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationLegalese:
                    'Copyright © 2026 Taply Contributors. All rights reserved.',
              );
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('View All Complete License Texts'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, String> pkg) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                pkg['name']!,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                pkg['version']!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryText.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pkg['license']!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pkg['description']!,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

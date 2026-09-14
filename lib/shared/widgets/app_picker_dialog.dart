import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../models/installed_app.dart';
import 'app_icon.dart';
import 'taply_search_bar.dart';

/// Multi-select dialog allowing users to pick favorite apps with instant search,
/// checkmarks, and batch save.
class AppPickerDialog extends ConsumerStatefulWidget {
  final List<InstalledApp> allApps;

  const AppPickerDialog({super.key, required this.allApps});

  static Future<void> show(BuildContext context, List<InstalledApp> allApps) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppPickerDialog(allApps: allApps),
    );
  }

  @override
  ConsumerState<AppPickerDialog> createState() => _AppPickerDialogState();
}

class _AppPickerDialogState extends ConsumerState<AppPickerDialog> {
  late Set<String> _selectedPackages;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedPackages = widget.allApps
        .where((a) => a.isFavorite)
        .map((a) => a.packageName)
        .toSet();
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  Future<void> _saveFavorites() async {
    await ref
        .read(appsProvider.notifier)
        .setFavorites(_selectedPackages.toList());
    if (mounted) {
      Navigator.of(context).pop();
      context.showSnackBar(
        'Favorites updated (${_selectedPackages.length} selected)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allApps.where((app) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return app.appName.toLowerCase().contains(q) ||
          app.packageName.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Favorite Apps',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_selectedPackages.length} selected for quick access',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cancel',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Search Bar
            TaplySearchBar(
              hintText: 'Search apps to pin...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
            const SizedBox(height: AppSpacing.sm),

            // App List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching apps found',
                        style: context.textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final app = filtered[index];
                        final isSelected = _selectedPackages.contains(
                          app.packageName,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(app.packageName),
                          secondary: AppIcon(
                            appName: app.appName,
                            iconData: app.defaultIcon,
                            color: app.iconColor,
                            iconBytes: app.iconBytes,
                            size: 38,
                          ),
                          title: Text(
                            app.appName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            app.packageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _saveFavorites,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Favorites'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

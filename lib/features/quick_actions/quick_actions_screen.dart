import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/services/system_action_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/quick_action.dart';

class QuickActionsScreen extends ConsumerStatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  ConsumerState<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends ConsumerState<QuickActionsScreen> {
  String _query = '';
  QuickActionCategory? _selectedCategory;

  static const List<QuickActionItem> _allActions = [
    // System Navigation
    QuickActionItem(
      id: 'back',
      title: 'Back',
      subtitle: 'Simulate system back navigation',
      icon: Icons.arrow_back_rounded,
      color: AppColors.primary,
      category: QuickActionCategory.system,
      systemAction: SystemActionType.back,
    ),
    QuickActionItem(
      id: 'home',
      title: 'Home',
      subtitle: 'Return to launcher home screen',
      icon: Icons.home_rounded,
      color: AppColors.primary,
      category: QuickActionCategory.system,
      systemAction: SystemActionType.home,
    ),
    QuickActionItem(
      id: 'recents',
      title: 'Recent Apps',
      subtitle: 'Open Android multitasking overview',
      icon: Icons.view_carousel_rounded,
      color: AppColors.primary,
      category: QuickActionCategory.system,
      systemAction: SystemActionType.recentApps,
    ),
    QuickActionItem(
      id: 'lock_screen',
      title: 'Lock Screen',
      subtitle: 'Turn off screen immediately',
      icon: Icons.lock_outline_rounded,
      color: Color(0xFFEF4444),
      category: QuickActionCategory.system,
      systemAction: SystemActionType.lockScreen,
    ),
    QuickActionItem(
      id: 'screenshot',
      title: 'Take Screenshot',
      subtitle: 'Capture active screen without physical keys',
      icon: Icons.screenshot_rounded,
      color: AppColors.accent,
      category: QuickActionCategory.system,
      systemAction: SystemActionType.screenshot,
    ),
    QuickActionItem(
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'Pull down status notification shade',
      icon: Icons.notifications_rounded,
      color: Color(0xFF8B5CF6),
      category: QuickActionCategory.system,
      systemAction: SystemActionType.openNotifications,
    ),
    QuickActionItem(
      id: 'quick_settings',
      title: 'Quick Settings',
      subtitle: 'Expand system quick settings shade',
      icon: Icons.tune_rounded,
      color: Color(0xFF0284C7),
      category: QuickActionCategory.system,
      systemAction: SystemActionType.openQuickSettings,
    ),

    // Display & Hardware
    QuickActionItem(
      id: 'flashlight',
      title: 'Torch / Flashlight',
      subtitle: 'Toggle camera LED flash',
      icon: Icons.flashlight_on_rounded,
      color: Color(0xFFF59E0B),
      category: QuickActionCategory.display,
      systemAction: SystemActionType.toggleFlashlight,
    ),
    QuickActionItem(
      id: 'brightness',
      title: 'Screen Brightness',
      subtitle: 'Control display luminosity slider',
      icon: Icons.brightness_6_rounded,
      color: Color(0xFFF97316),
      category: QuickActionCategory.display,
    ),
    QuickActionItem(
      id: 'auto_rotate',
      title: 'Auto Rotate',
      subtitle: 'Toggle orientation lock',
      icon: Icons.screen_rotation_rounded,
      color: Color(0xFF10B981),
      category: QuickActionCategory.display,
    ),

    // Sound & Media
    QuickActionItem(
      id: 'volume_up',
      title: 'Volume Up',
      subtitle: 'Increase system media audio',
      icon: Icons.volume_up_rounded,
      color: Color(0xFF06B6D4),
      category: QuickActionCategory.sound,
      systemAction: SystemActionType.volumeUp,
    ),
    QuickActionItem(
      id: 'volume_down',
      title: 'Volume Down',
      subtitle: 'Decrease system media audio',
      icon: Icons.volume_down_rounded,
      color: Color(0xFF06B6D4),
      category: QuickActionCategory.sound,
      systemAction: SystemActionType.volumeDown,
    ),
    QuickActionItem(
      id: 'mute',
      title: 'Mute / Unmute',
      subtitle: 'Toggle silent ringer mode',
      icon: Icons.volume_off_rounded,
      color: Color(0xFF64748B),
      category: QuickActionCategory.sound,
      systemAction: SystemActionType.mute,
    ),

    // Connectivity
    QuickActionItem(
      id: 'wifi',
      title: 'Wi-Fi Settings',
      subtitle: 'Open wireless networking settings',
      icon: Icons.wifi_rounded,
      color: Color(0xFF2563EB),
      category: QuickActionCategory.connectivity,
    ),
    QuickActionItem(
      id: 'bluetooth',
      title: 'Bluetooth Settings',
      subtitle: 'Manage connected audio & accessories',
      icon: Icons.bluetooth_rounded,
      color: Color(0xFF3B82F6),
      category: QuickActionCategory.connectivity,
    ),
    QuickActionItem(
      id: 'airplane',
      title: 'Airplane Mode',
      subtitle: 'System wireless radios toggle',
      icon: Icons.airplanemode_active_rounded,
      color: Color(0xFFEC4899),
      category: QuickActionCategory.connectivity,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _allActions.where((action) {
      if (_selectedCategory != null && action.category != _selectedCategory) {
        return false;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return action.title.toLowerCase().contains(q) ||
            (action.subtitle?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Actions Catalog'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search actions (e.g. Screenshot, Home)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: const Text('System'),
                  selected: _selectedCategory == QuickActionCategory.system,
                  onSelected: (_) => setState(
                    () => _selectedCategory = QuickActionCategory.system,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: const Text('Display'),
                  selected: _selectedCategory == QuickActionCategory.display,
                  onSelected: (_) => setState(
                    () => _selectedCategory = QuickActionCategory.display,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: const Text('Sound'),
                  selected: _selectedCategory == QuickActionCategory.sound,
                  onSelected: (_) => setState(
                    () => _selectedCategory = QuickActionCategory.sound,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: const Text('Connectivity'),
                  selected:
                      _selectedCategory == QuickActionCategory.connectivity,
                  onSelected: (_) => setState(
                    () => _selectedCategory = QuickActionCategory.connectivity,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching actions found',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final action = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.darkElevatedSurface
                              : Colors.white,
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: context.isDarkMode
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (action.color ?? AppColors.primary)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color ?? AppColors.primary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            action.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            action.subtitle ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.isDarkMode
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onPressed: () async {
                              if (action.systemAction != null) {
                                final service = ref.read(
                                  systemActionServiceProvider,
                                );
                                await service.executeAction(
                                  action.systemAction!,
                                );
                                if (context.mounted) {
                                  context.showSnackBar(
                                    'Executed "${action.title}"',
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  context.showSnackBar(
                                    'Action: ${action.title}',
                                  );
                                }
                              }
                            },
                            child: const Text('Test'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

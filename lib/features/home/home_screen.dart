import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/native_bridge.dart';
import '../../core/services/providers.dart';
import '../../core/services/system_action_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_section.dart';
import '../../shared/widgets/floating_button_preview.dart';
import '../../shared/widgets/quick_action_grid.dart';
import '../../shared/widgets/status_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appsAsync = ref.watch(appsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Your quick-access assistant',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.isDarkMode
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/quick-controls'),
            tooltip: 'Quick Controls',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.sm),

          // 1. MAIN STATUS SECTION (Floating Assistant [ON / OFF])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: StatusCard(
              isEnabled: settings.isAssistantEnabled,
              onToggle: (enabled) {
                ref.read(settingsProvider.notifier).toggleAssistant(enabled);
                context.showSnackBar(
                  enabled
                      ? 'Taply floating assistant enabled'
                      : 'Taply floating assistant disabled',
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. FLOATING BUTTON PREVIEW & CUSTOMIZATION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: FloatingButtonPreview(
              config: settings.buttonConfig,
              isEnabled: settings.isAssistantEnabled,
              onCustomizeTap: () => context.go('/customize'),
              onButtonTap: () => context.push('/floating-panel'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. QUICK ACTIONS (Grid of 8 required actions)
          AppSection(
            title: 'Quick Actions',
            subtitle: 'Immediate system shortcuts',
            trailing: TextButton(
              onPressed: () => context.push('/quick-controls'),
              child: const Text('View All'),
            ),
            children: [
              QuickActionGrid(
                actions: [
                  QuickActionItemData(
                    id: 'lock',
                    title: 'Lock Screen',
                    icon: Icons.lock_outline_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      ref
                          .read(systemActionServiceProvider)
                          .executeAction(SystemActionType.lockScreen);
                      context.showSnackBar('Screen locked');
                    },
                  ),
                  QuickActionItemData(
                    id: 'volume',
                    title: 'Volume',
                    icon: Icons.volume_up_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/quick-controls'),
                  ),
                  QuickActionItemData(
                    id: 'brightness',
                    title: 'Brightness',
                    icon: Icons.brightness_6_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push('/quick-controls'),
                  ),
                  QuickActionItemData(
                    id: 'screenshot',
                    title: 'Screenshot',
                    icon: Icons.screenshot_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      ref
                          .read(systemActionServiceProvider)
                          .executeAction(SystemActionType.screenshot);
                      context.showSnackBar('Taking screenshot...');
                    },
                  ),
                  QuickActionItemData(
                    id: 'home',
                    title: 'Home',
                    icon: Icons.home_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      ref
                          .read(systemActionServiceProvider)
                          .executeAction(SystemActionType.home);
                      context.showSnackBar('Home pressed');
                    },
                  ),
                  QuickActionItemData(
                    id: 'back',
                    title: 'Back',
                    icon: Icons.arrow_back_rounded,
                    color: const Color(0xFF64748B),
                    onTap: () {
                      ref
                          .read(systemActionServiceProvider)
                          .executeAction(SystemActionType.back);
                      context.showSnackBar('Back pressed');
                    },
                  ),
                  QuickActionItemData(
                    id: 'recents',
                    title: 'Recent Apps',
                    icon: Icons.view_carousel_rounded,
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      ref
                          .read(systemActionServiceProvider)
                          .executeAction(SystemActionType.recentApps);
                      context.showSnackBar('Recent apps opened');
                    },
                  ),
                  QuickActionItemData(
                    id: 'apps',
                    title: 'Apps',
                    icon: Icons.apps_rounded,
                    color: const Color(0xFF14B8A6),
                    onTap: () => context.go('/apps'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. FAVORITE APPS
          appsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const SizedBox(),
            data: (apps) {
              final favorites = apps
                  .where((a) => a.isFavorite && !a.isHidden)
                  .toList();

              return AppSection(
                title: 'Favorite Apps',
                subtitle: 'Pinned for rapid one-touch opening',
                trailing: TextButton(
                  onPressed: () => context.go('/apps'),
                  child: const Text('Manage'),
                ),
                children: [
                  if (favorites.isNotEmpty)
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: favorites.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final app = favorites[index];
                          return _buildFavoriteAppItem(context, ref, app);
                        },
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_border_rounded,
                              color: AppColors.accent,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No favorite apps yet',
                                    style: context.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Add your most-used apps for faster access.',
                                    style: context.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => context.go('/apps'),
                              child: const Text('Add Apps'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. RECENTLY USED
          appsAsync.when(
            loading: () => const SizedBox(),
            error: (err, stack) => const SizedBox(),
            data: (apps) {
              final recents =
                  apps
                      .where((a) => a.lastUsedAt != null && !a.isHidden)
                      .toList()
                    ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

              return AppSection(
                title: 'Recently Used',
                subtitle: 'Apps recently launched via Taply',
                children: [
                  if (recents.isNotEmpty)
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recents.take(3).length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final app = recents[index];
                          return ListTile(
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
                              ),
                            ),
                            subtitle: Text(
                              'Opened ${_timeAgo(app.lastUsedAt!)}',
                            ),
                            trailing: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            onTap: () {
                              ref
                                  .read(appsProvider.notifier)
                                  .recordLaunch(app.packageName);
                              NativeBridge.instance.launchApp(app.packageName);
                              context.showSnackBar('Opening ${app.appName}...');
                            },
                          );
                        },
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: context.colorScheme.onSurface
                                    .withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_rounded,
                                color: context.colorScheme.onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No recent apps',
                                    style: context.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your recently used apps will appear here.',
                                    style: context.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteAppItem(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) {
    return InkWell(
      onTap: () {
        ref.read(appsProvider.notifier).recordLaunch(app.packageName);
        NativeBridge.instance.launchApp(app.packageName);
        context.showSnackBar('Opening ${app.appName}...');
      },
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              appName: app.appName,
              iconData: app.defaultIcon,
              color: app.iconColor,
              iconBytes: app.iconBytes,
              size: 48,
            ),
            const SizedBox(height: 4),
            Text(
              app.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

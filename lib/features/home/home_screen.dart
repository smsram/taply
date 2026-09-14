import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/native_bridge.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/floating_button_config.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/models/system_action_catalog.dart';
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
    final allApps = appsAsync.asData?.value ?? [];
    final favorites = allApps
        .where((a) => a.isFavorite && !a.isHidden)
        .toList();
    final recents =
        allApps.where((a) => a.lastUsedAt != null && !a.isHidden).toList()
          ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

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
            tooltip: context.loc.quickControls,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: context.loc.settings,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.sm),

          // 1. MAIN STATUS SECTION (Floating Assistant [ON / OFF])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: StatusCard(
              isEnabled: settings.isAssistantEnabled,
              icon: settings.buttonConfig.iconStyle.icon,
              customColor: settings.buttonConfig.customColor,
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
          // 3. QUICK ACTIONS (Dynamic actions from configured actionOrder)
          AppSection(
            title:
                context.loc.quickActions != 'quickActions' &&
                    context.loc.quickActions.isNotEmpty
                ? context.loc.quickActions
                : 'Quick Actions',
            subtitle: 'Immediate system shortcuts',
            trailing: TextButton(
              onPressed: () => context.push('/quick-controls'),
              child: const Text('View All'),
            ),
            children: [
              QuickActionGrid(
                actions:
                    (settings.panelConfig.actionOrder.isNotEmpty
                            ? settings.panelConfig.actionOrder.take(8)
                            : const [
                                'lock_screen',
                                'volume',
                                'brightness',
                                'screenshot',
                                'home',
                                'back',
                                'recent_apps',
                                'flashlight',
                              ])
                        .map((actionId) {
                          final action = SystemActionCatalog.getAction(
                            actionId,
                          );
                          return QuickActionItemData(
                            id: action.id,
                            title: action.title,
                            icon: action.icon,
                            color: action.color,
                            onTap: () async {
                              if (action.toolRoute != null) {
                                context.push(action.toolRoute!);
                              } else if (action.systemAction != null) {
                                await ref
                                    .read(systemActionServiceProvider)
                                    .executeAction(action.systemAction!);
                                if (context.mounted) {
                                  context.showSnackBar(
                                    '${action.title} executed',
                                  );
                                }
                              }
                            },
                          );
                        })
                        .toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. FAVORITE APPS
          AppSection(
            title: context.loc.favoriteApps,
            subtitle: 'Pinned for rapid one-touch opening',
            trailing: TextButton(
              onPressed: () => context.go('/apps'),
              child: const Text('Manage'),
            ),
            children: [
              if (appsAsync.isLoading && !appsAsync.hasValue)
                const SizedBox(
                  height: 94,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (appsAsync.hasError && !appsAsync.hasValue)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Failed to load apps',
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.read(appsProvider.notifier).refreshApps(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. RECENTLY USED
          AppSection(
            title: context.loc.recentlyUsed,
            subtitle: 'Apps recently launched via Taply',
            children: [
              if (appsAsync.isLoading && !appsAsync.hasValue)
                const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (appsAsync.hasError && !appsAsync.hasValue)
                const SizedBox()
              else ...[
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Opened ${_timeAgo(app.lastUsedAt!)}'),
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
                              color: context.colorScheme.onSurface.withOpacity(
                                0.06,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              color: context.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No recent apps',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
            ],
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

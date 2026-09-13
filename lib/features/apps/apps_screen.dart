import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/widgets/app_section.dart';
import '../../shared/widgets/app_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/taply_search_bar.dart';

class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key});

  @override
  ConsumerState<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> {
  String _searchQuery = '';
  bool _isGridView = true;
  String? _selectedAlphabet;
  final ScrollController _scrollController = ScrollController();

  final List<String> _alphabetList = List.generate(
    26,
    (index) => String.fromCharCode(65 + index),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onAppTap(InstalledApp app) {
    ref.read(appsProvider.notifier).recordLaunch(app.packageName);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    app.defaultIcon,
                    color: app.iconColor,
                    size: 36,
                  ),
                  title: Text(
                    app.appName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(app.packageName),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.launch_rounded),
                  title: const Text('Open Application'),
                  subtitle: const Text('Normal full-screen launch'),
                  onTap: () {
                    Navigator.pop(context);
                    context.showSnackBar(
                      'Launching ${app.appName} (Phase 2 Native PackageManager)',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_in_picture_alt_rounded),
                  title: const Text('Open in Floating Window'),
                  subtitle: const Text('Floating / Freeform window mode'),
                  onTap: () {
                    Navigator.pop(context);
                    context.showSnackBar(
                      'Freeform mode check: depends on OS support in Phase 2',
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    app.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                  ),
                  title: Text(
                    app.isFavorite
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(appsProvider.notifier)
                        .toggleFavorite(app.packageName);
                  },
                ),
                ListTile(
                  leading: Icon(
                    app.isHidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  title: Text(
                    app.isHidden ? 'Unhide App' : 'Hide from Taply Drawer',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(appsProvider.notifier)
                        .toggleHidden(app.packageName);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps'),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_full_rounded),
            onPressed: () => context.push('/app-drawer'),
            tooltip: 'Dedicated App Drawer',
          ),
        ],
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading apps: $err')),
        data: (allApps) {
          if (allApps.isEmpty) {
            return const EmptyState(
              icon: Icons.apps_outage_rounded,
              title: 'No applications found',
              message:
                  'No installed applications could be queried on this device.',
            );
          }

          // Filter by search query
          final filteredApps = allApps.where((app) {
            final matchesQuery =
                app.appName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                app.packageName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            if (_searchQuery.isNotEmpty) return matchesQuery;
            return matchesQuery && !app.isHidden;
          }).toList();

          if (_searchQuery.isNotEmpty && filteredApps.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: TaplySearchBar(
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
                Expanded(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No search results',
                    message:
                        'No applications match "$_searchQuery". Check spelling or unhide app.',
                  ),
                ),
              ],
            );
          }

          // Sort alphabetically
          filteredApps.sort(
            (a, b) =>
                a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
          );

          // If searching, show direct list/grid
          if (_searchQuery.isNotEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: TaplySearchBar(
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
                Expanded(child: _buildAppCollection(filteredApps)),
              ],
            );
          }

          // Normal sections: Favorites, Recently Used, All Apps
          final favoriteApps = filteredApps.where((a) => a.isFavorite).toList();
          final recentApps =
              filteredApps.where((a) => a.lastUsedAt != null).toList()
                ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.sm,
                  AppSpacing.base,
                  AppSpacing.xs,
                ),
                child: TaplySearchBar(
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Main Scrollable App Content
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        children: [
                          // Favorites Section
                          if (favoriteApps.isNotEmpty)
                            AppSection(
                              title: 'Favorites',
                              subtitle:
                                  '${favoriteApps.length} quick access applications',
                              children: [_buildAppCollection(favoriteApps)],
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.base),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.base,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_outline_rounded,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          'No favorite apps yet. Tap the star icon on any app to pin it here.',
                                          style: context.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Recently Used Section
                          if (recentApps.isNotEmpty)
                            AppSection(
                              title: 'Recently Used',
                              subtitle: 'Apps launched through Taply',
                              children: [
                                _buildAppCollection(
                                  recentApps.take(4).toList(),
                                ),
                              ],
                            ),

                          // All Apps Section (Alphabetically grouped)
                          AppSection(
                            title: 'All Applications',
                            subtitle:
                                '${filteredApps.length} total installed apps',
                            children: [_buildAppCollection(filteredApps)],
                          ),
                        ],
                      ),
                    ),

                    // Alphabetical index sidebar
                    Container(
                      width: 28,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: ListView.builder(
                        itemCount: _alphabetList.length,
                        itemBuilder: (context, idx) {
                          final letter = _alphabetList[idx];
                          final isSelected = _selectedAlphabet == letter;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedAlphabet = letter);
                              // Scroll to letter section
                              context.showSnackBar(
                                'Jumped to section: $letter',
                              );
                            },
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.colorScheme.onSurface
                                            .withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppCollection(List<InstalledApp> apps) {
    if (_isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.isSmallPhone ? 3 : 4,
          childAspectRatio: 0.9,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return AppTile(
            app: app,
            isGrid: true,
            onTap: () => _onAppTap(app),
            onFavoriteToggle: () {
              ref.read(appsProvider.notifier).toggleFavorite(app.packageName);
            },
          );
        },
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return AppTile(
          app: app,
          isGrid: false,
          onTap: () => _onAppTap(app),
          onFavoriteToggle: () {
            ref.read(appsProvider.notifier).toggleFavorite(app.packageName);
          },
        );
      },
    );
  }
}

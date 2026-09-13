import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_launch_modal.dart';
import '../../shared/widgets/app_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/taply_search_bar.dart';

class AppDrawerScreen extends ConsumerStatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  ConsumerState<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends ConsumerState<AppDrawerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isGrid = true;
  String? _selectedAlphabet;

  final List<String> _alphabet = List.generate(
    26,
    (index) => String.fromCharCode(65 + index),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter, List<InstalledApp> apps) {
    setState(() => _selectedAlphabet = letter);
    final targetIndex = apps.indexWhere(
      (a) => a.appName.toUpperCase().startsWith(letter),
    );
    if (targetIndex != -1 && _scrollController.hasClients) {
      // Approximate offset per item
      final estimatedOffset = targetIndex * (_isGrid ? 80.0 : 64.0);
      _scrollController.animateTo(
        estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Drawer'),
        actions: [
          IconButton(
            icon: Icon(
              _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: _isGrid ? 'Switch to list view' : 'Switch to grid view',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.xs,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: TaplySearchBar(
                controller: _searchController,
                hintText: 'Search applications...',
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),

            // Content Area
            Expanded(
              child: appsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading applications: $err')),
                data: (allApps) {
                  final activeApps = allApps.where((a) => !a.isHidden).toList();

                  // When searching: flat sorted list
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final searchResults =
                        activeApps.where((a) {
                          return a.appName.toLowerCase().contains(query) ||
                              a.packageName.toLowerCase().contains(query);
                        }).toList()..sort(
                          (a, b) => a.appName.toLowerCase().compareTo(
                            b.appName.toLowerCase(),
                          ),
                        );

                    if (searchResults.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No applications found',
                        message: 'No apps match "$_searchQuery"',
                        actionLabel: 'Clear Search',
                        onAction: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      );
                    }

                    return _buildAppView(searchResults);
                  }

                  // Default Mini-Launcher Layout
                  final favorites = activeApps
                      .where((a) => a.isFavorite)
                      .toList();
                  final recents =
                      activeApps.where((a) => a.lastUsedAt != null).toList()
                        ..sort(
                          (a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!),
                        );
                  final sortedAll = List<InstalledApp>.from(activeApps)
                    ..sort(
                      (a, b) => a.appName.toLowerCase().compareTo(
                        b.appName.toLowerCase(),
                      ),
                    );

                  return Row(
                    children: [
                      // Main Scrollable Launcher
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xxl,
                          ),
                          children: [
                            // 1. Favorites Section
                            if (favorites.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.base,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Favorites',
                                      style: context.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      '${favorites.length} pinned',
                                      style: context.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                height: 86,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.base,
                                  ),
                                  itemCount: favorites.length,
                                  itemBuilder: (context, index) {
                                    final app = favorites[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: AppSpacing.md,
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            AppLaunchModal.show(context, app),
                                        borderRadius: AppSpacing.borderRadiusMd,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AppIcon(
                                              appName: app.appName,
                                              iconData: app.defaultIcon,
                                              color: app.iconColor,
                                              iconBytes: app.iconBytes,
                                              size: 44,
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 56,
                                              child: Text(
                                                app.appName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: context
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // 2. Recently Used Section
                            if (recents.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.base,
                                ),
                                child: Text(
                                  'Recently Used',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                height: 86,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.base,
                                  ),
                                  itemCount: recents.take(8).length,
                                  itemBuilder: (context, index) {
                                    final app = recents[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: AppSpacing.md,
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            AppLaunchModal.show(context, app),
                                        borderRadius: AppSpacing.borderRadiusMd,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AppIcon(
                                              appName: app.appName,
                                              iconData: app.defaultIcon,
                                              color: app.iconColor,
                                              iconBytes: app.iconBytes,
                                              size: 44,
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 56,
                                              child: Text(
                                                app.appName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: context
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // 3. All Applications Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.base,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'All Applications',
                                    style: context.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${sortedAll.length} apps',
                                    style: context.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // 4. All Apps Collection
                            _buildAppCollection(sortedAll),
                          ],
                        ),
                      ),

                      // Alphabet Index Scrubber Strip on the right
                      Container(
                        width: 22,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _alphabet.map((letter) {
                            final isSelected = _selectedAlphabet == letter;
                            return InkWell(
                              onTap: () => _scrollToLetter(letter, sortedAll),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1.0,
                                ),
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
                                              .withOpacity(0.4),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppView(List<InstalledApp> apps) {
    return _isGrid
        ? GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.isSmallPhone ? 3 : 4,
              childAspectRatio: 0.88,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return AppTile(
                app: app,
                isGrid: true,
                onTap: () => AppLaunchModal.show(context, app),
              );
            },
          )
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return AppTile(
                app: app,
                isGrid: false,
                onTap: () => AppLaunchModal.show(context, app),
              );
            },
          );
  }

  Widget _buildAppCollection(List<InstalledApp> apps) {
    if (_isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.base),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.isSmallPhone ? 3 : 4,
          childAspectRatio: 0.88,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return AppTile(
            app: app,
            isGrid: true,
            onTap: () => AppLaunchModal.show(context, app),
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
          onTap: () => AppLaunchModal.show(context, app),
        );
      },
    );
  }
}

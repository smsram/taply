import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/taply_search_bar.dart';

class AppDrawerScreen extends ConsumerStatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  ConsumerState<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends ConsumerState<AppDrawerScreen> {
  String _searchQuery = '';
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF070C15)
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('App Drawer'),
        actions: [
          IconButton(
            icon: Icon(
              _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: TaplySearchBar(
                hintText: 'Search applications...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: appsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (apps) {
                  final filtered =
                      apps.where((a) {
                        return !a.isHidden &&
                            (a.appName.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                a.packageName.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ));
                      }).toList()..sort(
                        (a, b) => a.appName.toLowerCase().compareTo(
                          b.appName.toLowerCase(),
                        ),
                      );

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No apps found',
                      message: 'No apps matching "$_searchQuery"',
                    );
                  }

                  return _isGrid
                      ? GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: context.isSmallPhone ? 3 : 4,
                                childAspectRatio: 0.88,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final app = filtered[index];
                            return AppTile(
                              app: app,
                              isGrid: true,
                              onTap: () {
                                ref
                                    .read(appsProvider.notifier)
                                    .recordLaunch(app.packageName);
                                Navigator.pop(context);
                                context.showSnackBar(
                                  'Opening ${app.appName} (Phase 2 Native)',
                                );
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final app = filtered[index];
                            return AppTile(
                              app: app,
                              isGrid: false,
                              onTap: () {
                                ref
                                    .read(appsProvider.notifier)
                                    .recordLaunch(app.packageName);
                                Navigator.pop(context);
                                context.showSnackBar(
                                  'Opening ${app.appName} (Phase 2 Native)',
                                );
                              },
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

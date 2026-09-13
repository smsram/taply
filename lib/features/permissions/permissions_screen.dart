import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/permission_service.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/permission_tile.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Center')),
      body: permissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          final grantedCount = items
              .where((i) => i.status == PermissionStatus.granted)
              .length;
          final totalCount = items.length;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              // Summary Progress Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkElevatedSurface
                      : const Color(0xFFEFF6FF),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: context.isDarkMode
                        ? AppColors.darkBorder
                        : AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'System Access Status',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$grantedCount / $totalCount Active',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? grantedCount / totalCount : 0,
                        minHeight: 6,
                        backgroundColor: context.isDarkMode
                            ? AppColors.darkBorder
                            : AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Taply requires specialized Android system privileges to render on top of apps and simulate navigation keys reliably.',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'PRIVILEGES & ACCESS',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Permissions List
              ...items.map((item) {
                return PermissionTile(
                  item: item,
                  onRequest: () async {
                    await ref
                        .read(permissionsProvider.notifier)
                        .request(item.type);
                    if (context.mounted) {
                      context.showSnackBar(
                        'Opening settings for ${item.title}...',
                      );
                    }
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

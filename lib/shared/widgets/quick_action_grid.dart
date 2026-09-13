import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import 'action_tile.dart';

class QuickActionItemData {
  final String id;
  final String title;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const QuickActionItemData({
    required this.id,
    required this.title,
    required this.icon,
    this.color,
    required this.onTap,
  });
}

class QuickActionGrid extends StatelessWidget {
  final List<QuickActionItemData> actions;
  final int crossAxisCount;

  const QuickActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColumns = context.isSmallPhone ? 3 : crossAxisCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveColumns,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.05,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return ActionTile(
          title: action.title,
          icon: action.icon,
          iconColor: action.color,
          onTap: action.onTap,
        );
      },
    );
  }
}

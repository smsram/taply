import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/gesture_action.dart';
import '../../shared/widgets/app_section.dart';

class GesturesScreen extends ConsumerWidget {
  const GesturesScreen({super.key});

  void _showActionPicker(
    BuildContext context,
    WidgetRef ref,
    GestureTrigger trigger,
    GestureBinding currentBinding,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(trigger.icon, color: AppColors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Assign Action to ${trigger.displayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  trigger.description,
                  style: sheetContext.textTheme.bodySmall,
                ),
                const Divider(height: AppSpacing.lg),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: GestureActionTarget.values.map((target) {
                      final isSelected = currentBinding.target == target;

                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.12)
                                : sheetContext.colorScheme.onSurface
                                      .withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            target.icon,
                            size: 18,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        title: Text(
                          target.displayName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          ref
                              .read(gesturesProvider.notifier)
                              .updateBinding(trigger, target);
                          Navigator.pop(sheetContext);
                          context.showSnackBar(
                            '${trigger.displayName} set to ${target.displayName}',
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = ref.watch(gesturesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Floating Gestures')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(AppSpacing.base),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? AppColors.darkElevatedSurface
                  : const Color(0xFFEFF6FF),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: context.isDarkMode
                    ? AppColors.darkBorder
                    : AppColors.primary.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.gesture_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Trigger shortcuts instantly without opening menus by tapping or flicking the floating button.',
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Tap Gestures
          AppSection(
            title: 'Tap & Press Triggers',
            subtitle: 'Direct touch interactions on the floating button',
            isCard: true,
            children: [
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.singleTap,
                bindings[GestureTrigger.singleTap]!,
              ),
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.doubleTap,
                bindings[GestureTrigger.doubleTap]!,
              ),
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.longPress,
                bindings[GestureTrigger.longPress]!,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Swipe Gestures
          AppSection(
            title: 'Directional Swipe Triggers',
            subtitle:
                'Flick gestures from the button towards any screen direction',
            isCard: true,
            children: [
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.swipeUp,
                bindings[GestureTrigger.swipeUp]!,
              ),
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.swipeDown,
                bindings[GestureTrigger.swipeDown]!,
              ),
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.swipeLeft,
                bindings[GestureTrigger.swipeLeft]!,
              ),
              _buildGestureTile(
                context,
                ref,
                GestureTrigger.swipeRight,
                bindings[GestureTrigger.swipeRight]!,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGestureTile(
    BuildContext context,
    WidgetRef ref,
    GestureTrigger trigger,
    GestureBinding binding, {
    bool isLast = false,
  }) {
    final target = binding.target;
    final isNone = target == GestureActionTarget.none;

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(trigger.icon, size: 20),
          ),
          title: Text(
            trigger.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            trigger.description,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isNone
                  ? context.colorScheme.onSurface.withOpacity(0.06)
                  : AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  target.icon,
                  size: 14,
                  color: isNone
                      ? context.colorScheme.onSurface.withOpacity(0.4)
                      : AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  target.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isNone
                        ? context.colorScheme.onSurface.withOpacity(0.5)
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _showActionPicker(context, ref, trigger, binding),
        ),
        if (!isLast) const Divider(height: 1, indent: 64),
      ],
    );
  }
}

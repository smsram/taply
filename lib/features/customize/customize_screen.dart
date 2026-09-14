import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/floating_button_config.dart';
import '../../shared/models/panel_config.dart';
import '../../shared/models/system_action_catalog.dart';
import '../../shared/widgets/app_section.dart';
import '../../shared/widgets/floating_button_preview.dart';
import '../../shared/widgets/floating_panel_preview.dart';
import '../../shared/widgets/slider_row.dart';
import '../../shared/widgets/toggle_row.dart';

class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  void _showAddActionSheet(BuildContext context, PanelConfig panelConfig) {
    final available = SystemActionCatalog.getAvailableActionsToAdd(
      panelConfig.actionOrder,
    );

    if (available.isEmpty) {
      context.showSnackBar('All available actions have already been added');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Action to Panel',
                            style: sheetContext.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose an action to add to your quick panel',
                            style: sheetContext.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: available.length,
                    padding: const EdgeInsets.only(bottom: AppSpacing.base),
                    itemBuilder: (context, index) {
                      final action = available[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: action.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          action.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          action.subtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          final updated = List<String>.from(
                            panelConfig.actionOrder,
                          )..add(action.id);
                          ref
                              .read(settingsProvider.notifier)
                              .updatePanelConfig(
                                panelConfig.copyWith(actionOrder: updated),
                              );
                          context.showSnackBar('Added ${action.title}');
                        },
                      );
                    },
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
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final buttonConfig = settings.buttonConfig;
    final panelConfig = settings.panelConfig;

    return Scaffold(
      appBar: AppBar(title: const Text('Customize')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // Live Floating Button Preview
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: FloatingButtonPreview(
              config: buttonConfig,
              isEnabled: settings.isAssistantEnabled,
            ),
          ),

          // 1. FLOATING BUTTON APPEARANCE
          AppSection(
            title: 'Floating Button',
            subtitle: 'Size, opacity, and touch physics',
            isCard: true,
            children: [
              SliderRow(
                title: 'Button Size',
                subtitle: 'Physical footprint on your screen',
                leadingIcon: Icons.photo_size_select_small_rounded,
                value: buttonConfig.size,
                min: 42.0,
                max: 72.0,
                divisions: 15,
                valueFormatter: (val) => '${val.toInt()} px',
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateButtonConfig(buttonConfig.copyWith(size: val));
                },
              ),
              SliderRow(
                title: 'Active Opacity',
                subtitle: 'Transparency level when interacting',
                leadingIcon: Icons.opacity_rounded,
                value: buttonConfig.opacity,
                min: 0.2,
                max: 1.0,
                divisions: 16,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateButtonConfig(buttonConfig.copyWith(opacity: val));
                },
              ),
              SliderRow(
                title: 'Idle Opacity',
                subtitle: 'Transparency when not being touched',
                leadingIcon: Icons.blur_on_rounded,
                value: buttonConfig.idleOpacity,
                min: 0.1,
                max: 0.9,
                divisions: 16,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateButtonConfig(
                        buttonConfig.copyWith(idleOpacity: val),
                      );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inactivity Auto-Dim',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Fade button when not touched',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: context.isDarkMode
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DropdownButton<int>(
                      value:
                          [
                            0,
                            3,
                            5,
                            10,
                            20,
                            30,
                          ].contains(buttonConfig.idleTimeoutSeconds)
                          ? buttonConfig.idleTimeoutSeconds
                          : 10,
                      underline: const SizedBox.shrink(),
                      borderRadius: AppSpacing.borderRadiusMd,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Never')),
                        DropdownMenuItem(value: 3, child: Text('After 3s')),
                        DropdownMenuItem(value: 5, child: Text('After 5s')),
                        DropdownMenuItem(value: 10, child: Text('After 10s')),
                        DropdownMenuItem(value: 20, child: Text('After 20s')),
                        DropdownMenuItem(value: 30, child: Text('After 30s')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateButtonConfig(
                                buttonConfig.copyWith(
                                  idleTimeoutSeconds: val,
                                  autoHideIdle: val > 0,
                                ),
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              ToggleRow(
                title: 'Edge Snapping',
                subtitle:
                    'Automatically snap button to screen borders when released',
                icon: Icons.border_vertical_rounded,
                value: buttonConfig.edgeSnapping,
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateButtonConfig(
                        buttonConfig.copyWith(edgeSnapping: val),
                      );
                },
              ),
              ToggleRow(
                title: 'Haptic Touch Feedback',
                subtitle: 'Vibrate lightly on button tap and drag snap',
                icon: Icons.vibration_rounded,
                value: buttonConfig.hapticFeedback,
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateButtonConfig(
                        buttonConfig.copyWith(hapticFeedback: val),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. BRAND COLOR PALETTE
          AppSection(
            title: 'Accent Color',
            subtitle: 'Choose from 7 curated Taply brand color schemes',
            isCard: true,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: FloatingButtonConfig.supportedColors.map((color) {
                    final isSelected =
                        buttonConfig.customColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .updateButtonConfig(
                              buttonConfig.copyWith(customColor: color),
                            );
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (context.isDarkMode
                                      ? Colors.white
                                      : Colors.black87)
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. ICON STYLE
          AppSection(
            title: 'Icon & Graphic Style',
            subtitle: 'Visual identity of the floating badge',
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: ButtonIconStyle.values.map((style) {
                    final isSelected = buttonConfig.iconStyle == style;

                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .updateButtonConfig(
                              buttonConfig.copyWith(iconStyle: style),
                            );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (context.isDarkMode
                                    ? buttonConfig.customColor.withOpacity(0.2)
                                    : buttonConfig.customColor.withOpacity(0.1))
                              : context.colorScheme.surface,
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: isSelected
                                ? buttonConfig.customColor
                                : context.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              style.icon,
                              size: 28,
                              color: isSelected
                                  ? buttonConfig.customColor
                                  : context.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              style.displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? buttonConfig.customColor
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Live Floating Panel Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: FloatingPanelPreview(
              panelConfig: panelConfig,
              primaryColor: buttonConfig.customColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. PANEL LAYOUT
          // 4. PANEL LAYOUT
          AppSection(
            title: 'Assistive Panel Layout',
            subtitle: 'Arrangement when the floating menu is opened',
            isCard: true,
            children: [
              ...PanelLayoutStyle.values.map((layout) {
                return RadioListTile<PanelLayoutStyle>(
                  value: layout,
                  groupValue: panelConfig.layoutStyle,
                  title: Text(
                    layout.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(layout.description),
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updatePanelConfig(
                            panelConfig.copyWith(layoutStyle: val),
                          );
                    }
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. ACTION REORDERING (Drag and Drop Ordering)
          // 5. ACTION REORDERING & ADD/REMOVE
          AppSection(
            title: 'Panel Action Order',
            subtitle: 'Drag items to reorder or add/remove shortcuts',
            trailing: TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              onPressed: () => _showAddActionSheet(context, panelConfig),
            ),
            isCard: true,
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: panelConfig.actionOrder.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final updated = List<String>.from(panelConfig.actionOrder);
                  final item = updated.removeAt(oldIndex);
                  updated.insert(newIndex, item);
                  ref
                      .read(settingsProvider.notifier)
                      .updatePanelConfig(
                        panelConfig.copyWith(actionOrder: updated),
                      );
                },
                itemBuilder: (context, index) {
                  final actionId = panelConfig.actionOrder[index];
                  final action = SystemActionCatalog.getAction(actionId);

                  return ListTile(
                    key: ValueKey(actionId),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(action.icon, color: action.color, size: 20),
                    ),
                    title: Text(
                      action.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      action.subtitle,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (panelConfig.actionOrder.length > 2)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            tooltip: 'Remove action',
                            onPressed: () {
                              final updated = List<String>.from(
                                panelConfig.actionOrder,
                              )..removeAt(index);
                              ref
                                  .read(settingsProvider.notifier)
                                  .updatePanelConfig(
                                    panelConfig.copyWith(actionOrder: updated),
                                  );
                            },
                          ),
                        const Icon(
                          Icons.drag_handle_rounded,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add More Actions'),
                    onPressed: () => _showAddActionSheet(context, panelConfig),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

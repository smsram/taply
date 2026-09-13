import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/tool_item.dart';
import '../../shared/widgets/app_section.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  List<ToolItem> get _tools => const [
    // Daily Utilities
    ToolItem(
      id: 'calculator',
      name: 'Calculator',
      description: 'Standard arithmetic calculations with precision',
      icon: Icons.calculate_rounded,
      iconColor: Color(0xFF10B981),
      category: ToolCategory.utilities,
      isImplementedInPhase1: true,
      routePath: '/tools/calculator',
    ),
    ToolItem(
      id: 'timer',
      name: 'Timer',
      description: 'Countdown presets and custom interval timer',
      icon: Icons.hourglass_bottom_rounded,
      iconColor: Color(0xFF3B82F6),
      category: ToolCategory.utilities,
      isImplementedInPhase1: true,
      routePath: '/tools/timer',
    ),
    ToolItem(
      id: 'stopwatch',
      name: 'Stopwatch',
      description: 'High-precision lap timer with splits',
      icon: Icons.timer_rounded,
      iconColor: Color(0xFF8B5CF6),
      category: ToolCategory.utilities,
      isImplementedInPhase1: true,
      routePath: '/tools/stopwatch',
    ),
    ToolItem(
      id: 'flashlight',
      name: 'Flashlight',
      description: 'Hardware torch, strobe, and lantern mode',
      icon: Icons.flashlight_on_rounded,
      iconColor: Color(0xFFF59E0B),
      category: ToolCategory.utilities,
      isImplementedInPhase1: true,
      routePath: '/tools/flashlight',
    ),
    ToolItem(
      id: 'notes',
      name: 'Quick Notes',
      description: 'Instant scratchpad for ideas and clipboard clips',
      icon: Icons.note_alt_rounded,
      iconColor: Color(0xFF14B8A6),
      category: ToolCategory.utilities,
      isImplementedInPhase1: true,
      routePath: '/tools/notes',
    ),

    // Vision & Sensors
    ToolItem(
      id: 'qr_studio',
      name: 'QR Code Studio',
      description: 'Scan barcodes & create custom QR codes',
      icon: Icons.qr_code_scanner_rounded,
      iconColor: Color(0xFF6366F1),
      category: ToolCategory.visionAndSensors,
      isImplementedInPhase1: true,
      routePath: '/tools/qr-studio',
    ),
    ToolItem(
      id: 'magnifier',
      name: 'Screen Magnifier',
      description: 'Camera-assisted zoom for fine text and details',
      icon: Icons.zoom_in_rounded,
      iconColor: Color(0xFFEC4899),
      category: ToolCategory.visionAndSensors,
      isImplementedInPhase1: false,
      routePath: '/tools/magnifier',
    ),
    ToolItem(
      id: 'compass',
      name: 'Compass',
      description: 'Directional heading and orientation sensor',
      icon: Icons.explore_rounded,
      iconColor: Color(0xFF06B6D4),
      category: ToolCategory.visionAndSensors,
      isImplementedInPhase1: false,
      routePath: '/tools/compass',
    ),

    // Device Insights
    ToolItem(
      id: 'device_info',
      name: 'Device & Hardware',
      description: 'Android version, CPU cores, display, and memory',
      icon: Icons.perm_device_information_rounded,
      iconColor: Color(0xFF2563EB),
      category: ToolCategory.deviceInsights,
      isImplementedInPhase1: true,
      routePath: '/tools/device-info',
    ),
    ToolItem(
      id: 'battery_info',
      name: 'Battery Diagnostics',
      description: 'Charge cycles, voltage, temperature, and health',
      icon: Icons.battery_charging_full_rounded,
      iconColor: Color(0xFF16A34A),
      category: ToolCategory.deviceInsights,
      isImplementedInPhase1: true,
      routePath: '/tools/device-info',
    ),
    ToolItem(
      id: 'storage',
      name: 'Storage Analyzer',
      description: 'Partition metrics, free space, and app sizes',
      icon: Icons.storage_rounded,
      iconColor: Color(0xFFF97316),
      category: ToolCategory.deviceInsights,
      isImplementedInPhase1: true,
      routePath: '/tools/device-info',
    ),
    ToolItem(
      id: 'converter',
      name: 'Unit Converter',
      description: 'Convert length, weight, and temperature instantly',
      icon: Icons.swap_horiz_rounded,
      iconColor: Color(0xFF0284C7),
      category: ToolCategory.deviceInsights,
      isImplementedInPhase1: true,
      routePath: '/tools/unit-converter',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ToolCategory.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: categories.map((category) {
          final categoryTools = _tools
              .where((t) => t.category == category)
              .toList();

          return AppSection(
            title: category.displayName,
            subtitle: category.description,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.isSmallPhone ? 1 : 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: context.isSmallPhone ? 3.0 : 2.2,
                ),
                itemCount: categoryTools.length,
                itemBuilder: (context, index) {
                  final tool = categoryTools[index];
                  return _buildToolCard(context, tool);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, ToolItem tool) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (tool.isImplementedInPhase1) {
            context.push(tool.routePath);
          } else {
            context.showSnackBar(
              '${tool.name} hardware camera/sensor API activates in Phase 2',
            );
          }
        },
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: context.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tool.iconColor.withOpacity(0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(tool.icon, color: tool.iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tool.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!tool.isImplementedInPhase1) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'P2',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.isDarkMode
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class BatteryDiagnosticsScreen extends StatefulWidget {
  const BatteryDiagnosticsScreen({super.key});

  @override
  State<BatteryDiagnosticsScreen> createState() =>
      _BatteryDiagnosticsScreenState();
}

class _BatteryDiagnosticsScreenState extends State<BatteryDiagnosticsScreen> {
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiagnostics();
  }

  Future<void> _fetchDiagnostics() async {
    setState(() => _isLoading = true);
    final data = await NativeBridge.instance.getBatteryDiagnostics();
    if (mounted) {
      setState(() {
        _diagnostics = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _diagnostics?['level'] as int? ?? 100;
    final isCharging = _diagnostics?['isCharging'] as bool? ?? false;
    final status = _diagnostics?['status'] as String? ?? 'Discharging';
    final plugType = _diagnostics?['plugType'] as String? ?? 'Battery';
    final health = _diagnostics?['health'] as String? ?? 'Good';
    final temp = (_diagnostics?['temperature'] as num?)?.toDouble() ?? 28.5;
    final voltage = _diagnostics?['voltage'] as int? ?? 4120;
    final tech = _diagnostics?['technology'] as String? ?? 'Li-ion';
    final isPowerSave = _diagnostics?['isPowerSaveMode'] as bool? ?? false;
    final isWhitelisted =
        _diagnostics?['isIgnoringBatteryOptimizations'] as bool? ?? true;

    Color levelColor = AppColors.success;
    if (level < 20) {
      levelColor = AppColors.error;
    } else if (level < 40) {
      levelColor = AppColors.warning;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Diagnostics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Telemetry',
            onPressed: _fetchDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDiagnostics,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  // Battery Big Status Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          levelColor.withOpacity(0.15),
                          context.isDarkMode
                              ? AppColors.darkElevatedSurface
                              : Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(color: levelColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCharging
                                  ? Icons.battery_charging_full_rounded
                                  : Icons.battery_std_rounded,
                              size: 48,
                              color: levelColor,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              '$level%',
                              style: context.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: levelColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          isCharging
                              ? 'Charging via $plugType'
                              : (status.isNotEmpty
                                    ? status
                                    : 'Discharging on Battery'),
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Power Source: $plugType',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.isDarkMode
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (level.clamp(0, 100)) / 100.0,
                            minHeight: 12,
                            backgroundColor: levelColor.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              levelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Hardware Telemetry',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Telemetry Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.8,
                    children: [
                      _buildMetricTile(
                        context,
                        icon: Icons.health_and_safety_rounded,
                        iconColor: AppColors.success,
                        title: 'Battery Health',
                        value: health,
                      ),
                      _buildMetricTile(
                        context,
                        icon: Icons.thermostat_rounded,
                        iconColor: temp > 40
                            ? AppColors.error
                            : AppColors.warning,
                        title: 'Temperature',
                        value: '${temp.toStringAsFixed(1)} °C',
                      ),
                      _buildMetricTile(
                        context,
                        icon: Icons.electric_bolt_rounded,
                        iconColor: AppColors.accent,
                        title: 'Voltage',
                        value: '$voltage mV',
                      ),
                      _buildMetricTile(
                        context,
                        icon: Icons.memory_rounded,
                        iconColor: AppColors.primary,
                        title: 'Chemistry',
                        value: tech,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'System Power Configuration',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildConfigTile(
                    context,
                    icon: Icons.eco_rounded,
                    title: 'Android Power Saver',
                    subtitle: isPowerSave
                        ? 'Active (Restricting background tasks)'
                        : 'Disabled (Standard performance)',
                    isActive: isPowerSave,
                  ),
                  _buildConfigTile(
                    context,
                    icon: Icons.battery_saver_rounded,
                    title: 'Background Optimization Exemption',
                    subtitle: isWhitelisted
                        ? 'Unrestricted (Taply overlay remains responsive)'
                        : 'Optimized by OS (May sleep in background)',
                    isActive: isWhitelisted,
                    badgeText: isWhitelisted ? 'Whitelisted' : 'Restricted',
                    badgeColor: isWhitelisted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.darkElevatedSurface
            : Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: context.isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: context.isDarkMode
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.darkElevatedSurface
            : Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: context.isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: badgeColor ?? AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.success).withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }
}

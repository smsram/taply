import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _info = {};

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
  }

  Future<void> _fetchDeviceInfo() async {
    setState(() => _isLoading = true);
    final data = await NativeBridge.instance.getDeviceInfo();
    if (mounted) {
      setState(() {
        _info = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device & System Info')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final batteryLevel = (_info['batteryLevel'] as num?)?.toInt() ?? 80;
    final isCharging = _info['isCharging'] as bool? ?? false;
    final batteryStatus = _info['batteryStatus']?.toString() ?? 'Normal';

    final totalBytes =
        (_info['storageTotalBytes'] as num?)?.toInt() ?? 128000000000;
    final freeBytes =
        (_info['storageFreeBytes'] as num?)?.toInt() ?? 64000000000;
    final totalGB = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final freeGB = (freeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final usedFraction = totalBytes > 0
        ? ((totalBytes - freeBytes) / totalBytes).clamp(0.0, 1.0)
        : 0.5;

    final osVersion = _info['osVersion']?.toString() ?? 'Android System';
    final deviceModel = _info['deviceModel']?.toString() ?? 'Android Device';
    final deviceHardware = _info['deviceHardware']?.toString() ?? 'ARM64';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device & System Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Specs',
            onPressed: _fetchDeviceInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // Battery Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCharging
                              ? Icons.battery_charging_full_rounded
                              : Icons.battery_std_rounded,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Battery Status',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Charge Level',
                          style: context.textTheme.bodyMedium,
                        ),
                        Text(
                          '$batteryLevel% • $batteryStatus',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (batteryLevel / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: context.colorScheme.onSurface
                            .withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isCharging
                          ? 'State: Connected to power source'
                          : 'State: Running on battery power ($batteryStatus)',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Storage Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.storage_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Internal Storage',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Space',
                          style: context.textTheme.bodyMedium,
                        ),
                        Text(
                          '$freeGB GB / $totalGB GB Free',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usedFraction,
                        minHeight: 8,
                        backgroundColor: context.colorScheme.onSurface
                            .withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Used: ${(usedFraction * 100).toInt()}% • Partition: User Data',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Hardware & Software Specs Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Hardware & Operating System',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoRow('Device Model', deviceModel),
                    _buildInfoRow('OS Version', osVersion),
                    _buildInfoRow('Platform Hardware', deviceHardware),
                    _buildInfoRow('Architecture', 'ARM64 Multi-Core'),
                    _buildInfoRow(
                      'Taply App Version',
                      '${AppConstants.appVersion} (${AppConstants.buildNumber})',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

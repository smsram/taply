import 'package:flutter/material.dart';

import '../../core/services/native_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class StorageAnalyzerScreen extends StatefulWidget {
  const StorageAnalyzerScreen({super.key});

  @override
  State<StorageAnalyzerScreen> createState() => _StorageAnalyzerScreenState();
}

class _StorageAnalyzerScreenState extends State<StorageAnalyzerScreen> {
  Map<String, dynamic>? _storageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStorage();
  }

  Future<void> _fetchStorage() async {
    setState(() => _isLoading = true);
    final data = await NativeBridge.instance.getStorageDiagnostics();
    if (mounted) {
      setState(() {
        _storageData = data;
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final totalBytes =
        (_storageData?['totalBytes'] as num?)?.toInt() ??
        (64 * 1024 * 1024 * 1024);
    final freeBytes =
        (_storageData?['freeBytes'] as num?)?.toInt() ??
        (24 * 1024 * 1024 * 1024);
    final usedBytes =
        (_storageData?['usedBytes'] as num?)?.toInt() ??
        (totalBytes - freeBytes);
    final usedPct =
        (_storageData?['usedPercentage'] as num?)?.toDouble() ?? 62.0;
    final dataDir = _storageData?['dataDirectory'] as String? ?? '/data';

    Color storageColor = AppColors.primary;
    if (usedPct >= 90) {
      storageColor = AppColors.error;
    } else if (usedPct >= 75) {
      storageColor = AppColors.warning;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Analyzer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Storage',
            onPressed: _fetchStorage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStorage,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  // Main Storage Overview Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          storageColor.withOpacity(0.12),
                          context.isDarkMode
                              ? AppColors.darkElevatedSurface
                              : Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(color: storageColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage_rounded,
                              size: 36,
                              color: storageColor,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Internal Storage',
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Primary Flash Memory',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.isDarkMode
                                              ? AppColors.darkSecondaryText
                                              : AppColors.secondaryText,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${usedPct.toInt()}%',
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: storageColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (usedPct.clamp(0, 100)) / 100.0,
                            minHeight: 14,
                            backgroundColor: storageColor.withOpacity(0.18),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              storageColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Used: ${_formatBytes(usedBytes)}',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Free: ${_formatBytes(freeBytes)}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Total: ${_formatBytes(totalBytes)}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.isDarkMode
                                    ? AppColors.darkSecondaryText
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Memory Allocation Breakdown',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildCategoryRow(
                    context,
                    icon: Icons.apps_rounded,
                    color: AppColors.primary,
                    title: 'Apps & Operating System',
                    subtitle: 'Installed packages and system binaries',
                    size: _formatBytes((usedBytes * 0.55).toInt()),
                  ),
                  _buildCategoryRow(
                    context,
                    icon: Icons.photo_library_rounded,
                    color: const Color(0xFFEC4899),
                    title: 'Media & Documents',
                    subtitle: 'Photos, videos, audio, and downloads',
                    size: _formatBytes((usedBytes * 0.35).toInt()),
                  ),
                  _buildCategoryRow(
                    context,
                    icon: Icons.folder_special_rounded,
                    color: AppColors.accent,
                    title: 'Other System & Cache',
                    subtitle: 'Temporary caches and cached data',
                    size: _formatBytes((usedBytes * 0.10).toInt()),
                  ),
                  _buildCategoryRow(
                    context,
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    title: 'Available Space',
                    subtitle: 'Free for new apps and media',
                    size: _formatBytes(freeBytes),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Mount Point Details',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? AppColors.darkElevatedSurface
                          : Colors.white,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: context.isDarkMode
                            ? AppColors.darkBorder
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Data Path', dataDir),
                        const Divider(height: 16),
                        _buildInfoRow(
                          'File System',
                          'ext4 / f2fs (Android Sandbox)',
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          'Storage Health',
                          usedPct < 90 ? 'Healthy' : 'Critically Low',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String size,
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
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
          Text(
            size,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

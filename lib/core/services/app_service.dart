import 'package:flutter/material.dart';

import '../../shared/models/installed_app.dart';

abstract class IAppService {
  Future<List<InstalledApp>> getInstalledApps();
  Future<List<InstalledApp>> getFavoriteApps();
  Future<List<InstalledApp>> getRecentApps();
  Future<void> toggleFavorite(String packageName);
  Future<void> toggleHidden(String packageName);
  Future<void> updateLaunchMode(String packageName, AppLaunchMode mode);
  Future<void> recordLaunch(String packageName);
}

/// Phase 1 application repository implementation.
/// Provides sample Android-standard utility apps for UI testing.
/// In Phase 2, this will be replaced with native Android PackageManager method channels.
class MockAppService implements IAppService {
  final List<InstalledApp> _apps = [
    const InstalledApp(
      packageName: 'com.google.android.dialer',
      appName: 'Phone',
      defaultIcon: Icons.phone_rounded,
      iconColor: Color(0xFF2563EB),
      isSystemApp: true,
      isFavorite: true,
    ),
    const InstalledApp(
      packageName: 'com.google.android.apps.messaging',
      appName: 'Messages',
      defaultIcon: Icons.message_rounded,
      iconColor: Color(0xFF14B8A6),
      isSystemApp: true,
      isFavorite: true,
    ),
    const InstalledApp(
      packageName: 'com.google.android.GoogleCamera',
      appName: 'Camera',
      defaultIcon: Icons.camera_alt_rounded,
      iconColor: Color(0xFFF59E0B),
      isSystemApp: true,
      isFavorite: true,
    ),
    const InstalledApp(
      packageName: 'com.google.android.apps.photos',
      appName: 'Photos',
      defaultIcon: Icons.photo_library_rounded,
      iconColor: Color(0xFFEC4899),
      isSystemApp: true,
      isFavorite: true,
    ),
    const InstalledApp(
      packageName: 'com.android.chrome',
      appName: 'Chrome',
      defaultIcon: Icons.language_rounded,
      iconColor: Color(0xFF3B82F6),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.google.android.deskclock',
      appName: 'Clock',
      defaultIcon: Icons.access_time_filled_rounded,
      iconColor: Color(0xFF8B5CF6),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.google.android.calculator',
      appName: 'Calculator',
      defaultIcon: Icons.calculate_rounded,
      iconColor: Color(0xFF10B981),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.google.android.calendar',
      appName: 'Calendar',
      defaultIcon: Icons.calendar_today_rounded,
      iconColor: Color(0xFF06B6D4),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.google.android.apps.maps',
      appName: 'Maps',
      defaultIcon: Icons.map_rounded,
      iconColor: Color(0xFF16A34A),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.google.android.apps.nbu.files',
      appName: 'Files',
      defaultIcon: Icons.folder_rounded,
      iconColor: Color(0xFFF97316),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.android.settings',
      appName: 'Settings',
      defaultIcon: Icons.settings_rounded,
      iconColor: Color(0xFF64748B),
      isSystemApp: true,
      isFavorite: false,
    ),
    const InstalledApp(
      packageName: 'com.google.android.music',
      appName: 'Music',
      defaultIcon: Icons.music_note_rounded,
      iconColor: Color(0xFFEF4444),
      isSystemApp: false,
      isFavorite: false,
    ),
  ];

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    return List.unmodifiable(_apps);
  }

  @override
  Future<List<InstalledApp>> getFavoriteApps() async {
    return _apps.where((app) => app.isFavorite && !app.isHidden).toList();
  }

  @override
  Future<List<InstalledApp>> getRecentApps() async {
    final withUsage = _apps.where((app) => app.lastUsedAt != null).toList();
    withUsage.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return withUsage;
  }

  @override
  Future<void> toggleFavorite(String packageName) async {
    final index = _apps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final current = _apps[index];
      _apps[index] = current.copyWith(isFavorite: !current.isFavorite);
    }
  }

  @override
  Future<void> toggleHidden(String packageName) async {
    final index = _apps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final current = _apps[index];
      _apps[index] = current.copyWith(isHidden: !current.isHidden);
    }
  }

  @override
  Future<void> updateLaunchMode(String packageName, AppLaunchMode mode) async {
    final index = _apps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final current = _apps[index];
      _apps[index] = current.copyWith(launchMode: mode);
    }
  }

  @override
  Future<void> recordLaunch(String packageName) async {
    final index = _apps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final current = _apps[index];
      _apps[index] = current.copyWith(
        lastUsedAt: DateTime.now(),
        usageCount: current.usageCount + 1,
      );
    }
  }
}

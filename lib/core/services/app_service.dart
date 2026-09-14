import 'package:flutter/material.dart';

import '../../shared/models/installed_app.dart';
import 'native_bridge.dart';
import 'storage_service.dart';

abstract class IAppService {
  Future<List<InstalledApp>> getInstalledApps();
  Future<List<InstalledApp>> getFavoriteApps();
  Future<List<InstalledApp>> getRecentApps();
  Future<void> toggleFavorite(String packageName);
  Future<void> setFavorites(List<String> packageNames);
  Future<void> reorderFavorites(int oldIndex, int newIndex);
  Future<void> toggleHidden(String packageName);
  Future<void> updateLaunchMode(String packageName, AppLaunchMode mode);
  Future<void> recordLaunch(String packageName);
}

/// Real Android Native Application Service.
/// Uses Android PackageManager via MethodChannel and persists favorites/hidden states locally.
class NativeAppService implements IAppService {
  final NativeBridge _bridge = NativeBridge.instance;
  final IStorageService storage;
  List<InstalledApp>? _cachedApps;

  NativeAppService({required this.storage});

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    if (_cachedApps != null) return _cachedApps!;

    final nativeList = await _bridge.getInstalledApps(includeIcons: true);
    final favList = storage.getStringList('taply_favorites') ?? [];
    final hiddenList = storage.getStringList('taply_hidden') ?? [];

    if (nativeList.isNotEmpty) {
      _cachedApps = nativeList.map((m) {
        final pkg = m['packageName'] as String? ?? '';
        final name = m['appName'] as String? ?? pkg;
        final isSys = m['isSystemApp'] as bool? ?? false;
        final iconBase64 = m['iconBase64'] as String?;
        final iconBytes = NativeBridge.decodeBase64Icon(iconBase64);

        return InstalledApp(
          packageName: pkg,
          appName: name,
          isSystemApp: isSys,
          iconBytes: iconBytes,
          isFavorite: favList.contains(pkg),
          isHidden: hiddenList.contains(pkg),
        );
      }).toList();
      return _cachedApps!;
    }

    // Fallback if running in mock/desktop/test environment
    _cachedApps = List<InstalledApp>.from(MockAppService.sampleApps);
    _cachedApps = MockAppService.sampleApps.map((app) {
      return app.copyWith(
        isFavorite: favList.isNotEmpty
            ? favList.contains(app.packageName)
            : app.isFavorite,
        isHidden: hiddenList.contains(app.packageName),
      );
    }).toList();
    return _cachedApps!;
  }

  @override
  Future<List<InstalledApp>> getFavoriteApps() async {
    final apps = await getInstalledApps();
    final favList = storage.getStringList('taply_favorites') ?? [];
    if (favList.isEmpty) {
      return apps.where((a) => a.isFavorite && !a.isHidden).toList();
    }
    final appMap = {for (final a in apps) a.packageName: a};
    final ordered = <InstalledApp>[];
    for (final pkg in favList) {
      final app = appMap[pkg];
      if (app != null && app.isFavorite && !app.isHidden) {
        ordered.add(app);
      }
    }
    for (final a in apps) {
      if (a.isFavorite && !a.isHidden && !favList.contains(a.packageName)) {
        ordered.add(a);
      }
    }
    return ordered;
  }

  @override
  Future<List<InstalledApp>> getRecentApps() async {
    final apps = await getInstalledApps();
    final recents = apps
        .where((a) => a.lastUsedAt != null && !a.isHidden)
        .toList();
    recents.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return recents;
  }

  @override
  Future<void> toggleFavorite(String packageName) async {
    final apps = await getInstalledApps();
    final index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      final current = apps[index];
      final newFav = !current.isFavorite;
      apps[index] = current.copyWith(isFavorite: newFav);

      final favList = List<String>.from(
        storage.getStringList('taply_favorites') ?? [],
      );
      if (newFav) {
        if (!favList.contains(packageName)) favList.add(packageName);
      } else {
        favList.remove(packageName);
      }
      await storage.setStringList('taply_favorites', favList);
    }
  }

  @override
  Future<void> setFavorites(List<String> packageNames) async {
    final apps = await getInstalledApps();
    final favSet = packageNames.toSet();
    for (int i = 0; i < apps.length; i++) {
      final isFav = favSet.contains(apps[i].packageName);
      if (apps[i].isFavorite != isFav) {
        apps[i] = apps[i].copyWith(isFavorite: isFav);
      }
    }
    await storage.setStringList('taply_favorites', packageNames);
  }

  @override
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final favList = List<String>.from(
      storage.getStringList('taply_favorites') ?? [],
    );
    if (oldIndex < 0 ||
        oldIndex >= favList.length ||
        newIndex < 0 ||
        newIndex >= favList.length) {
      return;
    }
    final item = favList.removeAt(oldIndex);
    favList.insert(newIndex, item);
    await storage.setStringList('taply_favorites', favList);
  }

  @override
  Future<void> toggleHidden(String packageName) async {
    final apps = await getInstalledApps();
    final index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      final current = apps[index];
      final newHidden = !current.isHidden;
      apps[index] = current.copyWith(isHidden: newHidden);

      final hiddenList = List<String>.from(
        storage.getStringList('taply_hidden') ?? [],
      );
      if (newHidden) {
        if (!hiddenList.contains(packageName)) hiddenList.add(packageName);
      } else {
        hiddenList.remove(packageName);
      }
      await storage.setStringList('taply_hidden', hiddenList);
    }
  }

  @override
  Future<void> updateLaunchMode(String packageName, AppLaunchMode mode) async {
    final apps = await getInstalledApps();
    final index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      apps[index] = apps[index].copyWith(launchMode: mode);
    }
  }

  @override
  Future<void> recordLaunch(String packageName) async {
    final apps = await getInstalledApps();
    final index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      apps[index] = apps[index].copyWith(
        lastUsedAt: DateTime.now(),
        usageCount: apps[index].usageCount + 1,
      );
    }
    // Trigger real Android app launch
    await _bridge.launchApp(packageName);
  }
}

/// Fallback sample applications for tests and simulation.
class MockAppService implements IAppService {
  static const List<InstalledApp> sampleApps = [
    InstalledApp(
      packageName: 'com.google.android.dialer',
      appName: 'Phone',
      defaultIcon: Icons.phone_rounded,
      iconColor: Color(0xFF2563EB),
      isSystemApp: true,
      isFavorite: true,
    ),
    InstalledApp(
      packageName: 'com.google.android.apps.messaging',
      appName: 'Messages',
      defaultIcon: Icons.message_rounded,
      iconColor: Color(0xFF14B8A6),
      isSystemApp: true,
      isFavorite: true,
    ),
    InstalledApp(
      packageName: 'com.google.android.GoogleCamera',
      appName: 'Camera',
      defaultIcon: Icons.camera_alt_rounded,
      iconColor: Color(0xFFF59E0B),
      isSystemApp: true,
      isFavorite: true,
    ),
    InstalledApp(
      packageName: 'com.google.android.apps.photos',
      appName: 'Photos',
      defaultIcon: Icons.photo_library_rounded,
      iconColor: Color(0xFFEC4899),
      isSystemApp: true,
      isFavorite: true,
    ),
    InstalledApp(
      packageName: 'com.android.chrome',
      appName: 'Chrome',
      defaultIcon: Icons.language_rounded,
      iconColor: Color(0xFF3B82F6),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.google.android.deskclock',
      appName: 'Clock',
      defaultIcon: Icons.access_time_filled_rounded,
      iconColor: Color(0xFF8B5CF6),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.google.android.calculator',
      appName: 'Calculator',
      defaultIcon: Icons.calculate_rounded,
      iconColor: Color(0xFF10B981),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.google.android.calendar',
      appName: 'Calendar',
      defaultIcon: Icons.calendar_today_rounded,
      iconColor: Color(0xFF06B6D4),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.google.android.apps.maps',
      appName: 'Maps',
      defaultIcon: Icons.map_rounded,
      iconColor: Color(0xFF16A34A),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.google.android.apps.nbu.files',
      appName: 'Files',
      defaultIcon: Icons.folder_rounded,
      iconColor: Color(0xFFF97316),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.android.settings',
      appName: 'Settings',
      defaultIcon: Icons.settings_rounded,
      iconColor: Color(0xFF64748B),
      isSystemApp: true,
      isFavorite: false,
    ),
    InstalledApp(
      packageName: 'com.google.android.music',
      appName: 'Music',
      defaultIcon: Icons.music_note_rounded,
      iconColor: Color(0xFFEF4444),
      isSystemApp: false,
      isFavorite: false,
    ),
  ];

  final List<InstalledApp> _apps = List.from(sampleApps);

  @override
  Future<List<InstalledApp>> getInstalledApps() async =>
      List.unmodifiable(_apps);

  @override
  Future<List<InstalledApp>> getFavoriteApps() async =>
      _apps.where((app) => app.isFavorite && !app.isHidden).toList();

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
  Future<void> setFavorites(List<String> packageNames) async {
    final set = packageNames.toSet();
    for (int i = 0; i < _apps.length; i++) {
      _apps[i] = _apps[i].copyWith(
        isFavorite: set.contains(_apps[i].packageName),
      );
    }
  }

  @override
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {}

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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/models/app_settings.dart';
import '../../shared/models/floating_button_config.dart';
import '../../shared/models/gesture_action.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/models/panel_config.dart';
import '../../shared/models/permission_item.dart';
import '../theme/app_theme.dart';
import 'app_service.dart';
import 'native_bridge.dart';
import 'permission_service.dart';
import 'storage_service.dart';
import 'system_action_service.dart';

// Services
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

final storageServiceProvider = Provider<IStorageService>((ref) {
  return SharedPreferencesStorageService();
});

final permissionServiceProvider = Provider<IPermissionService>((ref) {
  return NativePermissionService();
});

final appServiceProvider = Provider<IAppService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return NativeAppService(storage: storage);
});

final systemActionServiceProvider = Provider<ISystemActionService>((ref) {
  return NativeSystemActionService();
});

// App Settings Notifier
class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _storageKey = 'taply_settings';

  @override
  AppSettings build() {
    final storage = ref.watch(storageServiceProvider);
    final raw = storage.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return AppSettings.fromMap(decoded);
      } catch (e) {
        debugPrint('[AppSettingsNotifier] Error restoring settings: $e');
      }
    }
    return const AppSettings();
  }

  void _persist() {
    final storage = ref.read(storageServiceProvider);
    storage.setString(_storageKey, jsonEncode(state.toMap()));
  }

  void toggleAssistant(bool enabled) {
    state = state.copyWith(isAssistantEnabled: enabled);
    _persist();
    if (enabled) {
      NativeBridge.instance.startOverlayService();
      _syncConfigToNative();
    } else {
      NativeBridge.instance.stopOverlayService();
    }
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void updateButtonConfig(FloatingButtonConfig config) {
    state = state.copyWith(buttonConfig: config);
    _persist();
    _syncConfigToNative();
  }

  void updatePanelConfig(PanelConfig config) {
    state = state.copyWith(panelConfig: config);
    _persist();
    _syncConfigToNative();
  }

  void setDefaultLaunchMode(AppLaunchMode mode) {
    state = state.copyWith(defaultLaunchMode: mode);
    _persist();
  }

  void setHapticFeedback(bool enabled) {
    state = state.copyWith(hapticFeedback: enabled);
    _persist();
    _syncConfigToNative();
  }

  void setStartWithDevice(bool enabled) {
    state = state.copyWith(startWithDevice: enabled);
    _persist();
  }

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
    _persist();
  }

  void completeOnboarding() {
    state = state.copyWith(isOnboardingCompleted: true);
    _persist();
  }

  void _syncConfigToNative() {
    final favList =
        ref.read(storageServiceProvider).getStringList('taply_favorites') ?? [];
    NativeBridge.instance.updateOverlayConfig(
      config: state.buttonConfig,
      gestures: ref.read(gesturesProvider),
      panelConfig: state.panelConfig,
      favorites: favList,
    );
  }
}

final settingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});

// Gestures Notifier
class GesturesNotifier extends Notifier<Map<GestureTrigger, GestureBinding>> {
  static const _storageKey = 'taply_gestures';

  static const _defaultGestures = {
    GestureTrigger.singleTap: GestureBinding(
      trigger: GestureTrigger.singleTap,
      target: GestureActionTarget.openPanel,
    ),
    GestureTrigger.doubleTap: GestureBinding(
      trigger: GestureTrigger.doubleTap,
      target: GestureActionTarget.screenshot,
    ),
    GestureTrigger.longPress: GestureBinding(
      trigger: GestureTrigger.longPress,
      target: GestureActionTarget.quickControls,
    ),
    GestureTrigger.swipeUp: GestureBinding(
      trigger: GestureTrigger.swipeUp,
      target: GestureActionTarget.appDrawer,
    ),
    GestureTrigger.swipeDown: GestureBinding(
      trigger: GestureTrigger.swipeDown,
      target: GestureActionTarget.flashlight,
    ),
    GestureTrigger.swipeLeft: GestureBinding(
      trigger: GestureTrigger.swipeLeft,
      target: GestureActionTarget.none,
    ),
    GestureTrigger.swipeRight: GestureBinding(
      trigger: GestureTrigger.swipeRight,
      target: GestureActionTarget.none,
    ),
  };

  @override
  Map<GestureTrigger, GestureBinding> build() {
    final storage = ref.watch(storageServiceProvider);
    final raw = storage.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final result = <GestureTrigger, GestureBinding>{};
        for (final entry in decoded.entries) {
          final trigger = GestureTrigger.values.firstWhere(
            (t) => t.name == entry.key,
            orElse: () => GestureTrigger.singleTap,
          );
          result[trigger] = GestureBinding.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
        for (final defaultEntry in _defaultGestures.entries) {
          result.putIfAbsent(defaultEntry.key, () => defaultEntry.value);
        }
        return result;
      } catch (e) {
        debugPrint('[GesturesNotifier] Error restoring gestures: $e');
      }
    }
    return Map.from(_defaultGestures);
  }

  void updateBinding(
    GestureTrigger trigger,
    GestureActionTarget target, {
    String? customPayload,
  }) {
    final updated = Map<GestureTrigger, GestureBinding>.from(state);
    updated[trigger] = GestureBinding(
      trigger: trigger,
      target: target,
      customPayload: customPayload,
    );
    state = updated;

    final storage = ref.read(storageServiceProvider);
    final serialized = <String, dynamic>{};
    for (final entry in state.entries) {
      serialized[entry.key.name] = entry.value.toMap();
    }
    storage.setString(_storageKey, jsonEncode(serialized));

    final favList = storage.getStringList('taply_favorites') ?? [];
    final settings = ref.read(settingsProvider);
    NativeBridge.instance.updateOverlayConfig(
      config: settings.buttonConfig,
      gestures: state,
      panelConfig: settings.panelConfig,
      favorites: favList,
    );
  }
}

final gesturesProvider =
    NotifierProvider<GesturesNotifier, Map<GestureTrigger, GestureBinding>>(() {
      return GesturesNotifier();
    });

// Apps Notifier
class AppsNotifier extends AsyncNotifier<List<InstalledApp>> {
  @override
  Future<List<InstalledApp>> build() async {
    final service = ref.watch(appServiceProvider);
    return service.getInstalledApps();
  }

  void _syncFavoritesToNative(List<String> favList) {
    final settings = ref.read(settingsProvider);
    NativeBridge.instance.updateOverlayConfig(
      config: settings.buttonConfig,
      gestures: ref.read(gesturesProvider),
      panelConfig: settings.panelConfig,
      favorites: favList,
    );
  }

  Future<void> refreshApps() async {
    state = const AsyncLoading();
    final service = ref.read(appServiceProvider);
    state = AsyncData(await service.getInstalledApps());
    state = AsyncData(await service.getInstalledApps(forceRefresh: true));
  }

  Future<void> toggleFavorite(String packageName) async {
    final service = ref.read(appServiceProvider);
    await service.toggleFavorite(packageName);
    state = AsyncData(await service.getInstalledApps());
    final apps = await service.getInstalledApps();
    state = AsyncData(apps);
    final favList = apps
        .where((a) => a.isFavorite)
        .map((a) => a.packageName)
        .toList();
    _syncFavoritesToNative(favList);
  }

  Future<void> setFavorites(List<String> packageNames) async {
    final service = ref.read(appServiceProvider);
    await service.setFavorites(packageNames);
    state = AsyncData(await service.getInstalledApps());
    _syncFavoritesToNative(packageNames);
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final service = ref.read(appServiceProvider);
    await service.reorderFavorites(oldIndex, newIndex);
    state = AsyncData(await service.getInstalledApps());
    final apps = await service.getInstalledApps();
    state = AsyncData(apps);
    final favList = apps
        .where((a) => a.isFavorite)
        .map((a) => a.packageName)
        .toList();
    _syncFavoritesToNative(favList);
  }

  Future<void> toggleHidden(String packageName) async {
    final service = ref.read(appServiceProvider);
    await service.toggleHidden(packageName);
    state = AsyncData(await service.getInstalledApps());
  }

  Future<void> updateLaunchMode(String packageName, AppLaunchMode mode) async {
    final service = ref.read(appServiceProvider);
    await service.updateLaunchMode(packageName, mode);
    state = AsyncData(await service.getInstalledApps());
  }

  Future<void> recordLaunch(String packageName) async {
    final service = ref.read(appServiceProvider);
    await service.recordLaunch(packageName);
    state = AsyncData(await service.getInstalledApps());
  }
}

final appsProvider = AsyncNotifierProvider<AppsNotifier, List<InstalledApp>>(
  () {
    return AppsNotifier();
  },
);

// Permissions Notifier
class PermissionsNotifier extends AsyncNotifier<List<PermissionItem>> {
  @override
  Future<List<PermissionItem>> build() async {
    final service = ref.watch(permissionServiceProvider);
    final statuses = await service.checkAllPermissions();

    return [
      PermissionItem(
        type: PermissionType.overlay,
        title: 'Floating Access',
        subtitle: 'Display over other apps',
        description: 'Required to display the floating Taply assistive button on top of any active screen and application.',
        icon: Icons.layers_rounded,
        status:
            statuses[PermissionType.overlay] ?? PermissionStatus.notDetermined,
        isMandatory: true,
      ),
      PermissionItem(
        type: PermissionType.accessibility,
        title: 'Accessibility Access',
        subtitle: 'Global gestures and system controls',
        description: 'Enables Taply to execute system actions such as Back, Home, Recent Apps, and Lock Screen on your behalf.',
        icon: Icons.accessibility_new_rounded,
        status:
            statuses[PermissionType.accessibility] ??
            PermissionStatus.notDetermined,
        isMandatory: true,
      ),
      PermissionItem(
        type: PermissionType.notifications,
        title: 'Notifications',
        subtitle: 'Foreground service & quick toggles',
        description: 'Keeps the assistive touch service alive reliably in the background without being killed by Android.',
        icon: Icons.notifications_active_rounded,
        status:
            statuses[PermissionType.notifications] ?? PermissionStatus.granted,
        isMandatory: false,
      ),
      PermissionItem(
        type: PermissionType.batteryOptimization,
        title: 'Battery Optimization Exemption',
        subtitle: 'Unrestricted background operation',
        description: 'Prevents the Android OS power-saving system from suspending Taply when running long multitasking sessions.',
        icon: Icons.battery_saver_rounded,
        status:
            statuses[PermissionType.batteryOptimization] ??
            PermissionStatus.notDetermined,
        isMandatory: false,
      ),
      PermissionItem(
        type: PermissionType.writeSettings,
        title: 'Modify System Settings',
        subtitle: 'Screen brightness adjustment',
        description: 'Allows Taply to adjust screen brightness directly from quick controls without opening the full system settings menu.',
        icon: Icons.brightness_6_rounded,
        status:
            statuses[PermissionType.writeSettings] ??
            PermissionStatus.notDetermined,
        isMandatory: false,
      ),
    ];
  }

  Future<void> request(PermissionType type) async {
    final service = ref.read(permissionServiceProvider);
    await service.requestPermission(type);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final permissionsProvider =
    AsyncNotifierProvider<PermissionsNotifier, List<PermissionItem>>(() {
      return PermissionsNotifier();
    });

// Real-time Flashlight Notifier
class FlashlightNotifier extends Notifier<bool> {
  void Function(bool)? _listener;

  @override
  bool build() {
    _listener = (enabled) {
      state = enabled;
    };
    NativeBridge.instance.addTorchListener(_listener!);
    ref.onDispose(() {
      if (_listener != null) {
        NativeBridge.instance.removeTorchListener(_listener!);
      }
    });

    _syncState();
    return false;
  }

  Future<void> _syncState() async {
    final isOn = await NativeBridge.instance.isFlashlightOn();
    state = isOn;
  }

  Future<void> refresh() async {
    await _syncState();
  }

  Future<bool> toggle() async {
    final newState = await NativeBridge.instance.toggleFlashlight();
    state = newState;
    return newState;
  }

  Future<void> setTorch(bool on) async {
    final current = state;
    if (current != on) {
      final newState = await NativeBridge.instance.toggleFlashlight();
      state = newState;
    }
  }
}

final flashlightProvider = NotifierProvider<FlashlightNotifier, bool>(() {
  return FlashlightNotifier();
});

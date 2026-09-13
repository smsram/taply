import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_settings.dart';
import '../../shared/models/installed_app.dart';
import '../../shared/models/gesture_action.dart';
import '../../shared/models/permission_item.dart';
import '../../shared/models/floating_button_config.dart';
import '../../shared/models/panel_config.dart';
import '../theme/app_theme.dart';
import 'storage_service.dart';
import 'permission_service.dart';
import 'app_service.dart';
import 'system_action_service.dart';

// Services
final storageServiceProvider = Provider<IStorageService>((ref) {
  return SharedPreferencesStorageService();
});

final permissionServiceProvider = Provider<IPermissionService>((ref) {
  return MockPermissionService();
});

final appServiceProvider = Provider<IAppService>((ref) {
  return MockAppService();
});

final systemActionServiceProvider = Provider<ISystemActionService>((ref) {
  return MockSystemActionService();
});

// App Settings Notifier
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return const AppSettings();
  }

  void toggleAssistant(bool enabled) {
    state = state.copyWith(isAssistantEnabled: enabled);
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void updateButtonConfig(FloatingButtonConfig config) {
    state = state.copyWith(buttonConfig: config);
  }

  void updatePanelConfig(PanelConfig config) {
    state = state.copyWith(panelConfig: config);
  }

  void setDefaultLaunchMode(AppLaunchMode mode) {
    state = state.copyWith(defaultLaunchMode: mode);
  }

  void setHapticFeedback(bool enabled) {
    state = state.copyWith(hapticFeedback: enabled);
  }

  void setStartWithDevice(bool enabled) {
    state = state.copyWith(startWithDevice: enabled);
  }

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void completeOnboarding() {
    state = state.copyWith(isOnboardingCompleted: true);
  }
}

final settingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});

// Gestures Notifier
class GesturesNotifier extends Notifier<Map<GestureTrigger, GestureBinding>> {
  @override
  Map<GestureTrigger, GestureBinding> build() {
    return {
      GestureTrigger.singleTap: const GestureBinding(
        trigger: GestureTrigger.singleTap,
        target: GestureActionTarget.openPanel,
      ),
      GestureTrigger.doubleTap: const GestureBinding(
        trigger: GestureTrigger.doubleTap,
        target: GestureActionTarget.screenshot,
      ),
      GestureTrigger.longPress: const GestureBinding(
        trigger: GestureTrigger.longPress,
        target: GestureActionTarget.quickControls,
      ),
      GestureTrigger.swipeUp: const GestureBinding(
        trigger: GestureTrigger.swipeUp,
        target: GestureActionTarget.appDrawer,
      ),
      GestureTrigger.swipeDown: const GestureBinding(
        trigger: GestureTrigger.swipeDown,
        target: GestureActionTarget.flashlight,
      ),
      GestureTrigger.swipeLeft: const GestureBinding(
        trigger: GestureTrigger.swipeLeft,
        target: GestureActionTarget.none,
      ),
      GestureTrigger.swipeRight: const GestureBinding(
        trigger: GestureTrigger.swipeRight,
        target: GestureActionTarget.none,
      ),
    };
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

  Future<void> toggleFavorite(String packageName) async {
    final service = ref.read(appServiceProvider);
    await service.toggleFavorite(packageName);
    state = AsyncData(await service.getInstalledApps());
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
    ];
  }

  Future<void> request(PermissionType type) async {
    final service = ref.read(permissionServiceProvider);
    await service.requestPermission(type);
    ref.invalidateSelf();
  }
}

final permissionsProvider =
    AsyncNotifierProvider<PermissionsNotifier, List<PermissionItem>>(() {
      return PermissionsNotifier();
    });

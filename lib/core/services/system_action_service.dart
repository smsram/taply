import 'package:flutter/foundation.dart';

import 'native_bridge.dart';

enum SystemActionType {
  // System
  home,
  back,
  recentApps,
  lockScreen,
  screenshot,
  screenRotation,

  // Sound
  mediaVolume,
  ringVolume,
  alarmVolume,
  mute,
  vibrate,
  soundMode,

  // Display
  brightness,
  autoBrightness,
  displaySettings,

  // Connectivity
  wifi,
  bluetooth,
  mobileData,
  hotspot,
  airplaneMode,
  nfc,
  cast,
  location,
  vpn,
}

abstract class ISystemActionService {
  Future<bool> executeAction(SystemActionType action, {dynamic parameter});
  bool isSupported(SystemActionType action);
}

/// Real Android Native System Action Service.
class NativeSystemActionService implements ISystemActionService {
  final NativeBridge _bridge = NativeBridge.instance;

  @override
  Future<bool> executeAction(
    SystemActionType action, {
    dynamic parameter,
  }) async {
    switch (action) {
      // Global Navigation via AccessibilityService
      case SystemActionType.home:
        final res = await _bridge.executeSystemAction('home');
        return res['success'] as bool? ?? false;
      case SystemActionType.back:
        final res = await _bridge.executeSystemAction('back');
        return res['success'] as bool? ?? false;
      case SystemActionType.recentApps:
        final res = await _bridge.executeSystemAction('recents');
        return res['success'] as bool? ?? false;
      case SystemActionType.lockScreen:
        final res = await _bridge.executeSystemAction('lock_screen');
        return res['success'] as bool? ?? false;
      case SystemActionType.screenshot:
        final res = await _bridge.takeScreenshot();
        return res['success'] as bool? ?? false;

      // Volume & Sound controls
      case SystemActionType.mediaVolume:
        final vol = (parameter is num) ? parameter.toDouble() : 0.5;
        return await _bridge.setVolumeLevel('media', vol);
      case SystemActionType.ringVolume:
        final vol = (parameter is num) ? parameter.toDouble() : 0.5;
        return await _bridge.setVolumeLevel('ring', vol);
      case SystemActionType.alarmVolume:
        final vol = (parameter is num) ? parameter.toDouble() : 0.5;
        return await _bridge.setVolumeLevel('alarm', vol);
      case SystemActionType.mute:
        final isMuted = parameter == true;
        return await _bridge.setSoundMode(isMuted ? 'Silent' : 'Normal');
      case SystemActionType.vibrate:
        return await _bridge.setSoundMode('Vibrate');
      case SystemActionType.soundMode:
        final mode = parameter?.toString() ?? 'Normal';
        return await _bridge.setSoundMode(mode);

      // Display controls
      case SystemActionType.brightness:
        final b = (parameter is num) ? parameter.toDouble() : 0.5;
        return await _bridge.setBrightness(b);
      case SystemActionType.autoBrightness:
      case SystemActionType.displaySettings:
      case SystemActionType.screenRotation:
        return await _bridge.openSystemSetting('display');

      // Connectivity controls (direct settings shortcuts per Android security model)
      case SystemActionType.wifi:
        return await _bridge.openSystemSetting('wifi');
      case SystemActionType.bluetooth:
        return await _bridge.openSystemSetting('bluetooth');
      case SystemActionType.mobileData:
        return await _bridge.openSystemSetting('data');
      case SystemActionType.hotspot:
        return await _bridge.openSystemSetting('hotspot');
      case SystemActionType.airplaneMode:
        return await _bridge.openSystemSetting('airplane');
      case SystemActionType.nfc:
        return await _bridge.openSystemSetting('nfc');
      case SystemActionType.cast:
        return await _bridge.openSystemSetting('cast');
      case SystemActionType.location:
        return await _bridge.openSystemSetting('location');
      case SystemActionType.vpn:
        return await _bridge.openSystemSetting('vpn');
    }
  }

  @override
  bool isSupported(SystemActionType action) => true;
}

/// Fallback / mock implementation.
class MockSystemActionService implements ISystemActionService {
  @override
  Future<bool> executeAction(
    SystemActionType action, {
    dynamic parameter,
  }) async {
    debugPrint(
      '[Taply Mock] Action triggered: ${action.name}, param: $parameter',
    );
    return true;
  }

  @override
  bool isSupported(SystemActionType action) {
    return true;
  }
}

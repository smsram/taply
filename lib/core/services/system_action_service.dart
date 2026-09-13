import 'package:flutter/foundation.dart';

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

/// Phase 1 service implementation: Handles action dispatching cleanly
/// and provides feedback that native integration activates in Phase 2.
class MockSystemActionService implements ISystemActionService {
  @override
  Future<bool> executeAction(
    SystemActionType action, {
    dynamic parameter,
  }) async {
    debugPrint(
      '[Taply] System action triggered: ${action.name}, param: $parameter',
    );
    // In Phase 2: Dispatches to Android AccessibilityService / DevicePolicyManager / Settings APIs
    return true;
  }

  @override
  bool isSupported(SystemActionType action) {
    return true;
  }
}

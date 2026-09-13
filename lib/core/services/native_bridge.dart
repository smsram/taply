import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../shared/models/floating_button_config.dart';
import '../../shared/models/gesture_action.dart';

/// Centralized Flutter ↔ Android native bridge communicating over MethodChannel.
class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.taply.taply/channel',
  );

  static final NativeBridge instance = NativeBridge._();
  NativeBridge._();

  static bool enableInTests = false;

  /// Returns true only when running on a physical/emulated Android runtime
  /// and not in an automated widget/unit test environment.
  bool get isNativeAvailable {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (!enableInTests && Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return true;
  }

  // ==========================================
  // 1. OVERLAY SERVICE
  // ==========================================

  Future<bool> startOverlayService() async {
    if (!isNativeAvailable) return false;
    try {
      final res = await _channel.invokeMethod<Map>('startOverlay');
      return res?['success'] as bool? ?? false;
    } catch (e) {
      debugPrint('[NativeBridge] startOverlayService error: $e');
      return false;
    }
  }

  Future<bool> stopOverlayService() async {
    if (!isNativeAvailable) return false;
    try {
      final res = await _channel.invokeMethod<Map>('stopOverlay');
      return res?['success'] as bool? ?? false;
    } catch (e) {
      debugPrint('[NativeBridge] stopOverlayService error: $e');
      return false;
    }
  }

  Future<bool> isOverlayRunning() async {
    if (!isNativeAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('isOverlayRunning') ?? false;
    } catch (e) {
      debugPrint('[NativeBridge] isOverlayRunning error: $e');
      return false;
    }
  }

  Future<void> updateOverlayConfig({
    required FloatingButtonConfig config,
    required Map<GestureTrigger, GestureBinding> gestures,
  }) async {
    if (!isNativeAvailable) return;

    final gestureMap = <String, String>{};
    for (final entry in gestures.entries) {
      final key = entry.key.name; // e.g. singleTap, doubleTap, longPress
      final target = entry.value.target.name; // e.g. openPanel, screenshot
      gestureMap[key] = target;
    }

    try {
      await _channel.invokeMethod('updateOverlayConfig', {
        'size': config.size.toInt(),
        'opacity': config.opacity,
        'edgeSnapping': config.edgeSnapping,
        'hapticFeedback': config.hapticFeedback,
        'iconStyle': config.iconStyle.name,
        'gestures': gestureMap,
      });
    } catch (e) {
      debugPrint('[NativeBridge] updateOverlayConfig error: $e');
    }
  }

  // ==========================================
  // 2. PERMISSIONS
  // ==========================================

  Future<Map<String, bool>> checkAllPermissions() async {
    if (!isNativeAvailable) {
      return {
        'overlay': true,
        'accessibility': true,
        'notifications': true,
        'batteryOptimization': true,
      };
    }
    try {
      final res = await _channel.invokeMethod<Map>('checkAllPermissions');
      if (res != null) {
        return res.map((k, v) => MapEntry(k.toString(), v as bool));
      }
    } catch (e) {
      debugPrint('[NativeBridge] checkAllPermissions error: $e');
    }
    return {
      'overlay': false,
      'accessibility': false,
      'notifications': true,
      'batteryOptimization': false,
    };
  }

  Future<bool> checkPermission(String type) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('checkPermission', {
            'type': type,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] checkPermission error: $e');
      return false;
    }
  }

  Future<bool> requestPermission(String type) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('requestPermission', {
            'type': type,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] requestPermission error: $e');
      return false;
    }
  }

  // ==========================================
  // 3. APPS
  // ==========================================

  Future<List<Map<String, dynamic>>> getInstalledApps({
    bool includeIcons = true,
  }) async {
    if (!isNativeAvailable) {
      return [];
    }
    try {
      final res = await _channel.invokeMethod<List>('getInstalledApps', {
        'includeIcons': includeIcons,
      });
      if (res != null) {
        return res
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[NativeBridge] getInstalledApps error: $e');
    }
    return [];
  }

  Future<bool> launchApp(String packageName) async {
    if (!isNativeAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('launchApp', {
            'packageName': packageName,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] launchApp error: $e');
      return false;
    }
  }

  Future<bool> openAppDetails(String packageName) async {
    if (!isNativeAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('openAppDetails', {
            'packageName': packageName,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] openAppDetails error: $e');
      return false;
    }
  }

  Future<bool> uninstallApp(String packageName) async {
    if (!isNativeAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('uninstallApp', {
            'packageName': packageName,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] uninstallApp error: $e');
      return false;
    }
  }

  // ==========================================
  // 4. SYSTEM ACTIONS
  // ==========================================

  Future<Map<String, dynamic>> executeSystemAction(String action) async {
    if (!isNativeAvailable) {
      return {'success': true, 'simulated': true};
    }
    try {
      final res = await _channel.invokeMethod<Map>('executeSystemAction', {
        'action': action,
      });
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[NativeBridge] executeSystemAction error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> openSystemSetting(String setting) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('openSystemSetting', {
            'setting': setting,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] openSystemSetting error: $e');
      return false;
    }
  }

  // ==========================================
  // 5. VOLUME & SOUND
  // ==========================================

  Future<Map<String, dynamic>> getVolumeLevels() async {
    if (!isNativeAvailable) {
      return {
        'mediaVolume': 0.7,
        'ringVolume': 0.8,
        'alarmVolume': 0.8,
        'ringerMode': 'Normal',
      };
    }
    try {
      final res = await _channel.invokeMethod<Map>('getVolumeLevels');
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[NativeBridge] getVolumeLevels error: $e');
      return {
        'mediaVolume': 0.7,
        'ringVolume': 0.8,
        'alarmVolume': 0.8,
        'ringerMode': 'Normal',
      };
    }
  }

  Future<bool> setVolumeLevel(String stream, double volume) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('setVolumeLevel', {
            'stream': stream,
            'volume': volume,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] setVolumeLevel error: $e');
      return false;
    }
  }

  Future<bool> setSoundMode(String mode) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('setSoundMode', {
            'mode': mode,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] setSoundMode error: $e');
      return false;
    }
  }

  // ==========================================
  // 6. BRIGHTNESS
  // ==========================================

  Future<double> getBrightness() async {
    if (!isNativeAvailable) return 0.65;
    try {
      return await _channel.invokeMethod<double>('getBrightness') ?? 0.65;
    } catch (e) {
      debugPrint('[NativeBridge] getBrightness error: $e');
      return 0.65;
    }
  }

  Future<bool> setBrightness(double brightness) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('setBrightness', {
            'brightness': brightness,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] setBrightness error: $e');
      return false;
    }
  }

  // ==========================================
  // 7. FLASHLIGHT
  // ==========================================

  Future<bool> toggleFlashlight() async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('toggleFlashlight') ?? false;
    } catch (e) {
      debugPrint('[NativeBridge] toggleFlashlight error: $e');
      return false;
    }
  }

  Future<bool> isFlashlightOn() async {
    if (!isNativeAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('isFlashlightOn') ?? false;
    } catch (e) {
      debugPrint('[NativeBridge] isFlashlightOn error: $e');
      return false;
    }
  }

  // ==========================================
  // 8. MEDIA CONTROLS
  // ==========================================

  Future<bool> dispatchMediaKey(String keyAction) async {
    if (!isNativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('dispatchMediaKey', {
            'keyAction': keyAction,
          }) ??
          false;
    } catch (e) {
      debugPrint('[NativeBridge] dispatchMediaKey error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getMediaStatus() async {
    if (!isNativeAvailable) {
      return {'isPlaying': false, 'hasActiveSession': false};
    }
    try {
      final res = await _channel.invokeMethod<Map>('getMediaStatus');
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[NativeBridge] getMediaStatus error: $e');
      return {'isPlaying': false, 'hasActiveSession': false};
    }
  }

  // ==========================================
  // 9. COMPASS SENSOR
  // ==========================================

  Future<Map<String, dynamic>> getCompassHeading() async {
    if (!isNativeAvailable) {
      return {'available': true, 'heading': 45.0, 'accuracy': 'High'};
    }
    try {
      final res = await _channel.invokeMethod<Map>('getCompassHeading');
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[NativeBridge] getCompassHeading error: $e');
      return {'available': false, 'heading': 0.0, 'accuracy': 'Unavailable'};
    }
  }

  Future<void> startCompass() async {
    if (!isNativeAvailable) return;
    try {
      await _channel.invokeMethod('startCompass');
    } catch (e) {
      debugPrint('[NativeBridge] startCompass error: $e');
    }
  }

  Future<void> stopCompass() async {
    if (!isNativeAvailable) return;
    try {
      await _channel.invokeMethod('stopCompass');
    } catch (e) {
      debugPrint('[NativeBridge] stopCompass error: $e');
    }
  }

  // ==========================================
  // 9. SCREENSHOT
  // ==========================================

  Future<Map<String, dynamic>> takeScreenshot() async {
    if (!isNativeAvailable) {
      return {'success': true, 'simulated': true};
    }
    try {
      final res = await _channel.invokeMethod<Map>('takeScreenshot');
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[NativeBridge] takeScreenshot error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==========================================
  // 10. DEVICE INFO
  // ==========================================

  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (!isNativeAvailable) {
      return {
        'batteryLevel': 85,
        'isCharging': false,
        'batteryStatus': 'Discharging',
        'storageTotalBytes': 128000000000,
        'storageFreeBytes': 64000000000,
        'osVersion': 'Android 14 (API 34)',
        'deviceModel': 'Android Generic Phone',
        'deviceHardware': 'qcom',
      };
    }
    try {
      final res = await _channel.invokeMethod<Map>('getDeviceInfo');
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[NativeBridge] getDeviceInfo error: $e');
      return {};
    }
  }

  static Uint8List? decodeBase64Icon(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  void setNavigationHandler(void Function(String route) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNavigateRoute') {
        final route = call.arguments as String?;
        if (route != null && route.isNotEmpty) {
          handler(route);
        }
      }
    });
  }
}

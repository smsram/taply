import 'native_bridge.dart';

enum PermissionType {
  overlay,
  accessibility,
  notifications,
  batteryOptimization,
  writeSettings,
}

enum PermissionStatus { granted, denied, restricted, notDetermined }

abstract class IPermissionService {
  Future<PermissionStatus> checkPermission(PermissionType type);
  Future<bool> requestPermission(PermissionType type);
  Future<void> openPermissionSettings(PermissionType type);
  Future<Map<PermissionType, PermissionStatus>> checkAllPermissions();
}

/// Real Android Native Permission Service communicating over MethodChannel.
class NativePermissionService implements IPermissionService {
  final NativeBridge _bridge = NativeBridge.instance;

  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    final granted = await _bridge.checkPermission(type.name);
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  @override
  Future<bool> requestPermission(PermissionType type) async {
    return await _bridge.requestPermission(type.name);
  }

  @override
  Future<void> openPermissionSettings(PermissionType type) async {
    await _bridge.requestPermission(type.name);
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> checkAllPermissions() async {
    final raw = await _bridge.checkAllPermissions();
    return {
      PermissionType.overlay: (raw['overlay'] ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied,
      PermissionType.accessibility: (raw['accessibility'] ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied,
      PermissionType.notifications: (raw['notifications'] ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied,
      PermissionType.batteryOptimization: (raw['batteryOptimization'] ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied,
      PermissionType.writeSettings: (raw['writeSettings'] ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied,
    };
  }
}

/// Mock/fallback implementation for testing and non-Android environments.
class MockPermissionService implements IPermissionService {
  final Map<PermissionType, PermissionStatus> _statuses = {
    PermissionType.overlay: PermissionStatus.notDetermined,
    PermissionType.accessibility: PermissionStatus.notDetermined,
    PermissionType.notifications: PermissionStatus.granted,
    PermissionType.batteryOptimization: PermissionStatus.notDetermined,
    PermissionType.writeSettings: PermissionStatus.notDetermined,
  };

  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    return _statuses[type] ?? PermissionStatus.notDetermined;
  }

  @override
  Future<bool> requestPermission(PermissionType type) async {
    // Mock implementation for test environments
    _statuses[type] = PermissionStatus.granted;
    return true;
  }

  @override
  Future<void> openPermissionSettings(PermissionType type) async {
    // Mock implementation for test environments
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> checkAllPermissions() async {
    return Map.unmodifiable(_statuses);
  }
}

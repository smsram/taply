enum PermissionType {
  overlay,
  accessibility,
  notifications,
  batteryOptimization,
}

enum PermissionStatus { granted, denied, restricted, notDetermined }

abstract class IPermissionService {
  Future<PermissionStatus> checkPermission(PermissionType type);
  Future<bool> requestPermission(PermissionType type);
  Future<void> openPermissionSettings(PermissionType type);
  Future<Map<PermissionType, PermissionStatus>> checkAllPermissions();
}

/// Phase 1 implementation of IPermissionService.
/// Prepares architecture and local state. Native Android intent calls will be implemented in Phase 2.
class MockPermissionService implements IPermissionService {
  final Map<PermissionType, PermissionStatus> _statuses = {
    PermissionType.overlay: PermissionStatus.notDetermined,
    PermissionType.accessibility: PermissionStatus.notDetermined,
    PermissionType.notifications: PermissionStatus.granted,
    PermissionType.batteryOptimization: PermissionStatus.notDetermined,
  };

  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    return _statuses[type] ?? PermissionStatus.notDetermined;
  }

  @override
  Future<bool> requestPermission(PermissionType type) async {
    // Phase 1: Simulate granting for UI testing and state flow
    _statuses[type] = PermissionStatus.granted;
    return true;
  }

  @override
  Future<void> openPermissionSettings(PermissionType type) async {
    // In Phase 2: Invoke Android native intent (Settings.ACTION_MANAGE_OVERLAY_PERMISSION, etc.)
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> checkAllPermissions() async {
    return Map.unmodifiable(_statuses);
  }
}

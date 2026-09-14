import 'package:flutter/material.dart';

import '../../core/services/system_action_service.dart';
import '../../core/theme/app_colors.dart';

/// Metadata for a system action available across Taply
class CatalogAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final SystemActionType? systemAction;
  final String? toolRoute;

  const CatalogAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.systemAction,
    this.toolRoute,
  });
}

/// Unified catalog of all system shortcuts and tools available in Taply.
/// Serves as the single source of truth for Customize, Floating Panel,
/// Quick Actions, and Native Overlay synchronization.
class SystemActionCatalog {
  static const List<CatalogAction> allActions = [
    // 1. Core Navigation
    CatalogAction(
      id: 'back',
      title: 'Back',
      subtitle: 'Simulate system back navigation',
      icon: Icons.arrow_back_rounded,
      color: Color(0xFF64748B),
      systemAction: SystemActionType.back,
    ),
    CatalogAction(
      id: 'home',
      title: 'Home',
      subtitle: 'Return to launcher home screen',
      icon: Icons.home_rounded,
      color: AppColors.primary,
      systemAction: SystemActionType.home,
    ),
    CatalogAction(
      id: 'recent_apps',
      title: 'Recents',
      subtitle: 'Open Android multitasking overview',
      icon: Icons.view_carousel_rounded,
      color: Color(0xFF06B6D4),
      systemAction: SystemActionType.recentApps,
    ),
    CatalogAction(
      id: 'lock_screen',
      title: 'Lock Screen',
      subtitle: 'Turn off screen immediately',
      icon: Icons.lock_outline_rounded,
      color: Color(0xFFEF4444),
      systemAction: SystemActionType.lockScreen,
    ),
    CatalogAction(
      id: 'screenshot',
      title: 'Screenshot',
      subtitle: 'Capture screen without hardware buttons',
      icon: Icons.screenshot_rounded,
      color: Color(0xFF14B8A6),
      systemAction: SystemActionType.screenshot,
    ),
    CatalogAction(
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'Pull down notification shade',
      icon: Icons.notifications_rounded,
      color: Color(0xFF3B82F6),
      systemAction: SystemActionType.openNotifications,
    ),
    CatalogAction(
      id: 'quick_settings',
      title: 'Quick Settings',
      subtitle: 'Expand system quick settings shade',
      icon: Icons.tune_rounded,
      color: Color(0xFF0284C7),
      systemAction: SystemActionType.openQuickSettings,
    ),

    // 2. Hardware & Controls
    CatalogAction(
      id: 'volume',
      title: 'Volume',
      subtitle: 'Open volume slider controls',
      icon: Icons.volume_up_rounded,
      color: Color(0xFF8B5CF6),
      toolRoute: '/quick-controls',
    ),
    CatalogAction(
      id: 'brightness',
      title: 'Brightness',
      subtitle: 'Control screen luminosity',
      icon: Icons.brightness_6_rounded,
      color: Color(0xFFF59E0B),
      toolRoute: '/quick-controls',
    ),
    CatalogAction(
      id: 'flashlight',
      title: 'Flashlight',
      subtitle: 'Toggle camera LED torch',
      icon: Icons.flashlight_on_rounded,
      color: Color(0xFFEAB308),
      systemAction: SystemActionType.toggleFlashlight,
    ),
    CatalogAction(
      id: 'auto_rotate',
      title: 'Auto Rotate',
      subtitle: 'Toggle screen rotation lock',
      icon: Icons.screen_rotation_rounded,
      color: Color(0xFF10B981),
      systemAction: SystemActionType.screenRotation,
    ),

    // 3. Connectivity
    CatalogAction(
      id: 'wifi',
      title: 'Wi-Fi',
      subtitle: 'Toggle wireless network settings',
      icon: Icons.wifi_rounded,
      color: Color(0xFF2563EB),
      systemAction: SystemActionType.wifi,
    ),
    CatalogAction(
      id: 'bluetooth',
      title: 'Bluetooth',
      subtitle: 'Manage connected devices',
      icon: Icons.bluetooth_rounded,
      color: Color(0xFF3B82F6),
      systemAction: SystemActionType.bluetooth,
    ),
    CatalogAction(
      id: 'airplane',
      title: 'Airplane Mode',
      subtitle: 'System wireless radios toggle',
      icon: Icons.airplanemode_active_rounded,
      color: Color(0xFFEC4899),
      systemAction: SystemActionType.airplaneMode,
    ),

    // 4. In-Panel Utilities & Tools
    CatalogAction(
      id: 'calculator',
      title: 'Calculator',
      subtitle: 'Quick floating calculator',
      icon: Icons.calculate_rounded,
      color: Color(0xFF6366F1),
      toolRoute: '/tools/calculator',
    ),
    CatalogAction(
      id: 'timer',
      title: 'Timer',
      subtitle: 'Countdown timer with alerts',
      icon: Icons.timer_rounded,
      color: Color(0xFFF59E0B),
      toolRoute: '/tools/timer',
    ),
    CatalogAction(
      id: 'stopwatch',
      title: 'Stopwatch',
      subtitle: 'Millisecond-precision lap timer',
      icon: Icons.timer_outlined,
      color: Color(0xFF10B981),
      toolRoute: '/tools/stopwatch',
    ),
    CatalogAction(
      id: 'notes',
      title: 'Quick Notes',
      subtitle: 'Scratchpad for temporary thoughts',
      icon: Icons.note_alt_rounded,
      color: Color(0xFF8B5CF6),
      toolRoute: '/tools/notes',
    ),
    CatalogAction(
      id: 'device_info',
      title: 'Device Telemetry',
      subtitle: 'RAM, battery, and storage metrics',
      icon: Icons.analytics_rounded,
      color: Color(0xFF06B6D4),
      toolRoute: '/tools/device-info',
    ),
    CatalogAction(
      id: 'compass',
      title: 'Compass',
      subtitle: 'Real-time digital orientation',
      icon: Icons.explore_rounded,
      color: Color(0xFF0D9488),
      toolRoute: '/tools/compass',
    ),
    CatalogAction(
      id: 'apps',
      title: 'App Drawer',
      subtitle: 'Mini app launcher drawer',
      icon: Icons.apps_rounded,
      color: Color(0xFF14B8A6),
      toolRoute: '/app-drawer',
    ),
  ];

  /// Normalize action key to handle aliases seamlessly
  static String normalizeId(String rawId) {
    final lower = rawId.trim().toLowerCase();
    switch (lower) {
      case 'recents':
      case 'recentapps':
      case 'recent_apps':
        return 'recent_apps';
      case 'lock':
      case 'lockscreen':
      case 'lock_screen':
        return 'lock_screen';
      case 'notifs':
      case 'notifications':
        return 'notifications';
      case 'quicksettings':
      case 'quick_settings':
      case 'quick':
        return 'quick_settings';
      case 'torch':
      case 'flashlight':
        return 'flashlight';
      case 'volume':
      case 'vol':
      case 'volume_dialog':
        return 'volume';
      case 'calc':
      case 'calculator':
        return 'calculator';
      case 'notes':
      case 'quick_notes':
        return 'notes';
      case 'device':
      case 'deviceinfo':
      case 'device_info':
        return 'device_info';
      case 'app_drawer':
      case 'appdrawer':
      case 'apps':
        return 'apps';
      default:
        return lower;
    }
  }

  /// Get action metadata for an ID with alias fallback
  static CatalogAction getAction(String id) {
    final normalized = normalizeId(id);
    for (final action in allActions) {
      if (action.id == normalized) {
        return action;
      }
    }
    // Fallback for unknown action
    return CatalogAction(
      id: id,
      title: id.replaceAll('_', ' ').capitalize(),
      subtitle: 'System action',
      icon: Icons.extension_rounded,
      color: AppColors.primary,
    );
  }

  /// Return all available catalog actions not yet in the active action order
  static List<CatalogAction> getAvailableActionsToAdd(
    List<String> currentOrder,
  ) {
    final currentNormalized = currentOrder.map(normalizeId).toSet();
    return allActions
        .where((a) => !currentNormalized.contains(normalizeId(a.id)))
        .toList();
  }
}

extension _StringExt on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

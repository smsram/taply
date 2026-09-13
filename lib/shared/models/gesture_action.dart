import 'package:flutter/material.dart';

enum GestureTrigger {
  singleTap,
  doubleTap,
  longPress,
  swipeUp,
  swipeDown,
  swipeLeft,
  swipeRight,
}

extension GestureTriggerExtension on GestureTrigger {
  String get displayName {
    switch (this) {
      case GestureTrigger.singleTap:
        return 'Single Tap';
      case GestureTrigger.doubleTap:
        return 'Double Tap';
      case GestureTrigger.longPress:
        return 'Long Press';
      case GestureTrigger.swipeUp:
        return 'Swipe Up';
      case GestureTrigger.swipeDown:
        return 'Swipe Down';
      case GestureTrigger.swipeLeft:
        return 'Swipe Left';
      case GestureTrigger.swipeRight:
        return 'Swipe Right';
    }
  }

  String get description {
    switch (this) {
      case GestureTrigger.singleTap:
        return 'Tap the floating button once';
      case GestureTrigger.doubleTap:
        return 'Tap the floating button twice quickly';
      case GestureTrigger.longPress:
        return 'Press and hold the floating button';
      case GestureTrigger.swipeUp:
        return 'Flick the button upward';
      case GestureTrigger.swipeDown:
        return 'Flick the button downward';
      case GestureTrigger.swipeLeft:
        return 'Flick the button to the left';
      case GestureTrigger.swipeRight:
        return 'Flick the button to the right';
    }
  }

  IconData get icon {
    switch (this) {
      case GestureTrigger.singleTap:
        return Icons.touch_app_rounded;
      case GestureTrigger.doubleTap:
        return Icons.ads_click_rounded;
      case GestureTrigger.longPress:
        return Icons.pan_tool_alt_rounded;
      case GestureTrigger.swipeUp:
        return Icons.arrow_upward_rounded;
      case GestureTrigger.swipeDown:
        return Icons.arrow_downward_rounded;
      case GestureTrigger.swipeLeft:
        return Icons.arrow_back_rounded;
      case GestureTrigger.swipeRight:
        return Icons.arrow_forward_rounded;
    }
  }
}

enum GestureActionTarget {
  openPanel,
  screenshot,
  flashlight,
  appDrawer,
  quickControls,
  openApp,
  openTool,
  systemAction,
  none,
}

extension GestureActionTargetExtension on GestureActionTarget {
  String get displayName {
    switch (this) {
      case GestureActionTarget.openPanel:
        return 'Open Taply Panel';
      case GestureActionTarget.screenshot:
        return 'Screenshot';
      case GestureActionTarget.flashlight:
        return 'Flashlight';
      case GestureActionTarget.appDrawer:
        return 'App Drawer';
      case GestureActionTarget.quickControls:
        return 'Quick Controls';
      case GestureActionTarget.openApp:
        return 'Open App';
      case GestureActionTarget.openTool:
        return 'Open Tool';
      case GestureActionTarget.systemAction:
        return 'System Action';
      case GestureActionTarget.none:
        return 'None';
    }
  }

  IconData get icon {
    switch (this) {
      case GestureActionTarget.openPanel:
        return Icons.dashboard_customize_rounded;
      case GestureActionTarget.screenshot:
        return Icons.screenshot_rounded;
      case GestureActionTarget.flashlight:
        return Icons.flashlight_on_rounded;
      case GestureActionTarget.appDrawer:
        return Icons.apps_rounded;
      case GestureActionTarget.quickControls:
        return Icons.tune_rounded;
      case GestureActionTarget.openApp:
        return Icons.launch_rounded;
      case GestureActionTarget.openTool:
        return Icons.construction_rounded;
      case GestureActionTarget.systemAction:
        return Icons.settings_suggest_rounded;
      case GestureActionTarget.none:
        return Icons.block_rounded;
    }
  }
}

class GestureBinding {
  final GestureTrigger trigger;
  final GestureActionTarget target;
  final String?
  customPayload; // Package name or tool id if target is openApp / openTool

  const GestureBinding({
    required this.trigger,
    required this.target,
    this.customPayload,
  });

  GestureBinding copyWith({
    GestureTrigger? trigger,
    GestureActionTarget? target,
    String? customPayload,
  }) {
    return GestureBinding(
      trigger: trigger ?? this.trigger,
      target: target ?? this.target,
      customPayload: customPayload ?? this.customPayload,
    );
  }
}

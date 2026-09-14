enum PanelLayoutStyle {
  multiPage,
  grid3x3,
  grid4x2,
  compactWheel,
  verticalList,
}

extension PanelLayoutStyleExtension on PanelLayoutStyle {
  String get displayName {
    switch (this) {
      case PanelLayoutStyle.multiPage:
        return 'Multi-Page Carousel (Recommended)';
      case PanelLayoutStyle.grid3x3:
        return '3 × 3 Grid';
      case PanelLayoutStyle.grid4x2:
        return '4 × 2 Grid';
      case PanelLayoutStyle.compactWheel:
        return 'Radial Wheel';
      case PanelLayoutStyle.verticalList:
        return 'Compact List';
    }
  }

  String get description {
    switch (this) {
      case PanelLayoutStyle.multiPage:
        return 'Swipable pages: Actions, Apps, Tools, Controls & More';
      case PanelLayoutStyle.grid3x3:
        return 'Balanced layout with up to 9 quick tiles';
      case PanelLayoutStyle.grid4x2:
        return 'Wide layout for larger screens';
      case PanelLayoutStyle.compactWheel:
        return 'Circular arrangement centered around touch';
      case PanelLayoutStyle.verticalList:
        return 'Single-column one-handed access';
    }
  }
}

enum PanelAnimationType { fadeScale, slideUp, spring, none }

extension PanelAnimationTypeExtension on PanelAnimationType {
  String get displayName {
    switch (this) {
      case PanelAnimationType.fadeScale:
        return 'Fade + Scale';
      case PanelAnimationType.slideUp:
        return 'Slide Up';
      case PanelAnimationType.spring:
        return 'Gentle Spring';
      case PanelAnimationType.none:
        return 'None (Instant)';
    }
  }
}

class PanelConfig {
  final PanelLayoutStyle layoutStyle;
  final PanelAnimationType animationType;
  final int maxActions;
  final List<String> actionOrder;
  final List<String> appShortcutPackages;
  final bool showLabels;
  final bool closeOnAction;

  const PanelConfig({
    this.layoutStyle = PanelLayoutStyle.multiPage,
    this.animationType = PanelAnimationType.fadeScale,
    this.maxActions = 8,
    this.actionOrder = const [
      'screenshot',
      'volume',
      'brightness',
      'home',
      'back',
      'recent_apps',
      'lock_screen',
      'flashlight',
    ],
    this.appShortcutPackages = const [
      'com.google.android.dialer',
      'com.google.android.apps.messaging',
      'com.google.android.GoogleCamera',
      'com.android.chrome',
    ],
    this.showLabels = true,
    this.closeOnAction = true,
  });

  PanelConfig copyWith({
    PanelLayoutStyle? layoutStyle,
    PanelAnimationType? animationType,
    int? maxActions,
    List<String>? actionOrder,
    List<String>? appShortcutPackages,
    bool? showLabels,
    bool? closeOnAction,
  }) {
    return PanelConfig(
      layoutStyle: layoutStyle ?? this.layoutStyle,
      animationType: animationType ?? this.animationType,
      maxActions: maxActions ?? this.maxActions,
      actionOrder: actionOrder ?? this.actionOrder,
      appShortcutPackages: appShortcutPackages ?? this.appShortcutPackages,
      showLabels: showLabels ?? this.showLabels,
      closeOnAction: closeOnAction ?? this.closeOnAction,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layoutStyle': layoutStyle.name,
      'animationType': animationType.name,
      'maxActions': maxActions,
      'actionOrder': actionOrder,
      'appShortcutPackages': appShortcutPackages,
      'showLabels': showLabels,
      'closeOnAction': closeOnAction,
    };
  }

  factory PanelConfig.fromMap(Map<String, dynamic> map) {
    return PanelConfig(
      layoutStyle: PanelLayoutStyle.values.firstWhere(
        (e) => e.name == map['layoutStyle'],
        orElse: () => PanelLayoutStyle.multiPage,
      ),
      animationType: PanelAnimationType.values.firstWhere(
        (e) => e.name == map['animationType'],
        orElse: () => PanelAnimationType.fadeScale,
      ),
      maxActions: map['maxActions'] as int? ?? 8,
      actionOrder:
          (map['actionOrder'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'screenshot',
            'volume',
            'brightness',
            'home',
            'back',
            'recent_apps',
            'lock_screen',
            'flashlight',
          ],
      appShortcutPackages:
          (map['appShortcutPackages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'com.google.android.dialer',
            'com.google.android.apps.messaging',
            'com.google.android.GoogleCamera',
            'com.android.chrome',
          ],
      showLabels: map['showLabels'] as bool? ?? true,
      closeOnAction: map['closeOnAction'] as bool? ?? true,
    );
  }
}

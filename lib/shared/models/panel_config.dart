enum PanelLayoutStyle { grid3x3, grid4x2, compactWheel, verticalList }

extension PanelLayoutStyleExtension on PanelLayoutStyle {
  String get displayName {
    switch (this) {
      case PanelLayoutStyle.grid3x3:
        return '3 × 3 Grid (Recommended)';
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

class PanelConfig {
  final PanelLayoutStyle layoutStyle;
  final int maxActions;
  final List<String> actionOrder;
  final List<String> appShortcutPackages;
  final bool showLabels;
  final bool closeOnAction;

  const PanelConfig({
    this.layoutStyle = PanelLayoutStyle.grid3x3,
    this.maxActions = 8,
    this.actionOrder = const [
      'home',
      'back',
      'recent_apps',
      'lock_screen',
      'screenshot',
      'volume',
      'brightness',
      'apps',
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
    int? maxActions,
    List<String>? actionOrder,
    List<String>? appShortcutPackages,
    bool? showLabels,
    bool? closeOnAction,
  }) {
    return PanelConfig(
      layoutStyle: layoutStyle ?? this.layoutStyle,
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
        orElse: () => PanelLayoutStyle.grid3x3,
      ),
      maxActions: map['maxActions'] as int? ?? 8,
      actionOrder:
          (map['actionOrder'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'home',
            'back',
            'recent_apps',
            'lock_screen',
            'screenshot',
            'volume',
            'brightness',
            'apps',
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

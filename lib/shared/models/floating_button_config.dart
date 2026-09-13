import 'package:flutter/material.dart';

enum ButtonIconStyle { defaultDot, minimal, circle, square, custom }

extension ButtonIconStyleExtension on ButtonIconStyle {
  String get displayName {
    switch (this) {
      case ButtonIconStyle.defaultDot:
        return 'Default';
      case ButtonIconStyle.minimal:
        return 'Minimal';
      case ButtonIconStyle.circle:
        return 'Circle';
      case ButtonIconStyle.square:
        return 'Square';
      case ButtonIconStyle.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case ButtonIconStyle.defaultDot:
        return Icons.adjust_rounded;
      case ButtonIconStyle.minimal:
        return Icons.fiber_manual_record_rounded;
      case ButtonIconStyle.circle:
        return Icons.radio_button_unchecked_rounded;
      case ButtonIconStyle.square:
        return Icons.crop_square_rounded;
      case ButtonIconStyle.custom:
        return Icons.star_rounded;
    }
  }
}

enum ButtonAnimationType { none, pulse, fade }

class FloatingButtonConfig {
  final double size; // 40.0 - 72.0, default 56.0
  final double opacity; // 0.2 - 1.0, default 0.85
  final double idleOpacity; // 0.1 - 1.0, default 0.45
  final bool autoHideIdle;
  final int idleTimeoutSeconds;
  final bool edgeSnapping;
  final bool hapticFeedback;
  final ButtonIconStyle iconStyle;
  final ButtonAnimationType animationType;
  final Color customColor;

  const FloatingButtonConfig({
    this.size = 56.0,
    this.opacity = 0.85,
    this.idleOpacity = 0.45,
    this.autoHideIdle = true,
    this.idleTimeoutSeconds = 3,
    this.edgeSnapping = true,
    this.hapticFeedback = true,
    this.iconStyle = ButtonIconStyle.defaultDot,
    this.animationType = ButtonAnimationType.none,
    this.customColor = const Color(0xFF2563EB),
  });

  FloatingButtonConfig copyWith({
    double? size,
    double? opacity,
    double? idleOpacity,
    bool? autoHideIdle,
    int? idleTimeoutSeconds,
    bool? edgeSnapping,
    bool? hapticFeedback,
    ButtonIconStyle? iconStyle,
    ButtonAnimationType? animationType,
    Color? customColor,
  }) {
    return FloatingButtonConfig(
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      idleOpacity: idleOpacity ?? this.idleOpacity,
      autoHideIdle: autoHideIdle ?? this.autoHideIdle,
      idleTimeoutSeconds: idleTimeoutSeconds ?? this.idleTimeoutSeconds,
      edgeSnapping: edgeSnapping ?? this.edgeSnapping,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      iconStyle: iconStyle ?? this.iconStyle,
      animationType: animationType ?? this.animationType,
      customColor: customColor ?? this.customColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'opacity': opacity,
      'idleOpacity': idleOpacity,
      'autoHideIdle': autoHideIdle,
      'idleTimeoutSeconds': idleTimeoutSeconds,
      'edgeSnapping': edgeSnapping,
      'hapticFeedback': hapticFeedback,
      'iconStyle': iconStyle.name,
      'animationType': animationType.name,
      'customColor': customColor.value,
    };
  }

  factory FloatingButtonConfig.fromMap(Map<String, dynamic> map) {
    return FloatingButtonConfig(
      size: (map['size'] as num?)?.toDouble() ?? 56.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.85,
      idleOpacity: (map['idleOpacity'] as num?)?.toDouble() ?? 0.45,
      autoHideIdle: map['autoHideIdle'] as bool? ?? true,
      idleTimeoutSeconds: map['idleTimeoutSeconds'] as int? ?? 3,
      edgeSnapping: map['edgeSnapping'] as bool? ?? true,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      iconStyle: ButtonIconStyle.values.firstWhere(
        (e) => e.name == map['iconStyle'],
        orElse: () => ButtonIconStyle.defaultDot,
      ),
      animationType: ButtonAnimationType.values.firstWhere(
        (e) => e.name == map['animationType'],
        orElse: () => ButtonAnimationType.none,
      ),
      customColor: map['customColor'] != null
          ? Color(map['customColor'] as int)
          : const Color(0xFF2563EB),
    );
  }
}

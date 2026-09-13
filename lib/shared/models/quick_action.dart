import 'package:flutter/material.dart';

import '../../core/services/system_action_service.dart';

enum QuickActionCategory { system, sound, display, connectivity }

class QuickActionItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final QuickActionCategory category;
  final SystemActionType? systemAction;
  final bool isToggle;
  final bool isEnabled;
  final double? value; // For sliders (e.g. volume, brightness)

  const QuickActionItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    required this.category,
    this.systemAction,
    this.isToggle = false,
    this.isEnabled = false,
    this.value,
  });

  QuickActionItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? color,
    QuickActionCategory? category,
    SystemActionType? systemAction,
    bool? isToggle,
    bool? isEnabled,
    double? value,
  }) {
    return QuickActionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      systemAction: systemAction ?? this.systemAction,
      isToggle: isToggle ?? this.isToggle,
      isEnabled: isEnabled ?? this.isEnabled,
      value: value ?? this.value,
    );
  }
}

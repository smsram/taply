import 'package:flutter/material.dart';

enum ToolCategory { utilities, visionAndSensors, deviceInsights }

extension ToolCategoryExtension on ToolCategory {
  String get displayName {
    switch (this) {
      case ToolCategory.utilities:
        return 'Daily Utilities';
      case ToolCategory.visionAndSensors:
        return 'Vision & Sensors';
      case ToolCategory.deviceInsights:
        return 'Device Insights';
    }
  }

  String get description {
    switch (this) {
      case ToolCategory.utilities:
        return 'Essential tools for quick day-to-day calculations and timing';
      case ToolCategory.visionAndSensors:
        return 'Hardware camera and directional tools';
      case ToolCategory.deviceInsights:
        return 'Diagnostics and system resource information';
    }
  }
}

class ToolItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final ToolCategory category;
  final bool isImplementedInPhase1; // true for Calculator, Timer, Stopwatch
  final String routePath;

  const ToolItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.category,
    this.isImplementedInPhase1 = false,
    required this.routePath,
  });
}

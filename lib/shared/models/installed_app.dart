import 'dart:typed_data';

import 'package:flutter/material.dart';

enum AppLaunchMode { normal, floating }

/// Represents an installed Android application.
class InstalledApp {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final IconData defaultIcon;
  final Color iconColor;
  final Uint8List? iconBytes;
  final bool isSystemApp;
  final bool isFavorite;
  final bool isHidden;
  final AppLaunchMode launchMode;
  final DateTime? lastUsedAt;
  final int usageCount;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.versionName = '1.0.0',
    this.versionCode = 1,
    this.defaultIcon = Icons.android_rounded,
    this.iconColor = const Color(0xFF2563EB),
    this.iconBytes,
    this.isSystemApp = false,
    this.isFavorite = false,
    this.isHidden = false,
    this.launchMode = AppLaunchMode.normal,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  InstalledApp copyWith({
    String? packageName,
    String? appName,
    String? versionName,
    int? versionCode,
    IconData? defaultIcon,
    Color? iconColor,
    Uint8List? iconBytes,
    bool? isSystemApp,
    bool? isFavorite,
    bool? isHidden,
    AppLaunchMode? launchMode,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return InstalledApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      defaultIcon: defaultIcon ?? this.defaultIcon,
      iconColor: iconColor ?? this.iconColor,
      iconBytes: iconBytes ?? this.iconBytes,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isFavorite: isFavorite ?? this.isFavorite,
      isHidden: isHidden ?? this.isHidden,
      launchMode: launchMode ?? this.launchMode,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'versionName': versionName,
      'versionCode': versionCode,
      'isSystemApp': isSystemApp,
      'isFavorite': isFavorite,
      'isHidden': isHidden,
      'launchMode': launchMode.index,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  factory InstalledApp.fromJson(Map<String, dynamic> json) {
    return InstalledApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      versionName: json['versionName'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      isSystemApp: json['isSystemApp'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      launchMode: AppLaunchMode.values[json['launchMode'] as int? ?? 0],
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }
}

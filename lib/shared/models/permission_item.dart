import 'package:flutter/material.dart';

import '../../core/services/permission_service.dart';

class PermissionItem {
  final PermissionType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final PermissionStatus status;
  final bool isMandatory;

  const PermissionItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.status = PermissionStatus.notDetermined,
    this.isMandatory = false,
  });

  PermissionItem copyWith({
    PermissionType? type,
    String? title,
    String? subtitle,
    String? description,
    IconData? icon,
    PermissionStatus? status,
    bool? isMandatory,
  }) {
    return PermissionItem(
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      isMandatory: isMandatory ?? this.isMandatory,
    );
  }
}

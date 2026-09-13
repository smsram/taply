import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import 'section_header.dart';

/// Clean section container that combines an optional SectionHeader with grouped child widgets.
class AppSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool isCard;
  final EdgeInsetsGeometry padding;

  const AppSection({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.isCard = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          SectionHeader(title: title!, subtitle: subtitle, trailing: trailing),
        Padding(
          padding: padding,
          child: isCard
              ? Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: context.colorScheme.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
        ),
      ],
    );
  }
}

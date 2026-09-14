import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  AppLocalizations get loc => AppLocalizations.of(this);

  // Screen size helpers for responsive layouts
  bool get isSmallPhone => screenSize.width < 360;
  bool get isTablet => screenSize.width >= 600;

  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

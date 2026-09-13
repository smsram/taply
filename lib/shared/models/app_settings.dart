import '../../core/theme/app_theme.dart';
import 'floating_button_config.dart';
import 'panel_config.dart';
import 'installed_app.dart';

class AppSettings {
  final bool isAssistantEnabled;
  final bool startWithDevice;
  final String language;
  final bool hapticFeedback;
  final AppThemeMode themeMode;
  final FloatingButtonConfig buttonConfig;
  final PanelConfig panelConfig;
  final AppLaunchMode defaultLaunchMode;
  final bool isOnboardingCompleted;

  const AppSettings({
    this.isAssistantEnabled = true,
    this.startWithDevice = true,
    this.language = 'System default',
    this.hapticFeedback = true,
    this.themeMode = AppThemeMode.system,
    this.buttonConfig = const FloatingButtonConfig(),
    this.panelConfig = const PanelConfig(),
    this.defaultLaunchMode = AppLaunchMode.normal,
    this.isOnboardingCompleted = true,
  });

  AppSettings copyWith({
    bool? isAssistantEnabled,
    bool? startWithDevice,
    String? language,
    bool? hapticFeedback,
    AppThemeMode? themeMode,
    FloatingButtonConfig? buttonConfig,
    PanelConfig? panelConfig,
    AppLaunchMode? defaultLaunchMode,
    bool? isOnboardingCompleted,
  }) {
    return AppSettings(
      isAssistantEnabled: isAssistantEnabled ?? this.isAssistantEnabled,
      startWithDevice: startWithDevice ?? this.startWithDevice,
      language: language ?? this.language,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      themeMode: themeMode ?? this.themeMode,
      buttonConfig: buttonConfig ?? this.buttonConfig,
      panelConfig: panelConfig ?? this.panelConfig,
      defaultLaunchMode: defaultLaunchMode ?? this.defaultLaunchMode,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }
}

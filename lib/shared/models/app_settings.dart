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
    this.isOnboardingCompleted = false,
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

  Map<String, dynamic> toMap() {
    return {
      'isAssistantEnabled': isAssistantEnabled,
      'startWithDevice': startWithDevice,
      'language': language,
      'hapticFeedback': hapticFeedback,
      'themeMode': themeMode.name,
      'buttonConfig': buttonConfig.toMap(),
      'panelConfig': panelConfig.toMap(),
      'defaultLaunchMode': defaultLaunchMode.name,
      'isOnboardingCompleted': isOnboardingCompleted,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isAssistantEnabled: map['isAssistantEnabled'] as bool? ?? true,
      startWithDevice: map['startWithDevice'] as bool? ?? true,
      language: map['language'] as String? ?? 'System default',
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      buttonConfig: map['buttonConfig'] is Map<String, dynamic>
          ? FloatingButtonConfig.fromMap(
              Map<String, dynamic>.from(map['buttonConfig'] as Map),
            )
          : const FloatingButtonConfig(),
      panelConfig: map['panelConfig'] is Map<String, dynamic>
          ? PanelConfig.fromMap(
              Map<String, dynamic>.from(map['panelConfig'] as Map),
            )
          : const PanelConfig(),
      defaultLaunchMode: AppLaunchMode.values.firstWhere(
        (e) => e.name == map['defaultLaunchMode'],
        orElse: () => AppLaunchMode.normal,
      ),
      isOnboardingCompleted: map['isOnboardingCompleted'] as bool? ?? false,
    );
  }
}

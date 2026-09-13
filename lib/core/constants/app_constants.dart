/// Core application constants for Taply.
class AppConstants {
  AppConstants._();

  static const String appName = 'Taply';
  static const String appDisplayName = 'Taply – Assistive Touch';
  static const String appTagline = 'Everything, one tap away.';
  static const String appVersion = '1.0.0 (Phase 1)';
  static const String buildNumber = '1';

  // Persistence Keys
  static const String keyFirstRun = 'taply_first_run';
  static const String keyAssistantEnabled = 'taply_assistant_enabled';
  static const String keyThemeMode = 'taply_theme_mode';
  static const String keyButtonSize = 'taply_button_size';
  static const String keyButtonOpacity = 'taply_button_opacity';
  static const String keyButtonIcon = 'taply_button_icon';
  static const String keyEdgeSnapping = 'taply_edge_snapping';
  static const String keyHapticFeedback = 'taply_haptic_feedback';
  static const String keyAnimationSpeed = 'taply_animation_speed';
  static const String keySingleTapAction = 'taply_gesture_single_tap';
  static const String keyDoubleTapAction = 'taply_gesture_double_tap';
  static const String keyLongPressAction = 'taply_gesture_long_press';
  static const String keySwipeUpAction = 'taply_gesture_swipe_up';
  static const String keySwipeDownAction = 'taply_gesture_swipe_down';
  static const String keySwipeLeftAction = 'taply_gesture_swipe_left';
  static const String keySwipeRightAction = 'taply_gesture_swipe_right';
  static const String keyFavoriteApps = 'taply_favorite_apps';
  static const String keyHiddenApps = 'taply_hidden_apps';
  static const String keyPanelLayout = 'taply_panel_layout';
  static const String keyDefaultLaunchMode = 'taply_default_launch_mode';

  // Legal and Links
  static const String privacyPolicyUrl = 'https://taply.app/privacy';
  static const String termsOfServiceUrl = 'https://taply.app/terms';
  static const String contactEmail = 'support@taply.app';
  static const String sourceRepoUrl = 'https://github.com/taply/taply';
}

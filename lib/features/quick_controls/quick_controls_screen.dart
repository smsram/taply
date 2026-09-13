import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/services/system_action_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/app_section.dart';
import '../../shared/widgets/slider_row.dart';
import '../../shared/widgets/toggle_row.dart';

class QuickControlsScreen extends ConsumerStatefulWidget {
  const QuickControlsScreen({super.key});

  @override
  ConsumerState<QuickControlsScreen> createState() =>
      _QuickControlsScreenState();
}

class _QuickControlsScreenState extends ConsumerState<QuickControlsScreen> {
  // Volume state
  double _mediaVolume = 0.7;
  double _ringVolume = 0.8;
  double _alarmVolume = 0.9;
  bool _isMuted = false;
  bool _isVibrate = false;
  String _soundMode = 'Normal';

  // Display state
  double _brightness = 0.65;
  bool _autoBrightness = true;

  // Connectivity states
  final Map<String, bool> _connectivityToggles = {
    'Wi-Fi': true,
    'Bluetooth': true,
    'Mobile Data': true,
    'Hotspot': false,
    'Airplane Mode': false,
    'NFC': true,
    'Cast': false,
    'Location': true,
    'VPN': false,
  };

  void _triggerAction(SystemActionType type, String name) {
    ref.read(systemActionServiceProvider).executeAction(type);
    context.showSnackBar('$name action queued (Phase 2 Native Service)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Controls')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // Informational Banner
          Container(
            margin: const EdgeInsets.all(AppSpacing.base),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? AppColors.darkElevatedSurface
                  : const Color(0xFFEFF6FF),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: context.isDarkMode
                    ? AppColors.darkBorder
                    : AppColors.primary.withOpacity(0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clean Control Architecture',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.isDarkMode
                              ? AppColors.darkPrimaryText
                              : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'System toggles and audio controls below are wired to the dispatch service layer. Native hardware toggles will execute in Phase 2.',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 1. SYSTEM
          AppSection(
            title: 'System Actions',
            subtitle: 'Core navigation and device management gestures',
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: context.isSmallPhone ? 2 : 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.15,
                children: [
                  ActionTile(
                    title: 'Home',
                    icon: Icons.home_rounded,
                    onTap: () => _triggerAction(SystemActionType.home, 'Home'),
                  ),
                  ActionTile(
                    title: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onTap: () => _triggerAction(SystemActionType.back, 'Back'),
                  ),
                  ActionTile(
                    title: 'Recent Apps',
                    icon: Icons.view_carousel_rounded,
                    onTap: () => _triggerAction(
                      SystemActionType.recentApps,
                      'Recent Apps',
                    ),
                  ),
                  ActionTile(
                    title: 'Lock Screen',
                    icon: Icons.lock_outline_rounded,
                    onTap: () => _triggerAction(
                      SystemActionType.lockScreen,
                      'Lock Screen',
                    ),
                  ),
                  ActionTile(
                    title: 'Screenshot',
                    icon: Icons.screenshot_rounded,
                    onTap: () => _triggerAction(
                      SystemActionType.screenshot,
                      'Screenshot',
                    ),
                  ),
                  ActionTile(
                    title: 'Rotation',
                    icon: Icons.screen_rotation_rounded,
                    onTap: () => _triggerAction(
                      SystemActionType.screenRotation,
                      'Screen Rotation',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. SOUND
          AppSection(
            title: 'Sound & Audio',
            subtitle: 'Volume streams and vibration profile',
            isCard: true,
            children: [
              SliderRow(
                title: 'Media Volume',
                leadingIcon: Icons.volume_up_rounded,
                value: _mediaVolume,
                min: 0,
                max: 1,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: (val) {
                  setState(() => _mediaVolume = val);
                  ref
                      .read(systemActionServiceProvider)
                      .executeAction(
                        SystemActionType.mediaVolume,
                        parameter: val,
                      );
                },
              ),
              SliderRow(
                title: 'Ring Volume',
                leadingIcon: Icons.notifications_active_rounded,
                value: _ringVolume,
                min: 0,
                max: 1,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: (val) {
                  setState(() => _ringVolume = val);
                  ref
                      .read(systemActionServiceProvider)
                      .executeAction(
                        SystemActionType.ringVolume,
                        parameter: val,
                      );
                },
              ),
              SliderRow(
                title: 'Alarm Volume',
                leadingIcon: Icons.alarm_rounded,
                value: _alarmVolume,
                min: 0,
                max: 1,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: (val) {
                  setState(() => _alarmVolume = val);
                  ref
                      .read(systemActionServiceProvider)
                      .executeAction(
                        SystemActionType.alarmVolume,
                        parameter: val,
                      );
                },
              ),
              const Divider(),
              ToggleRow(
                title: 'Mute All Audio',
                subtitle: 'Silence media, ringers, and system tones',
                icon: Icons.volume_off_rounded,
                value: _isMuted,
                onChanged: (val) => setState(() => _isMuted = val),
              ),
              ToggleRow(
                title: 'Vibrate on Tap',
                subtitle: 'Haptic feedback for system controls',
                icon: Icons.vibration_rounded,
                value: _isVibrate,
                onChanged: (val) => setState(() => _isVibrate = val),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sound Profile',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Normal', label: Text('Normal')),
                        ButtonSegment(value: 'Vibrate', label: Text('Vibrate')),
                        ButtonSegment(value: 'Silent', label: Text('Silent')),
                      ],
                      selected: {_soundMode},
                      onSelectionChanged: (s) =>
                          setState(() => _soundMode = s.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. DISPLAY
          AppSection(
            title: 'Display Controls',
            subtitle: 'Screen brightness and ambient sensor management',
            isCard: true,
            children: [
              SliderRow(
                title: 'Screen Brightness',
                leadingIcon: Icons.brightness_6_rounded,
                value: _brightness,
                min: 0.05,
                max: 1.0,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: (val) {
                  setState(() => _brightness = val);
                  ref
                      .read(systemActionServiceProvider)
                      .executeAction(
                        SystemActionType.brightness,
                        parameter: val,
                      );
                },
              ),
              ToggleRow(
                title: 'Auto Brightness',
                subtitle: 'Adjust according to ambient light sensor',
                icon: Icons.brightness_auto_rounded,
                value: _autoBrightness,
                onChanged: (val) => setState(() => _autoBrightness = val),
              ),
              ListTile(
                leading: const Icon(Icons.settings_display_rounded),
                title: const Text('Android Display Settings'),
                subtitle: const Text('Open device system display preferences'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _triggerAction(
                  SystemActionType.displaySettings,
                  'Display Settings',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. CONNECTIVITY
          AppSection(
            title: 'Connectivity',
            subtitle: 'Radios, wireless protocols, and networking',
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: context.isSmallPhone ? 2 : 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.15,
                children: [
                  _buildConnectivityTile(
                    'Wi-Fi',
                    Icons.wifi_rounded,
                    SystemActionType.wifi,
                  ),
                  _buildConnectivityTile(
                    'Bluetooth',
                    Icons.bluetooth_rounded,
                    SystemActionType.bluetooth,
                  ),
                  _buildConnectivityTile(
                    'Mobile Data',
                    Icons.network_cell_rounded,
                    SystemActionType.mobileData,
                  ),
                  _buildConnectivityTile(
                    'Hotspot',
                    Icons.wifi_tethering_rounded,
                    SystemActionType.hotspot,
                  ),
                  _buildConnectivityTile(
                    'Airplane Mode',
                    Icons.airplanemode_active_rounded,
                    SystemActionType.airplaneMode,
                  ),
                  _buildConnectivityTile(
                    'NFC',
                    Icons.nfc_rounded,
                    SystemActionType.nfc,
                  ),
                  _buildConnectivityTile(
                    'Cast',
                    Icons.cast_rounded,
                    SystemActionType.cast,
                  ),
                  _buildConnectivityTile(
                    'Location',
                    Icons.location_on_rounded,
                    SystemActionType.location,
                  ),
                  _buildConnectivityTile(
                    'VPN',
                    Icons.vpn_key_rounded,
                    SystemActionType.vpn,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityTile(
    String name,
    IconData icon,
    SystemActionType actionType,
  ) {
    final isEnabled = _connectivityToggles[name] ?? false;

    return ActionTile(
      title: name,
      icon: icon,
      isActive: isEnabled,
      iconColor: isEnabled ? AppColors.secondary : null,
      onTap: () {
        setState(() {
          _connectivityToggles[name] = !isEnabled;
        });
        _triggerAction(
          actionType,
          '$name (${!isEnabled ? "Enabled" : "Disabled"})',
        );
      },
    );
  }
}

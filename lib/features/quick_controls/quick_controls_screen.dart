import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/native_bridge.dart';
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

class _QuickControlsScreenState extends ConsumerState<QuickControlsScreen>
    with WidgetsBindingObserver {
  // Volume state
  double _mediaVolume = 0.7;
  double _ringVolume = 0.8;
  double _alarmVolume = 0.8;
  String _soundMode = 'Normal';

  // Display state
  double _brightness = 0.65;
  bool _autoBrightness = true;

  // Flashlight & Connectivity states
  bool _isTorchOn = false;
  bool _isPlayingMedia = false;
  bool _hasMediaSession = false;
  Map<String, dynamic> _connectivity = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLiveDeviceState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLiveDeviceState();
    }
  }

  Future<void> _fetchLiveDeviceState() async {
    final vol = await NativeBridge.instance.getVolumeLevels();
    final bri = await NativeBridge.instance.getBrightness();
    final torch = await NativeBridge.instance.isFlashlightOn();
    final media = await NativeBridge.instance.getMediaStatus();
    final conn = await NativeBridge.instance.getConnectivityStatus();

    if (mounted) {
      setState(() {
        _mediaVolume = (vol['mediaVolume'] as num?)?.toDouble() ?? 0.7;
        _ringVolume = (vol['ringVolume'] as num?)?.toDouble() ?? 0.8;
        _alarmVolume = (vol['alarmVolume'] as num?)?.toDouble() ?? 0.8;
        _soundMode = vol['ringerMode']?.toString() ?? 'Normal';
        _brightness = bri.clamp(0.05, 1.0);
        _isTorchOn = torch;
        _isPlayingMedia = media['isPlaying'] as bool? ?? false;
        _hasMediaSession =
            (media['hasActiveSession'] as bool? ?? false) || _isPlayingMedia;
        _connectivity = conn;
      });
    }
  }

  void _triggerHaptic() {
    final settings = ref.read(settingsProvider);
    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _triggerAction(SystemActionType type, String name) async {
    _triggerHaptic();
    final service = ref.read(systemActionServiceProvider);
    await service.executeAction(type);
    if (mounted) {
      context.showSnackBar(name);
    }
  }

  Future<void> _toggleFlashlight() async {
    _triggerHaptic();
    final ok = await NativeBridge.instance.toggleFlashlight();
    if (!mounted) return;
    if (ok) {
      setState(() => _isTorchOn = !_isTorchOn);
      context.showSnackBar(
        _isTorchOn ? 'Flashlight enabled' : 'Flashlight turned off',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Controls')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.sm),

          // 1. SYSTEM ACTIONS (Highest Priority)
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
                    onTap: () =>
                        _triggerAction(SystemActionType.home, 'Home pressed'),
                  ),
                  ActionTile(
                    title: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onTap: () =>
                        _triggerAction(SystemActionType.back, 'Back pressed'),
                  ),
                  ActionTile(
                    title: 'Recent Apps',
                    icon: Icons.view_carousel_rounded,
                    onTap: () => _triggerAction(
                      SystemActionType.recentApps,
                      'Recent apps opened',
                    ),
                  ),
                  ActionTile(
                    title: 'Screenshot',
                    icon: Icons.screenshot_rounded,
                    iconColor: AppColors.secondary,
                    onTap: () => _triggerAction(
                      SystemActionType.screenshot,
                      'Taking screenshot...',
                    ),
                  ),
                  ActionTile(
                    title: 'Lock Screen',
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.error,
                    onTap: () => _triggerAction(
                      SystemActionType.lockScreen,
                      'Screen locked',
                    ),
                  ),
                  ActionTile(
                    title: _isTorchOn ? 'Flashlight On' : 'Flashlight',
                    icon: _isTorchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    iconColor: _isTorchOn
                        ? AppColors.accent
                        : AppColors.secondary,
                    onTap: _toggleFlashlight,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. SOUND CONTROLS
          AppSection(
            title: 'Sound & Volume',
            subtitle: 'Adjust stream levels and ringer profile',
            isCard: true,
            children: [
              SliderRow(
                title: 'Media Volume',
                leadingIcon: Icons.music_note_rounded,
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
                title: 'Ring & Notifications',
                leadingIcon: Icons.notifications_rounded,
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
                      onSelectionChanged: (s) {
                        final mode = s.first;
                        setState(() => _soundMode = mode);
                        NativeBridge.instance.setSoundMode(mode);
                        context.showSnackBar('Sound mode: $mode');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. DISPLAY CONTROLS
          AppSection(
            title: 'Display Controls',
            subtitle: 'Screen brightness and ambient settings',
            isCard: true,
            children: [
              SliderRow(
                title: 'Screen Brightness',
                leadingIcon: Icons.brightness_6_rounded,
                value: _brightness,
                min: 0.0,
                max: 1.0,
                valueFormatter: (val) => '${(val * 100).toInt()}%',
                onChanged: _updateBrightness,
              ),
              ToggleRow(
                title: 'Auto Brightness',
                subtitle: 'Adjust according to ambient light sensor',
                icon: Icons.brightness_auto_rounded,
                value: _autoBrightness,
                onChanged: (val) {
                  setState(() => _autoBrightness = val);
                  context.showSnackBar(
                    val
                        ? 'Auto brightness enabled'
                        : 'Auto brightness disabled',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_display_rounded),
                title: const Text('Android Display Settings'),
                subtitle: const Text('Open device system display preferences'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => NativeBridge.instance.openSystemSetting('display'),
              ),
            ],
          ),
          // 4. MEDIA CONTROLS (Only shown when active media session or playing)
          if (_hasMediaSession) ...[
            AppSection(
              title: 'Media Playback',
              subtitle: 'Audio and video media key dispatching',
              isCard: true,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_previous_rounded),
                        tooltip: 'Previous Track',
                        iconSize: 28,
                        onPressed: () {
                          _triggerHaptic();
                          NativeBridge.instance.dispatchMediaKey('previous');
                          context.showSnackBar('Previous track');
                        },
                      ),
                      IconButton.filled(
                        icon: Icon(
                          _isPlayingMedia
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        tooltip: _isPlayingMedia ? 'Pause' : 'Play',
                        iconSize: 36,
                        onPressed: () {
                          _triggerHaptic();
                          setState(() => _isPlayingMedia = !_isPlayingMedia);
                          NativeBridge.instance.dispatchMediaKey('play_pause');
                          context.showSnackBar(
                            _isPlayingMedia ? 'Media playing' : 'Media paused',
                          );
                        },
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_next_rounded),
                        tooltip: 'Next Track',
                        iconSize: 28,
                        onPressed: () {
                          _triggerHaptic();
                          NativeBridge.instance.dispatchMediaKey('next');
                          context.showSnackBar('Next track');
                        },
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.stop_rounded),
                        tooltip: 'Stop',
                        iconSize: 24,
                        onPressed: () {
                          _triggerHaptic();
                          setState(() => _isPlayingMedia = false);
                          NativeBridge.instance.dispatchMediaKey('stop');
                          context.showSnackBar('Media stopped');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 5. CONNECTIVITY & SHORTCUTS
          AppSection(
            title: 'Connectivity',
            subtitle: 'Live state indicators & system settings shortcuts',
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
                    isActive:
                        _connectivity['wifi'] == true ||
                        _connectivity['wifiEnabled'] == true,
                  ),
                  _buildConnectivityTile(
                    'Bluetooth',
                    Icons.bluetooth_rounded,
                    SystemActionType.bluetooth,
                    isActive:
                        _connectivity['bluetooth'] == true ||
                        _connectivity['bluetoothEnabled'] == true,
                  ),
                  _buildConnectivityTile(
                    'Airplane Mode',
                    Icons.airplanemode_active_rounded,
                    SystemActionType.airplaneMode,
                    isActive: _connectivity['airplaneMode'] == true,
                  ),
                  _buildConnectivityTile(
                    'Location',
                    Icons.location_on_rounded,
                    SystemActionType.location,
                    isActive:
                        _connectivity['location'] == true ||
                        _connectivity['locationEnabled'] == true,
                  ),
                  _buildConnectivityTile(
                    'NFC',
                    Icons.nfc_rounded,
                    SystemActionType.nfc,
                    isActive:
                        _connectivity['nfc'] == true ||
                        _connectivity['nfcEnabled'] == true,
                  ),
                  _buildConnectivityTile(
                    'Mobile Data',
                    Icons.network_cell_rounded,
                    SystemActionType.mobileData,
                    isShortcut: true,
                  ),
                  _buildConnectivityTile(
                    'Hotspot',
                    Icons.wifi_tethering_rounded,
                    SystemActionType.hotspot,
                    isShortcut: true,
                  ),
                  _buildConnectivityTile(
                    'Cast',
                    Icons.cast_rounded,
                    SystemActionType.cast,
                    isShortcut: true,
                  ),
                  _buildConnectivityTile(
                    'VPN',
                    Icons.vpn_key_rounded,
                    SystemActionType.vpn,
                    isShortcut: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateBrightness(double val) async {
    setState(() => _brightness = val);
    final hasWritePerm = await NativeBridge.instance.checkPermission(
      'writeSettings',
    );
    if (!mounted) return;
    if (!hasWritePerm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Permission required to modify system brightness',
          ),
          action: SnackBarAction(
            label: 'Grant',
            onPressed: () =>
                NativeBridge.instance.requestPermission('writeSettings'),
          ),
        ),
      );
    } else {
      ref
          .read(systemActionServiceProvider)
          .executeAction(SystemActionType.brightness, parameter: val);
    }
  }

  Widget _buildConnectivityTile(
    String name,
    IconData icon,
    SystemActionType actionType, {
    bool isActive = false,
    bool isShortcut = false,
  }) {
    return ActionTile(
      title: name,
      icon: icon,
      isActive: isActive,
      isShortcut: isShortcut,
      onTap: () {
        _triggerAction(actionType, 'Opening $name settings');
      },
    );
  }
}

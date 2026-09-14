import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/native_bridge.dart';
import '../../core/services/providers.dart';
import '../../core/services/system_action_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_icon.dart';

/// The signature Floating Taply Panel.
/// Provides a multi-page carousel (Actions, Apps, Tools, Controls)
/// with in-panel tool hosting (Calculator, Timer, Stopwatch, Notes, Compass run inside the panel with a Back button).
class FloatingPanelScreen extends ConsumerStatefulWidget {
  const FloatingPanelScreen({super.key});

  @override
  ConsumerState<FloatingPanelScreen> createState() =>
      _FloatingPanelScreenState();
}

class _FloatingPanelScreenState extends ConsumerState<FloatingPanelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Draggable panel offset
  Offset _panelOffset = Offset.zero;
  bool _isDragging = false;
  bool _isTorchActive = false;

  // Multi-page carousel state (0: Actions, 1: Apps, 2: Tools, 3: Controls)
  int _currentTab = 0;
  final PageController _pageController = PageController();

  // In-Panel Hosted Tool State ('calculator', 'timer', 'stopwatch', 'notes', 'compass', or null)
  String? _activeInPanelTool;

  // Embedded Calculator State
  String _calcDisplay = '0';
  double? _calcOperand;
  String? _calcOperator;
  bool _calcNewNumber = true;

  // Embedded Timer State
  int _timerSeconds = 300;
  Timer? _timerTicker;
  bool _isTimerRunning = false;

  // Embedded Stopwatch State
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTicker;

  // Embedded Notes State
  final TextEditingController _notesController = TextEditingController();

  // Embedded Live Compass State
  double _compassHeading = 0.0;
  Timer? _compassTicker;
  bool _isCompassAvailable = true;

  // Quick Controls in-panel state
  double _mediaVolume = 0.7;
  double _brightness = 0.65;
  String _soundMode = 'Normal';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad),
    );

    _animController.forward();
    _initDeviceState();
  }

  Future<void> _initDeviceState() async {
    final torch = await NativeBridge.instance.isFlashlightOn();
    final vol = await NativeBridge.instance.getVolumeLevels();
    final bri = await NativeBridge.instance.getBrightness();
    final storage = ref.read(storageServiceProvider);
    final savedNotes = storage.getString('taply_quick_note') ?? '';

    if (mounted) {
      setState(() {
        _isTorchActive = torch;
        _mediaVolume = (vol['mediaVolume'] as num?)?.toDouble() ?? 0.7;
        _soundMode = vol['ringerMode']?.toString() ?? 'Normal';
        _brightness = bri.clamp(0.0, 1.0);
        _notesController.text = savedNotes;
      });
    }
  }

  void _startInPanelCompass() {
    NativeBridge.instance.startCompass();
    _compassTicker?.cancel();
    _compassTicker = Timer.periodic(const Duration(milliseconds: 60), (
      _,
    ) async {
      final data = await NativeBridge.instance.getCompassHeading();
      if (mounted && _activeInPanelTool == 'compass') {
        final avail = data['available'] as bool? ?? true;
        final rawHeading = (data['heading'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _isCompassAvailable = avail;
          if (avail) {
            _compassHeading = rawHeading;
          }
        });
      }
    });
  }

  void _stopInPanelCompass() {
    _compassTicker?.cancel();
    _compassTicker = null;
    NativeBridge.instance.stopCompass();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    _timerTicker?.cancel();
    _stopwatchTicker?.cancel();
    _stopwatch.stop();
    _stopInPanelCompass();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _closePanel() async {
    _stopInPanelCompass();
    await _animController.reverse();
    if (mounted) {
      context.pop();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _triggerHaptic() {
    final settings = ref.read(settingsProvider);
    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _executeAction(SystemActionType action, String label) async {
    _triggerHaptic();
    final service = ref.read(systemActionServiceProvider);
    await service.executeAction(action);
    if (mounted) {
      context.showSnackBar(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = context.isDarkMode;
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final panelWidth =
        (isLandscape ? 380.0 : (context.isSmallPhone ? 324.0 : 360.0)).clamp(
          280.0,
          size.width - 32.0,
        );
    final bodyHeight = isLandscape
        ? (size.height - 115.0).clamp(190.0, 260.0)
        : 310.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Semi-transparent backdrop with blur
          GestureDetector(
            onTap: _closePanel,
            behavior: HitTestBehavior.opaque,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: (isDark ? Colors.black : Colors.black87).withOpacity(
                    0.55,
                  ),
                ),
              ),
            ),
          ),

          // 2. Centered / Draggable Floating Panel
          Center(
            child: Transform.translate(
              offset: _panelOffset,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => _isDragging = true),
                    onPanUpdate: (details) {
                      setState(() {
                        _panelOffset += details.delta;
                      });
                    },
                    onPanEnd: (_) => setState(() => _isDragging = false),
                    child: Container(
                      width: panelWidth,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: AppSpacing.borderRadiusLg,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.45 : 0.18,
                            ),
                            blurRadius: _isDragging ? 24 : 16,
                            offset: Offset(0, _isDragging ? 10 : 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppSpacing.borderRadiusLg,
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // If hosting a tool in-panel, show in-panel tool header with Back button
                              if (_activeInPanelTool != null)
                                _buildInPanelToolHeader()
                              else ...[
                                // Standard Panel Header & Tab Navigation
                                _buildPanelHeader(settings.isAssistantEnabled),
                                _buildTabBar(),
                              ],

                              const Divider(height: 1),

                              // Body: In-panel tool or Carousel PageView
                              if (_activeInPanelTool != null)
                                _buildActiveInPanelToolView(bodyHeight)
                              else
                                _buildCarouselBody(bodyHeight),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADERS ---

  Widget _buildPanelHeader(bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppColors.success
                        : AppColors.secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Taply Assistant',
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Drag handle in center
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 18),
                onPressed: () {
                  _closePanel();
                  context.push('/settings');
                },
                tooltip: 'Settings',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _closePanel,
                tooltip: 'Close Panel',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInPanelToolHeader() {
    final title = _getToolTitle(_activeInPanelTool!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              if (_activeInPanelTool == 'compass') {
                _stopInPanelCompass();
              }
              setState(() => _activeInPanelTool = null);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          Text(
            title,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: _closePanel,
            tooltip: 'Close Panel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  String _getToolTitle(String toolId) {
    switch (toolId) {
      case 'calculator':
        return 'Calculator';
      case 'timer':
        return 'Quick Timer';
      case 'stopwatch':
        return 'Stopwatch';
      case 'notes':
        return 'Quick Notes';
      case 'compass':
        return 'Compass';
      default:
        return 'Tool';
    }
  }

  // --- CAROUSEL TAB BAR ---

  Widget _buildTabBar() {
    const tabs = ['Actions', 'Apps', 'Tools', 'Controls'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isSelected = _currentTab == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() => _currentTab = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutQuad,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : context.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- CAROUSEL PAGES ---

  Widget _buildCarouselBody(double height) {
    return SizedBox(
      height: height,
      child: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentTab = page),
        children: [
          _buildActionsPage(),
          _buildAppsPage(),
          _buildToolsPage(),
          _buildControlsPage(),
        ],
      ),
    );
  }

  // Page 0: Actions
  Widget _buildActionsPage() {
    final actions = [
      _PanelAction(
        title: 'Back',
        icon: Icons.arrow_back_rounded,
        color: AppColors.primary,
        onTap: () => _executeAction(SystemActionType.back, 'Back pressed'),
      ),
      _PanelAction(
        title: 'Home',
        icon: Icons.home_rounded,
        color: AppColors.primary,
        onTap: () => _executeAction(SystemActionType.home, 'Home pressed'),
      ),
      _PanelAction(
        title: 'Recents',
        icon: Icons.view_carousel_rounded,
        color: AppColors.primary,
        onTap: () => _executeAction(SystemActionType.recentApps, 'Recent apps'),
      ),
      _PanelAction(
        title: 'Screenshot',
        icon: Icons.screenshot_rounded,
        color: AppColors.secondary,
        onTap: () {
          _executeAction(SystemActionType.screenshot, 'Taking screenshot...');
          _closePanel();
        },
      ),
      _PanelAction(
        title: 'Lock Screen',
        icon: Icons.lock_outline_rounded,
        color: AppColors.error,
        onTap: () {
          _executeAction(SystemActionType.lockScreen, 'Screen locked');
          _closePanel();
        },
      ),
      _PanelAction(
        title: 'Volume',
        icon: Icons.volume_up_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => _pageController.jumpToPage(3),
      ),
      _PanelAction(
        title: 'Brightness',
        icon: Icons.brightness_6_rounded,
        color: AppColors.accent,
        onTap: () => _pageController.jumpToPage(3),
      ),
      _PanelAction(
        title: _isTorchActive ? 'Torch On' : 'Torch',
        icon: _isTorchActive
            ? Icons.flashlight_on_rounded
            : Icons.flashlight_off_rounded,
        color: _isTorchActive ? AppColors.accent : AppColors.secondary,
        onTap: () async {
          _triggerHaptic();
          final ok = await NativeBridge.instance.toggleFlashlight();
          if (ok) {
            setState(() => _isTorchActive = !_isTorchActive);
          }
        },
      ),
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.92,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final item = actions[index];
          return InkWell(
            onTap: item.onTap,
            borderRadius: AppSpacing.borderRadiusMd,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Page 1: Apps
  Widget _buildAppsPage() {
    final appsAsync = ref.watch(appsProvider);

    return Column(
      children: [
        Expanded(
          child: appsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                const Center(child: Text('Error loading apps')),
            data: (allApps) {
              final favorites = allApps
                  .where((a) => a.isFavorite && !a.isHidden)
                  .take(8)
                  .toList();

              if (favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_outline_rounded,
                        size: 36,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No favorite apps pinned',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          _closePanel();
                          context.push('/apps');
                        },
                        child: const Text('Add Favorites'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favorites.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final app = favorites[index];
                  return InkWell(
                    onTap: () async {
                      _triggerHaptic();
                      ref
                          .read(appsProvider.notifier)
                          .recordLaunch(app.packageName);
                      await NativeBridge.instance.launchApp(app.packageName);
                      _closePanel();
                    },
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          appName: app.appName,
                          iconData: app.defaultIcon,
                          color: app.iconColor,
                          iconBytes: app.iconBytes,
                          size: 40,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        ListTile(
          dense: true,
          leading: const Icon(
            Icons.apps_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          title: const Text(
            'All Applications',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Search and launch installed apps',
            style: TextStyle(fontSize: 11),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          onTap: () {
            _closePanel();
            context.push('/app-drawer');
          },
        ),
      ],
    );
  }

  // Page 2: Tools (Clicking launches In-Panel Tool Hosting or Full Screen)
  Widget _buildToolsPage() {
    final tools = [
      {
        'id': 'calculator',
        'name': 'Calculator',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'timer',
        'name': 'Timer',
        'icon': Icons.hourglass_bottom_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'stopwatch',
        'name': 'Stopwatch',
        'icon': Icons.timer_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'notes',
        'name': 'Quick Notes',
        'icon': Icons.note_alt_rounded,
        'color': const Color(0xFF14B8A6),
      },
      {
        'id': 'compass',
        'name': 'Compass',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFF06B6D4),
      },
      {
        'id': 'flashlight',
        'name': 'Flashlight',
        'icon': Icons.flashlight_on_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'battery',
        'name': 'Battery',
        'icon': Icons.battery_charging_full_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'storage',
        'name': 'Storage',
        'icon': Icons.storage_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'device_info',
        'name': 'Device Info',
        'icon': Icons.perm_device_information_rounded,
        'color': const Color(0xFF06B6D4),
      },
      {
        'id': 'qr',
        'name': 'QR Studio',
        'icon': Icons.qr_code_scanner_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'id': 'magnifier',
        'name': 'Magnifier',
        'icon': Icons.zoom_in_rounded,
        'color': const Color(0xFFEC4899),
      },
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.92,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final tool = tools[index];
          final toolId = tool['id'] as String;
          final color = tool['color'] as Color;

          return InkWell(
            onTap: () {
              _triggerHaptic();
              if (toolId == 'qr') {
                _closePanel();
                context.push('/tools/qr-studio');
              } else if (toolId == 'magnifier') {
                _closePanel();
                context.push('/tools/magnifier');
              } else if (toolId == 'flashlight') {
                _closePanel();
                context.push('/tools/flashlight');
              } else if (toolId == 'battery') {
                _closePanel();
                context.push('/tools/battery-diagnostics');
              } else if (toolId == 'storage') {
                _closePanel();
                context.push('/tools/storage-analyzer');
              } else if (toolId == 'device_info') {
                _closePanel();
                context.push('/tools/device-info');
              } else {
                // Host tool inside floating panel
                setState(() {
                  _activeInPanelTool = toolId;
                  if (toolId == 'compass') {
                    _startInPanelCompass();
                  }
                });
              }
            },
            borderRadius: AppSpacing.borderRadiusMd,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(tool['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  tool['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Page 3: Quick Controls
  Widget _buildControlsPage() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _mediaVolume,
                  onChanged: (val) {
                    setState(() => _mediaVolume = val);
                    NativeBridge.instance.setVolumeLevel('media', val);
                  },
                ),
              ),
              Text(
                '${(_mediaVolume * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.brightness_6_rounded,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) {
                    setState(() => _brightness = val);
                    NativeBridge.instance.setBrightness(val);
                  },
                ),
              ),
              Text(
                '${(_brightness * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Normal',
                label: Text('Normal', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 'Vibrate',
                label: Text('Vibrate', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 'Silent',
                label: Text('Silent', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {_soundMode},
            onSelectionChanged: (s) {
              setState(() => _soundMode = s.first);
              NativeBridge.instance.setSoundMode(s.first);
            },
          ),
        ],
      ),
    );
  }

  // --- IN-PANEL HOSTED TOOL VIEWS ---

  Widget _buildActiveInPanelToolView(double height) {
    switch (_activeInPanelTool) {
      case 'calculator':
        return _buildInPanelCalculator(height);
      case 'timer':
        return _buildInPanelTimer(height);
      case 'stopwatch':
        return _buildInPanelStopwatch(height);
      case 'notes':
        return _buildInPanelNotes(height);
      case 'compass':
        return _buildInPanelCompass(height);
      default:
        return SizedBox(height: height);
    }
  }

  // 1. In-Panel Calculator
  Widget _buildInPanelCalculator(double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.black26
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _calcDisplay,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _calcBtn(
                  'C',
                  color: AppColors.error,
                  onTap: () => setState(() {
                    _calcDisplay = '0';
                    _calcOperand = null;
                    _calcOperator = null;
                    _calcNewNumber = true;
                  }),
                ),
                _calcBtn(
                  '+/-',
                  onTap: () => setState(() {
                    final val = double.tryParse(_calcDisplay) ?? 0;
                    _calcDisplay = (-val).toString().replaceAll(
                      RegExp(r'\.0$'),
                      '',
                    );
                  }),
                ),
                _calcBtn(
                  '%',
                  onTap: () => setState(() {
                    final val = double.tryParse(_calcDisplay) ?? 0;
                    _calcDisplay = (val / 100).toString();
                  }),
                ),
                _calcBtn(
                  '÷',
                  color: AppColors.primary,
                  onTap: () => _setCalcOp('÷'),
                ),
                _calcBtn('7', onTap: () => _calcInput('7')),
                _calcBtn('8', onTap: () => _calcInput('8')),
                _calcBtn('9', onTap: () => _calcInput('9')),
                _calcBtn(
                  '×',
                  color: AppColors.primary,
                  onTap: () => _setCalcOp('×'),
                ),
                _calcBtn('4', onTap: () => _calcInput('4')),
                _calcBtn('5', onTap: () => _calcInput('5')),
                _calcBtn('6', onTap: () => _calcInput('6')),
                _calcBtn(
                  '-',
                  color: AppColors.primary,
                  onTap: () => _setCalcOp('-'),
                ),
                _calcBtn('1', onTap: () => _calcInput('1')),
                _calcBtn('2', onTap: () => _calcInput('2')),
                _calcBtn('3', onTap: () => _calcInput('3')),
                _calcBtn(
                  '+',
                  color: AppColors.primary,
                  onTap: () => _setCalcOp('+'),
                ),
                _calcBtn('0', onTap: () => _calcInput('0')),
                _calcBtn('.', onTap: () => _calcInput('.')),
                _calcBtn(
                  '⌫',
                  onTap: () => setState(() {
                    if (_calcDisplay.length > 1) {
                      _calcDisplay = _calcDisplay.substring(
                        0,
                        _calcDisplay.length - 1,
                      );
                    } else {
                      _calcDisplay = '0';
                    }
                  }),
                ),
                _calcBtn('=', color: AppColors.success, onTap: _calcEquals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcBtn(String label, {Color? color, required VoidCallback onTap}) {
    return Material(
      color: (color ?? context.colorScheme.onSurface).withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          _triggerHaptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color ?? context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  void _calcInput(String char) {
    setState(() {
      if (_calcNewNumber) {
        _calcDisplay = char == '.' ? '0.' : char;
        _calcNewNumber = false;
      } else {
        if (_calcDisplay.length < 10) {
          if (char != '.' || !_calcDisplay.contains('.')) {
            _calcDisplay += char;
          }
        }
      }
    });
  }

  void _setCalcOp(String op) {
    final cur = double.tryParse(_calcDisplay) ?? 0;
    _calcOperand = cur;
    _calcOperator = op;
    _calcNewNumber = true;
  }

  void _calcEquals() {
    if (_calcOperator == null || _calcOperand == null) return;
    final cur = double.tryParse(_calcDisplay) ?? 0;
    double res = 0;
    switch (_calcOperator) {
      case '+':
        res = _calcOperand! + cur;
        break;
      case '-':
        res = _calcOperand! - cur;
        break;
      case '×':
        res = _calcOperand! * cur;
        break;
      case '÷':
        res = cur != 0 ? _calcOperand! / cur : 0;
        break;
    }
    setState(() {
      _calcDisplay = res.toString().replaceAll(RegExp(r'\.0$'), '');
      _calcOperand = null;
      _calcOperator = null;
      _calcNewNumber = true;
    });
  }

  // 2. In-Panel Timer
  Widget _buildInPanelTimer(double height) {
    final mins = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_timerSeconds % 60).toString().padLeft(2, '0');

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$mins:$secs',
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              children: [60, 180, 300, 600].map((s) {
                final label = '${s ~/ 60}m';
                return ActionChip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() {
                    _timerTicker?.cancel();
                    _isTimerRunning = false;
                    _timerSeconds = s;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: Icon(
                    _isTimerRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  iconSize: 28,
                  onPressed: () {
                    _triggerHaptic();
                    if (_isTimerRunning) {
                      _timerTicker?.cancel();
                      setState(() => _isTimerRunning = false);
                    } else {
                      setState(() => _isTimerRunning = true);
                      _timerTicker = Timer.periodic(
                        const Duration(seconds: 1),
                        (_) {
                          if (_timerSeconds > 0) {
                            setState(() => _timerSeconds--);
                          } else {
                            _timerTicker?.cancel();
                            setState(() => _isTimerRunning = false);
                            context.showSnackBar('Timer finished!');
                          }
                        },
                      );
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton.outlined(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    _triggerHaptic();
                    _timerTicker?.cancel();
                    setState(() {
                      _isTimerRunning = false;
                      _timerSeconds = 300;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. In-Panel Stopwatch
  Widget _buildInPanelStopwatch(double height) {
    final elapsed = _stopwatch.elapsed;
    final mins = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final ms = ((elapsed.inMilliseconds % 1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$mins:$secs.$ms',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: Icon(
                    _stopwatch.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  iconSize: 28,
                  onPressed: () {
                    _triggerHaptic();
                    if (_stopwatch.isRunning) {
                      _stopwatch.stop();
                      _stopwatchTicker?.cancel();
                    } else {
                      _stopwatch.start();
                      _stopwatchTicker = Timer.periodic(
                        const Duration(milliseconds: 30),
                        (_) {
                          setState(() {});
                        },
                      );
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton.outlined(
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: () {
                    _triggerHaptic();
                    _stopwatch.reset();
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. In-Panel Notes
  Widget _buildInPanelNotes(double height) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText:
                      'Type your quick thoughts, clipboard text, or list...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  final storage = ref.read(storageServiceProvider);
                  storage.setString('taply_quick_note', val);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _notesController.text),
                    );
                    context.showSnackBar('Note copied to clipboard');
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear'),
                  onPressed: () {
                    _notesController.clear();
                    ref.read(storageServiceProvider).remove('taply_quick_note');
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCardinal(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    return 'NW';
  }

  // 5. In-Panel Live Compass
  Widget _buildInPanelCompass(double height) {
    final cardinal = _getCardinal(_compassHeading);
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -_compassHeading * (math.pi / 180),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 4,
                          child: Text(
                            'N',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          child: Text(
                            'E',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6,
                          child: Text(
                            'W',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      size: 32,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_compassHeading.toInt()}° $cardinal',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isCompassAvailable
                  ? 'Real-time Directional Sensor Active'
                  : 'Magnetic Sensor Unavailable',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PanelAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

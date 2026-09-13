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
import '../../shared/models/installed_app.dart';
import '../../shared/widgets/app_icon.dart';

/// The signature Floating Taply Panel.
/// Provides instant access to system navigation, favorite apps, app drawer, and device controls.
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
    _checkTorchStatus();
  }

  Future<void> _checkTorchStatus() async {
    final status = await NativeBridge.instance.isFlashlightOn();
    if (mounted) {
      setState(() => _isTorchActive = status);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _closePanel() async {
    await _animController.reverse();
    if (mounted) {
      context.pop();
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
    final appsAsync = ref.watch(appsProvider);
    final isDark = context.isDarkMode;

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
                      width: context.isSmallPhone ? 320 : 356,
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drag Handle Indicator & Header
                            _buildPanelHeader(settings.isAssistantEnabled),

                            if (!settings.isAssistantEnabled)
                              _buildDisabledBanner()
                            else ...[
                              // PRIORITY 1: Most-Used System Actions
                              _buildSystemActionsSection(),

                              const Divider(height: 1),

                              // PRIORITY 2: Favorite Apps
                              _buildFavoriteAppsSection(appsAsync),

                              const Divider(height: 1),

                              // PRIORITY 3: App Drawer Pill
                              _buildAppDrawerTrigger(),

                              const Divider(height: 1),

                              // PRIORITY 4: More Actions
                              _buildMoreActionsRow(),
                            ],
                          ],
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
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.success
                      : AppColors.secondaryText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Taply Assistant',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          // Drag handle in center
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
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

  Widget _buildDisabledBanner() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          const Icon(
            Icons.power_settings_new_rounded,
            size: 40,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Floating Assistant is Off',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Turn on Taply to activate the floating overlay over all applications.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.base),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).toggleAssistant(true);
            },
            child: const Text('Turn On Assistant'),
          ),
        ],
      ),
    );
  }

  // PRIORITY 1: Most-Used System Actions Grid
  Widget _buildSystemActionsSection() {
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
        onTap: () {
          _closePanel();
          context.push('/quick-controls');
        },
      ),
      _PanelAction(
        title: 'Brightness',
        icon: Icons.brightness_6_rounded,
        color: AppColors.accent,
        onTap: () {
          _closePanel();
          context.push('/quick-controls');
        },
      ),
      _PanelAction(
        title: _isTorchActive ? 'Flashlight On' : 'Flashlight',
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.95,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
        ),
        itemBuilder: (context, index) {
          final item = actions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: AppSpacing.borderRadiusMd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
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
              ),
            ),
          );
        },
      ),
    );
  }

  // PRIORITY 2: Favorite Apps Horizontal Strip
  Widget _buildFavoriteAppsSection(AsyncValue<List<InstalledApp>> appsAsync) {
    return appsAsync.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (allApps) {
        final favorites = allApps
            .where((a) => a.isFavorite && !a.isHidden)
            .toList();

        if (favorites.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'No favorite apps pinned yet',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _closePanel();
                    context.push('/apps');
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Apps'),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final app = favorites[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: InkWell(
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
                      SizedBox(
                        width: 52,
                        child: Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // PRIORITY 3: App Drawer Trigger
  Widget _buildAppDrawerTrigger() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _closePanel();
          context.push('/app-drawer');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Applications',
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Search and launch installed apps',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PRIORITY 4: More Actions Row
  Widget _buildMoreActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPillAction(
              label: 'Tools',
              icon: Icons.handyman_outlined,
              onTap: () {
                _closePanel();
                context.push('/tools');
              },
            ),
          ),
          Expanded(
            child: _buildPillAction(
              label: 'Controls',
              icon: Icons.tune_rounded,
              onTap: () {
                _closePanel();
                context.push('/quick-controls');
              },
            ),
          ),
          Expanded(
            child: _buildPillAction(
              label: 'Customize',
              icon: Icons.palette_outlined,
              onTap: () {
                _closePanel();
                context.push('/customize');
              },
            ),
          ),
          Expanded(
            child: _buildPillAction(
              label: 'Settings',
              icon: Icons.settings_outlined,
              onTap: () {
                _closePanel();
                context.push('/settings');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 3),
              Text(
                label,
                maxLines: 1,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
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

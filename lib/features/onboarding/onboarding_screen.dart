import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/models/system_action_catalog.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import '../../shared/widgets/taply_brand_icon.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isOverlayGranted = false;

  // Slide 2: Default selected essential action IDs from SystemActionCatalog
  final Set<String> _selectedActionIds = {
    'home',
    'back',
    'recent_apps',
    'screenshot',
    'lock_screen',
    'volume',
    'brightness',
    'flashlight',
  };

  // Catalog actions offered on Slide 2
  static const List<String> _essentialActionCandidateIds = [
    'home',
    'back',
    'recent_apps',
    'screenshot',
    'lock_screen',
    'volume',
    'brightness',
    'flashlight',
    'notifications',
    'quick_settings',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionState();
    }
  }

  Future<void> _checkPermissionState() async {
    try {
      final status = await ref
          .read(permissionServiceProvider)
          .checkPermission(PermissionType.overlay);
      if (mounted) {
        setState(() {
          _isOverlayGranted = status == PermissionStatus.granted;
        });
      }
    } catch (e) {
      debugPrint('[Onboarding] Error checking permission: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutQuad,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _finishOnboarding() {
    final storage = ref.read(storageServiceProvider);
    final isAlreadyCustomized =
        storage.getBool('taply_user_customized_actions') ?? false;

    // "IF NOT ALREADY" REQUIREMENT:
    // Only apply onboarding selections if the user has not already saved a custom configuration.
    if (!isAlreadyCustomized) {
      final validCatalogIds = SystemActionCatalog.allActions
          .map((a) => a.id)
          .toSet();
      final seen = <String>{};
      final validatedOrder = <String>[];

      for (final raw in _selectedActionIds) {
        final norm = SystemActionCatalog.normalizeId(raw);
        if (validCatalogIds.contains(norm) && seen.add(norm)) {
          validatedOrder.add(norm);
        }
      }

      final fallbackDefaults = [
        'home',
        'back',
        'recent_apps',
        'screenshot',
        'lock_screen',
        'volume',
        'brightness',
        'flashlight',
      ];

      final finalOrder = validatedOrder.isNotEmpty
          ? validatedOrder
          : fallbackDefaults;
      final currentSettings = ref.read(settingsProvider);

      ref
          .read(settingsProvider.notifier)
          .updatePanelConfig(
            currentSettings.panelConfig.copyWith(actionOrder: finalOrder),
            markUserCustomized: false,
          );
    }

    // Persist onboardingCompleted = true
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Progress Indicator + Back/Skip)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button or placeholder
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Previous',
                      onPressed: _previousPage,
                    )
                  else
                    const SizedBox(width: 24, height: 24),

                  // 4-Step Progress Indicator
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 8,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : context.colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Skip Button
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 48, height: 36),
                ],
              ),
            ),

            // Responsive 4-Step PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1Welcome(context),
                  _buildStep2Essentials(context),
                  _buildStep3Permission(context),
                  _buildStep4Ready(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SLIDE 1: Welcome & Value Proposition
  // ==========================================
  Widget _buildStep1Welcome(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.base,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const TaplyAppIcon(size: 88, borderRadius: 22),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConstants.appName,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppConstants.appTagline,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'A lightweight, unobtrusive assistant that stays available over any app. Instant access to system navigation, audio levels, brightness, flashlight, and your favorite apps.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Docked Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: PrimaryButton(label: 'Get Started', onPressed: _nextPage),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // SLIDE 2: Choose Your Essentials (Actions)
  // ==========================================
  Widget _buildStep2Essentials(BuildContext context) {
    final candidateActions = _essentialActionCandidateIds
        .map(SystemActionCatalog.getAction)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Essentials',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select which actions appear in your floating quick panel.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Scrollable Action Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 500 ? 3 : 2,
                        childAspectRatio: constraints.maxWidth > 360
                            ? 2.4
                            : 1.9,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                      ),
                      itemCount: candidateActions.length,
                      itemBuilder: (context, index) {
                        final action = candidateActions[index];
                        final isSelected = _selectedActionIds.contains(
                          action.id,
                        );

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_selectedActionIds.length > 1) {
                                  _selectedActionIds.remove(action.id);
                                }
                              } else {
                                _selectedActionIds.add(action.id);
                              }
                            });
                          },
                          borderRadius: AppSpacing.borderRadiusMd,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.12)
                                  : context.colorScheme.surface,
                              borderRadius: AppSpacing.borderRadiusMd,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.colorScheme.outline,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  action.icon,
                                  color: isSelected
                                      ? AppColors.primary
                                      : action.color,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    action.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppColors.primary
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Docked Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: PrimaryButton(
                label: 'Continue (${_selectedActionIds.length} selected)',
                onPressed: _nextPage,
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // SLIDE 3: Overlay Permission Explanation
  // ==========================================
  Widget _buildStep3Permission(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxImgHeight = (constraints.maxHeight * 0.22).clamp(60.0, 130.0);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/branding/onboarding/display_over_apps.png',
                      height: maxImgHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Display Over Other Apps',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Taply needs overlay permission so the floating button and panel remain accessible on top of your other apps.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: context.isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Permission Status Pill
                    if (_isOverlayGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Permission Granted',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.darkElevatedSurface
                              : const Color(0xFFF1F5F9),
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: context.isDarkMode
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'No tracking or personal data collection. Taply operates completely on your device.',
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Docked Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: _isOverlayGranted
                  ? PrimaryButton(label: 'Continue', onPressed: _nextPage)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryButton(
                          label: 'Grant Permission',
                          onPressed: () async {
                            final service = ref.read(permissionServiceProvider);
                            await service.requestPermission(
                              PermissionType.overlay,
                            );
                            // Refresh status immediately
                            await _checkPermissionState();
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SecondaryButton(
                          label: 'Set Up Later',
                          onPressed: _nextPage,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // SLIDE 4: Ready to Tap / All Set
  // ==========================================
  Widget _buildStep4Ready(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxImgHeight = (constraints.maxHeight * 0.18).clamp(50.0, 110.0);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/branding/onboarding/all_set.png',
                      height: maxImgHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "You're All Set!",
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Taply is ready to assist you.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Feature highlights container
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.darkElevatedSurface
                            : const Color(0xFFF1F5F9),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: context.isDarkMode
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildPillarRow(
                            Icons.touch_app_rounded,
                            'Floating Assistant',
                            'Always available along your screen edge',
                          ),
                          const SizedBox(height: 8),
                          _buildPillarRow(
                            Icons.gesture_rounded,
                            'Fast Navigation Gestures',
                            'Tap, double-tap, or flick for Back and Home',
                          ),
                          const SizedBox(height: 8),
                          _buildPillarRow(
                            Icons.tune_rounded,
                            'Quick System Controls',
                            'Volume sliders, brightness, torch, screenshot',
                          ),
                          const SizedBox(height: 8),
                          _buildPillarRow(
                            Icons.apps_rounded,
                            'Instant App Access',
                            'Favorite shortcuts and mini launcher drawer',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Docked Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: PrimaryButton(
                label: 'Start Using Taply',
                onPressed: _finishOnboarding,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillarRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: context.isDarkMode
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

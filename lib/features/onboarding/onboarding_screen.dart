import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import '../../shared/widgets/taply_brand_icon.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Set<String> _selectedEssentials = {
    'Screenshot',
    'Volume',
    'Brightness',
    'Home',
    'Back',
    'Recent Apps',
  };

  final List<Map<String, dynamic>> _essentialOptions = [
    {'title': 'Screenshot', 'icon': Icons.screenshot_rounded},
    {'title': 'Volume', 'icon': Icons.volume_up_rounded},
    {'title': 'Brightness', 'icon': Icons.brightness_6_rounded},
    {'title': 'Home', 'icon': Icons.home_rounded},
    {'title': 'Back', 'icon': Icons.arrow_back_rounded},
    {'title': 'Recent Apps', 'icon': Icons.view_carousel_rounded},
    {'title': 'Lock Screen', 'icon': Icons.lock_outline_rounded},
    {'title': 'Flashlight', 'icon': Icons.flashlight_on_rounded},
  ];

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

  void _finishOnboarding() {
    const mapping = {
      'Screenshot': 'screenshot',
      'Volume': 'volume',
      'Brightness': 'brightness',
      'Home': 'home',
      'Back': 'back',
      'Recent Apps': 'recent_apps',
      'Lock Screen': 'lock_screen',
      'Flashlight': 'flashlight',
    };
    final orderedActions = _selectedEssentials
        .map((e) => mapping[e] ?? e.toLowerCase())
        .toList();
    const defaultActions = [
      'screenshot',
      'volume',
      'brightness',
      'home',
      'back',
      'recent_apps',
      'lock_screen',
      'flashlight',
    ];
    final finalActions = orderedActions.isNotEmpty
        ? orderedActions
        : defaultActions;
    final settings = ref.read(settingsProvider);
    ref
        .read(settingsProvider.notifier)
        .updatePanelConfig(
          settings.panelConfig.copyWith(actionOrder: finalActions),
        );
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go('/');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top 4-Step Indicator and Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index == _currentPage;
                      return Container(
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
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // 4-Step Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1Welcome(context),
                  _buildStep2Permission(context),
                  _buildStep3Essentials(context),
                  _buildStep4Ready(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Welcome & Value Proposition
  Widget _buildStep1Welcome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const TaplyAppIcon(size: 92, borderRadius: 24),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppConstants.appName,
            style: context.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppConstants.appTagline,
            style: context.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'A small, unobtrusive assistant that stays available over any app. Instant access to system navigation, audio levels, brightness, flashlight, and your favorite apps.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const Spacer(),
          PrimaryButton(label: 'Get Started', onPressed: _nextPage),
        ],
      ),
    );
  }

  // STEP 2: Plain Language Permission Explanation
  Widget _buildStep2Permission(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            'assets/branding/onboarding/display_over_apps.png',
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.layers_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Display Over Other Apps',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Taply needs permission to appear above other apps so the floating button can stay available while you use other apps.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                    style: context.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Grant Permission',
            onPressed: () async {
              final service = ref.read(permissionServiceProvider);
              await service.requestPermission(PermissionType.overlay);
              _nextPage();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(label: 'Set Up Later', onPressed: _nextPage),
        ],
      ),
    );
  }

  // STEP 3: Quick Essentials Selection
  Widget _buildStep3Essentials(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Essentials',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select which system actions appear first in your quick panel.',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.isSmallPhone ? 2 : 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: _essentialOptions.length,
              itemBuilder: (context, index) {
                final opt = _essentialOptions[index];
                final title = opt['title'] as String;
                final icon = opt['icon'] as IconData;
                final isSelected = _selectedEssentials.contains(title);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedEssentials.remove(title);
                      } else {
                        _selectedEssentials.add(title);
                      }
                    });
                  },
                  borderRadius: AppSpacing.borderRadiusMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
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
                          icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.secondaryText,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          PrimaryButton(
            label: 'Continue (${_selectedEssentials.length} selected)',
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // STEP 4: Ready to Tap
  Widget _buildStep4Ready(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            'assets/branding/onboarding/all_set.png',
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "You're All Set!",
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Taply is ready to assist you.',
            style: context.textTheme.titleMedium?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                  'Favorite shortcuts and mini-launcher drawer',
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Start Using Taply',
            onPressed: _finishOnboarding,
          ),
        ],
      ),
    );
  }

  Widget _buildPillarRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
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
                  fontSize: 13,
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

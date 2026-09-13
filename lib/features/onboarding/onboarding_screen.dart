import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Screen 3 Essentials selected items
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
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
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
            // Top indicator and Skip button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(5, (index) {
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
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildScreen1Welcome(context),
                  _buildScreen2Permission(context),
                  _buildScreen3Essentials(context),
                  _buildScreen4FavoriteApps(context),
                  _buildScreen5Ready(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SCREEN 1: Welcome & Value Proposition
  Widget _buildScreen1Welcome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.touch_app_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppConstants.appName,
            style: context.textTheme.headlineLarge?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
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
            'A faster way to access your favorite apps, quick system controls, and everyday utilities with a single ergonomic floating touch.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Get Started',
            onPressed: _nextPage,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  // SCREEN 2: Floating Assistant Overlay Access
  Widget _buildScreen2Permission(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.layers_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Enable Floating Assistant',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Taply renders an unobtrusive assistive button that remains accessible across every game, app, and screen.\n\nTo operate, Android requires "Display over other apps" permission.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Enable Floating Access',
            icon: Icons.check_rounded,
            onPressed: () {
              ref
                  .read(permissionsProvider.notifier)
                  .request(PermissionType.overlay);
              _nextPage();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(label: 'Set up later', onPressed: _nextPage),
        ],
      ),
    );
  }

  // SCREEN 3: Choose Essentials
  Widget _buildScreen3Essentials(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose your essentials',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Select which system actions appear first in your quick panel.',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.base),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.isSmallPhone ? 2 : 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.25,
              ),
              itemCount: _essentialOptions.length,
              itemBuilder: (context, index) {
                final item = _essentialOptions[index];
                final title = item['title'] as String;
                final icon = item['icon'] as IconData;
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
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (context.isDarkMode
                                ? AppColors.darkPrimary.withOpacity(0.18)
                                : const Color(0xFFEFF6FF))
                          : context.colorScheme.surface,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : context.colorScheme.outline,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? AppColors.primary : null,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? AppColors.primary : null,
                          ),
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

  // SCREEN 4: Choose Favorite Apps
  Widget _buildScreen4FavoriteApps(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose favorite apps',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Pin your most frequently used apps for one-tap launching.',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.base),
          Expanded(
            child: appsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (apps) {
                return ListView.separated(
                  itemCount: apps.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return CheckboxListTile(
                      value: app.isFavorite,
                      secondary: AppIcon(
                        appName: app.appName,
                        iconData: app.defaultIcon,
                        color: app.iconColor,
                        size: 38,
                      ),
                      title: Text(
                        app.appName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        app.packageName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (_) {
                        ref
                            .read(appsProvider.notifier)
                            .toggleFavorite(app.packageName);
                      },
                    );
                  },
                );
              },
            ),
          ),
          PrimaryButton(label: 'Continue', onPressed: _nextPage),
        ],
      ),
    );
  }

  // SCREEN 5: Taply is ready
  Widget _buildScreen5Ready(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 52,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Taply is ready',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your shortcuts and preferences are configured.\nYou can reposition the button on screen at any time.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              height: 1.5,
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
}

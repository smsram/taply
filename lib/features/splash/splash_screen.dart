import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';

/// Clean, professional startup splash screen for Taply.
/// Renders solid Taply blue (#2563EB) with the centered branding icon,
/// subtle 85% -> 100% scale and gentle ripple pulse, and seamless routing.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleOpacity;
  late final Animation<double> _rippleScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Subtle scale: 0.85 -> 1.0 (smooth easing), then subtle 1.0 -> 1.05 -> 1.0 tap pulse
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Subtle fading ripple ring during the tap pulse
    _rippleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.35,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
    ]).animate(_controller);

    _rippleScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) => _onAnimationComplete());
  }

  void _onAnimationComplete() {
    if (!mounted) return;

    final settings = ref.read(settingsProvider);
    final isCompleted = settings.isOnboardingCompleted;

    if (isCompleted) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle pulse ripple ring
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final opacity = _rippleOpacity.value;
                if (opacity <= 0.01) return const SizedBox.shrink();
                return Transform.scale(
                  scale: _rippleScale.value,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(opacity),
                        width: 2.0,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Official Taply branding icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/branding/taply_icon.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.touch_app_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

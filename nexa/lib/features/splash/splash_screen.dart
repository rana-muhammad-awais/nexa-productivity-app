import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/lock_screen.dart';
import '../../widgets/logo.dart';
import '../../widgets/nav_scaffold.dart';
import '../onboarding/onboarding_page.dart';

/// Animated luxury splash screen with glowing monogram and fluid transition.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // After animation, navigate to the target screen
    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _navigateToTarget();
    });
  }

  void _navigateToTarget() {
    final asyncData = ref.read(appStoreProvider);
    final data = asyncData.valueOrNull;

    if (data == null) {
      // Store still loading, wait a bit
      Timer(const Duration(milliseconds: 200), _navigateToTarget);
      return;
    }

    Widget destination;
    if (!data.user.onboarded) {
      destination = const OnboardingPage();
    } else if (data.user.biometricLock && !AuthService.instance.isAppUnlocked) {
      destination = LockScreen(
        onUnlocked: () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const NavScaffold(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      );
    } else {
      destination = const NavScaffold();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(appStoreProvider);
    final user = asyncData.valueOrNull?.user;
    final accentGrad = NexaColors.accentGradient(user?.accentColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NexaColors.darkBg : NexaColors.lightBg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient radial gradient
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) => Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentGrad.first.withOpacity(0.18 * _glowAnimation.value),
                    accentGrad.last.withOpacity(0.06 * _glowAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central branding content
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NexoraLogo(size: 88),
                  const SizedBox(height: 28),

                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        accentGrad.first,
                        accentGrad.length > 1 ? accentGrad[1] : accentGrad[0],
                        if (accentGrad.length > 2) accentGrad[2],
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'NEXORA',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Personal Operating System',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: accentGrad.first.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentGrad.first.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'v4.0 SuperOS · Offline-First',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentGrad.first,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    '100% Private · Zero Telemetry',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondaryColor(context).withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

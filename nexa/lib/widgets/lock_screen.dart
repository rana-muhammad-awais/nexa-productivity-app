import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/haptics.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../services/auth_service.dart';
import 'glass.dart';
import 'logo.dart';

/// Full-screen luxury biometric lock screen.
class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticating = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-prompt biometric on display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    NexaHaptics.light();
    final success = await AuthService.instance.authenticate(
      reason: 'Unlock Nexora Personal OS',
    );

    if (!mounted) return;

    if (success) {
      NexaHaptics.success();
      widget.onUnlocked();
    } else {
      NexaHaptics.error();
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Authentication failed or canceled. Tap to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(appStoreProvider);
    final user = asyncData.valueOrNull?.user;
    final userName = user?.name ?? 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient gradient orb
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NexaColors.accentGradient(user?.accentColor).first.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated Monogram
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const NexoraLogo(size: 76),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Welcome back, $userName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Nexora is secured with Biometric Protection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: textSecondaryColor(context),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: NexaColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: NexaColors.danger.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.alertCircle,
                                size: 16, color: NexaColors.danger),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: NexaColors.danger,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Biometric Unlock Button
                    GradientBorderCard(
                      gradient: NexaColors.accentGradient(user?.accentColor),
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton.icon(
                        icon: _isAuthenticating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(LucideIcons.fingerprint, size: 22),
                        label: Text(
                          _isAuthenticating ? 'Authenticating...' : 'Unlock Nexora',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? NexaColors.darkCard : Colors.white,
                          foregroundColor:
                              isDark ? Colors.white : NexaColors.lightText,
                          minimumSize: const Size.fromHeight(54),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isAuthenticating ? null : _authenticate,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Protected by Android Biometrics & Keystore',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondaryColor(context).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

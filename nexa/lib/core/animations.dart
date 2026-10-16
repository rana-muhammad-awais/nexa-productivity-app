import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ─── Nexa Animation System ────────────────────────────────────────────────
/// Standard curves, durations, and reusable animation widgets that give
/// every surface a premium feel.

// ─── Standard durations & curves ────────────────────────────────────────
class NexaAnim {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const pageTransition = Duration(milliseconds: 350);
  static const staggerDelay = Duration(milliseconds: 60);

  static const spring = Curves.easeOutBack;
  static const smooth = Curves.easeOutCubic;
  static const snap = Curves.easeOutExpo;
  static const bounce = Curves.bounceOut;
  static const decelerate = Curves.decelerate;
}

// ─── iOS-style slide page transition ─────────────────────────────────────
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: NexaAnim.pageTransition,
          reverseTransitionDuration: NexaAnim.pageTransition,
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            final slide = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: NexaAnim.smooth));
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: anim,
                curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
              ),
            );
            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: fade, child: child),
            );
          },
        );
}

// ─── Fade + scale page transition ────────────────────────────────────────
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadeScalePageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: NexaAnim.normal,
          reverseTransitionDuration: NexaAnim.normal,
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            final curve = CurvedAnimation(parent: anim, curve: NexaAnim.smooth);
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );
}

// ─── Staggered fade-in for lists ─────────────────────────────────────────
class StaggeredFadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double verticalOffset;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delay = NexaAnim.staggerDelay,
    this.duration = NexaAnim.normal,
    this.verticalOffset = 16,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay * index,
      curve: NexaAnim.smooth,
      builder: (context, value, child) {
        final progress = ((value - (index * 0.1)).clamp(0.0, 1.0));
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─── Count-up animated number ────────────────────────────────────────────
class CountUpText extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: NexaAnim.decelerate,
      builder: (_, v, __) => Text(formatter(v), style: style),
    );
  }
}

// ─── Pulse glow effect ───────────────────────────────────────────────────
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxGlow;
  const PulseGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.maxGlow = 12,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween(begin: 4.0, end: widget.maxGlow).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(0.4),
              blurRadius: _glow.value,
              spreadRadius: _glow.value * 0.3,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─── Scale-on-press wrapper ──────────────────────────────────────────────
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: NexaAnim.fast);
    _scale = Tween(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _ctrl, curve: NexaAnim.smooth),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Animated gradient blob ──────────────────────────────────────────────
class AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;
  final bool dark;
  const AnimatedBlob({
    super.key,
    required this.color,
    this.size = 300,
    this.dark = true,
  });

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final dx = math.sin(t * math.pi * 2) * 12;
        final dy = math.cos(t * math.pi * 2) * 8;
        final scale = 1.0 + math.sin(t * math.pi) * 0.08;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withOpacity(widget.dark ? 0.35 : 0.30),
                    widget.color.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shimmer loading placeholder ─────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final base = isDarkMode ? const Color(0xFF1C1C24) : const Color(0xFFE8E8EE);
    final highlight =
        isDarkMode ? const Color(0xFF2A2A34) : const Color(0xFFF5F5FA);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-1.0 + 2.0 * _ctrl.value + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

// ─── Confetti / sparkle burst on task completion ─────────────────────────
class CompletionBurst extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Color color;
  const CompletionBurst({
    super.key,
    required this.child,
    required this.trigger,
    this.color = const Color(0xFF22C55E),
  });

  @override
  State<CompletionBurst> createState() => _CompletionBurstState();
}

class _CompletionBurstState extends State<CompletionBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _wasTriggered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(CompletionBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !_wasTriggered) {
      _ctrl.forward(from: 0);
    }
    _wasTriggered = widget.trigger;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        if (!_ctrl.isAnimating) return child!;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            child!,
            // Ring burst
            Positioned.fill(
              child: Transform.scale(
                scale: 1.0 + _ctrl.value * 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(1.0 - _ctrl.value),
                      width: 2.5 * (1.0 - _ctrl.value),
                    ),
                  ),
                ),
              ),
            ),
            // Sparkle dots
            for (var i = 0; i < 6; i++)
              Positioned(
                left: 13 +
                    math.cos(i * math.pi / 3) * 18 * _ctrl.value,
                top: 13 +
                    math.sin(i * math.pi / 3) * 18 * _ctrl.value,
                child: Opacity(
                  opacity: (1.0 - _ctrl.value).clamp(0, 1),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

// ─── Animated tab indicator pill ─────────────────────────────────────────
class AnimatedTabIndicator extends StatelessWidget {
  final int itemCount;
  final int selectedIndex;
  final double itemWidth;
  final double height;
  final List<Color> gradient;

  const AnimatedTabIndicator({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemWidth,
    this.height = 44,
    this.gradient = const [Color(0xFF5B5FEF), Color(0xFF8B5CF6), Color(0xFFD946EF)],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: NexaAnim.normal,
      curve: NexaAnim.spring,
      left: selectedIndex * itemWidth,
      child: Container(
        width: itemWidth,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

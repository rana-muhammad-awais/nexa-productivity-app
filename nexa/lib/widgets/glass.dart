import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/animations.dart';
import '../core/theme.dart';

/// Frosted luxury glass card — the signature surface of Nexora.
/// Features a layered translucent fill, inner light refraction highlight,
/// and clean depth shadow. Supports elevated vs flat variants.
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double blur;
  final double radius;
  final Color? tint;
  final Border? border;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.blur = 18,
    this.radius = 20,
    this.tint,
    this.border,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final fill = tint ??
        (dark
            ? Color.fromRGBO(18, 18, 30, elevated ? 0.92 : 0.85)
            : Color.fromRGBO(255, 255, 255, elevated ? 0.95 : 0.88));

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withOpacity(elevated ? 0.45 : 0.3)
                : Colors.black.withOpacity(elevated ? 0.08 : 0.04),
            blurRadius: elevated ? 24 : 12,
            spreadRadius: -2,
            offset: Offset(0, elevated ? 6 : 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: border ??
                  Border.all(
                    color: dark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE8E6E1),
                    width: 1,
                  ),
              // Inner highlight for light refraction effect
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(dark ? 0.06 : 0.4),
                  Colors.white.withOpacity(0),
                ],
                stops: const [0.0, 0.5],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: BorderRadius.circular(radius),
                child: padding == null
                    ? child
                    : Padding(padding: padding!, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass card with animated gradient border — for flagship stat cards.
class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final List<Color> gradient;
  final double radius;
  final double borderWidth;
  final VoidCallback? onTap;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient = NexaColors.gradPrimary,
    this.radius = 20,
    this.borderWidth = 1.2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(dark ? 0.22 : 0.14),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: dark ? NexaColors.darkSurface1 : Colors.white,
          borderRadius: BorderRadius.circular(radius - borderWidth),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed gradient canvas painted behind the app content.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const GradientBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final base = backgroundColor(context);
    final glow = colors ?? NexaColors.gradPrimary;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: base),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: AnimatedBlob(color: glow[0], dark: dark, size: 280),
        ),
        Positioned(
          top: 100,
          left: -110,
          child: AnimatedBlob(color: glow[1], dark: dark, size: 240),
        ),
        Positioned(
          bottom: -120,
          right: -40,
          child: AnimatedBlob(
              color: glow[2 % glow.length], dark: dark, size: 280),
        ),
        child,
      ],
    );
  }
}

/// Compact stat card for dashboards — icon, label, value, optional trend.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final List<Color>? iconGradient;
  final String? trend; // e.g., "+12%" or "-5%"
  final bool trendUp;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconGradient,
    this.trend,
    this.trendUp = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final iColor = iconColor ?? primaryColor(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: iconGradient != null
                      ? LinearGradient(colors: iconGradient!)
                      : null,
                  color: iconGradient == null
                      ? iColor.withOpacity(dark ? 0.15 : 0.1)
                      : null,
                ),
                child: Center(
                  child: Icon(icon,
                      size: 18,
                      color: iconGradient != null ? Colors.white : iColor),
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendUp ? NexaColors.success : NexaColors.danger)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color:
                          trendUp ? NexaColors.success : NexaColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill / chip with optional gradient fill.
class GradientPill extends StatelessWidget {
  final String label;
  final List<Color>? gradient;
  final Color? color;
  final IconData? icon;
  const GradientPill(this.label,
      {super.key, this.gradient, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? textSecondaryColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient:
            gradient != null ? LinearGradient(colors: gradient!) : null,
        color: gradient == null ? fg.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: gradient != null ? Colors.white : fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: gradient != null ? Colors.white : fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with clean left accent line.
class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? action;
  final Color? color;
  const SectionHeader(this.text, {super.key, this.action, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color ?? primaryColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? textSecondaryColor(context),
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Friendly empty state with breathing pulse icon.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? buttonLabel;
  final VoidCallback? onButton;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.buttonLabel,
    this.onButton,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _breathAnim = Tween(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _breathAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor(context)
                      .withOpacity(dark ? 0.12 : 0.08),
                  border: Border.all(
                    color: primaryColor(context).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(widget.icon,
                      size: 34,
                      color: primaryColor(context).withOpacity(0.7)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondaryColor(context),
                height: 1.5,
              ),
            ),
            if (widget.buttonLabel != null) ...[
              const SizedBox(height: 24),
              GradientButton(
                widget.buttonLabel!,
                onPressed: widget.onButton,
                icon: Icons.add,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Primary gradient button with subtle press scale and glow.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<Color>? gradient;
  final bool expanded;
  const GradientButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.gradient,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? NexaColors.gradPrimary;
    return PressableScale(
      onTap: onPressed,
      child: Container(
        width: expanded ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ghost / secondary outline button.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  const GhostButton(this.label,
      {super.key, this.onPressed, this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final fg = danger ? NexaColors.danger : primaryColor(context);
    return PressableScale(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(0.25), width: 1),
          color: fg.withOpacity(0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring with gradient stroke.
class ProgressRing extends StatelessWidget {
  final double percent;
  final double size;
  final double stroke;
  final List<Color>? gradient;
  final Widget? center;
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 64,
    this.stroke = 6,
    this.gradient,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: stroke,
                backgroundColor: borderColor(context),
                valueColor: AlwaysStoppedAnimation(
                    gradient?[0] ?? primaryColor(context)),
                strokeCap: StrokeCap.round,
              ),
            ),
            center ??
                Text('${value.round()}%',
                    style: TextStyle(
                      fontSize: size * 0.24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
          ],
        ),
      ),
    );
  }
}

/// Initials avatar with gradient background based on name hash.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final gradients = [
      NexaColors.gradPrimary,
      NexaColors.gradCool,
      NexaColors.gradSuccess,
      NexaColors.gradWarm,
      NexaColors.gradRose,
      NexaColors.gradOcean,
      NexaColors.gradSunrise,
      NexaColors.gradFocus,
    ];
    final grad = gradients[name.hashCode.abs() % gradients.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grad,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

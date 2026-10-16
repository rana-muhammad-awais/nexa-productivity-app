import 'package:flutter/material.dart';

/// A modern, premium vector logo for Nexora.
/// Renders an isometric geometric 'N' ribbon with vibrant glowing gradients.
class NexoraLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool animate;

  const NexoraLogo({
    super.key,
    this.size = 56,
    this.showGlow = true,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: size * 0.35,
                  spreadRadius: -size * 0.05,
                  offset: Offset(0, size * 0.08),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: -size * 0.02,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _NexoraLogoPainter(),
      ),
    );
  }
}

class _NexoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // 1. Dark luxury background disk
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [
          Color(0xFF161626),
          Color(0xFF090912),
          Color(0xFF040408),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.26),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Subtle border highlight
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.35),
          const Color(0xFF818CF8).withOpacity(0.2),
          Colors.white.withOpacity(0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(rrect, borderPaint);

    // 3. Monogram 'N' paths
    // Scale coords relative to size
    final leftBarRect = Rect.fromLTWH(w * 0.24, h * 0.24, w * 0.16, h * 0.52);
    final rightBarRect = Rect.fromLTWH(w * 0.60, h * 0.24, w * 0.16, h * 0.52);

    // Left vertical stem (Cyan to Indigo)
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF22D3EE), // Cyan
          Color(0xFF6366F1), // Indigo
        ],
      ).createShader(leftBarRect);

    final leftRRect = RRect.fromRectAndRadius(
      leftBarRect,
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(leftRRect, leftPaint);

    // Diagonal connection band (Indigo to Magenta-Purple)
    final diagPath = Path();
    diagPath.moveTo(w * 0.26, h * 0.32);
    diagPath.lineTo(w * 0.42, h * 0.24);
    diagPath.lineTo(w * 0.74, h * 0.68);
    diagPath.lineTo(w * 0.58, h * 0.76);
    diagPath.close();

    final diagPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
          Color(0xFFC084FC),
        ],
      ).createShader(Rect.fromLTWH(w * 0.26, h * 0.24, w * 0.48, h * 0.52));
    canvas.drawPath(diagPath, diagPaint);

    // Right vertical stem (Purple to Magenta)
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFC084FC), // Lavender / Light Purple
          Color(0xFF8B5CF6), // Purple
          Color(0xFF4F46E5), // Deep Indigo
        ],
      ).createShader(rightBarRect);

    final rightRRect = RRect.fromRectAndRadius(
      rightBarRect,
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rightRRect, rightPaint);

    // 4. Highlight apex sparkle
    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(w * 0.32, h * 0.28), w * 0.035, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

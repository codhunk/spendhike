import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Reusable Attractive Illusion Background & Glassmorphic 3D Card
/// Provides animated optical illusion contour depth lines and a floating 3D illusion container
class AuthIllusionBackground extends StatefulWidget {
  final Widget child;

  const AuthIllusionBackground({super.key, required this.child});

  @override
  State<AuthIllusionBackground> createState() => _AuthIllusionBackgroundState();
}

class _AuthIllusionBackgroundState extends State<AuthIllusionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;

    return Stack(
      children: [
        // 1. Base Gradient Canvas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF070B18),
                        const Color(0xFF0C1329),
                        const Color(0xFF090E1F),
                      ]
                    : [
                        const Color(0xFFF3F6FD),
                        const Color(0xFFE8EEF9),
                        const Color(0xFFF0F4FC),
                      ],
              ),
            ),
          ),
        ),

        // 2. Animated Hypnotic Optical Illusion Waves & Depth Rings
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _OpticalIllusionPainter(
                  progress: _controller.value,
                  primaryColor: colors.primary,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),

        // 3. Floating Glow Spheres for 3D Illusion Depth
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
                  colors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF818CF8).withValues(alpha: isDark ? 0.28 : 0.18),
                  const Color(0xFF818CF8).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 4. Foreground Content
        widget.child,
      ],
    );
  }
}

/// Custom Optical Illusion Painter rendering 3D contour vortex waves and moire geometric lines
class _OpticalIllusionPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isDark;

  _OpticalIllusionPainter({
    required this.progress,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.65;
    final ringCount = 14;

    for (int i = 0; i < ringCount; i++) {
      // Harmonic wave phase shift for optical illusion breathing
      final phase = (progress + (i / ringCount)) % 1.0;
      final currentRadius = 30.0 + phase * (maxRadius - 30.0);

      final alpha = (math.sin(phase * math.pi) * (isDark ? 0.16 : 0.09)).clamp(0.01, 0.22);
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 + (i % 2 == 0 ? 0.8 : 0.2))
        ..color = (i % 3 == 0 ? const Color(0xFF6366F1) : primaryColor).withValues(alpha: alpha);

      // Warped ellipse path for 3D perspective illusion
      final path = Path();
      final points = 72;
      for (int p = 0; p <= points; p++) {
        final angle = (p / points) * 2 * math.pi;
        // Subtle rhythmic modulation
        final warp = math.sin(angle * 3 + progress * 2 * math.pi) * (8.0 + i * 1.5);
        final r = currentRadius + warp;
        final x = center.dx + r * math.cos(angle) * 1.08;
        final y = center.dy + r * math.sin(angle) * 0.78; // 3D tilt

        if (p == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, strokePaint);
    }

    // Subtle isometric corner illusion lines
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = primaryColor.withValues(alpha: isDark ? 0.07 : 0.04);

    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.35, size.height),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OpticalIllusionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}

/// Floating 3D Glassmorphic Illusion Card
/// Wraps forms with sleek border glow, frosted backdrop filter, and layered perspective depth
class AuthIllusionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthIllusionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF131B33).withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : colors.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              // 1. Soft Ambient Shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              // 2. Optical Neon Glow Halo
              BoxShadow(
                color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 36,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top Prismatic Highlight Specular Line for 3D Glass Illusion
              Positioned(
                top: 0,
                left: 10,
                right: 10,
                height: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.white : colors.primary).withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

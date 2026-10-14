import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Ultra-Attractive Chromatic Aurora & Spatial Depth Illusion Background
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
      duration: const Duration(seconds: 10),
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
        // 1. Rich Base Background Tone
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF090D1A) : const Color(0xFFF4F7FC),
          ),
        ),

        // 2. Animated Fluid Chromatic Aurora Orbs (Smooth Floating Light Waves)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              final dx1 = math.sin(t) * 70;
              final dy1 = math.cos(t) * 50;
              final dx2 = math.cos(t * 0.8) * 80;
              final dy2 = math.sin(t * 0.8) * 60;
              final dx3 = math.sin(t * 1.2) * 60;
              final dy3 = math.cos(t * 1.2) * 50;

              return Stack(
                children: [
                  // Orb 1: Vibrant Royal Blue
                  Positioned(
                    top: -40 + dy1,
                    left: -40 + dx1,
                    child: _buildAuroraOrb(
                      size: 380,
                      color: isDark
                          ? const Color(0xFF1E40AF).withValues(alpha: 0.55)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    ),
                  ),

                  // Orb 2: Electric Cyan / Turquoise
                  Positioned(
                    bottom: -30 + dy2,
                    right: -30 + dx2,
                    child: _buildAuroraOrb(
                      size: 360,
                      color: isDark
                          ? const Color(0xFF06B6D4).withValues(alpha: 0.40)
                          : const Color(0xFF06B6D4).withValues(alpha: 0.25),
                    ),
                  ),

                  // Orb 3: Violet / Neon Purple Aura
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35 + dy3,
                    right: -60 + dx3,
                    child: _buildAuroraOrb(
                      size: 320,
                      color: isDark
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.42)
                          : const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    ),
                  ),

                  // Orb 4: Subtle Golden Amber Accent
                  Positioned(
                    bottom: 80 - dy1,
                    left: -50 + dx2,
                    child: _buildAuroraOrb(
                      size: 260,
                      color: isDark
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 3. Heavy Gaussian Blur to create the Silky Liquid Aurora Illusion
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
            child: const SizedBox.expand(),
          ),
        ),

        // 4. Subtle 3D Perspective Matrix Dot Grid with Radial Vignette
        Positioned.fill(
          child: CustomPaint(
            painter: _SpatialDotGridPainter(
              dotColor: (isDark ? Colors.white : colors.primary).withValues(alpha: isDark ? 0.08 : 0.05),
            ),
          ),
        ),

        // 5. Foreground Content
        widget.child,
      ],
    );
  }

  Widget _buildAuroraOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Perspective Hologram Spatial Dot Grid
class _SpatialDotGridPainter extends CustomPainter {
  final Color dotColor;

  _SpatialDotGridPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final maxDist = size.width * 0.65;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final dist = (Offset(x, y) - center).distance;
        if (dist > maxDist) continue;

        // Radial falloff so dots fade smoothly towards edges
        final factor = (1.0 - (dist / maxDist)).clamp(0.0, 1.0);
        final r = 1.2 * factor;
        if (r > 0.3) {
          canvas.drawCircle(Offset(x, y), r, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpatialDotGridPainter oldDelegate) => false;
}

/// Floating Neo-Glassmorphic 3D Card with Iridescent Gradient Border & Depth Aura
class AuthIllusionCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthIllusionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  @override
  State<AuthIllusionCard> createState() => _AuthIllusionCardState();
}

class _AuthIllusionCardState extends State<AuthIllusionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;

    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, _) {
        final angle = _borderController.value * 2 * math.pi;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Floating 3D Perspective Glow Shadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.07),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: colors.primary.withValues(alpha: isDark ? 0.24 : 0.12),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Container(
            // Iridescent Animated Border
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: SweepGradient(
                center: Alignment.center,
                transform: GradientRotation(angle),
                colors: isDark
                    ? [
                        colors.primary.withValues(alpha: 0.8),
                        const Color(0xFF06B6D4).withValues(alpha: 0.6),
                        const Color(0xFF818CF8).withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.2),
                        colors.primary.withValues(alpha: 0.8),
                      ]
                    : [
                        colors.primary.withValues(alpha: 0.6),
                        const Color(0xFF06B6D4).withValues(alpha: 0.4),
                        const Color(0xFF818CF8).withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.8),
                        colors.primary.withValues(alpha: 0.6),
                      ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.5),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10172B).withValues(alpha: 0.84)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(22.5),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Top Optical Glass Specular Glint
                      Positioned(
                        top: 0,
                        left: 20,
                        right: 20,
                        height: 1.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                (isDark ? Colors.white : colors.primary).withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

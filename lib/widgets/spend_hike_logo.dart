import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable icon component for SpendHike (Wallet + Upward Hike Trend Arrow)
class SpendHikeIcon extends StatelessWidget {
  final double size;
  final Color walletColor;
  final Color arrowColor;

  const SpendHikeIcon({
    super.key,
    this.size = 48.0,
    this.walletColor = const Color(0xFF0B1C30),
    this.arrowColor = const Color(0xFF0066FF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SpendHikeLogoPainter(
        walletColor: walletColor,
        arrowColor: arrowColor,
      ),
    );
  }
}

/// Reusable Brand Logo component combining SpendHikeIcon + SpendHike Text
class SpendHikeLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color walletColor;
  final Color arrowColor;
  final Color textColor;
  final bool isVertical;

  const SpendHikeLogo({
    super.key,
    this.iconSize = 36.0,
    this.fontSize = 24.0,
    this.walletColor = const Color(0xFF0B1C30),
    this.arrowColor = const Color(0xFF0066FF),
    this.textColor = const Color(0xFF0B1C30),
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpendHikeIcon(
            size: iconSize,
            walletColor: walletColor,
            arrowColor: arrowColor,
          ),
          const SizedBox(height: 12),
          Text(
            'SpendHike',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SpendHikeIcon(
          size: iconSize,
          walletColor: walletColor,
          arrowColor: arrowColor,
        ),
        const SizedBox(width: 12),
        Text(
          'SpendHike',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SpendHikeLogoPainter extends CustomPainter {
  final Color walletColor;
  final Color arrowColor;

  _SpendHikeLogoPainter({
    required this.walletColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.08;

    // ── 1. Draw Wallet Base Outer Shape ────────────────────────────────────
    final walletPaint = Paint()
      ..color = walletColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final walletFillPaint = Paint()
      ..color = walletColor
      ..style = PaintingStyle.fill;

    // Wallet Body Outer Rect
    final walletRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.12, h * 0.24, w * 0.86, h * 0.88),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(walletRect, walletPaint);

    // Top Wallet Flap Line
    final flapY = h * 0.40;
    canvas.drawLine(
      Offset(w * 0.14, flapY),
      Offset(w * 0.65, flapY),
      walletPaint,
    );

    // Wallet Clasp/Lock on Right Side
    final claspRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.72, h * 0.48, w * 0.94, h * 0.68),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(claspRect, walletFillPaint);

    // Clasp Dot (white hole/button inside clasp)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.83, h * 0.58), w * 0.04, dotPaint);

    // ── 2. Draw Upward Hike Trend Arrow (Blue) ──────────────────────────────
    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trendPath = Path();
    final p1 = Offset(w * 0.16, h * 0.76);
    final p2 = Offset(w * 0.35, h * 0.52);
    final p3 = Offset(w * 0.48, h * 0.63);
    final p4 = Offset(w * 0.82, h * 0.20);

    trendPath.moveTo(p1.dx, p1.dy);
    trendPath.lineTo(p2.dx, p2.dy);
    trendPath.lineTo(p3.dx, p3.dy);
    trendPath.lineTo(p4.dx, p4.dy);

    canvas.drawPath(trendPath, arrowPaint);

    // Arrow Head at p4
    final arrowHeadPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headPath = Path();
    final headSize = w * 0.18;

    // Arrow pointing top-right (approx -45 degrees)
    final angle = -math.pi / 4;
    final tip = p4;

    final leftWing = Offset(
      tip.dx - headSize * math.cos(angle - math.pi / 6),
      tip.dy - headSize * math.sin(angle - math.pi / 6),
    );
    final rightWing = Offset(
      tip.dx - headSize * math.cos(angle + math.pi / 6),
      tip.dy - headSize * math.sin(angle + math.pi / 6),
    );

    headPath.moveTo(tip.dx, tip.dy);
    headPath.lineTo(leftWing.dx, leftWing.dy);
    headPath.lineTo(
      tip.dx - (headSize * 0.5) * math.cos(angle),
      tip.dy - (headSize * 0.5) * math.sin(angle),
    );
    headPath.lineTo(rightWing.dx, rightWing.dy);
    headPath.close();

    canvas.drawPath(headPath, arrowHeadPaint);
  }

  @override
  bool shouldRepaint(_SpendHikeLogoPainter oldDelegate) =>
      oldDelegate.walletColor != walletColor ||
      oldDelegate.arrowColor != arrowColor;
}

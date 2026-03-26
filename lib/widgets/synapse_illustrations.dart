/// Synapse — Custom line-art illustrations using Flutter CustomPainter.
/// No asset files required — pure Flutter drawing.
library;

import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Slide 1 Illustration: "Reclaim Your Time" — minimal hourglass / clock
// ─────────────────────────────────────────────────────────────────────────────
class ReclaimTimeIllustration extends StatefulWidget {
  final double size;
  const ReclaimTimeIllustration({super.key, this.size = 220});

  @override
  State<ReclaimTimeIllustration> createState() =>
      _ReclaimTimeIllustrationState();
}

class _ReclaimTimeIllustrationState extends State<ReclaimTimeIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => CustomPaint(
          painter: _ClockPainter(progress: _anim.value),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double progress;
  _ClockPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(center, radius * 1.15, paint);

    // Outer ring
    final ringPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, ringPaint);

    // Hour markers
    final markerPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      final inner = Offset(
        center.dx + (radius - 10) * _cos(angle),
        center.dy + (radius - 10) * _sin(angle),
      );
      final outer = Offset(
        center.dx + (radius - 2) * _cos(angle),
        center.dy + (radius - 2) * _sin(angle),
      );
      canvas.drawLine(inner, outer, markerPaint);
    }

    // Hour hand
    final hourAngle = progress * 2 * 3.14159 - 3.14159 / 2;
    final hourPaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.5 * _cos(hourAngle),
        center.dy + radius * 0.5 * _sin(hourAngle),
      ),
      hourPaint,
    );

    // Minute hand
    final minAngle = progress * 24 * 3.14159 - 3.14159 / 2;
    final minPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.72 * _cos(minAngle),
        center.dy + radius * 0.72 * _sin(minAngle),
      ),
      minPaint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      5,
      Paint()..color = AppTheme.primaryColor,
    );
  }

  double _cos(double angle) => (angle == 0) ? 1.0 : _approxCos(angle);
  double _sin(double angle) => _approxSin(angle);

  double _approxCos(double a) {
    // Use Dart's math via the formula — import avoided for widget purity
    return _approxSin(a + 3.14159 / 2);
  }

  double _approxSin(double a) {
    a = a % (2 * 3.14159);
    if (a < 0) a += 2 * 3.14159;
    // Taylor approx sufficient for drawing
    final x = a - 3.14159;
    return -x *
        (1 -
            x * x / 6 * (1 - x * x / 20 * (1 - x * x / 42)));
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
/// Slide 2 Illustration: "Enhance Your Focus" — target / bullseye rings
// ─────────────────────────────────────────────────────────────────────────────
class EnhanceFocusIllustration extends StatelessWidget {
  final double size;
  const EnhanceFocusIllustration({super.key, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TargetPainter()),
    );
  }
}

class _TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.42;

    final colors = [
      AppTheme.primaryColor.withValues(alpha: 0.08),
      AppTheme.primaryColor.withValues(alpha: 0.14),
      AppTheme.primaryColor.withValues(alpha: 0.22),
      AppTheme.primaryColor.withValues(alpha: 0.35),
    ];

    for (int i = 4; i >= 1; i--) {
      final r = maxRadius * (i / 4);
      canvas.drawCircle(
        center,
        r,
        Paint()..color = colors[i - 1]..style = PaintingStyle.fill,
      );
    }

    // Center dot
    canvas.drawCircle(
      center,
      maxRadius * 0.12,
      Paint()..color = AppTheme.primaryColor,
    );

    // Cross-hair lines
    final linePaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius * 1.1),
      Offset(center.dx, center.dy - maxRadius * 0.55),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + maxRadius * 0.55),
      Offset(center.dx, center.dy + maxRadius * 1.1),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius * 1.1, center.dy),
      Offset(center.dx - maxRadius * 0.55, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + maxRadius * 0.55, center.dy),
      Offset(center.dx + maxRadius * 1.1, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_TargetPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
/// Slide 3 Illustration: "Rewire Your Habit Loop" — looping arrows circle
// ─────────────────────────────────────────────────────────────────────────────
class HabitLoopIllustration extends StatefulWidget {
  final double size;
  const HabitLoopIllustration({super.key, this.size = 220});

  @override
  State<HabitLoopIllustration> createState() => _HabitLoopIllustrationState();
}

class _HabitLoopIllustrationState extends State<HabitLoopIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          painter: _LoopPainter(progress: _ctrl.value),
        ),
      ),
    );
  }
}

class _LoopPainter extends CustomPainter {
  final double progress;
  _LoopPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Background glow circle
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()
        ..color = AppTheme.secondaryColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );

    // Dashed arc rotating
    final arcPaint = Paint()
      ..color = AppTheme.secondaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const pi = 3.14159265;
    canvas.drawArc(
      rect,
      progress * 2 * pi,
      pi * 1.5,
      false,
      arcPaint,
    );

    // 3 dots on the orbit
    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * pi + (i * 2 * pi / 3);
      final dotX = center.dx + radius * _cos(angle);
      final dotY = center.dy + radius * _sin(angle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()..color = AppTheme.secondaryColor,
      );
    }

    // Center icon — simple loop symbol
    final centerPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius * 0.25, centerPaint);
  }

  double _cos(double a) {
    final sinVal = _sin(a + 3.14159 / 2);
    return sinVal;
  }

  double _sin(double a) {
    a = a % (2 * 3.14159);
    if (a < 0) a += 2 * 3.14159;
    final x = a - 3.14159;
    return -x * (1 - x * x / 6 * (1 - x * x / 20 * (1 - x * x / 42)));
  }

  @override
  bool shouldRepaint(_LoopPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
/// Circular Focus Score badge — arc fills proportionally.
// ─────────────────────────────────────────────────────────────────────────────
class FocusScoreBadge extends StatelessWidget {
  final int score;
  final int maxScore;
  final double size;

  const FocusScoreBadge({
    super.key,
    required this.score,
    this.maxScore = 200,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (score / maxScore).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreArcPainter(ratio: ratio),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: size * 0.12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  final double ratio;
  _ScoreArcPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Filled arc
    final arcPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A90B8), Color(0xFF7B9CE1)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      ratio * 2 * pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) => old.ratio != ratio;
}

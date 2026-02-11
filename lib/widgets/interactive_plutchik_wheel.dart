// lib/widgets/interactive_plutchik_wheel.dart
// Roue de Plutchik interactive — 18 secteurs, sélection par tap

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/emotion_config.dart';

class InteractivePlutchikWheel extends StatefulWidget {
  final int? selectedIndex;
  final ValueChanged<int> onEmotionTapped;

  const InteractivePlutchikWheel({
    super.key,
    this.selectedIndex,
    required this.onEmotionTapped,
  });

  @override
  State<InteractivePlutchikWheel> createState() =>
      _InteractivePlutchikWheelState();
}

class _InteractivePlutchikWheelState extends State<InteractivePlutchikWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static final List<EmotionConfig> _allEmotions = [
    ...EmotionCategories.negativeEmotions,
    ...EmotionCategories.positiveEmotions,
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, size),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _PlutchikWheelPainter(
                  emotions: _allEmotions,
                  selectedIndex: widget.selectedIndex,
                  pulseValue: _pulseAnimation.value,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, double size) {
    final center = Offset(size / 2, size / 2);
    final tap = details.localPosition;
    final dx = tap.dx - center.dx;
    final dy = tap.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final outerRadius = size / 2 - 8;
    final innerRadius = outerRadius * 0.28;

    if (distance < innerRadius || distance > outerRadius) return;

    // Angle du tap (0 = haut, sens horaire)
    var angle = math.atan2(dx, -dy); // 0 en haut
    if (angle < 0) angle += 2 * math.pi;

    final segmentAngle = 2 * math.pi / _allEmotions.length;
    final index = (angle / segmentAngle).floor() % _allEmotions.length;

    widget.onEmotionTapped(index);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CustomPainter — Roue Plutchik 18 secteurs
// ═══════════════════════════════════════════════════════════════════════════════

class _PlutchikWheelPainter extends CustomPainter {
  final List<EmotionConfig> emotions;
  final int? selectedIndex;
  final double pulseValue;

  _PlutchikWheelPainter({
    required this.emotions,
    this.selectedIndex,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 8;
    final innerRadius = outerRadius * 0.28;
    final midRadius = (outerRadius + innerRadius) / 2;
    final segmentAngle = 2 * math.pi / emotions.length;

    for (int i = 0; i < emotions.length; i++) {
      final emotion = emotions[i];
      final startAngle = -math.pi / 2 + i * segmentAngle;
      final isSelected = i == selectedIndex;

      // ── Anneau extérieur (plus clair) ──────────────────────────────────
      final outerColor = _lighten(emotion.color, 0.2);
      _drawArcSegment(
        canvas,
        center,
        midRadius,
        outerRadius + (isSelected ? 4 : 0),
        startAngle,
        segmentAngle,
        outerColor,
        isSelected,
      );

      // ── Anneau intérieur (plus foncé) ──────────────────────────────────
      final innerColor = _darken(emotion.color, 0.15);
      _drawArcSegment(
        canvas,
        center,
        innerRadius,
        midRadius,
        startAngle,
        segmentAngle,
        innerColor,
        isSelected,
      );

      // ── Bordure sélection ──────────────────────────────────────────────
      if (isSelected) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4 + 0.3 * pulseValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        final path = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: outerRadius + 4),
            startAngle,
            segmentAngle,
          )
          ..arcTo(
            Rect.fromCircle(center: center, radius: innerRadius),
            startAngle + segmentAngle,
            -segmentAngle,
            false,
          )
          ..close();

        canvas.drawPath(path, glowPaint);
      }

      // ── Lignes de séparation ───────────────────────────────────────────
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.2;
      final lineStart = Offset(
        center.dx + innerRadius * math.cos(startAngle),
        center.dy + innerRadius * math.sin(startAngle),
      );
      final lineEnd = Offset(
        center.dx + outerRadius * math.cos(startAngle),
        center.dy + outerRadius * math.sin(startAngle),
      );
      canvas.drawLine(lineStart, lineEnd, linePaint);

      // ── Texte radial ───────────────────────────────────────────────────
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = (midRadius + outerRadius) / 2;
      final textCenter = Offset(
        center.dx + textRadius * math.cos(textAngle),
        center.dy + textRadius * math.sin(textAngle),
      );

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);

      // Rotation pour le texte lisible
      double rotation = textAngle + math.pi / 2;
      // Inverser si le texte serait à l'envers
      if (textAngle > math.pi / 2 && textAngle < 3 * math.pi / 2) {
        rotation += math.pi;
      }
      canvas.rotate(rotation);

      final textPainter = TextPainter(
        text: TextSpan(
          text: emotion.name,
          style: TextStyle(
            fontSize: isSelected ? 11 : 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: 70);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // ── Cercle central ─────────────────────────────────────────────────────
    final centerPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius - 2, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, innerRadius - 2, centerBorderPaint);

    // Texte central
    final centralText = TextPainter(
      text: TextSpan(
        text: selectedIndex != null
            ? emotions[selectedIndex!].name
            : 'Que\nressens-tu ?',
        style: TextStyle(
          fontSize: selectedIndex != null ? 12 : 10,
          fontWeight: FontWeight.w700,
          color: selectedIndex != null
              ? emotions[selectedIndex!].color
              : const Color(0xFF64748B),
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    centralText.layout(maxWidth: innerRadius * 1.5);
    centralText.paint(
      canvas,
      Offset(
        center.dx - centralText.width / 2,
        center.dy - centralText.height / 2,
      ),
    );
  }

  void _drawArcSegment(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    double startAngle,
    double sweepAngle,
    Color color,
    bool isSelected,
  ) {
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: outerR),
        startAngle,
        sweepAngle,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerR),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _PlutchikWheelPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.pulseValue != pulseValue;
  }
}

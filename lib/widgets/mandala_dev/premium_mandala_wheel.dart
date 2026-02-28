// premium_mandala_wheel.dart
// Mandala Premium — Anneau de nuances rotatif + Intensité 0→10→0

import 'dart:math' as math;
import 'package:flutter/material.dart';

class PremiumMandalaWheel extends StatefulWidget {
  final List<String> nuances;
  final int? selectedEmotionIndex;
  final int intensity;
  final Set<String> selectedNuances;

  final Function(int) onEmotionTap;
  final Function(String) onNuanceToggle;
  final Function(int) onIntensityChange;
  final Function(int?) onPreviewEmotion;

  const PremiumMandalaWheel({
    super.key,
    required this.nuances,
    required this.selectedEmotionIndex,
    required this.intensity,
    required this.selectedNuances,
    required this.onEmotionTap,
    required this.onNuanceToggle,
    required this.onIntensityChange,
    required this.onPreviewEmotion,
  });

  @override
  State<PremiumMandalaWheel> createState() => _PremiumMandalaWheelState();
}

class _PremiumMandalaWheelState extends State<PremiumMandalaWheel> {

  double nuanceRotation = 0;

  void _handleCenterTap() {
    final next = widget.intensity >= 10 ? 0 : widget.intensity + 1;
    widget.onIntensityChange(next);
  }

  void _handleNuanceDrag(DragUpdateDetails d) {
    setState(() {
      nuanceRotation += d.delta.dx * 0.01;
    });
  }

  void _handleTapDown(TapDownDetails d, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final pos = d.localPosition;
    final r = (pos - center).distance;

    final centerRadius = size.width * 0.18;
    final nuanceInner = size.width * 0.35;
    final nuanceOuter = size.width * 0.48;

    if (r <= centerRadius) {
      _handleCenterTap();
      return;
    }

    if (r >= nuanceInner && r <= nuanceOuter && widget.nuances.isNotEmpty) {
      final angle = math.atan2(pos.dy - center.dy, pos.dx - center.dx) - nuanceRotation;
      final index = ((angle + math.pi) / (2*math.pi) * widget.nuances.length).floor();
      if (index >= 0 && index < widget.nuances.length) {
        widget.onNuanceToggle(widget.nuances[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return GestureDetector(
        onTapDown: (d) => _handleTapDown(d, size),
        onPanUpdate: _handleNuanceDrag,
        child: CustomPaint(
          size: size,
          painter: _PremiumPainter(
            nuances: widget.nuances,
            rotation: nuanceRotation,
            selectedNuances: widget.selectedNuances,
            intensity: widget.intensity,
            isAppui: widget.selectedEmotionIndex == null ||
                widget.selectedEmotionIndex! >= 9,
          ),
        ),
      );
    });
  }
}

class _PremiumPainter extends CustomPainter {

  final List<String> nuances;
  final double rotation;
  final Set<String> selectedNuances;
  final int intensity;
  final bool isAppui;

  _PremiumPainter({
    required this.nuances,
    required this.rotation,
    required this.selectedNuances,
    required this.intensity,
    required this.isAppui,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final R = size.width * 0.48;

    final bg = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF071428), Color(0xFF000000)],
      ).createShader(Rect.fromCircle(center: center, radius: R));

    canvas.drawCircle(center, R, bg);

    // --- MANDALA DECORATIF INTERNE ---
    final decoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.15);

    for (int i = 0; i < 36; i++) {
      final angle = i / 36 * 2 * math.pi;
      final r1 = R * 0.42;
      final r2 = R * 0.68;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * r1;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * r2;
      canvas.drawLine(p1, p2, decoPaint);
    }

    // Cercle sacré interne
    canvas.drawCircle(
      center,
      R * 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.25),
    );

    // --- GEOMETRIE SACREE INTERNE ---
    final squareSize = R * 0.78;
    final half = squareSize / 2;

    // Carré central
    final rect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );

    final squarePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.25);

    canvas.drawRect(rect, squarePaint);

    // --- PORTES CARDINALES ---
    final gateWidth = squareSize * 0.18;
    final gateDepth = squareSize * 0.08;

    final gatePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.30);

    // NORD
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(0, -half),
        width: gateWidth,
        height: gateDepth,
      ),
      gatePaint,
    );

    // SUD
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(0, half),
        width: gateWidth,
        height: gateDepth,
      ),
      gatePaint,
    );

    // EST
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(half, 0),
        width: gateDepth,
        height: gateWidth,
      ),
      gatePaint,
    );

    // OUEST
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(-half, 0),
        width: gateDepth,
        height: gateWidth,
      ),
      gatePaint,
    );

    // --- ANNEAU NUANCES ---
    final nuanceInner = R * 0.72;
    final nuanceOuter = R * 0.92;

    final n = nuances.length;

    for (int i=0;i<n;i++) {
      final a0 = (i/n)*2*math.pi + rotation;
      final a1 = ((i+1)/n)*2*math.pi + rotation;

      final path = Path()
        ..addArc(Rect.fromCircle(center:center, radius:nuanceOuter), a0, a1-a0)
        ..arcTo(Rect.fromCircle(center:center, radius:nuanceInner), a1, -(a1-a0), false)
        ..close();

      final isSel = selectedNuances.contains(nuances[i]);

      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: isSel ? 0.45 : 0.12));
    }

    // --- ENERGIE CENTRALE APPUI vs TENSION ---
    final t = intensity / 10.0;

    final energyColor = isAppui
        ? const Color(0xFF4FC3F7)   // bleu (appui)
        : const Color(0xFFF59E0B);  // ambre (tension)

    final centerRadius = R * (0.34 + (isAppui ? 0.05 * t : -0.03 * t));

    final core = Paint()
      ..color = energyColor.withValues(alpha: 0.18 + 0.35 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, centerRadius, core);

    // Aura externe
    final aura = Paint()
      ..color = energyColor.withValues(alpha: 0.05 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(center, centerRadius * 1.5, aura);
  }

  @override
  bool shouldRepaint(covariant _PremiumPainter old) =>
    old.rotation != rotation ||
    old.selectedNuances != selectedNuances ||
    old.intensity != intensity ||
    old.isAppui != isAppui;
}

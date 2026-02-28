// premium_mandala_wheel_v2.dart
// Mandala Premium V2 — Structure mandala + anneau émotions + anneau nuances rotatif
// UX: tap émotion = "ciblée" même si intensité=0. Tap centre: 0→1→…→10→0.
// Nuances affichées: uniquement celles de l'émotion ciblée.
// Palette: bleu nuit + bleus + ambre/or, sans rose.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum _DragMode { none, nuance, emotion }

class PremiumMandalaWheelV2 extends StatefulWidget {
  /// 18 émotions -> on dessine un anneau de pétales (sans texte dans la roue)
  final int emotionCount;

  /// Index de l'émotion "ciblée" (affichage). Peut rester non-null même si intensity==0.
  final int? selectedEmotionIndex;

  /// Nuances de l'émotion ciblée (affichées sur l'anneau nuances)
  final List<String> nuances;

  /// Multi-sélection de nuances
  final Set<String> selectedNuances;

  /// 0..10
  final int intensity;

  /// Callbacks
  final ValueChanged<int> onEmotionTap;          // tap pétale
  final ValueChanged<int?> onPreviewEmotion;     // drag/preview (afficher le nom en haut)
  final ValueChanged<String> onNuanceToggle;     // toggle nuance
  final ValueChanged<int> onIntensityChange;     // tap centre -> cycle

  const PremiumMandalaWheelV2({
    super.key,
    required this.emotionCount,
    required this.selectedEmotionIndex,
    required this.nuances,
    required this.selectedNuances,
    required this.intensity,
    required this.onEmotionTap,
    required this.onPreviewEmotion,
    required this.onNuanceToggle,
    required this.onIntensityChange,
  });

  @override
  State<PremiumMandalaWheelV2> createState() => _PremiumMandalaWheelV2State();
}

class _PremiumMandalaWheelV2State extends State<PremiumMandalaWheelV2> {
  double _nuanceRotation = 0.0;
  _DragMode _dragMode = _DragMode.none;

  // --- Geometry (unifiée dessin + hit-test)
  late double _R;
  late double _centerRadius;
  late double _emotionInner;
  late double _emotionOuter;
  late double _nuanceInner;
  late double _nuanceOuter;

  void _updateGeom(Size size) {
    _R = math.min(size.width, size.height) * 0.48;
    _centerRadius = _R * 0.28;
    _emotionInner = _R * 0.44;
    _emotionOuter = _R * 0.70;
    _nuanceInner = _R * 0.72;
    _nuanceOuter = _R * 0.92;
  }

  void _cycleIntensity() {
    final cur = widget.intensity.clamp(0, 10);
    final next = (cur >= 10) ? 0 : (cur + 1);
    widget.onIntensityChange(next);
  }

  int _angleToIndex(double theta, int count) {
    final idx = (theta / (2 * math.pi) * count).floor();
    return idx.clamp(0, count - 1);
  }

  double _thetaFor(Offset p) {
    var t = math.atan2(p.dy, p.dx);
    if (t < 0) t += 2 * math.pi;
    return t;
  }

  void _onTapDown(TapDownDetails d, Size size) {
    _updateGeom(size);
    final center = Offset(size.width / 2, size.height / 2);
    final p = d.localPosition - center;
    final r = p.distance;
    final theta = _thetaFor(p);

    // Centre
    if (r <= _centerRadius) {
      _cycleIntensity();
      return;
    }

    // Nuances (si présentes)
    if (r >= _nuanceInner && r <= _nuanceOuter && widget.nuances.isNotEmpty) {
      final thetaAdj = (theta - _nuanceRotation) % (2 * math.pi);
      final idx = _angleToIndex(thetaAdj, widget.nuances.length);
      widget.onNuanceToggle(widget.nuances[idx]);
      return;
    }

    // Émotions
    if (r >= _emotionInner && r <= _emotionOuter && widget.emotionCount > 0) {
      final idx = _angleToIndex(theta, widget.emotionCount);
      widget.onEmotionTap(idx);
      return;
    }
  }

  void _onPanStart(DragStartDetails d, Size size) {
    _updateGeom(size);
    final center = Offset(size.width / 2, size.height / 2);
    final p = d.localPosition - center;
    final r = p.distance;

    if (r >= _nuanceInner && r <= _nuanceOuter && widget.nuances.isNotEmpty) {
      _dragMode = _DragMode.nuance;
      return;
    }
    if (r >= _emotionInner && r <= _emotionOuter && widget.emotionCount > 0) {
      _dragMode = _DragMode.emotion;
      final theta = _thetaFor(p);
      widget.onPreviewEmotion(_angleToIndex(theta, widget.emotionCount));
      return;
    }
    _dragMode = _DragMode.none;
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    _updateGeom(size);
    final center = Offset(size.width / 2, size.height / 2);
    final p = d.localPosition - center;

    switch (_dragMode) {
      case _DragMode.nuance:
        setState(() {
          _nuanceRotation = (_nuanceRotation + d.delta.dx * 0.008) % (2 * math.pi);
        });
      case _DragMode.emotion:
        final theta = _thetaFor(p);
        widget.onPreviewEmotion(_angleToIndex(theta, widget.emotionCount));
      case _DragMode.none:
        break;
    }
  }

  void _onPanEnd(_) {
    if (_dragMode == _DragMode.emotion) {
      widget.onPreviewEmotion(null);
    }
    _dragMode = _DragMode.none;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      _updateGeom(size);
      return GestureDetector(
        onTapDown: (d) => _onTapDown(d, size),
        onPanStart: (d) => _onPanStart(d, size),
        onPanUpdate: (d) => _onPanUpdate(d, size),
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          size: size,
          painter: _PremiumMandalaPainterV2(
            nuanceRotation: _nuanceRotation,
            emotionCount: widget.emotionCount,
            selectedEmotionIndex: widget.selectedEmotionIndex,
            nuances: widget.nuances,
            selectedNuances: widget.selectedNuances,
            intensity: widget.intensity.clamp(0, 10),
          ),
        ),
      );
    });
  }
}

class _PremiumMandalaPainterV2 extends CustomPainter {
  final double nuanceRotation;
  final int emotionCount;
  final int? selectedEmotionIndex;
  final List<String> nuances;
  final Set<String> selectedNuances;
  final int intensity;

  _PremiumMandalaPainterV2({
    required this.nuanceRotation,
    required this.emotionCount,
    required this.selectedEmotionIndex,
    required this.nuances,
    required this.selectedNuances,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) * 0.48;

    // Palette (sans rose)
    const bgA = Color(0xFF071428);
    const bgB = Color(0xFF000000);
    const blue = Color(0xFF4FC3F7);
    const indigo = Color(0xFF1E40AF);
    const amber = Color(0xFFF59E0B);

    // Fond radial
    final bg = Paint()
      ..shader = ui.Gradient.radial(
        center,
        R * 1.25,
        [bgA, bgB],
        [0.0, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bg);

    // Halo externe discret
    final halo = Paint()
      ..color = blue.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, R * 0.98, halo);

    // --- Décor mandala (rayons + cercles)
    final rayPaint = Paint()
      ..color = amber.withValues(alpha: 0.10)
      ..strokeWidth = 1.2;

    const rays = 72;
    for (int i = 0; i < rays; i++) {
      final a = i / rays * 2 * math.pi;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (R * 0.30);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (R * 0.62);
      canvas.drawLine(p1, p2, rayPaint);
    }

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(center, R * 0.30, circlePaint);
    canvas.drawCircle(center, R * 0.62, circlePaint);

    // --- Carré sacré + portes
    final squareSize = R * 0.78;
    final half = squareSize / 2;
    final rect = Rect.fromCenter(center: center, width: squareSize, height: squareSize);

    final squarePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = amber.withValues(alpha: 0.22);
    canvas.drawRect(rect, squarePaint);

    final gateWidth = squareSize * 0.18;
    final gateDepth = squareSize * 0.08;

    final gatePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = amber.withValues(alpha: 0.28);

    // N/S/E/W
    canvas.drawRect(Rect.fromCenter(center: center + Offset(0, -half), width: gateWidth, height: gateDepth), gatePaint);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(0, half), width: gateWidth, height: gateDepth), gatePaint);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(half, 0), width: gateDepth, height: gateWidth), gatePaint);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(-half, 0), width: gateDepth, height: gateWidth), gatePaint);

    // --- Anneau émotions (pétales)
    final emotionInner = R * 0.44;
    final emotionOuter = R * 0.70;

    if (emotionCount > 0) {
      for (int i = 0; i < emotionCount; i++) {
        final a0 = (i / emotionCount) * 2 * math.pi;
        final a1 = ((i + 1) / emotionCount) * 2 * math.pi;
        final isSel = (selectedEmotionIndex == i);

        final path = Path()
          ..addArc(Rect.fromCircle(center: center, radius: emotionOuter), a0, a1 - a0)
          ..arcTo(Rect.fromCircle(center: center, radius: emotionInner), a1, -(a1 - a0), false)
          ..close();

        canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: isSel ? 0.10 : 0.05));

        if (isSel) {
          final glow = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = amber.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
          canvas.drawPath(path, glow);
        }

        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 1.8 : 1.1
            ..color = Colors.white.withValues(alpha: isSel ? 0.16 : 0.10),
        );
      }
    }

    // --- Anneau nuances rotatif
    final nuanceInner = R * 0.72;
    final nuanceOuter = R * 0.92;

    if (nuances.isNotEmpty) {
      final n = nuances.length;
      for (int i = 0; i < n; i++) {
        final a0 = (i / n) * 2 * math.pi + nuanceRotation;
        final a1 = ((i + 1) / n) * 2 * math.pi + nuanceRotation;
        final isSel = selectedNuances.contains(nuances[i]);

        final path = Path()
          ..addArc(Rect.fromCircle(center: center, radius: nuanceOuter), a0, a1 - a0)
          ..arcTo(Rect.fromCircle(center: center, radius: nuanceInner), a1, -(a1 - a0), false)
          ..close();

        canvas.drawPath(path, Paint()..color = (isSel ? amber : indigo).withValues(alpha: isSel ? 0.28 : 0.10));
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 2.0 : 1.0
            ..color = Colors.white.withValues(alpha: isSel ? 0.16 : 0.07),
        );
      }
    } else {
      canvas.drawCircle(center, nuanceInner, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = Colors.white.withValues(alpha: 0.05));
      canvas.drawCircle(center, nuanceOuter, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = Colors.white.withValues(alpha: 0.05));
    }

    // --- Centre: intensité
    final t = intensity / 10.0;
    final centerRadius = R * (0.28 + 0.06 * t);

    final core = Paint()
      ..color = amber.withValues(alpha: 0.10 + 0.22 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, centerRadius, core);

    final aura = Paint()
      ..color = blue.withValues(alpha: 0.05 + 0.08 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(center, centerRadius * 1.55, aura);

    canvas.drawCircle(
      center,
      centerRadius * 1.02,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '$intensity/10',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: R * 0.075,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PremiumMandalaPainterV2 old) {
    return old.nuanceRotation != nuanceRotation ||
        old.emotionCount != emotionCount ||
        old.selectedEmotionIndex != selectedEmotionIndex ||
        old.intensity != intensity ||
        old.nuances != nuances ||
        old.selectedNuances != selectedNuances;
  }
}

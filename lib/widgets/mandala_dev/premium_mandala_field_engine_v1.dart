// premium_mandala_field_engine_v1.dart
// HYBRID — Field Engine architecture + Parametric Faces V2
//
// Intensity (0..10) drives: halo + density + micro-pulse + nuance corona.
// Faces are drawn via Canvas (ParametricEmotionFaceV2), no PNG assets needed.
// Center face is large, filling the center circle, with field glow around it.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'parametric_emotion_face_v2.dart';

enum _DragMode { none, nuance, emotion }

class PremiumMandalaFieldEngineV1 extends StatefulWidget {
  final List<String> emotionKeys;
  final int? selectedEmotionIndex; // targeted (do NOT null when intensity==0)
  final List<String> nuances;
  final Set<String> selectedNuances;
  final int intensity; // 0..10

  final ValueChanged<int> onEmotionTap;
  final ValueChanged<int?> onPreviewEmotion;
  final ValueChanged<String> onNuanceToggle;
  final ValueChanged<int> onIntensityChange;

  final ImageProvider? backgroundMandala;

  // Visual params
  final Color glowAmber;
  final Color glowBlue;
  final bool showNuanceCorona;
  final bool showOuterNuanceRing;

  const PremiumMandalaFieldEngineV1({
    super.key,
    required this.emotionKeys,
    required this.selectedEmotionIndex,
    required this.nuances,
    required this.selectedNuances,
    required this.intensity,
    required this.onEmotionTap,
    required this.onPreviewEmotion,
    required this.onNuanceToggle,
    required this.onIntensityChange,
    this.backgroundMandala,
    this.glowAmber = const Color(0xFFF59E0B),
    this.glowBlue = const Color(0xFF38BDF8),
    this.showNuanceCorona = true,
    this.showOuterNuanceRing = false,
  });

  @override
  State<PremiumMandalaFieldEngineV1> createState() =>
      _PremiumMandalaFieldEngineV1State();
}

class _PremiumMandalaFieldEngineV1State
    extends State<PremiumMandalaFieldEngineV1>
    with SingleTickerProviderStateMixin {
  double _nuanceRotation = 0.0;
  _DragMode _dragMode = _DragMode.none;

  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  late double _R, _centerRadius, _emotionInner, _emotionOuter,
      _nuanceInner, _nuanceOuter;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _updateGeom(Size size) {
    _R = math.min(size.width, size.height) * 0.48;
    _centerRadius = _R * 0.285;
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

  double _thetaFor(Offset p) {
    var t = math.atan2(p.dy, p.dx);
    if (t < 0) t += 2 * math.pi;
    return t;
  }

  int _angleToIndex(double theta, int count) {
    final idx = (theta / (2 * math.pi) * count).floor();
    return idx.clamp(0, count - 1);
  }

  // ── Gesture handling ──────────────────────────────────────────────────

  void _onTapDown(TapDownDetails d, Size size) {
    _updateGeom(size);
    final center = Offset(size.width / 2, size.height / 2);
    final p = d.localPosition - center;
    final r = p.distance;
    final theta = _thetaFor(p);

    if (r <= _centerRadius) {
      _cycleIntensity();
      return;
    }

    // Corona nuances (between center and emotion ring)
    final coronaInner = _centerRadius * 1.22;
    final coronaOuter = _centerRadius * 1.55;
    if (widget.showNuanceCorona &&
        r >= coronaInner &&
        r <= coronaOuter &&
        widget.nuances.isNotEmpty) {
      final thetaAdj = (theta - _nuanceRotation) % (2 * math.pi);
      final idx = _angleToIndex(thetaAdj, widget.nuances.length);
      widget.onNuanceToggle(widget.nuances[idx]);
      return;
    }

    if (widget.showOuterNuanceRing &&
        r >= _nuanceInner &&
        r <= _nuanceOuter &&
        widget.nuances.isNotEmpty) {
      final thetaAdj = (theta - _nuanceRotation) % (2 * math.pi);
      final idx = _angleToIndex(thetaAdj, widget.nuances.length);
      widget.onNuanceToggle(widget.nuances[idx]);
      return;
    }

    if (r >= _emotionInner &&
        r <= _emotionOuter &&
        widget.emotionKeys.isNotEmpty) {
      final idx = _angleToIndex(theta, widget.emotionKeys.length);
      widget.onEmotionTap(idx);
      return;
    }
  }

  void _onPanStart(DragStartDetails d, Size size) {
    _updateGeom(size);
    final center = Offset(size.width / 2, size.height / 2);
    final p = d.localPosition - center;
    final r = p.distance;

    if (widget.showOuterNuanceRing &&
        r >= _nuanceInner &&
        r <= _nuanceOuter &&
        widget.nuances.isNotEmpty) {
      _dragMode = _DragMode.nuance;
      return;
    }
    if (r >= _emotionInner &&
        r <= _emotionOuter &&
        widget.emotionKeys.isNotEmpty) {
      _dragMode = _DragMode.emotion;
      final theta = _thetaFor(p);
      widget.onPreviewEmotion(
          _angleToIndex(theta, widget.emotionKeys.length));
      return;
    }
    _dragMode = _DragMode.none;
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    _updateGeom(size);
    final p = d.localPosition - Offset(size.width / 2, size.height / 2);

    switch (_dragMode) {
      case _DragMode.nuance:
        setState(() {
          _nuanceRotation =
              (_nuanceRotation + d.delta.dx * 0.008) % (2 * math.pi);
        });
      case _DragMode.emotion:
        final theta = _thetaFor(p);
        widget.onPreviewEmotion(
            _angleToIndex(theta, widget.emotionKeys.length));
      case _DragMode.none:
        break;
    }
  }

  void _onPanEnd(_) {
    if (_dragMode == _DragMode.emotion) widget.onPreviewEmotion(null);
    _dragMode = _DragMode.none;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      _updateGeom(size);

      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) {
          final pulse = (widget.intensity >= 7)
              ? (0.92 + 0.08 * _pulseAnim.value)
              : 1.0;

          return GestureDetector(
            onTapDown: (d) => _onTapDown(d, size),
            onPanStart: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Optional mandala background
                if (widget.backgroundMandala != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: size.shortestSide,
                          height: size.shortestSide,
                          child: Image(
                              image: widget.backgroundMandala!,
                              fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),

                // All canvas drawing in one painter
                CustomPaint(
                  size: size,
                  painter: _HybridFieldPainter(
                    nuanceRotation: _nuanceRotation,
                    emotionKeys: widget.emotionKeys,
                    selectedEmotionIndex: widget.selectedEmotionIndex,
                    intensity: widget.intensity,
                    nuances: widget.nuances,
                    selectedNuances: widget.selectedNuances,
                    showNuanceCorona: widget.showNuanceCorona,
                    showOuterNuanceRing: widget.showOuterNuanceRing,
                    glowAmber: widget.glowAmber,
                    glowBlue: widget.glowBlue,
                    pulse: pulse,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SINGLE HYBRID PAINTER — rings + faces + field + corona
// ═══════════════════════════════════════════════════════════════════════════════

class _HybridFieldPainter extends CustomPainter {
  final double nuanceRotation;
  final List<String> emotionKeys;
  final int? selectedEmotionIndex;
  final int intensity;
  final List<String> nuances;
  final Set<String> selectedNuances;
  final bool showNuanceCorona;
  final bool showOuterNuanceRing;
  final Color glowAmber;
  final Color glowBlue;
  final double pulse;

  _HybridFieldPainter({
    required this.nuanceRotation,
    required this.emotionKeys,
    required this.selectedEmotionIndex,
    required this.intensity,
    required this.nuances,
    required this.selectedNuances,
    required this.showNuanceCorona,
    required this.showOuterNuanceRing,
    required this.glowAmber,
    required this.glowBlue,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) * 0.48;
    final t = intensity.clamp(0, 10) / 10.0;
    final count = emotionKeys.length;
    if (count == 0) return;

    final centerRadius = R * 0.285;
    final emotionInner = R * 0.44;
    final emotionOuter = R * 0.70;

    // ── 1. Background gradient ──────────────────────────────────────────
    final bg = Paint()
      ..shader = ui.Gradient.radial(center, R * 1.35, const [
        Color(0xFF071428),
        Color(0xFF000000),
      ], const [0.0, 1.0]);
    canvas.drawRect(Offset.zero & size, bg);

    // ── 2. Emotion ring petals ──────────────────────────────────────────
    for (int i = 0; i < count; i++) {
      final a0 = (i / count) * 2 * math.pi;
      final a1 = ((i + 1) / count) * 2 * math.pi;
      final isSel = (selectedEmotionIndex == i);

      final path = Path()
        ..addArc(
            Rect.fromCircle(center: center, radius: emotionOuter), a0, a1 - a0)
        ..arcTo(
            Rect.fromCircle(center: center, radius: emotionInner),
            a1,
            -(a1 - a0),
            false)
        ..close();

      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: isSel ? 0.10 : 0.04));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 2.0 : 1.0
            ..color = Colors.white.withValues(alpha: isSel ? 0.18 : 0.08));

      if (isSel) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = glowAmber.withValues(alpha: 0.10 + 0.18 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
      }
    }

    // ── 3. Parametric faces in petals (fixed size) ──────────────────────
    final faceR = R * 0.072;
    final ringR = R * 0.57;
    for (int i = 0; i < count; i++) {
      final key = emotionKeys[i];
      final isSel = (selectedEmotionIndex == i);
      final a = (i + 0.5) / count * 2 * math.pi;
      final pos = center + Offset(math.cos(a), math.sin(a)) * ringR;

      // Dimmer for non-selected faces
      if (!isSel) {
        canvas.saveLayer(
          Rect.fromCircle(center: pos, radius: faceR * 1.3),
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }

      ParametricEmotionFaceV2.draw(
        canvas,
        pos,
        faceR,
        key,
        isSel ? t : 0.0,
      );

      if (!isSel) {
        canvas.restore();
      }
    }

    // ── 4. Optional outer nuance ring ───────────────────────────────────
    if (showOuterNuanceRing && nuances.isNotEmpty) {
      final nuanceInner = R * 0.72;
      final nuanceOuter = R * 0.92;
      final n = nuances.length;
      for (int i = 0; i < n; i++) {
        final a0 = (i / n) * 2 * math.pi + nuanceRotation;
        final a1 = ((i + 1) / n) * 2 * math.pi + nuanceRotation;
        final isSel = selectedNuances.contains(nuances[i]);

        final path = Path()
          ..addArc(Rect.fromCircle(center: center, radius: nuanceOuter), a0,
              a1 - a0)
          ..arcTo(Rect.fromCircle(center: center, radius: nuanceInner), a1,
              -(a1 - a0), false)
          ..close();

        canvas.drawPath(
            path,
            Paint()
              ..color = (isSel ? glowAmber : const Color(0xFF1E3A8A))
                  .withValues(alpha: isSel ? 0.25 : 0.10));
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = isSel ? 2.0 : 1.0
              ..color =
                  Colors.white.withValues(alpha: isSel ? 0.12 : 0.06));
      }
    }

    // ── 5. Center field (halo + density + rays) ─────────────────────────
    final haloR1 = centerRadius * (1.45 + 0.65 * t) * pulse;
    final haloR2 = centerRadius * (1.05 + 0.20 * t) * pulse;

    canvas.drawCircle(
      center,
      haloR1,
      Paint()
        ..color = glowBlue.withValues(alpha: 0.04 + 0.10 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );
    canvas.drawCircle(
      center,
      haloR2,
      Paint()
        ..color = glowAmber.withValues(alpha: 0.08 + 0.26 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    // Inner ring
    canvas.drawCircle(
      center,
      centerRadius * 1.03,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.10 + 0.10 * t),
    );

    // Radial rays at high intensity
    if (t >= 0.7) {
      const rays = 36;
      final rayP = Paint()
        ..strokeWidth = 1.2
        ..color = glowAmber.withValues(alpha: 0.05 + 0.10 * (t - 0.7) / 0.3);
      final r0 = centerRadius * 1.08;
      final r1 = centerRadius * (1.35 + 0.25 * (t - 0.7) / 0.3);
      for (int i = 0; i < rays; i++) {
        final a = i / rays * 2 * math.pi;
        final p0 = center + Offset(math.cos(a), math.sin(a)) * r0;
        final p1 = center + Offset(math.cos(a), math.sin(a)) * r1;
        canvas.drawLine(p0, p1, rayP);
      }
    }

    // ── 6. Nuance corona around center ──────────────────────────────────
    if (showNuanceCorona && nuances.isNotEmpty) {
      final n = nuances.length;
      final coronaInner = centerRadius * 1.22;
      final coronaOuter = centerRadius * 1.55;
      for (int i = 0; i < n; i++) {
        final a0 = (i / n) * 2 * math.pi + nuanceRotation;
        final a1 = ((i + 1) / n) * 2 * math.pi + nuanceRotation;
        final isSel = selectedNuances.contains(nuances[i]);

        final base = 0.05 + 0.16 * t;
        final bump = isSel ? (0.10 + 0.18 * t) : 0.0;

        final path = Path()
          ..addArc(Rect.fromCircle(center: center, radius: coronaOuter), a0,
              a1 - a0)
          ..arcTo(Rect.fromCircle(center: center, radius: coronaInner), a1,
              -(a1 - a0), false)
          ..close();

        canvas.drawPath(
            path,
            Paint()
              ..color = (isSel ? glowAmber : glowBlue)
                  .withValues(alpha: (base + bump).clamp(0.0, 0.55)));
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = isSel ? 1.6 : 1.0
              ..color = Colors.white
                  .withValues(alpha: isSel ? (0.10 + 0.10 * t) : 0.05));
      }
    }

    // ── 7. Center parametric face (large, fills center) ─────────────────
    final selIdx = selectedEmotionIndex;
    if (selIdx != null && selIdx >= 0 && selIdx < count) {
      final key = emotionKeys[selIdx];
      ParametricEmotionFaceV2.draw(
        canvas,
        center,
        centerRadius * 0.82,
        key,
        t,
      );
    }

    // ── 8. Intensity label ──────────────────────────────────────────────
    final tp = TextPainter(
      text: TextSpan(
        text: '$intensity/10',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: R * 0.065,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center + Offset(-tp.width / 2, centerRadius * 0.55));
  }

  @override
  bool shouldRepaint(covariant _HybridFieldPainter old) {
    return old.nuanceRotation != nuanceRotation ||
        old.selectedEmotionIndex != selectedEmotionIndex ||
        old.intensity != intensity ||
        old.nuances != nuances ||
        old.selectedNuances != selectedNuances ||
        old.showNuanceCorona != showNuanceCorona ||
        old.showOuterNuanceRing != showOuterNuanceRing ||
        old.pulse != pulse ||
        old.emotionKeys != emotionKeys;
  }
}

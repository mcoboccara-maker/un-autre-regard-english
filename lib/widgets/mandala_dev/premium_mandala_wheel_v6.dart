// premium_mandala_wheel_v6.dart
// V6 — Sacred Seal Mode: sceaux PNG dans les pétales + centre,
// intensité contrôle glow + scale, fond mandala sacré.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _DragMode { none, nuance, emotion }

class PremiumMandalaWheelV6 extends StatefulWidget {
  final List<String> emotionKeys; // 18
  final int? selectedEmotionIndex;
  final List<String> nuances;
  final Set<String> selectedNuances;
  final int intensity; // 0..10

  final ValueChanged<int> onEmotionTap;
  final ValueChanged<int?> onPreviewEmotion;
  final ValueChanged<String> onNuanceToggle;
  final ValueChanged<int> onIntensityChange;

  const PremiumMandalaWheelV6({
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
  });

  @override
  State<PremiumMandalaWheelV6> createState() => _PremiumMandalaWheelV6State();
}

class _PremiumMandalaWheelV6State extends State<PremiumMandalaWheelV6> {
  double _nuanceRotation = 0.0;
  _DragMode _dragMode = _DragMode.none;

  // Images chargées — clé = emotionKey
  final Map<String, ui.Image> _sealImages = {};

  late double _R, _centerRadius, _emotionInner, _emotionOuter, _nuanceInner, _nuanceOuter;

  /// Mapping emotionKey → nom de fichier
  static String _keyToFilename(String key) {
    // EN_COLERE → encolere, les autres → lowercase sans underscore
    return key.toLowerCase().replaceAll('_', '');
  }

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    for (final key in widget.emotionKeys) {
      final filename = _keyToFilename(key);
      final path = 'assets/emotions_seal/${filename}_512.png';
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _sealImages[key] = frame.image;
          });
        }
      } catch (e) {
        debugPrint('Seal image not found: $path ($e)');
      }
    }
  }

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

    if (r <= _centerRadius) {
      _cycleIntensity();
      return;
    }
    if (r >= _nuanceInner && r <= _nuanceOuter && widget.nuances.isNotEmpty) {
      final thetaAdj = (theta - _nuanceRotation) % (2 * math.pi);
      final idx = _angleToIndex(thetaAdj, widget.nuances.length);
      widget.onNuanceToggle(widget.nuances[idx]);
      return;
    }
    if (r >= _emotionInner && r <= _emotionOuter && widget.emotionKeys.isNotEmpty) {
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

    if (r >= _nuanceInner && r <= _nuanceOuter && widget.nuances.isNotEmpty) {
      _dragMode = _DragMode.nuance;
      return;
    }
    if (r >= _emotionInner && r <= _emotionOuter && widget.emotionKeys.isNotEmpty) {
      _dragMode = _DragMode.emotion;
      final theta = _thetaFor(p);
      widget.onPreviewEmotion(_angleToIndex(theta, widget.emotionKeys.length));
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
        widget.onPreviewEmotion(_angleToIndex(theta, widget.emotionKeys.length));
      case _DragMode.none:
        break;
    }
  }

  void _onPanEnd(_) {
    if (_dragMode == _DragMode.emotion) widget.onPreviewEmotion(null);
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
          painter: _PremiumMandalaPainterV6(
            nuanceRotation: _nuanceRotation,
            emotionKeys: widget.emotionKeys,
            selectedEmotionIndex: widget.selectedEmotionIndex,
            nuances: widget.nuances,
            selectedNuances: widget.selectedNuances,
            intensity: widget.intensity.clamp(0, 10),
            sealImages: _sealImages,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _sealImages.clear();
    super.dispose();
  }
}

class _PremiumMandalaPainterV6 extends CustomPainter {
  final double nuanceRotation;
  final List<String> emotionKeys;
  final int? selectedEmotionIndex;
  final List<String> nuances;
  final Set<String> selectedNuances;
  final int intensity;
  final Map<String, ui.Image> sealImages;

  _PremiumMandalaPainterV6({
    required this.nuanceRotation,
    required this.emotionKeys,
    required this.selectedEmotionIndex,
    required this.nuances,
    required this.selectedNuances,
    required this.intensity,
    required this.sealImages,
  });

  void _drawSealImage(Canvas canvas, ui.Image img, Offset center, double radius, double glowOpacity) {
    // Dessiner le sceau dans un cercle
    final dst = Rect.fromCircle(center: center, radius: radius);
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

    // Glow sacré (halo)
    if (glowOpacity > 0.05) {
      final halo = Paint()
        ..color = const Color(0xFF2DD4BF).withValues(alpha: glowOpacity * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15);
      canvas.drawCircle(center, radius * 1.08, halo);

      // Inner ring glow
      final innerGlow = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: glowOpacity * 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.06);
      canvas.drawCircle(center, radius * 1.02, innerGlow);
    }

    // Clip circulaire pour le sceau
    canvas.save();
    canvas.clipPath(Path()..addOval(dst));
    canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) * 0.48;

    const bgA = Color(0xFF071428);
    const bgB = Color(0xFF000000);
    const blue = Color(0xFF4FC3F7);
    const indigo = Color(0xFF1E40AF);
    const amber = Color(0xFFF59E0B);

    // Fond radial
    final bg = Paint()
      ..shader = ui.Gradient.radial(center, R * 1.25, [bgA, bgB], [0.0, 1.0]);
    canvas.drawRect(Offset.zero & size, bg);

    // Halo externe
    final halo = Paint()
      ..color = blue.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, R * 0.98, halo);

    // Décor mandala (rayons + cercles)
    final rayPaint = Paint()..color = amber.withValues(alpha: 0.10)..strokeWidth = 1.2;
    const rays = 72;
    for (int i = 0; i < rays; i++) {
      final a = i / rays * 2 * math.pi;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (R * 0.30);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (R * 0.62);
      canvas.drawLine(p1, p2, rayPaint);
    }
    final circlePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(center, R * 0.30, circlePaint);
    canvas.drawCircle(center, R * 0.62, circlePaint);

    // Carré sacré + portes
    final squareSize = R * 0.78;
    final half = squareSize / 2;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: squareSize, height: squareSize),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = amber.withValues(alpha: 0.22),
    );
    final gateWidth = squareSize * 0.18;
    final gateDepth = squareSize * 0.08;
    final gatePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = amber.withValues(alpha: 0.28);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(0, -half), width: gateWidth, height: gateDepth), gatePaint);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(0, half), width: gateWidth, height: gateDepth), gatePaint);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(half, 0), width: gateDepth, height: gateWidth), gatePaint);
    canvas.drawRect(Rect.fromCenter(center: center + Offset(-half, 0), width: gateDepth, height: gateWidth), gatePaint);

    // --- Anneau émotions avec sceaux ---
    final emotionInner = R * 0.44;
    final emotionOuter = R * 0.70;

    for (int i = 0; i < emotionKeys.length; i++) {
      final a0 = (i / emotionKeys.length) * 2 * math.pi;
      final a1 = ((i + 1) / emotionKeys.length) * 2 * math.pi;
      final isSel = (selectedEmotionIndex == i);

      // Pétale
      final path = Path()
        ..addArc(Rect.fromCircle(center: center, radius: emotionOuter), a0, a1 - a0)
        ..arcTo(Rect.fromCircle(center: center, radius: emotionInner), a1, -(a1 - a0), false)
        ..close();

      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: isSel ? 0.10 : 0.04));

      if (isSel) {
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = amber.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }

      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? 1.8 : 1.0
        ..color = Colors.white.withValues(alpha: isSel ? 0.18 : 0.08));

      // Sceau dans le pétale
      final midAngle = (a0 + a1) / 2;
      final iconR = R * 0.065;
      final iconCenter = center + Offset(math.cos(midAngle), math.sin(midAngle)) * (R * 0.57);
      final key = emotionKeys[i];
      final img = sealImages[key];

      if (img != null) {
        final scale = isSel ? (1.0 + 0.08 * (intensity / 10.0)) : 1.0;
        final glowT = isSel ? (intensity / 10.0) : 0.0;
        _drawSealImage(canvas, img, iconCenter, iconR * scale, glowT);
      } else {
        // Fallback : petit cercle teal
        canvas.drawCircle(iconCenter, iconR * 0.5, Paint()
          ..color = const Color(0xFF2DD4BF).withValues(alpha: isSel ? 0.5 : 0.2));
      }
    }

    // --- Anneau nuances rotatif ---
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
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 2.0 : 1.0
          ..color = Colors.white.withValues(alpha: isSel ? 0.16 : 0.07));
      }
    }

    // --- Centre : sceau fort + énergie ---
    final t = intensity / 10.0;
    final centerRadius = R * (0.26 + 0.07 * t);

    // Énergie
    canvas.drawCircle(center, centerRadius * 1.55,
      Paint()..color = blue.withValues(alpha: 0.05 + 0.08 * t)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70));
    canvas.drawCircle(center, centerRadius,
      Paint()..color = amber.withValues(alpha: 0.10 + 0.22 * t)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    canvas.drawCircle(center, centerRadius * 1.02,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = Colors.white.withValues(alpha: 0.12));

    // Sceau au centre
    final selIdx = selectedEmotionIndex;
    if (selIdx != null && selIdx >= 0 && selIdx < emotionKeys.length) {
      final key = emotionKeys[selIdx];
      final img = sealImages[key];
      if (img != null) {
        final scale = 1.0 + 0.08 * t;
        _drawSealImage(canvas, img, center, centerRadius * 0.85 * scale, t);
      }
    }

    // Texte intensité
    final tp = TextPainter(
      text: TextSpan(
        text: '$intensity/10',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: R * 0.070,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center + Offset(-tp.width / 2, centerRadius * 0.65));
  }

  @override
  bool shouldRepaint(covariant _PremiumMandalaPainterV6 old) {
    return old.nuanceRotation != nuanceRotation ||
        old.selectedEmotionIndex != selectedEmotionIndex ||
        old.intensity != intensity ||
        old.nuances != nuances ||
        old.selectedNuances != selectedNuances ||
        old.emotionKeys != emotionKeys ||
        old.sealImages != sealImages;
  }
}

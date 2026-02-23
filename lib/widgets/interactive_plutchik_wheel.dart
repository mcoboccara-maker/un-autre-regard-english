// lib/widgets/interactive_plutchik_wheel.dart
// Roue de Plutchik style MANDALA ORGANIQUE — pétales lotus arrondis, ornements,
// palette chaude psychédélique, icônes PNG, intensité au centre
// Positives à droite (vert appui), Négatives à gauche (orange tension)

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/emotion_config.dart';

/// Couleurs thématiques des deux pôles
const Color _kAppuiColor = Color(0xFF10B981);   // Vert — émotions positives
const Color _kTensionColor = Color(0xFFF97316);  // Orange — émotions négatives

/// Palette chaude du mandala
const Color _kGoldWarm = Color(0xFFD4A574);
const Color _kGoldLight = Color(0xFFFFF0DB);
const Color _kAmberGlow = Color(0xFFE8B84B);
const Color _kTealSoft = Color(0xFF7FC4B8);

class InteractivePlutchikWheel extends StatefulWidget {
  final int? selectedIndex;
  final Set<int> confirmedIndices;
  final Set<String> selectedNuances;
  final int intensity;
  final ValueChanged<int> onEmotionTapped;
  final ValueChanged<String> onNuanceTapped;
  final ValueChanged<int>? onIntensityChanged;

  const InteractivePlutchikWheel({
    super.key,
    this.selectedIndex,
    this.confirmedIndices = const {},
    this.selectedNuances = const {},
    this.intensity = 5,
    required this.onEmotionTapped,
    required this.onNuanceTapped,
    this.onIntensityChanged,
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
    ...EmotionCategories.positiveEmotions,
    ...EmotionCategories.negativeEmotions,
  ];

  final Map<String, ui.Image> _loadedImages = {};
  bool _imagesLoaded = false;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    final paths = <String>{};
    for (final e in _allEmotions) {
      paths.add(e.iconPath);
    }
    paths.add('assets/univers_visuel/appui.png');
    paths.add('assets/univers_visuel/tension.png');

    for (final path in paths) {
      try {
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
        final frame = await codec.getNextFrame();
        _loadedImages[path] = frame.image;
      } catch (e) {
        debugPrint('Could not load image: $path — $e');
      }
    }
    if (mounted) setState(() => _imagesLoaded = true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int? get _internalSelectedIndex {
    if (widget.selectedIndex == null) return null;
    final idx = widget.selectedIndex!;
    final negCount = EmotionCategories.negativeEmotions.length;
    if (idx < negCount) return idx + 9;
    return idx - negCount;
  }

  int _toExternalIndex(int internalIndex) {
    final posCount = EmotionCategories.positiveEmotions.length;
    if (internalIndex < posCount) {
      return internalIndex + EmotionCategories.negativeEmotions.length;
    }
    return internalIndex - posCount;
  }

  Set<int> get _internalConfirmedIndices {
    final negCount = EmotionCategories.negativeEmotions.length;
    return widget.confirmedIndices.map((idx) {
      if (idx < negCount) return idx + 9;
      return idx - negCount;
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: (event) => _updateHoveredIndex(event.localPosition, size),
          onExit: (_) {
            if (_hoveredIndex != null) setState(() => _hoveredIndex = null);
          },
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details, size),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(size, size),
                          painter: _MandalaWheelPainter(
                            emotions: _allEmotions,
                            selectedIndex: _internalSelectedIndex,
                            confirmedIndices: _internalConfirmedIndices,
                            selectedNuances: widget.selectedNuances,
                            intensity: widget.intensity,
                            pulseValue: _pulseAnimation.value,
                            images: _loadedImages,
                            imagesLoaded: _imagesLoaded,
                          ),
                        );
                      },
                    ),
                  ),
                  if (_hoveredIndex != null) _buildHoverTooltip(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoverTooltip() {
    final emotion = _allEmotions[_hoveredIndex!];
    final isPos = _hoveredIndex! < EmotionCategories.positiveEmotions.length;
    return Positioned(
      top: 2, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isPos ? const Color(0xEE2A7B6F) : const Color(0xEECF7B3A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(emotion.name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        ),
      ),
    );
  }

  int? _petalIndexAtPosition(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outerRadius = size / 2 - 8;
    final emotionInnerR = outerRadius * 0.30;
    final emotionOuterR = outerRadius * 0.58;
    if (distance < emotionInnerR * 0.7 || distance > emotionOuterR * 1.1) return null;
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;
    final n = _allEmotions.length;
    final segmentAngle = 2 * math.pi / n;
    return (angle / segmentAngle).floor().clamp(0, n - 1);
  }

  void _updateHoveredIndex(Offset position, double size) {
    final idx = _petalIndexAtPosition(position, size);
    if (idx != _hoveredIndex) setState(() => _hoveredIndex = idx);
  }

  void _handleTap(TapUpDetails details, double size) {
    final center = Offset(size / 2, size / 2);
    final tap = details.localPosition;
    final dx = tap.dx - center.dx;
    final dy = tap.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outerRadius = size / 2 - 8;
    final emotionInnerR = outerRadius * 0.30;
    final emotionOuterR = outerRadius * 0.58;
    final nuanceInnerR = emotionOuterR + 4;
    final nuanceOuterR = outerRadius;
    final centerR = emotionInnerR - 3;
    final n = _allEmotions.length;
    final segmentAngle = 2 * math.pi / n;
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    // Centre -> intensité
    if (distance <= centerR && _internalSelectedIndex != null) {
      widget.onIntensityChanged?.call((widget.intensity + 1) % 11);
      return;
    }

    // Anneau nuances
    if (distance >= nuanceInnerR && distance <= nuanceOuterR && _internalSelectedIndex != null) {
      final emotion = _allEmotions[_internalSelectedIndex!];
      final allNuances = emotion.nuances;
      if (allNuances.isEmpty) return;
      const maxVisible = 15;
      final nuances = allNuances.length > maxVisible ? allNuances.sublist(0, maxVisible) : allNuances;
      final emotionStartAngle = _internalSelectedIndex! * segmentAngle;
      final nuanceTotalArc = math.min(segmentAngle * 7, 2 * math.pi * 0.75);
      final nuanceStartAngle = emotionStartAngle + segmentAngle / 2 - nuanceTotalArc / 2;
      final nuanceSegment = nuanceTotalArc / nuances.length;
      var relAngle = angle - nuanceStartAngle;
      if (relAngle < 0) relAngle += 2 * math.pi;
      if (relAngle > nuanceTotalArc) return;
      final nuanceIndex = (relAngle / nuanceSegment).floor().clamp(0, nuances.length - 1);
      widget.onNuanceTapped(nuances[nuanceIndex]);
      return;
    }

    // Pétales
    if (distance >= emotionInnerR * 0.85 && distance <= emotionOuterR * 1.05) {
      for (int i = 0; i < n; i++) {
        final midAngle = -math.pi / 2 + i * segmentAngle + segmentAngle / 2;
        final halfAngle = (segmentAngle - segmentAngle * 0.08) / 2;
        final path = _MandalaWheelPainter.flowerPetalPath(center, emotionInnerR, emotionOuterR, midAngle, halfAngle);
        if (path.contains(tap)) {
          widget.onEmotionTapped(_toExternalIndex(i));
          return;
        }
      }
    }
  }
}

// =============================================================================
// MANDALA WHEEL PAINTER — STYLE ORGANIQUE PSYCHÉDÉLIQUE
// =============================================================================

class _MandalaWheelPainter extends CustomPainter {
  final List<EmotionConfig> emotions;
  final int? selectedIndex;
  final Set<int> confirmedIndices;
  final Set<String> selectedNuances;
  final int intensity;
  final double pulseValue;
  final Map<String, ui.Image> images;
  final bool imagesLoaded;

  _MandalaWheelPainter({
    required this.emotions, this.selectedIndex,
    this.confirmedIndices = const {}, this.selectedNuances = const {},
    this.intensity = 5, required this.pulseValue,
    required this.images, required this.imagesLoaded,
  });

  // ── Helpers géométriques ──────────────────────────────────────────

  static Offset _polar(Offset center, double r, double angle) {
    return Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
  }

  static Color _warmBlend(Color c, double t) {
    return Color.lerp(c, _kGoldWarm, t)!;
  }

  // ── Pétale BODHI (large arrondi + pointe effilée au sommet) ─────

  static Path flowerPetalPath(Offset center, double innerR, double outerR, double midAngle, double halfAngle) {
    final path = Path();
    final innerLeft = _polar(center, innerR, midAngle - halfAngle);
    final innerRight = _polar(center, innerR, midAngle + halfAngle);

    // Pointe effilée au sommet (drip tip de la feuille de Bodhi)
    final tipApex = _polar(center, outerR, midAngle);

    // Renflement large : le point le plus large est à ~50% de la hauteur du pétale
    // et dépasse largement l'angle du segment pour la forme cœur
    final bulgeSpread = halfAngle * 1.35;  // plus large que le segment
    final bulgeR = innerR + (outerR - innerR) * 0.50;

    // Ctrl1 : sortie de la base, léger évasement
    final ctrl1L = _polar(center, innerR + (outerR - innerR) * 0.25, midAngle - halfAngle * 0.95);
    final ctrl1R = _polar(center, innerR + (outerR - innerR) * 0.25, midAngle + halfAngle * 0.95);

    // Point de renflement max (le « ventre » de la feuille)
    final bulgeL = _polar(center, bulgeR, midAngle - bulgeSpread);
    final bulgeR2 = _polar(center, bulgeR, midAngle + bulgeSpread);

    // Ctrl2 : depuis le ventre, convergence vers la pointe
    final ctrl2L = _polar(center, outerR * 0.82, midAngle - halfAngle * 0.45);
    final ctrl2R = _polar(center, outerR * 0.82, midAngle + halfAngle * 0.45);

    // Côté gauche : base → renflement
    path.moveTo(innerLeft.dx, innerLeft.dy);
    path.cubicTo(
      ctrl1L.dx, ctrl1L.dy,
      bulgeL.dx, bulgeL.dy,
      _polar(center, bulgeR + (outerR - bulgeR) * 0.35, midAngle - bulgeSpread * 0.55).dx,
      _polar(center, bulgeR + (outerR - bulgeR) * 0.35, midAngle - bulgeSpread * 0.55).dy,
    );
    // Renflement → pointe effilée
    path.cubicTo(
      ctrl2L.dx, ctrl2L.dy,
      _polar(center, outerR * 0.96, midAngle - halfAngle * 0.08).dx,
      _polar(center, outerR * 0.96, midAngle - halfAngle * 0.08).dy,
      tipApex.dx, tipApex.dy,
    );

    // Côté droit (symétrique) : pointe → renflement → base
    path.cubicTo(
      _polar(center, outerR * 0.96, midAngle + halfAngle * 0.08).dx,
      _polar(center, outerR * 0.96, midAngle + halfAngle * 0.08).dy,
      ctrl2R.dx, ctrl2R.dy,
      _polar(center, bulgeR + (outerR - bulgeR) * 0.35, midAngle + bulgeSpread * 0.55).dx,
      _polar(center, bulgeR + (outerR - bulgeR) * 0.35, midAngle + bulgeSpread * 0.55).dy,
    );
    // Renflement → base droite
    path.cubicTo(
      bulgeR2.dx, bulgeR2.dy,
      ctrl1R.dx, ctrl1R.dy,
      innerRight.dx, innerRight.dy,
    );

    path.arcTo(Rect.fromCircle(center: center, radius: innerR), midAngle + halfAngle, -halfAngle * 2, false);
    path.close();

    return path;
  }

  Path _arcSegmentPath(Offset center, double innerR, double outerR, double startAngle, double sweepAngle) {
    final path = Path();
    path.arcTo(Rect.fromCircle(center: center, radius: outerR), startAngle, sweepAngle, true);
    path.arcTo(Rect.fromCircle(center: center, radius: innerR), startAngle + sweepAngle, -sweepAngle, false);
    path.close();
    return path;
  }

  // ── PAINT PRINCIPAL ───────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 8;
    final n = emotions.length;
    final segmentAngle = 2 * math.pi / n;
    final gapAngle = segmentAngle * 0.08;
    final emotionInnerR = outerRadius * 0.30;
    final emotionOuterR = outerRadius * 0.58;
    final nuanceInnerR = emotionOuterR + 4;
    final nuanceOuterR = outerRadius;

    // 1. Aura de fond
    _drawBackgroundAura(canvas, center, outerRadius);

    // 2. Halo d'intensité diffus
    _drawIntensityHalo(canvas, center, emotionOuterR, outerRadius);

    // 3. Marqueurs Appui / Tension
    _drawZoneMarkers(canvas, center, emotionInnerR, outerRadius, segmentAngle);

    // 4. Pétales lotus + décorations
    _drawPetals(canvas, center, n, segmentAngle, gapAngle, emotionInnerR, emotionOuterR);

    // 5. Anneau décoratif de dots (entre pétales et nuances)
    _drawOrnamentalDotRing(canvas, center, emotionOuterR + 2.5, n * 2, 1.2,
      _kGoldWarm.withValues(alpha: 0.30));

    // 6. Nuances (si émotion sélectionnée)
    _drawNuances(canvas, center, n, segmentAngle, nuanceInnerR, nuanceOuterR);

    // 7. Anneau ornamental intérieur (autour du centre)
    _drawOrnamentalDotRing(canvas, center, emotionInnerR - 6, n, 1.5,
      _kGoldWarm.withValues(alpha: 0.35));

    // Fin anneau doré subtil autour des pétales
    canvas.drawCircle(center, emotionOuterR + 1, Paint()
      ..color = _kGoldWarm.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);

    // 8. Centre orné
    _drawMandalaCenter(canvas, center, emotionInnerR - 3);
  }

  // ── AURA DE FOND ──────────────────────────────────────────────────

  void _drawBackgroundAura(Canvas canvas, Offset center, double outerRadius) {
    final auraGrad = ui.Gradient.radial(
      center, outerRadius * 1.15,
      [
        _kAmberGlow.withValues(alpha: 0.06),
        _kGoldWarm.withValues(alpha: 0.03),
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(center, outerRadius * 1.15, Paint()..shader = auraGrad);

    canvas.drawCircle(center + const Offset(0, 3), outerRadius + 4, Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  }

  // ── HALO D'INTENSITÉ (DIFFUS) ────────────────────────────────────

  void _drawIntensityHalo(Canvas canvas, Offset center, double emotionOuterR, double outerRadius) {
    if (selectedIndex == null) return;
    final emotion = emotions[selectedIndex!];
    final intensityFrac = intensity / 10.0;
    if (intensityFrac <= 0) return;

    final haloRadius = outerRadius + 5 + intensityFrac * 12;
    final haloColor = _warmBlend(emotion.color, 0.35);

    canvas.drawCircle(center, haloRadius, Paint()
      ..color = haloColor.withValues(alpha: 0.04 + intensityFrac * 0.08 + pulseValue * 0.03)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + intensityFrac * 12));

    canvas.drawCircle(center, outerRadius + 2, Paint()
      ..color = haloColor.withValues(alpha: 0.06 + intensityFrac * 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + intensityFrac * 6));
  }

  // ── PÉTALES LOTUS (LARGES, CHEVAUCHEMENT MANDALA) ─────────────────

  void _drawPetals(Canvas canvas, Offset center, int n, double segmentAngle, double gapAngle, double emotionInnerR, double emotionOuterR) {
    // Pétales 1.6× plus larges que le segment → chevauchement ~30%
    final visualHalfAngle = segmentAngle * 0.80;

    // Ordre de peinture : pairs en fond, impairs par-dessus, sélectionné tout devant
    final paintOrder = <int>[];
    for (int i = 0; i < n; i += 2) {
      paintOrder.add(i);
    }
    for (int i = 1; i < n; i += 2) {
      paintOrder.add(i);
    }
    if (selectedIndex != null) {
      paintOrder.remove(selectedIndex!);
      paintOrder.add(selectedIndex!);
    }

    for (final i in paintOrder) {
      _drawSinglePetal(canvas, center, i, n, segmentAngle, visualHalfAngle, emotionInnerR, emotionOuterR);
    }
  }

  void _drawSinglePetal(Canvas canvas, Offset center, int i, int n, double segmentAngle, double halfAngle, double emotionInnerR, double emotionOuterR) {
    final emotion = emotions[i];
    final midAngle = -math.pi / 2 + i * segmentAngle + segmentAngle / 2;
    final isSelected = i == selectedIndex;
    final isConfirmed = confirmedIndices.contains(i);
    final isHighlighted = isSelected || isConfirmed;

    // Couleurs pétale (réchauffées)
    final hsl = HSLColor.fromColor(emotion.color);
    final Color innerColor;
    final Color outerColor;
    if (isHighlighted) {
      innerColor = _warmBlend(emotion.color, 0.08);
      outerColor = _warmBlend(
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 0.88)).toColor(), 0.12);
    } else {
      innerColor = _warmBlend(
        hsl.withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
            .withLightness((hsl.lightness + 0.10).clamp(0.0, 0.85)).toColor(), 0.18);
      outerColor = _warmBlend(
        hsl.withSaturation((hsl.saturation * 0.35).clamp(0.0, 1.0))
            .withLightness((hsl.lightness + 0.28).clamp(0.0, 0.92)).toColor(), 0.22);
    }

    // Semi-transparence pour l'overlap mandala
    final fillAlpha = isSelected ? 0.95 : isConfirmed ? 0.90 : 0.80;
    final innerColorA = innerColor.withValues(alpha: fillAlpha);
    final outerColorA = outerColor.withValues(alpha: fillAlpha * 0.80);

    // Pétale lotus LARGE (chevauchement)
    final path = flowerPetalPath(center, emotionInnerR, emotionOuterR, midAngle, halfAngle);
    final gradient = ui.Gradient.radial(center, emotionOuterR,
      [innerColorA, outerColorA], [emotionInnerR / emotionOuterR, 1.0]);
    canvas.drawPath(path, Paint()..shader = gradient);

    // Contour doré doux
    final strokeColor = isSelected
        ? _kAmberGlow.withValues(alpha: 0.9)
        : isConfirmed
            ? _kGoldWarm.withValues(alpha: 0.7)
            : _kGoldWarm.withValues(alpha: 0.20);
    canvas.drawPath(path, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : isConfirmed ? 1.5 : 0.5);

    // Glow sélection (halo chaud pulsé)
    if (isSelected) {
      canvas.drawPath(path, Paint()
        ..color = _warmBlend(emotion.color, 0.25).withValues(alpha: 0.12 + 0.10 * pulseValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 5 * pulseValue));
    }

    // Motif interne lotus (proportionnel au pétale large)
    final innerMotifInnerR = emotionInnerR + (emotionOuterR - emotionInnerR) * 0.10;
    final innerMotifOuterR = emotionInnerR + (emotionOuterR - emotionInnerR) * 0.58;
    final innerMotifHalf = halfAngle * 0.55;
    final innerPath = flowerPetalPath(center, innerMotifInnerR, innerMotifOuterR, midAngle, innerMotifHalf);
    canvas.drawPath(innerPath, Paint()..color = Colors.white.withValues(alpha: 0.07));
    canvas.drawPath(innerPath, Paint()
      ..color = _kGoldWarm.withValues(alpha: isHighlighted ? 0.22 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);

    // Icône PNG (centrée sur midAngle)
    final iconRadius = emotionInnerR + (emotionOuterR - emotionInnerR) * 0.32;
    final iconPos = _polar(center, iconRadius, midAngle);
    final iconSize = isSelected ? 24.0 : 20.0;
    if (imagesLoaded && images.containsKey(emotion.iconPath)) {
      _drawImage(canvas, images[emotion.iconPath]!, iconPos, iconSize);
    } else {
      _drawMaterialIcon(canvas, emotion.icon, iconPos, iconSize,
        Colors.white.withValues(alpha: isSelected ? 1.0 : 0.85));
    }

    // Point décoratif au sommet du pétale
    final tipDotPos = _polar(center, emotionOuterR + 1.5, midAngle);
    canvas.drawCircle(tipDotPos, isSelected ? 3.5 : 2.5, Paint()
      ..color = isSelected
          ? _kAmberGlow.withValues(alpha: 0.85)
          : _kGoldWarm.withValues(alpha: 0.40));
    if (isSelected) {
      canvas.drawCircle(tipDotPos, 3.5, Paint()
        ..color = _kAmberGlow.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // Point confirmé (doré lumineux)
    if (isConfirmed && !isSelected) {
      final dotPos = _polar(center, emotionOuterR * 0.82, midAngle);
      canvas.drawCircle(dotPos, 4.5, Paint()..color = _kAmberGlow.withValues(alpha: 0.9));
      canvas.drawCircle(dotPos, 4.5, Paint()
        ..color = _kGoldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
      canvas.drawCircle(dotPos, 6.0, Paint()
        ..color = _kAmberGlow.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  // ── NUANCES ───────────────────────────────────────────────────────

  void _drawNuances(Canvas canvas, Offset center, int n, double segmentAngle, double nuanceInnerR, double nuanceOuterR) {
    if (selectedIndex == null) return;
    final emotion = emotions[selectedIndex!];
    final allNuances = emotion.nuances;
    if (allNuances.isEmpty) return;

    const maxVisible = 15;
    final nuances = allNuances.length > maxVisible ? allNuances.sublist(0, maxVisible) : allNuances;
    final emotionCenterAngle = -math.pi / 2 + selectedIndex! * segmentAngle + segmentAngle / 2;
    final nuanceTotalArc = math.min(segmentAngle * 7, 2 * math.pi * 0.75);
    final nuanceStartAngle = emotionCenterAngle - nuanceTotalArc / 2;
    final nuanceSegment = nuanceTotalArc / nuances.length;
    final nuanceGap = nuanceSegment * 0.03;

    for (int j = 0; j < nuances.length; j++) {
      final nStart = nuanceStartAngle + j * nuanceSegment + nuanceGap / 2;
      final nSweep = nuanceSegment - nuanceGap;
      final isNSel = selectedNuances.contains(nuances[j]);
      final hsl = HSLColor.fromColor(emotion.color);
      final baseC = isNSel
          ? _warmBlend(emotion.color, 0.10)
          : _warmBlend(
              hsl.withLightness((hsl.lightness + 0.22 + (j % 2 == 0 ? 0.04 : 0.0)).clamp(0.0, 0.90)).toColor(), 0.15);
      final edgeC = isNSel
          ? _warmBlend(hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 0.88)).toColor(), 0.08)
          : _warmBlend(hsl.withLightness((hsl.lightness + 0.32).clamp(0.0, 0.93)).toColor(), 0.20);

      final path = _arcSegmentPath(center, nuanceInnerR, nuanceOuterR, nStart, nSweep);
      final grad = ui.Gradient.radial(center, nuanceOuterR, [baseC, edgeC], [nuanceInnerR / nuanceOuterR, 1.0]);
      canvas.drawPath(path, Paint()..shader = grad);
      canvas.drawPath(path, Paint()
        ..color = isNSel ? _kAmberGlow.withValues(alpha: 0.85) : _kGoldWarm.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isNSel ? 1.8 : 0.5);

      final nuanceRingWidth = nuanceOuterR - nuanceInnerR;
      final tAngle = nStart + nSweep / 2;
      final tR = (nuanceInnerR + nuanceOuterR) / 2;
      _drawRadialText(canvas, center, tAngle, tR, nuances[j],
        isNSel ? 9.0 : 8.0,
        isNSel ? FontWeight.bold : FontWeight.w600,
        color: isNSel ? Colors.white : const Color(0xFF2D1B00),
        withShadow: true,
        maxTextWidth: nuanceRingWidth * 0.85);
    }
  }

  // ── ANNEAU DÉCORATIF DE DOTS ─────────────────────────────────────

  void _drawOrnamentalDotRing(Canvas canvas, Offset center, double radius, int count, double dotRadius, Color color) {
    final angleStep = 2 * math.pi / count;
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final pos = _polar(center, radius, angle);
      canvas.drawCircle(pos, dotRadius, Paint()..color = color);
    }
  }

  // ── MARQUEURS APPUI / TENSION ────────────────────────────────────

  void _drawZoneMarkers(Canvas canvas, Offset center, double innerR, double outerR, double segmentAngle) {
    final canvasSize = center.dx * 2;
    const markerSize = 22.0;
    const tensionIconPos = Offset(30, 22);
    const tensionLabelPos = Offset(30, 42);
    final appuiIconPos = Offset(canvasSize - 30, 22);
    final appuiLabelPos = Offset(canvasSize - 30, 42);
    if (imagesLoaded) {
      final appuiImg = images['assets/univers_visuel/appui.png'];
      final tensionImg = images['assets/univers_visuel/tension.png'];
      if (appuiImg != null) { _drawImage(canvas, appuiImg, appuiIconPos, markerSize); _drawLabel(canvas, appuiLabelPos, 'Appui', _kAppuiColor, 9.0); }
      if (tensionImg != null) { _drawImage(canvas, tensionImg, tensionIconPos, markerSize); _drawLabel(canvas, tensionLabelPos, 'Tension', _kTensionColor, 9.0); }
    }
  }

  // ── CENTRE ORNÉ DU MANDALA ───────────────────────────────────────

  void _drawMandalaCenter(Canvas canvas, Offset center, double radius) {
    if (selectedIndex != null) {
      final emotion = emotions[selectedIndex!];
      final hsl = HSLColor.fromColor(emotion.color);
      final intensityFrac = intensity / 10.0;

      // Anneaux concentriques décoratifs
      for (int ring = 0; ring < 3; ring++) {
        final r = radius + 2 + ring * 3.5;
        final alpha = (0.18 - ring * 0.05).clamp(0.03, 0.25);
        canvas.drawCircle(center, r, Paint()
          ..color = _warmBlend(emotion.color, 0.4).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);
      }

      // Image de fond clippée
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
      canvas.drawCircle(center, radius, Paint()..color = _kGoldLight);
      final bgIconSize = radius * 1.8;
      if (imagesLoaded && images.containsKey(emotion.iconPath)) {
        final img = images[emotion.iconPath]!;
        final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        final dstRect = Rect.fromCenter(center: center, width: bgIconSize, height: bgIconSize);
        canvas.drawImageRect(img, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
      }
      canvas.restore();

      // Ring d'intensité (doré, pulsé)
      final ringWidth = 2.5 + intensityFrac * 5.0;
      final ringColor = _warmBlend(
        hsl.withSaturation((0.3 + intensityFrac * 0.7).clamp(0.0, 1.0))
            .withLightness((hsl.lightness + 0.1 * (1 - intensityFrac)).clamp(0.0, 0.85)).toColor(), 0.3);
      canvas.drawCircle(center, radius - 1, Paint()
        ..color = ringColor.withValues(alpha: 0.5 + 0.3 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth);

      // Dots décoratifs autour du centre
      const dotCount = 12;
      final dotR = radius - 4;
      for (int d = 0; d < dotCount; d++) {
        final a = -math.pi / 2 + d * 2 * math.pi / dotCount;
        final p = _polar(center, dotR, a);
        canvas.drawCircle(p, 1.0, Paint()..color = _kAmberGlow.withValues(alpha: 0.3 + 0.15 * pulseValue));
      }

      // Intensité chiffrée
      final intensityPainter = TextPainter(
        text: TextSpan(
          text: '$intensity/10',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
            color: const Color(0xFF2D1B00),
            shadows: [
              Shadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 3),
              Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 1),
            ])),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      intensityPainter.layout();
      intensityPainter.paint(canvas, Offset(center.dx - intensityPainter.width / 2, center.dy - intensityPainter.height / 2));
    } else {
      // Centre vide : motif mandala chaud
      for (int ring = 0; ring < 3; ring++) {
        final r = radius + 2 + ring * 3.5;
        canvas.drawCircle(center, r, Paint()
          ..color = _kTealSoft.withValues(alpha: (0.15 - ring * 0.04).clamp(0.03, 0.20))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);
      }

      final bgGradient = ui.Gradient.radial(center, radius,
        [const Color(0xFF2A7B6F), const Color(0xFF1A5C52), const Color(0xFF15473F)], [0.0, 0.6, 1.0]);
      canvas.drawCircle(center, radius, Paint()..shader = bgGradient);

      canvas.drawCircle(center, radius - 1, Paint()
        ..color = _kGoldWarm.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);

      // Dots intérieurs décoratifs
      const dotCount = 8;
      final dotR = radius * 0.65;
      for (int d = 0; d < dotCount; d++) {
        final a = -math.pi / 2 + d * 2 * math.pi / dotCount + pulseValue * 0.05;
        final p = _polar(center, dotR, a);
        canvas.drawCircle(p, 2.0, Paint()..color = _kGoldWarm.withValues(alpha: 0.25 + 0.10 * pulseValue));
      }

      canvas.drawCircle(center, radius * 0.20, Paint()
        ..color = _kGoldWarm.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);

      final textPainter = TextPainter(
        text: TextSpan(text: 'Que\nressens-tu ?',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: _kGoldLight.withValues(alpha: 0.85), height: 1.3)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      textPainter.layout(maxWidth: radius * 1.6);
      textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
    }
  }

  // ── UTILITAIRES DE DESSIN ─────────────────────────────────────────

  void _drawImage(Canvas canvas, ui.Image image, Offset pos, double size) {
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromCenter(center: pos, width: size, height: size);
    canvas.drawImageRect(image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
  }

  void _drawMaterialIcon(Canvas canvas, IconData icon, Offset pos, double size, Color color) {
    final iconPainter = TextPainter(text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 2)])), textDirection: TextDirection.ltr);
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(pos.dx - iconPainter.width / 2, pos.dy - iconPainter.height / 2));
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color, double fontSize) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: color)), textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawRadialText(Canvas canvas, Offset center, double angle, double radius, String text, double fontSize, FontWeight weight, {Color color = Colors.white, bool withShadow = false, List<Shadow>? customShadows, double maxTextWidth = 75}) {
    final pos = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    double normAngle = angle % (2 * math.pi);
    if (normAngle < 0) normAngle += 2 * math.pi;
    double rotation = (normAngle > math.pi / 2 && normAngle < 3 * math.pi / 2) ? angle + math.pi : angle;
    canvas.rotate(rotation);
    final shadows = customShadows ?? (withShadow ? [Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 3), Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1)] : <Shadow>[]);
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color, shadows: shadows)), textDirection: TextDirection.ltr, textAlign: TextAlign.center, maxLines: 1, ellipsis: '..');
    tp.layout(maxWidth: maxTextWidth);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MandalaWheelPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.confirmedIndices != confirmedIndices || oldDelegate.pulseValue != pulseValue || oldDelegate.selectedNuances != selectedNuances || oldDelegate.intensity != intensity || oldDelegate.imagesLoaded != imagesLoaded;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget animé représentant un œil cosmique regardant la Terre
/// avec des rayons lumineux et des particules photoniques.
///
/// Usage :
/// ```dart
/// CosmicEyeWidget(width: 300, height: 400)
/// // ou sans contraintes, prend tout l'espace parent
/// CosmicEyeWidget()
/// ```
class CosmicEyeWidget extends StatefulWidget {
  final double? width;
  final double? height;

  const CosmicEyeWidget({super.key, this.width, this.height});

  @override
  State<CosmicEyeWidget> createState() => _CosmicEyeWidgetState();
}

class _CosmicEyeWidgetState extends State<CosmicEyeWidget>
    with TickerProviderStateMixin {
  late final AnimationController _earthController;
  late final AnimationController _rayPulseController;
  late final AnimationController _photonController;

  @override
  void initState() {
    super.initState();

    // Terre : rotation continue 90s
    _earthController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();

    // Rayons : pulse luminosité 4s aller-retour
    _rayPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Photons : cycle 6s
    _photonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _earthController.dispose();
    _rayPulseController.dispose();
    _photonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _earthController,
          _rayPulseController,
          _photonController,
        ]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond statique
              Image.asset(
                'assets/univers_visuel/oeil_cosmique.webp',
                fit: BoxFit.cover,
              ),
              // Overlay animé
              CustomPaint(
                painter: _CosmicEyePainter(
                  earthT: _earthController.value,
                  pulseT: _rayPulseController.value,
                  photonT: _photonController.value,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Painter qui dessine la Terre rotative, les rayons lumineux
/// et les particules photoniques par-dessus l'image statique.
class _CosmicEyePainter extends CustomPainter {
  final double earthT;
  final double pulseT;
  final double photonT;

  // Positions pseudo-aléatoires des photons (seed fixe)
  static final List<_Photon> _photons = _generatePhotons(25);

  _CosmicEyePainter({
    required this.earthT,
    required this.pulseT,
    required this.photonT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawEarth(canvas, w, h);
    _drawRays(canvas, w, h);
    _drawPhotons(canvas, w, h);
  }

  /// Terre : arc bleu semi-transparent en bas, rotation lente
  void _drawEarth(Canvas canvas, double w, double h) {
    final centerX = w / 2;
    final earthY = h * 0.92;
    final earthRadius = w * 0.18;

    canvas.save();
    canvas.translate(centerX, earthY);

    // Fond de la planète (bleu foncé semi-transparent)
    final earthPaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, earthRadius, earthPaint);

    // Arc lumineux rotatif (atmosphère)
    final atmospherePaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = earthRadius * 0.15;

    final rotAngle = earthT * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: earthRadius * 1.05),
      rotAngle,
      math.pi * 0.8,
      false,
      atmospherePaint,
    );

    // Deuxième arc (continent)
    final continentPaint = Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = earthRadius * 0.12;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: earthRadius * 0.85),
      rotAngle + math.pi * 0.5,
      math.pi * 0.5,
      false,
      continentPaint,
    );

    canvas.restore();
  }

  /// Rayons : faisceaux coniques de l'œil vers la Terre
  void _drawRays(Canvas canvas, double w, double h) {
    final eyeCenterX = w / 2;
    final eyeY = h * 0.28;
    final earthY = h * 0.92;
    final earthRadius = w * 0.18;

    // Luminosité pulsante
    final alpha = 0.06 + 0.1 * pulseT;

    const rayCount = 7;
    const spreadAngle = math.pi * 0.25;

    for (int i = 0; i < rayCount; i++) {
      final t = (i / (rayCount - 1)) - 0.5; // -0.5 à 0.5
      final angle = t * spreadAngle;

      // Point de départ (œil)
      final startX = eyeCenterX + math.sin(angle) * w * 0.05;
      final startY = eyeY;

      // Point d'arrivée (surface Terre)
      final endX = eyeCenterX + math.sin(angle) * earthRadius * 1.8;
      final endY = earthY - earthRadius * 0.3;

      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: alpha * 1.5),
            const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.8),
            const Color(0xFF42A5F5).withValues(alpha: alpha * 0.3),
          ],
        ).createShader(Rect.fromLTRB(0, startY, w, endY))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulseT * 0.8;

      final path = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(
          (startX + endX) / 2 + math.sin(angle) * w * 0.02,
          (startY + endY) / 2,
          endX,
          endY,
        );

      canvas.drawPath(path, rayPaint);
    }
  }

  /// Photons : particules blanches descendant le long des rayons
  void _drawPhotons(Canvas canvas, double w, double h) {
    final eyeY = h * 0.28;
    final earthY = h * 0.85;
    final centerX = w / 2;
    final spreadW = w * 0.25;

    for (final photon in _photons) {
      // Position le long du trajet (cyclique, décalée par phase)
      final progress = (photonT + photon.phase) % 1.0;

      // Position Y : de l'œil vers la Terre
      final y = eyeY + (earthY - eyeY) * progress;

      // Position X : léger spread latéral
      final xOffset = (photon.xOffset - 0.5) * spreadW * 2;
      final x = centerX + xOffset * progress; // s'écarte en descendant

      // Taille et opacité selon position
      final fadeFactor = math.sin(progress * math.pi); // fade in/out
      final radius = photon.size * (1.0 + 0.3 * fadeFactor);
      final alpha = (0.4 + 0.5 * fadeFactor) * photon.brightness;

      if (alpha < 0.05) continue;

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD54F),
          Colors.white,
          photon.warmth,
        )!
            .withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Halo autour des plus grosses particules
      if (photon.size > 2.0) {
        final haloPaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), radius * 2, haloPaint);
      }
    }
  }

  static List<_Photon> _generatePhotons(int count) {
    final rng = math.Random(42); // seed fixe pour stabilité
    return List.generate(count, (_) {
      return _Photon(
        phase: rng.nextDouble(),
        xOffset: rng.nextDouble(),
        size: 1.2 + rng.nextDouble() * 2.0,
        brightness: 0.5 + rng.nextDouble() * 0.5,
        warmth: rng.nextDouble(),
      );
    });
  }

  @override
  bool shouldRepaint(_CosmicEyePainter old) {
    return old.earthT != earthT ||
        old.pulseT != pulseT ||
        old.photonT != photonT;
  }
}

/// Données d'une particule photonique (position pseudo-aléatoire fixe).
class _Photon {
  final double phase;
  final double xOffset;
  final double size;
  final double brightness;
  final double warmth;

  const _Photon({
    required this.phase,
    required this.xOffset,
    required this.size,
    required this.brightness,
    required this.warmth,
  });
}

// lib/widgets/animated_menu_cards.dart
// 4 widgets animés pour le menu principal
// ARCHITECTURE : Image statique FIXE + effets CustomPainter animés par-dessus
// Les images ne bougent JAMAIS — seuls des effets peints en Flutter s'animent

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// 1. EXPRIME CE QUI TE TRAVERSE — Halo cérébral pulsant + particules d'énergie
// =============================================================================

class ExprimeCeQuiTeTraverseCard extends StatefulWidget {
  final VoidCallback? onTap;
  const ExprimeCeQuiTeTraverseCard({super.key, this.onTap});

  @override
  State<ExprimeCeQuiTeTraverseCard> createState() =>
      _ExprimeCeQuiTeTraverseCardState();
}

class _ExprimeCeQuiTeTraverseCardState
    extends State<ExprimeCeQuiTeTraverseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedCardShell(
      onTap: widget.onTap,
      label: 'Express what\ncrosses your mind',
      baseImage: 'assets/univers_visuel/exprime_ce_qui_te_traverse.png',
      animation: _ctrl,
      painterBuilder: (t) => _BrainEnergyPainter(t),
    );
  }
}

// =============================================================================
// 2. PARTAGE CE QUE TU RESSENS — Glow pulsant + ondes concentriques
// =============================================================================

class PartageCeQueTuRessensCard extends StatefulWidget {
  final VoidCallback? onTap;
  const PartageCeQueTuRessensCard({super.key, this.onTap});

  @override
  State<PartageCeQueTuRessensCard> createState() =>
      _PartageCeQueTuRessensCardState();
}

class _PartageCeQueTuRessensCardState
    extends State<PartageCeQueTuRessensCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedCardShell(
      onTap: widget.onTap,
      label: 'Share what\nyou feel',
      baseImage: 'assets/univers_visuel/partage_ce_que_tu_ressens.png',
      animation: _ctrl,
      painterBuilder: (t) => _HeartPulsePainter(t),
    );
  }
}

// =============================================================================
// 3. TON CHEMIN PARCOURU — Particules lumineuses remontant la rivière
// =============================================================================

class TonCheminParcouruCard extends StatefulWidget {
  final VoidCallback? onTap;
  const TonCheminParcouruCard({super.key, this.onTap});

  @override
  State<TonCheminParcouruCard> createState() => _TonCheminParcouruCardState();
}

class _TonCheminParcouruCardState extends State<TonCheminParcouruCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedCardShell(
      onTap: widget.onTap,
      label: 'Your journey\nso far',
      baseImage: 'assets/univers_visuel/mon_chemin_parcouru.png',
      animation: _ctrl,
      painterBuilder: (t) => _RiverFlowPainter(t),
    );
  }
}

// =============================================================================
// 4. CONNECTE TOI AUX SOURCES — Étoiles en rotation + constellations
// =============================================================================

class ConnecteToiAuxSourcesCard extends StatefulWidget {
  final VoidCallback? onTap;
  const ConnecteToiAuxSourcesCard({super.key, this.onTap});

  @override
  State<ConnecteToiAuxSourcesCard> createState() =>
      _ConnecteToiAuxSourcesCardState();
}

class _ConnecteToiAuxSourcesCardState
    extends State<ConnecteToiAuxSourcesCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedCardShell(
      onTap: widget.onTap,
      label: 'Connect with\nthe sources',
      baseImage: 'assets/univers_visuel/connecte_toi_aux_sources.png',
      animation: _ctrl,
      painterBuilder: (t) => _CosmosRotationPainter(t),
    );
  }
}

// =============================================================================
// PAINTERS — Effets visuels dessinés par-dessus les images statiques
// =============================================================================

// ── 1. Énergie cérébrale : halo radial pulsant + particules orbitales ────────

class _BrainEnergyPainter extends CustomPainter {
  final double t;
  _BrainEnergyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Centre du cerveau dans l'image (ajusté pour BoxFit.cover)
    final center = Offset(size.width * 0.42, size.height * 0.24);

    // ── Halo radial pulsant (INTENSE) ──
    final pulse = math.sin(t * 2 * math.pi);
    final glowRadius = size.width * (0.35 + 0.10 * pulse);
    final glowAlpha = 0.30 + 0.15 * pulse;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 200, 50, glowAlpha),
          Color.fromRGBO(255, 140, 0, glowAlpha * 0.5),
          const Color.fromRGBO(255, 100, 0, 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));

    canvas.drawCircle(center, glowRadius, glowPaint);

    // ── Second halo plus large, subtil ──
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 180, 30, glowAlpha * 0.3),
          const Color.fromRGBO(255, 120, 0, 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius * 1.5));
    canvas.drawCircle(center, glowRadius * 1.5, outerGlow);

    // ── Particules d'énergie orbitales (plus nombreuses, plus grosses) ──
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);

    for (int i = 0; i < 28; i++) {
      final baseAngle = rng.nextDouble() * 2 * math.pi;
      final orbitRadius = size.width * (0.06 + rng.nextDouble() * 0.25);
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final pSize = 2.0 + rng.nextDouble() * 4.0;

      final angle = baseAngle + t * 2 * math.pi * speed;
      final wobble = math.sin(t * 2 * math.pi * 2 + i) * 4;
      final r = orbitRadius + wobble;

      final px = center.dx + math.cos(angle) * r;
      final py = center.dy + math.sin(angle) * r * 0.7;

      // Scintillement
      final twinkle =
          (0.4 + 0.6 * math.sin(t * 2 * math.pi * 3 + i * 1.1))
              .clamp(0.0, 1.0);

      // Point lumineux
      particlePaint.color = Color.fromRGBO(255, 220, 100, twinkle);
      canvas.drawCircle(Offset(px, py), pSize, particlePaint);

      // Halo autour de chaque particule
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 200, 80, twinkle * 0.4),
            const Color.fromRGBO(255, 180, 50, 0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(px, py), radius: pSize * 5));
      canvas.drawCircle(Offset(px, py), pSize * 5, haloPaint);
    }
  }

  @override
  bool shouldRepaint(_BrainEnergyPainter old) => old.t != t;
}

// ── 2. Battement cardiaque : glow pulsant + ondes concentriques ──────────────

class _HeartPulsePainter extends CustomPainter {
  final double t;
  _HeartPulsePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.33);

    // ── Double battement (lub-dub) ──
    double beat;
    if (t < 0.10) {
      beat = math.sin(t / 0.10 * math.pi);
    } else if (t > 0.18 && t < 0.28) {
      beat = math.sin((t - 0.18) / 0.10 * math.pi) * 0.65;
    } else {
      beat = 0;
    }

    // ── Glow central pulsant (INTENSE) ──
    final glowRadius = size.width * (0.30 + 0.12 * beat);
    final glowAlpha = 0.25 + 0.30 * beat;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 120, 60, glowAlpha),
          Color.fromRGBO(255, 80, 30, glowAlpha * 0.5),
          const Color.fromRGBO(255, 50, 10, 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));

    canvas.drawCircle(center, glowRadius, glowPaint);

    // ── Halo externe permanent ──
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 100, 40, 0.12 + 0.10 * beat),
          const Color.fromRGBO(255, 60, 20, 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius * 1.6));
    canvas.drawCircle(center, glowRadius * 1.6, outerGlow);

    // ── Ondes concentriques (plus d'anneaux, plus épais, toujours visibles) ──
    for (int i = 0; i < 5; i++) {
      final ringAge = (t * 1.5 + i * 0.20) % 1.0;
      final ringRadius = size.width * (0.10 + ringAge * 0.45);
      final ringAlpha = ((1 - ringAge) * 0.40 * (0.5 + beat * 0.5))
          .clamp(0.0, 1.0);

      if (ringAlpha > 0.02) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 + (1 - ringAge) * 2.5
          ..color = Color.fromRGBO(255, 160, 90, ringAlpha);

        canvas.drawCircle(center, ringRadius, ringPaint);
      }
    }

    // ── Étincelles autour du coeur (toujours visibles, plus fortes au beat) ──
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(77);
    for (int i = 0; i < 14; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = size.width * (0.12 + rng.nextDouble() * 0.18);
      final sparkSize = 1.5 + rng.nextDouble() * 2.5;

      final sx = center.dx + math.cos(angle + t * 2) * dist;
      final sy = center.dy + math.sin(angle + t * 2) * dist;

      final sparkAlpha = (0.3 + beat * 0.5 +
              0.2 * math.sin(t * 2 * math.pi * 3 + i))
          .clamp(0.0, 1.0);
      sparkPaint.color = Color.fromRGBO(255, 200, 120, sparkAlpha);
      canvas.drawCircle(Offset(sx, sy), sparkSize, sparkPaint);

      // Halo par étincelle
      final sHalo = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 180, 100, sparkAlpha * 0.3),
            const Color.fromRGBO(255, 150, 80, 0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(sx, sy), radius: sparkSize * 4));
      canvas.drawCircle(Offset(sx, sy), sparkSize * 4, sHalo);
    }
  }

  @override
  bool shouldRepaint(_HeartPulsePainter old) => old.t != t;
}

// ── 3. Rivière : particules lumineuses remontant le cours d'eau ──────────────

class _RiverFlowPainter extends CustomPainter {
  final double t;
  _RiverFlowPainter(this.t);

  // Chemin de la rivière (normalisé 0..1, du bas vers le haut)
  // Correspond à la forme en S visible dans l'image
  static const List<List<double>> _riverPath = [
    [0.48, 0.95],
    [0.52, 0.88],
    [0.58, 0.80],
    [0.60, 0.72],
    [0.56, 0.64],
    [0.48, 0.56],
    [0.42, 0.50],
    [0.40, 0.43],
    [0.43, 0.36],
    [0.48, 0.30],
    [0.50, 0.24],
    [0.50, 0.18],
  ];

  Offset _pointOnPath(Size size, double progress) {
    final idx = progress * (_riverPath.length - 1);
    final i = idx.floor().clamp(0, _riverPath.length - 2);
    final frac = idx - i;
    final ax = _riverPath[i][0], ay = _riverPath[i][1];
    final bx = _riverPath[i + 1][0], by = _riverPath[i + 1][1];
    return Offset(
      size.width * (ax + (bx - ax) * frac),
      size.height * (ay + (by - ay) * frac),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(55);

    // ── Ligne lumineuse de base le long de la rivière ──
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Color.fromRGBO(255, 240, 200, 0.08 + 0.06 * math.sin(t * 2 * math.pi));
    final trailPath = Path();
    for (int i = 0; i <= 20; i++) {
      final p = _pointOnPath(size, i / 20.0);
      if (i == 0) {
        trailPath.moveTo(p.dx, p.dy);
      } else {
        trailPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(trailPath, trailPaint);

    // ── Particules voyageant le long de la rivière (plus grosses, plus nombreuses) ──
    for (int i = 0; i < 22; i++) {
      final speed = 0.5 + rng.nextDouble() * 0.5;
      final phase = (t * speed + i / 22.0) % 1.0;

      final pos = _pointOnPath(size, phase);

      // Décalage latéral (largeur de la rivière)
      final lateralOffset = math.sin(phase * math.pi * 4 + i) *
          size.width *
          (0.03 + rng.nextDouble() * 0.03);
      final finalPos = Offset(pos.dx + lateralOffset, pos.dy);

      // Plus lumineux au milieu du trajet
      final brightness = math.sin(phase * math.pi);
      final alpha = (0.4 + 0.6 * brightness).clamp(0.0, 1.0);
      final radius = 2.5 + 4.0 * brightness;

      // Point lumineux
      particlePaint.color = Color.fromRGBO(255, 240, 180, alpha);
      canvas.drawCircle(finalPos, radius, particlePaint);

      // Halo large
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 230, 150, alpha * 0.45),
            const Color.fromRGBO(200, 220, 255, 0),
          ],
        ).createShader(
            Rect.fromCircle(center: finalPos, radius: radius * 6));
      canvas.drawCircle(finalPos, radius * 6, haloPaint);
    }

    // ── Scintillements fixes le long de la rivière (plus visibles) ──
    for (int i = 0; i < 30; i++) {
      final pathPos = rng.nextDouble();
      final pos = _pointOnPath(size, pathPos);
      final lateral =
          (rng.nextDouble() - 0.5) * size.width * 0.06;

      final twinkle =
          (0.2 + 0.5 * math.sin(t * 2 * math.pi * 2 + i * 0.8))
              .clamp(0.0, 1.0);

      particlePaint.color = Color.fromRGBO(220, 230, 255, twinkle);
      canvas.drawCircle(
          Offset(pos.dx + lateral, pos.dy), 1.5 + rng.nextDouble() * 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_RiverFlowPainter old) => old.t != t;
}

// ── 4. Cosmos : étoiles en rotation + constellations autour de la tête ───────

class _CosmosRotationPainter extends CustomPainter {
  final double t;
  _CosmosRotationPainter(this.t);

  // Étoiles prégénérées (déterministes)
  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = math.Random(123);
    final stars = <_Star>[];
    for (int i = 0; i < 40; i++) {
      stars.add(_Star(
        angle: rng.nextDouble() * 2 * math.pi,
        radius: 0.08 + rng.nextDouble() * 0.42,
        size: 1.5 + rng.nextDouble() * 3.5,
        speed: 0.2 + rng.nextDouble() * 0.6,
      ));
    }
    return stars;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Centre de rotation : sommet de la tête de la silhouette
    final center = Offset(size.width * 0.50, size.height * 0.30);

    // ── Halo central ambiant ──
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(100, 220, 100, 0.08 + 0.04 * math.sin(t * 2 * math.pi)),
          const Color.fromRGBO(50, 150, 50, 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.4));
    canvas.drawCircle(center, size.width * 0.4, ambientPaint);

    final starPaint = Paint()..style = PaintingStyle.fill;
    final positions = <Offset>[];

    // ── Étoiles en orbite (plus grosses, plus lumineuses) ──
    for (int i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final angle = star.angle + t * 2 * math.pi * star.speed;
      final r = star.radius * size.width;

      final px = center.dx + math.cos(angle) * r;
      final py = center.dy + math.sin(angle) * r * 0.65;
      final pos = Offset(px, py);
      positions.add(pos);

      // Scintillement
      final twinkle =
          (0.4 + 0.6 * math.sin(t * 2 * math.pi * 2.5 + star.angle * 3))
              .clamp(0.0, 1.0);

      // Halo vert fort
      final haloRadius = star.size * 6;
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(150, 255, 150, twinkle * 0.40),
            const Color.fromRGBO(100, 220, 100, 0),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: haloRadius));
      canvas.drawCircle(pos, haloRadius, haloPaint);

      // Point étoile brillant
      starPaint.color = Color.fromRGBO(220, 255, 200, twinkle);
      canvas.drawCircle(pos, star.size, starPaint);
    }

    // ── Lignes de constellation (plus visibles) ──
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final maxDist = size.width * 0.16;
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < maxDist) {
          final lineAlpha = (1 - dist / maxDist) * 0.30;
          linePaint.color = Color.fromRGBO(150, 230, 150, lineAlpha);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    // ── Flux d'énergie descendant vers la tête (plus de particules, plus grosses) ──
    final flowPaint = Paint()..style = PaintingStyle.fill;
    final headTop = Offset(size.width * 0.50, size.height * 0.38);
    for (int i = 0; i < 12; i++) {
      final phase = (t * 1.5 + i / 12.0) % 1.0;
      final startAngle = i * math.pi / 6 + t * 0.5;
      final startR = size.width * 0.30;

      final sx = center.dx + math.cos(startAngle) * startR * (1 - phase);
      final sy = center.dy + math.sin(startAngle) * startR * 0.5 * (1 - phase);
      final fx = sx + (headTop.dx - sx) * phase;
      final fy = sy + (headTop.dy - sy) * phase;

      final alpha = math.sin(phase * math.pi) * 0.7;
      final radius = 2.0 + (1 - phase) * 2.5;
      flowPaint.color = Color.fromRGBO(200, 255, 180, alpha);
      canvas.drawCircle(Offset(fx, fy), radius, flowPaint);

      // Halo par particule de flux
      final fHalo = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(180, 255, 160, alpha * 0.3),
            const Color.fromRGBO(150, 230, 130, 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(fx, fy), radius: radius * 4));
      canvas.drawCircle(Offset(fx, fy), radius * 4, fHalo);
    }
  }

  @override
  bool shouldRepaint(_CosmosRotationPainter old) => old.t != t;
}

class _Star {
  final double angle;
  final double radius;
  final double size;
  final double speed;
  const _Star(
      {required this.angle,
      required this.radius,
      required this.size,
      required this.speed});
}

// =============================================================================
// SHELL COMMUN — Image statique + CustomPaint animé + dégradé + légende
// =============================================================================

Widget _fallback() => Container(
      color: const Color(0xFF1A2332),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white38, size: 40),
      ),
    );

class _AnimatedCardShell extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final String baseImage;
  final Animation<double> animation;
  final CustomPainter Function(double t) painterBuilder;

  const _AnimatedCardShell({
    this.onTap,
    required this.label,
    required this.baseImage,
    required this.animation,
    required this.painterBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // COUCHE 0 : Fond sombre plein (aucun blanc ne passe)
            Container(color: const Color(0xFF0A1628)),
              // COUCHE 1 : Image de base FIXE, zoomée 1.15x
              // pour éliminer totalement les coins blancs des PNG
              // COUCHE 1 : Image zoomée + remontée pour masquer le texte brûlé du PNG
              Positioned.fill(
                child: Transform.scale(
                  scale: 1.35,
                  alignment: const Alignment(0.0, -0.15),
                  child: Image.asset(
                    baseImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _fallback(),
                  ),
                ),
              ),
            // COUCHE 1b : Bordure sombre interne pour masquer
            // tout résidu blanc/clair venant des bords des PNG
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF0A1628),
                    width: 4.5,
                  ),
                ),
              ),
            ),
            // COUCHE 2 : Effets animés peints par-dessus
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => CustomPaint(
                  painter: painterBuilder(animation.value),
                  size: Size.infinite,
                ),
              ),
            ),
            // COUCHE 3a : Dégradé HAUT pour masquer texte brûlé en haut du PNG
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.12, 0.25, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // COUCHE 3b : Dégradé BAS renforcé pour masquer texte brûlé + légende
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55, 0.75, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
            // COUCHE 4 : Légende texte
            Positioned(
              left: 8,
              right: 8,
              bottom: 12,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 8),
                    Shadow(color: Colors.black, blurRadius: 4),
                    Shadow(color: Colors.black, blurRadius: 2),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ],
          ),
        ),
    );
  }
}


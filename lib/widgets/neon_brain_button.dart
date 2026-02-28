// lib/widgets/neon_brain_button.dart
// Bouton cerveau neon inspire de l'image de reference:
// Cerveau bleu electrique avec anneau cyan, rayons violet/rose,
// particules scintillantes sur fond noir.

import 'dart:math';
import 'package:flutter/material.dart';

class NeonBrainButton extends StatefulWidget {
  /// Taille totale du widget (largeur et hauteur)
  final double size;

  /// Si true, affiche un etat "complete" (vert au lieu de cyan)
  final bool isComplete;

  /// Si true, le bouton pulse doucement
  final bool pulse;

  /// Couleur principale du glow (cyan par defaut)
  final Color glowColor;

  /// Icone overlay optionnelle (ex: Icons.refresh pour erreur)
  final IconData? overlayIcon;

  const NeonBrainButton({
    super.key,
    this.size = 120,
    this.isComplete = false,
    this.pulse = true,
    this.glowColor = const Color(0xFF00D4FF),
    this.overlayIcon,
  });

  @override
  State<NeonBrainButton> createState() => _NeonBrainButtonState();
}

class _NeonBrainButtonState extends State<NeonBrainButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseScale = widget.pulse
            ? 0.97 + sin(_controller.value * 2 * pi) * 0.03
            : 1.0;
        return Transform.scale(
          scale: pulseScale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _NeonBrainPainter(
                progress: _controller.value,
                glowColor: widget.glowColor,
              ),
              child: Center(
                child: _buildCenterContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterContent() {
    final brainSize = widget.size * 0.42;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Image cerveau avec teinte bleue electrique
        Image.asset(
          'assets/univers_visuel/brain_loading.png',
          width: brainSize,
          height: brainSize,
          fit: BoxFit.contain,
          color: widget.glowColor.withOpacity(0.35),
          colorBlendMode: BlendMode.screen,
          errorBuilder: (_, __, ___) => Icon(
            Icons.psychology,
            color: widget.glowColor,
            size: brainSize * 0.7,
          ),
        ),
        // Overlay optionnel (refresh, etc.)
        if (widget.overlayIcon != null)
          Container(
            width: brainSize,
            height: brainSize,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.overlayIcon,
              color: Colors.white,
              size: brainSize * 0.5,
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// CUSTOM PAINTER — Effet neon (rayons, anneau, particules)
// ============================================================================

class _NeonBrainPainter extends CustomPainter {
  final double progress;
  final Color glowColor;

  _NeonBrainPainter({
    required this.progress,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 1. Fond noir circulaire
    _drawBlackBackground(canvas, center, maxRadius);

    // 2. Rayons d'energie violet/rose (burst radial)
    _drawEnergyBurst(canvas, center, maxRadius);

    // 3. Anneau neon cyan/bleu lumineux
    _drawNeonRing(canvas, center, maxRadius * 0.50);

    // 4. Halo interieur (glow autour du cerveau)
    _drawInnerGlow(canvas, center, maxRadius * 0.30);

    // 5. Particules scintillantes
    _drawSparkles(canvas, center, maxRadius);
  }

  /// Fond noir circulaire avec bord doux
  void _drawBlackBackground(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF050510),
          const Color(0xFF0A0A1E),
          const Color(0xFF050510),
          Colors.black,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);
  }

  /// Rayons d'energie violet/rose irradiant du centre
  void _drawEnergyBurst(Canvas canvas, Offset center, double maxRadius) {
    final rng = Random(42);
    final rayPaint = Paint()..style = PaintingStyle.stroke;

    // Couche 1: rayons larges et diffus (fond)
    for (int i = 0; i < 24; i++) {
      final baseAngle = (i / 24) * 2 * pi;
      final angle = baseAngle + sin(progress * 2 * pi + i * 0.7) * 0.08;
      final startR = maxRadius * 0.38;
      final endR = maxRadius * (0.65 + rng.nextDouble() * 0.30);
      final width = 2.0 + rng.nextDouble() * 4.0;

      // Couleur violet -> rose
      final t = (i / 24 + progress * 0.2) % 1.0;
      final color = Color.lerp(
        const Color(0xFF7C3AED), // violet
        const Color(0xFFEC4899), // rose
        (sin(t * 2 * pi) * 0.5 + 0.5),
      )!;

      final alpha = (0.15 + sin(progress * 2 * pi * 1.5 + i * 0.8) * 0.12)
          .clamp(0.05, 0.35);

      rayPaint
        ..color = color.withOpacity(alpha)
        ..strokeWidth = width
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawLine(
        Offset(center.dx + cos(angle) * startR,
            center.dy + sin(angle) * startR),
        Offset(
            center.dx + cos(angle) * endR, center.dy + sin(angle) * endR),
        rayPaint,
      );
    }

    // Couche 2: rayons fins et brillants (premier plan)
    for (int i = 0; i < 36; i++) {
      final baseAngle = (i / 36) * 2 * pi;
      final angle = baseAngle + cos(progress * 2 * pi * 0.7 + i) * 0.05;
      final startR = maxRadius * 0.42;
      final endR = maxRadius * (0.55 + rng.nextDouble() * 0.35);
      final width = 0.5 + rng.nextDouble() * 1.5;

      final t2 = (i / 36 + progress * 0.5) % 1.0;
      final color2 = Color.lerp(
        const Color(0xFFA855F7), // violet clair
        const Color(0xFFF472B6), // rose clair
        (sin(t2 * 2 * pi) * 0.5 + 0.5),
      )!;

      final alpha2 = (0.1 + sin(progress * 2 * pi * 2.0 + i * 1.2) * 0.15)
          .clamp(0.03, 0.3);

      rayPaint
        ..color = color2.withOpacity(alpha2)
        ..strokeWidth = width
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(
        Offset(center.dx + cos(angle) * startR,
            center.dy + sin(angle) * startR),
        Offset(
            center.dx + cos(angle) * endR, center.dy + sin(angle) * endR),
        rayPaint,
      );
    }
  }

  /// Anneau neon cyan lumineux
  void _drawNeonRing(Canvas canvas, Offset center, double radius) {
    final pulseR = radius * (1.0 + sin(progress * 2 * pi) * 0.02);

    // Glow externe tres diffus
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = glowColor.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Glow moyen
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = glowColor.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Anneau principal cyan vif
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = glowColor.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Coeur blanc brillant de l'anneau
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  /// Halo interieur lumineux autour du cerveau
  void _drawInnerGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.15),
          glowColor.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);
  }

  /// Particules scintillantes autour du cerveau
  void _drawSparkles(Canvas canvas, Offset center, double maxRadius) {
    final rng = Random(77);
    final sparklePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      // Position orbitale avec rotation lente
      final baseAngle = rng.nextDouble() * 2 * pi;
      final dist = maxRadius * (0.25 + rng.nextDouble() * 0.65);
      final angle = baseAngle + progress * (0.3 + rng.nextDouble() * 0.4);
      final sparkleSize = 0.8 + rng.nextDouble() * 2.0;

      // Scintillement individuel
      final phaseOffset = rng.nextDouble() * 2 * pi;
      final twinkle = sin(progress * 2 * pi * (2.0 + rng.nextDouble()) + phaseOffset);
      final alpha = ((0.2 + twinkle * 0.5)).clamp(0.0, 0.9);

      if (alpha < 0.05) continue;

      final pos = Offset(
        center.dx + cos(angle) * dist,
        center.dy + sin(angle) * dist,
      );

      // Verifier qu'on est dans le cercle
      if ((pos - center).distance > maxRadius * 0.95) continue;

      // Alterner blanc, cyan et rose
      Color sparkleColor;
      switch (i % 4) {
        case 0:
          sparkleColor = Colors.white;
          break;
        case 1:
          sparkleColor = glowColor;
          break;
        case 2:
          sparkleColor = const Color(0xFFD4A5FF); // violet clair
          break;
        default:
          sparkleColor = const Color(0xFFF9A8D4); // rose clair
      }

      // Glow de la particule
      sparklePaint
        ..color = sparkleColor.withOpacity(alpha * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkleSize * 2);
      canvas.drawCircle(pos, sparkleSize * 1.5, sparklePaint);

      // Coeur de la particule
      sparklePaint
        ..color = sparkleColor.withOpacity(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkleSize * 0.5);
      canvas.drawCircle(pos, sparkleSize * 0.6, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonBrainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

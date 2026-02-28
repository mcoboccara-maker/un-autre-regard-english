// lib/widgets/parametric_emotion_face.dart
// Visages paramétriques pour le mandala des émotions
// Résolution infinie (Canvas), transition continue 0.0 → 1.0
// Prototype : EN_COLERE, BLESSE, HEUREUX

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dessine des visages expressifs paramétriques directement sur le Canvas.
/// Remplace les PNG pour les émotions supportées — résolution infinie,
/// transition d'intensité continue, cercle strictement identique.
class ParametricEmotionFace {
  ParametricEmotionFace._();

  static const _supported = {'EN_COLERE', 'BLESSE', 'HEUREUX'};

  /// Vérifie si un visage paramétrique est disponible pour cette émotion.
  static bool isSupported(String emotionKey) => _supported.contains(emotionKey);

  /// Dessine le visage paramétrique.
  /// [center] : centre du visage sur le canvas
  /// [radius] : rayon du cercle du visage
  /// [emotionKey] : clé de l'émotion (EN_COLERE, BLESSE, HEUREUX)
  /// [intensity] : 0.0 (neutre) → 1.0 (expression maximale)
  static void draw(Canvas canvas, Offset center, double radius,
      String emotionKey, double intensity) {
    final t = intensity.clamp(0.0, 1.0);
    _drawFaceCircle(canvas, center, radius);

    switch (emotionKey) {
      case 'EN_COLERE':
        _drawAngryFace(canvas, center, radius, t);
      case 'BLESSE':
        _drawHurtFace(canvas, center, radius, t);
      case 'HEUREUX':
        _drawHappyFace(canvas, center, radius, t);
    }
  }

  // ── Cercle du visage (toujours identique par construction) ─────────

  static void _drawFaceCircle(Canvas canvas, Offset center, double radius) {
    // Remplissage vert pâle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFE8F5E9),
    );
    // Contour vert
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF4CAF93)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius * 0.06).clamp(1.0, 4.0),
    );
  }

  // ── Primitives partagées ───────────────────────────────────────────

  /// Dessine un œil.
  /// [squeeze] < 1 rétrécit verticalement (colère), > 1 agrandit (blessé)
  /// [arcSmile] 0→1 transforme l'œil en arc souriant fermé (heureux)
  static void _drawEye(Canvas canvas, Offset pos, double baseRadius,
      {double squeeze = 1.0, double arcSmile = 0.0}) {
    final sw = (baseRadius * 0.4).clamp(0.8, 3.0);
    final paint = Paint()
      ..color = const Color(0xFF2D1B00)
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    if (arcSmile > 0.05) {
      // Arc souriant (yeux fermés heureux) — courbure progressive
      paint.style = PaintingStyle.stroke;
      final arcRect = Rect.fromCenter(
        center: pos,
        width: baseRadius * 2.0,
        height: baseRadius * 2.0 * arcSmile.clamp(0.2, 1.0),
      );
      // Arc du bas (π → 2π = demi-cercle inférieur = sourire ∪)
      canvas.drawArc(arcRect, 0, -math.pi, false, paint);
    } else {
      // Œil elliptique plein
      paint.style = PaintingStyle.fill;
      final rx = baseRadius;
      final ry = baseRadius * squeeze;
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: rx * 2, height: ry * 2),
        paint,
      );
      // Reflet (petit point blanc) — visible seulement si assez grand
      if (baseRadius > 2.5) {
        canvas.drawCircle(
          Offset(pos.dx + baseRadius * 0.3, pos.dy - ry * 0.3),
          (baseRadius * 0.25).clamp(0.5, 3.0),
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      }
    }
  }

  /// Dessine un sourcil (courbe de Bézier quadratique).
  /// [innerDrop] : décalage Y du côté intérieur (vers le nez)
  ///   positif = vers le bas (colère V), négatif = vers le haut (blessé worried)
  /// [curve] : courbure vers le haut (positif = arqué)
  /// [isLeft] : true pour le sourcil gauche (dx négatif)
  static void _drawEyebrow(Canvas canvas, Offset pos, double length,
      {required bool isLeft,
      double innerDrop = 0.0,
      double curve = 0.0,
      double thickness = 2.0,
      double opacity = 1.0}) {
    final paint = Paint()
      ..color = const Color(0xFF2D1B00).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final halfLen = length / 2;
    // Côté extérieur (tempe) et intérieur (nez)
    final outerX = isLeft ? pos.dx - halfLen : pos.dx + halfLen;
    final innerX = isLeft ? pos.dx + halfLen : pos.dx - halfLen;
    final outerY = pos.dy;
    final innerY = pos.dy + innerDrop;

    final path = Path();
    path.moveTo(outerX, outerY);
    path.quadraticBezierTo(
      pos.dx,
      pos.dy - curve, // point de contrôle au-dessus = arqué
      innerX,
      innerY,
    );
    canvas.drawPath(path, paint);
  }

  /// Dessine une bouche.
  /// [smile] : -1 = frown max, 0 = neutre, +1 = sourire max
  /// [openness] : 0 = fermée, 1 = grande ouverte
  static void _drawMouth(Canvas canvas, Offset pos, double width,
      {double smile = 0.0, double openness = 0.0, double thickness = 2.0}) {
    final paint = Paint()
      ..color = const Color(0xFF2D1B00)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final halfW = width / 2;
    final curveY = smile * halfW * 0.8; // amplitude de la courbe

    if (openness > 0.05) {
      // Bouche ouverte (forme remplie)
      paint.style = PaintingStyle.fill;
      final openH = width * openness * 0.4;
      final path = Path();

      // Lèvre supérieure
      path.moveTo(pos.dx - halfW, pos.dy);
      path.quadraticBezierTo(pos.dx, pos.dy + curveY, pos.dx + halfW, pos.dy);

      // Lèvre inférieure — s'ouvre toujours vers le bas
      final lowerCtrlY = math.max(curveY, 0) + openH;
      path.quadraticBezierTo(
        pos.dx,
        pos.dy + lowerCtrlY,
        pos.dx - halfW,
        pos.dy,
      );
      path.close();

      // Fond sombre de la bouche
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFF8B1A1A).withValues(alpha: 0.7),
      );
      // Contour
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF2D1B00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness,
      );
    } else {
      // Bouche fermée (simple courbe)
      paint.style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(pos.dx - halfW, pos.dy);
      path.quadraticBezierTo(pos.dx, pos.dy + curveY, pos.dx + halfW, pos.dy);
      canvas.drawPath(path, paint);
    }
  }

  // ── EN COLÈRE ──────────────────────────────────────────────────────

  static void _drawAngryFace(
      Canvas canvas, Offset center, double r, double t) {
    final eyeR = (r * 0.10).clamp(1.2, 10.0);
    final leftEye = Offset(center.dx - r * 0.25, center.dy - r * 0.10);
    final rightEye = Offset(center.dx + r * 0.25, center.dy - r * 0.10);
    final sw = (r * 0.05).clamp(0.8, 3.0);

    // Yeux : ronds → rétrécis verticalement
    final squeeze = 1.0 - t * 0.6; // 1.0 → 0.4
    _drawEye(canvas, leftEye, eyeR, squeeze: squeeze);
    _drawEye(canvas, rightEye, eyeR, squeeze: squeeze);

    // Sourcils : plats → V aigu (côté intérieur descend)
    final browLen = r * 0.28;
    final browY = center.dy - r * 0.28;
    final browDrop = t * r * 0.15;
    _drawEyebrow(
      canvas,
      Offset(center.dx - r * 0.25, browY),
      browLen,
      isLeft: true,
      innerDrop: browDrop,
      curve: r * 0.02,
      thickness: sw,
    );
    _drawEyebrow(
      canvas,
      Offset(center.dx + r * 0.25, browY),
      browLen,
      isLeft: false,
      innerDrop: browDrop,
      curve: r * 0.02,
      thickness: sw,
    );

    // Bouche : neutre → frown → ouverte furieuse (>0.6)
    final mouthPos = Offset(center.dx, center.dy + r * 0.30);
    final mouthW = r * 0.35;
    final frown = -t; // 0 → -1 (frown)
    final openness = t > 0.6 ? (t - 0.6) / 0.4 : 0.0;
    _drawMouth(canvas, mouthPos, mouthW,
        smile: frown, openness: openness * 0.6, thickness: sw);

    // Extras : marques de colère (>0.7)
    if (t > 0.7) {
      _drawAngerMarks(canvas, center, r, (t - 0.7) / 0.3);
    }
  }

  /// Marques de colère — petites croix stylisées près des tempes
  static void _drawAngerMarks(
      Canvas canvas, Offset center, double r, double progress) {
    final paint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: progress.clamp(0.0, 1.0) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.04).clamp(0.8, 2.5)
      ..strokeCap = StrokeCap.round;

    final ms = r * 0.08; // taille de la croix

    // Marque tempe droite
    final markR = Offset(center.dx + r * 0.55, center.dy - r * 0.35);
    canvas.drawLine(Offset(markR.dx - ms, markR.dy - ms),
        Offset(markR.dx + ms, markR.dy + ms), paint);
    canvas.drawLine(Offset(markR.dx + ms, markR.dy - ms),
        Offset(markR.dx - ms, markR.dy + ms), paint);

    // Marque tempe gauche
    final markL = Offset(center.dx - r * 0.55, center.dy - r * 0.35);
    canvas.drawLine(Offset(markL.dx - ms, markL.dy - ms),
        Offset(markL.dx + ms, markL.dy + ms), paint);
    canvas.drawLine(Offset(markL.dx + ms, markL.dy - ms),
        Offset(markL.dx - ms, markL.dy + ms), paint);
  }

  // ── BLESSÉ ─────────────────────────────────────────────────────────

  static void _drawHurtFace(
      Canvas canvas, Offset center, double r, double t) {
    final eyeR = (r * (0.10 + t * 0.04)).clamp(1.2, 12.0); // yeux grossissent
    final leftEye = Offset(center.dx - r * 0.25, center.dy - r * 0.10);
    final rightEye = Offset(center.dx + r * 0.25, center.dy - r * 0.10);
    final sw = (r * 0.05).clamp(0.8, 3.0);

    // Yeux : ronds → plus gros (via eyeR croissant)
    _drawEye(canvas, leftEye, eyeR);
    _drawEye(canvas, rightEye, eyeR);

    // Sourcils : plats → relevés au centre (worried)
    final browLen = r * 0.28;
    final browY = center.dy - r * 0.28;
    final innerRaise = -t * r * 0.12; // négatif = monte
    _drawEyebrow(
      canvas,
      Offset(center.dx - r * 0.25, browY),
      browLen,
      isLeft: true,
      innerDrop: innerRaise,
      curve: t * r * 0.06,
      thickness: sw,
    );
    _drawEyebrow(
      canvas,
      Offset(center.dx + r * 0.25, browY),
      browLen,
      isLeft: false,
      innerDrop: innerRaise,
      curve: t * r * 0.06,
      thickness: sw,
    );

    // Bouche : neutre → frown profond
    final mouthPos = Offset(center.dx, center.dy + r * 0.30);
    final mouthW = r * 0.30;
    _drawMouth(canvas, mouthPos, mouthW, smile: -t * 0.8, thickness: sw);

    // Extras : larmes progressives (>0.4)
    if (t > 0.4) {
      _drawTears(canvas, center, r, (t - 0.4) / 0.6);
    }
  }

  /// Larmes — gouttes bleues sous les yeux
  static void _drawTears(
      Canvas canvas, Offset center, double r, double progress) {
    final tearW = r * 0.04;

    // Larme gauche (apparaît en premier)
    final leftTear = Offset(center.dx - r * 0.22, center.dy + r * 0.02);
    final tearH = r * 0.12 * progress;
    _drawTeardrop(canvas, leftTear, tearW, tearH,
        const Color(0xFF60A5FA).withValues(alpha: progress.clamp(0.0, 1.0) * 0.7));

    // Larme droite (apparaît avec un décalage)
    if (progress > 0.3) {
      final rightTear = Offset(center.dx + r * 0.22, center.dy + r * 0.05);
      final rProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      _drawTeardrop(canvas, rightTear, tearW, tearH * rProgress,
          const Color(0xFF60A5FA).withValues(alpha: rProgress * 0.6));
    }
  }

  /// Forme de goutte d'eau
  static void _drawTeardrop(
      Canvas canvas, Offset top, double width, double height, Color color) {
    if (height < 0.5) return;
    final path = Path();
    path.moveTo(top.dx, top.dy);
    path.quadraticBezierTo(
      top.dx - width,
      top.dy + height * 0.6,
      top.dx,
      top.dy + height,
    );
    path.quadraticBezierTo(
      top.dx + width,
      top.dy + height * 0.6,
      top.dx,
      top.dy,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── HEUREUX ────────────────────────────────────────────────────────

  static void _drawHappyFace(
      Canvas canvas, Offset center, double r, double t) {
    final eyeR = (r * 0.10).clamp(1.2, 10.0);
    final leftEye = Offset(center.dx - r * 0.25, center.dy - r * 0.10);
    final rightEye = Offset(center.dx + r * 0.25, center.dy - r * 0.10);
    final sw = (r * 0.05).clamp(0.8, 3.0);

    // Yeux : ronds → arcs souriants fermés
    _drawEye(canvas, leftEye, eyeR, arcSmile: t);
    _drawEye(canvas, rightEye, eyeR, arcSmile: t);

    // Sourcils : absents → doucement arqués (apparaissent progressivement)
    if (t > 0.1) {
      final browOpacity = ((t - 0.1) / 0.9).clamp(0.0, 1.0);
      final browLen = r * 0.22;
      final browY = center.dy - r * 0.28;
      _drawEyebrow(
        canvas,
        Offset(center.dx - r * 0.25, browY),
        browLen,
        isLeft: true,
        curve: t * r * 0.08,
        thickness: sw * 0.8,
        opacity: browOpacity,
      );
      _drawEyebrow(
        canvas,
        Offset(center.dx + r * 0.25, browY),
        browLen,
        isLeft: false,
        curve: t * r * 0.08,
        thickness: sw * 0.8,
        opacity: browOpacity,
      );
    }

    // Bouche : neutre → sourire → grand sourire ouvert (>0.5)
    final mouthPos = Offset(center.dx, center.dy + r * 0.28);
    final mouthW = r * (0.25 + t * 0.15); // s'élargit avec l'intensité
    final openness = t > 0.5 ? (t - 0.5) / 0.5 : 0.0;
    _drawMouth(canvas, mouthPos, mouthW,
        smile: t, openness: openness * 0.5, thickness: sw);

    // Extras : étincelles (>0.7)
    if (t > 0.7) {
      _drawSparkles(canvas, center, r, (t - 0.7) / 0.3);
    }
  }

  /// Petites étincelles rayonnantes autour du visage
  static void _drawSparkles(
      Canvas canvas, Offset center, double r, double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: clampedProgress * 0.8)
      ..strokeWidth = (r * 0.03).clamp(0.5, 2.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const count = 6;
    final sparkR = r * 0.85;
    final sparkLen = r * 0.08 * clampedProgress;

    for (int i = 0; i < count; i++) {
      final angle =
          -math.pi / 2 + i * 2 * math.pi / count + math.pi / count;
      final inner = Offset(
        center.dx + sparkR * math.cos(angle),
        center.dy + sparkR * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (sparkR + sparkLen) * math.cos(angle),
        center.dy + (sparkR + sparkLen) * math.sin(angle),
      );
      // Ligne radiale
      canvas.drawLine(inner, outer, paint);
      // Petit point lumineux au bout
      canvas.drawCircle(
        outer,
        (r * 0.02).clamp(0.5, 1.5),
        Paint()..color = const Color(0xFFFBBF24).withValues(alpha: clampedProgress * 0.8),
      );
    }
  }
}

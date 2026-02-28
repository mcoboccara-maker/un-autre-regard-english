// parametric_emotion_face_v2.dart
// Visages paramétriques (Canvas) pour 18 émotions — traits accentués par intensité 0.0→1.0
// Règles: yeux identiques (forme/taille/position), style minimal flat, traits teal.
// NOTE: ce fichier remplace/complète parametric_emotion_face.dart (prototype 3 émotions).

import 'package:flutter/material.dart';

class ParametricEmotionFaceV2 {
  ParametricEmotionFaceV2._();

  static const supported = <String>{
    'BLESSE',
    'CONFUS',
    'CRITIQUE',
    'DEPRIME',
    'EFFRAYE',
    'EN_COLERE',
    'IMPUISSANT',
    'INDIFFERENT',
    'TRISTE',
    'AIMANT',
    'DETENDU',
    'FORT',
    'HEUREUX',
    'INTERESSE',
    'OUVERT',
    'PAISIBLE',
    'POSITIF',
    'VIVANT',
  };

  static bool isSupported(String key) => supported.contains(key);

  // --- Style (teal)
  static const Color strokeColor = Color(0xFF2DD4BF); // teal/menthe
  static const Color strokeSoft = Color(0xFF2DD4BF);
  static const double eyeX = 0.30;
  static const double eyeY = -0.10;
  static const double eyeR = 0.065;

  static void draw(Canvas canvas, Offset center, double radius, String key, double intensity) {
    final t = intensity.clamp(0.0, 1.0);
    _drawFaceCircle(canvas, center, radius, t);

    switch (key) {
      case 'EN_COLERE':   _angry(canvas, center, radius, t);
      case 'BLESSE':      _hurt(canvas, center, radius, t);
      case 'HEUREUX':     _happy(canvas, center, radius, t);

      case 'TRISTE':      _sad(canvas, center, radius, t);
      case 'DEPRIME':     _depressed(canvas, center, radius, t);
      case 'EFFRAYE':     _afraid(canvas, center, radius, t);
      case 'CONFUS':      _confused(canvas, center, radius, t);
      case 'IMPUISSANT':  _powerless(canvas, center, radius, t);
      case 'INDIFFERENT': _indifferent(canvas, center, radius, t);
      case 'CRITIQUE':    _critical(canvas, center, radius, t);

      case 'AIMANT':      _loving(canvas, center, radius, t);
      case 'DETENDU':     _relaxed(canvas, center, radius, t);
      case 'PAISIBLE':    _peaceful(canvas, center, radius, t);
      case 'OUVERT':      _open(canvas, center, radius, t);
      case 'INTERESSE':   _interested(canvas, center, radius, t);
      case 'POSITIF':     _positive(canvas, center, radius, t);
      case 'VIVANT':      _alive(canvas, center, radius, t);
      case 'FORT':        _strong(canvas, center, radius, t);
      default:            _neutral(canvas, center, radius, t);
    }
  }

  // ----------------- Primitives (yeux identiques) -----------------

  static Paint _stroke(double r, double t, {double a = 0.65}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = strokeColor.withValues(alpha: a)
    ..strokeWidth = (r * (0.085 + 0.12 * t)).clamp(1.0, 7.0);

  static Paint _fill(double r, double t, {double a = 0.70}) => Paint()
    ..style = PaintingStyle.fill
    ..color = strokeColor.withValues(alpha: a);

  static void _drawFaceCircle(Canvas canvas, Offset c, double r, double t) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * (0.12)).clamp(1.0, 7.0)
      ..color = strokeSoft.withValues(alpha: 0.20 + 0.10 * t);
    canvas.drawCircle(c, r, ring);
  }

  static void _eyes(Canvas canvas, Offset c, double r) {
    final p = _fill(r, 0.0, a: 0.65);
    canvas.drawCircle(c + Offset(-r * eyeX, r * eyeY), r * eyeR, p);
    canvas.drawCircle(c + Offset( r * eyeX, r * eyeY), r * eyeR, p);
  }

  static void _brows(Canvas canvas, Offset c, double r, double t,
      {required double leftSlope, required double rightSlope, double y = 0.32, double lift = 0.0}) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (r * (0.06 + 0.11 * t)).clamp(1.0, 7.0)
      ..color = strokeColor.withValues(alpha: 0.40 + 0.35 * t);

    // left brow
    final ly = -r * (y + lift * t);
    canvas.drawLine(
      c + Offset(-r * (0.42), ly + r * leftSlope * 0.12),
      c + Offset(-r * (0.12), ly - r * leftSlope * 0.12),
      p,
    );
    // right brow
    final ry = -r * (y + lift * t);
    canvas.drawLine(
      c + Offset( r * (0.42), ry + r * rightSlope * 0.12),
      c + Offset( r * (0.12), ry - r * rightSlope * 0.12),
      p,
    );
  }

  static void _mouthArc(Canvas canvas, Offset c, double r, double t,
      {required double smile, double y = 0.24, double width = 0.30, double open = 0.0}) {
    // smile: -1 frown .. +1 smile
    final p = _stroke(r, t, a: 0.65);
    final yy = r * y;
    final w = r * width;
    final h = r * (0.16 * smile);
    final o = r * (0.08 * open * t);
    final path = Path()
      ..moveTo(c.dx - w, c.dy + yy - o)
      ..quadraticBezierTo(c.dx, c.dy + yy + h + o, c.dx + w, c.dy + yy - o);
    canvas.drawPath(path, p);
  }

  static void _cheeks(Canvas canvas, Offset c, double r, double t, {double a = 0.18}) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.05).clamp(1.0, 5.0)
      ..color = strokeColor.withValues(alpha: a + 0.10 * t);
    canvas.drawArc(Rect.fromCircle(center: c + Offset(-r*0.35, r*0.05), radius: r*0.18), 0.2, 1.2, false, p);
    canvas.drawArc(Rect.fromCircle(center: c + Offset( r*0.35, r*0.05), radius: r*0.18), 1.7, 1.2, false, p);
  }

  static void _tearlessDroop(Canvas canvas, Offset c, double r, double t) {
    // petite courbe sous yeux (sans larmes)
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (r * (0.04 + 0.08 * t)).clamp(1.0, 6.0)
      ..color = strokeColor.withValues(alpha: 0.20 + 0.25 * t);
    final y = -r * 0.00;
    canvas.drawArc(Rect.fromCircle(center: c + Offset(-r*0.30, y), radius: r*0.12), 0.2, 1.0, false, p);
    canvas.drawArc(Rect.fromCircle(center: c + Offset( r*0.30, y), radius: r*0.12), 1.9, 1.0, false, p);
  }

  // ----------------- Expressions (18) -----------------

  static void _neutral(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.0, rightSlope: 0.0);
    _mouthArc(canvas, c, r, t, smile: 0.0, y: 0.24, width: 0.28);
  }

  static void _angry(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 1.0, rightSlope: -1.0, lift: -0.10);
    _mouthArc(canvas, c, r, t, smile: -0.75, y: 0.22, width: 0.30, open: 0.35);
  }

  static void _hurt(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.6, rightSlope: -0.6, lift: 0.18);
    _tearlessDroop(canvas, c, r, t);
    _mouthArc(canvas, c, r, t, smile: -0.55, y: 0.26, width: 0.26);
  }

  static void _happy(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.2, rightSlope: 0.2, lift: 0.25);
    _cheeks(canvas, c, r, t, a: 0.16);
    _mouthArc(canvas, c, r, t, smile: 0.95, y: 0.22, width: 0.34, open: 0.20);
  }

  static void _sad(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.8, rightSlope: 0.8, lift: 0.12);
    _tearlessDroop(canvas, c, r, t);
    _mouthArc(canvas, c, r, t, smile: -0.70, y: 0.28, width: 0.28);
  }

  static void _depressed(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.2, rightSlope: 0.2, lift: -0.05);
    _mouthArc(canvas, c, r, t, smile: -0.25, y: 0.32, width: 0.26);
    _tearlessDroop(canvas, c, r, t*0.6);
  }

  static void _afraid(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.2, rightSlope: 0.2, lift: 0.35);
    _mouthArc(canvas, c, r, t, smile: -0.15, y: 0.22, width: 0.18, open: 0.85);
  }

  static void _confused(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    // un sourcil relevé
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (r * (0.06 + 0.11 * t)).clamp(1.0, 7.0)
      ..color = strokeColor.withValues(alpha: 0.40 + 0.35 * t);
    final y = -r * (0.32 + 0.12 * t);
    canvas.drawLine(c + Offset(-r*0.42, y), c + Offset(-r*0.12, y + r*0.10), p); // gauche incliné
    canvas.drawLine(c + Offset( r*0.42, -r*0.30), c + Offset( r*0.12, -r*0.30), p); // droit plat
    _mouthArc(canvas, c, r, t, smile: 0.10, y: 0.26, width: 0.22);
  }

  static void _powerless(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.6, rightSlope: 0.6, lift: 0.08);
    _mouthArc(canvas, c, r, t, smile: -0.55, y: 0.30, width: 0.22);
  }

  static void _indifferent(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.0, rightSlope: 0.0, lift: -0.10);
    _mouthArc(canvas, c, r, t, smile: 0.0, y: 0.26, width: 0.24);
  }

  static void _critical(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.9, rightSlope: -0.9, lift: 0.05);
    _mouthArc(canvas, c, r, t, smile: -0.35, y: 0.24, width: 0.22);
  }

  static void _loving(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.2, rightSlope: 0.2, lift: 0.22);
    _cheeks(canvas, c, r, t, a: 0.14);
    _mouthArc(canvas, c, r, t, smile: 0.70, y: 0.24, width: 0.30);
  }

  static void _relaxed(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.0, rightSlope: 0.0, lift: 0.10);
    _mouthArc(canvas, c, r, t, smile: 0.25, y: 0.26, width: 0.28);
  }

  static void _peaceful(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.0, rightSlope: 0.0, lift: 0.18);
    _mouthArc(canvas, c, r, t, smile: 0.30, y: 0.26, width: 0.24);
  }

  static void _open(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.1, rightSlope: 0.1, lift: 0.28);
    _mouthArc(canvas, c, r, t, smile: 0.45, y: 0.24, width: 0.28, open: 0.15);
  }

  static void _interested(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.2, rightSlope: 0.0, lift: 0.22);
    _mouthArc(canvas, c, r, t, smile: 0.20, y: 0.24, width: 0.22);
  }

  static void _positive(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.1, rightSlope: 0.1, lift: 0.24);
    _cheeks(canvas, c, r, t, a: 0.12);
    _mouthArc(canvas, c, r, t, smile: 0.65, y: 0.24, width: 0.30);
  }

  static void _alive(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: -0.2, rightSlope: 0.2, lift: 0.34);
    _mouthArc(canvas, c, r, t, smile: 0.85, y: 0.22, width: 0.34, open: 0.35);
  }

  static void _strong(Canvas canvas, Offset c, double r, double t) {
    _eyes(canvas, c, r);
    _brows(canvas, c, r, t, leftSlope: 0.2, rightSlope: -0.2, lift: -0.08);
    _mouthArc(canvas, c, r, t, smile: 0.35, y: 0.24, width: 0.26);
    // petit "menton" (line), discret
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (r * (0.04 + 0.08*t)).clamp(1.0, 6.0)
      ..color = strokeColor.withValues(alpha: 0.18 + 0.25*t);
    canvas.drawLine(c + Offset(-r*0.07, r*0.48), c + Offset(r*0.07, r*0.48), p);
  }
}

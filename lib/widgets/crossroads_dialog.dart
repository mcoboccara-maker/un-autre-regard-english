// lib/widgets/crossroads_dialog.dart
// Carrefour des inspirations – scène illustrée interactive

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SourceItem {
  final String label;
  final String asset;
  const SourceItem(this.label, this.asset);
}

class CrossroadsDialog extends StatefulWidget {
  const CrossroadsDialog({super.key});

  static Future<List<String>?> show(BuildContext context) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CrossroadsDialog(),
    );
  }

  @override
  State<CrossroadsDialog> createState() => _CrossroadsDialogState();
}

class _CrossroadsDialogState extends State<CrossroadsDialog>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  String? _hoveredPath;

  // 3 familles visuelles : temple / forêt / bibliothèque
  static const List<SourceItem> spiritualites = [
    SourceItem('Judaism', 'judaisme.png'),
    SourceItem('Mussar', 'moussar.png'),
    SourceItem('Theravāda', 'theravada.png'),
    SourceItem('Zen', 'zen.png'),
    SourceItem('Advaita Vedānta', 'advaita_vedanta.png'),
    SourceItem('Bhakti', 'bhakti.png'),
    SourceItem('Sufism', 'soufisme.png'),
  ];

  static const List<SourceItem> introspection = [
    SourceItem('Ancient Philosophy', 'philo_antique.png'),
    SourceItem('Modern Philosophy', 'philo_moderne.png'),
    SourceItem('Psychology', 'psychologie.png'),
    SourceItem('Jungian', 'jungienne.png'),
  ];

  static const List<SourceItem> textes = [
    SourceItem('Poetry', 'poesie.png'),
    SourceItem('Sacred Texts', 'textes_sacres.png'),
    SourceItem('Romanticism', 'romantisme.png'),
    SourceItem('Realism', 'realisme.png'),
  ];

  void _pickFrom(List<SourceItem> list) {
    final pick = list[_random.nextInt(list.length)];
    Navigator.of(context).pop(<String>[pick.label]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.75),
      body: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            height: 420,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F1117),
                  Color(0xFF171823),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF444857),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // Scène
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CrossroadsPainter(hoveredPath: _hoveredPath),
                    ),
                  ),

                  // Titre / texte
                  Positioned(
                    top: 16,
                    left: 18,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crossroads of Inspirations',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a path. A different source awaits you.',
                          style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zones cliquables
                  Positioned.fill(
                    child: Column(
                      children: [
                        const Spacer(flex: 7),
                        Expanded(
                          flex: 11,
                          child: Row(
                            children: [
                              const Spacer(),
                              _buildPathHitBox(
                                id: 'spiritualites',
                                onTap: () => _pickFrom(spiritualites),
                                alignment: Alignment.topLeft,
                              ),
                              const Spacer(),
                              _buildPathHitBox(
                                id: 'introspection',
                                onTap: () => _pickFrom(introspection),
                                alignment: Alignment.topCenter,
                              ),
                              const Spacer(),
                              _buildPathHitBox(
                                id: 'textes',
                                onTap: () => _pickFrom(textes),
                                alignment: Alignment.topRight,
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        const Spacer(flex: 6),
                      ],
                    ),
                  ),

                  // Légendes sur les chemins
                  _buildPathLabel(
                    id: 'spiritualites',
                    text: 'Spiritualities',
                    subtitle: 'Judaism, mussar,\ntraditions',
                    alignment: const Alignment(-0.75, -0.2),
                  ),
                  _buildPathLabel(
                    id: 'introspection',
                    text: 'Introspection',
                    subtitle: 'Philosophy,\npsychology',
                    alignment: const Alignment(0.0, -0.1),
                  ),
                  _buildPathLabel(
                    id: 'textes',
                    text: 'Texts & Poetry',
                    subtitle: 'Poems, stories,\nclassics',
                    alignment: const Alignment(0.75, -0.2),
                  ),

                  // Bouton fermer
                  Positioned(
                    top: 12,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPathHitBox({
    required String id,
    required VoidCallback onTap,
    required Alignment alignment,
  }) {
    return Align(
      alignment: alignment,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredPath = id),
        onExit: (_) => setState(() => _hoveredPath = null),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: SizedBox(
            width: 80,
            height: 80,
          ),
        ),
      ),
    );
  }

  Widget _buildPathLabel({
    required String id,
    required String text,
    required String subtitle,
    required Alignment alignment,
  }) {
    final isHovered = _hoveredPath == id;
    return Align(
      alignment: alignment,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isHovered ? 1.06 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isHovered ? 1.0 : 0.86,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHovered
                    ? const Color(0xFFF0D598)
                    : Colors.white.withOpacity(0.28),
                width: 1,
              ),
            ),
            child: DefaultTextStyle(
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 11,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9.5, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossroadsPainter extends CustomPainter {
  final String? hoveredPath;
  const _CrossroadsPainter({required this.hoveredPath});

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintGround(canvas, size);
    _paintPaths(canvas, size);
    _paintDestinations(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF151829),
          Color(0xFF25273A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Halo lointain
    final haloPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, 0.0),
        radius: 0.6,
        colors: [
          Color(0xFFFAE2B3),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, haloPaint);
  }

  void _paintGround(Canvas canvas, Size size) {
    final rect =
        Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2A261E),
          Color(0xFF1A160F),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Texture légère
    final grain = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1;
    for (int i = 0; i < 40; i++) {
      final dx = (i / 40.0) * size.width;
      canvas.drawLine(
        Offset(dx, size.height * 0.45),
        Offset(dx + 12, size.height),
        grain,
      );
    }
  }

  void _paintPaths(Canvas canvas, Size size) {
    final baseY = size.height * 0.65;
    final baseX = size.width * 0.5;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE2D0A7).withOpacity(0.9);

    // Chemin central (introspection)
    final pathCenter = Path()
      ..moveTo(baseX - 16, baseY)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.52,
        size.height * 0.28,
      )
      ..lineTo(size.width * 0.58, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.5,
        baseX + 16,
        baseY,
      )
      ..close();
    canvas.drawPath(pathCenter, paint);

    // Chemin gauche (spiritualités)
    final pathLeft = Path()
      ..moveTo(baseX - 18, baseY)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.55,
        size.width * 0.22,
        size.height * 0.32,
      )
      ..lineTo(size.width * 0.16, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.58,
        baseX - 30,
        baseY + 4,
      )
      ..close();
    canvas.drawPath(pathLeft, paint..color = const Color(0xFFDCC594));

    // Chemin droit (textes)
    final pathRight = Path()
      ..moveTo(baseX + 18, baseY)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.55,
        size.width * 0.80,
        size.height * 0.32,
      )
      ..lineTo(size.width * 0.86, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.58,
        baseX + 32,
        baseY + 4,
      )
      ..close();
    canvas.drawPath(pathRight, paint..color = const Color(0xFFE8D5A8));

    // Lueur sur le centre du carrefour
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF7E2B4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(baseX, baseY),
        radius: 40,
      ));
    canvas.drawCircle(Offset(baseX, baseY), 40, glowPaint);
  }

  void _paintDestinations(Canvas canvas, Size size) {
    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Temple (spiritualités)
    final templeCenter = Offset(size.width * 0.18, size.height * 0.28);
    _drawTemple(canvas, templeCenter, 20, iconPaint);

    // Arbre (introspection)
    final treeCenter = Offset(size.width * 0.5, size.height * 0.24);
    _drawTree(canvas, treeCenter, 22, iconPaint);

    // Bibliothèque (textes)
    final libCenter = Offset(size.width * 0.82, size.height * 0.28);
    _drawLibrary(canvas, libCenter, 20, iconPaint);
  }

  void _drawTemple(
      Canvas canvas, Offset center, double size, Paint basePaint) {
    final p = Paint()
      ..color = basePaint.color
      ..style = PaintingStyle.fill;

    final w = size;
    final h = size * 0.8;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawRect(rect, p);

    final roof = Path()
      ..moveTo(center.dx - w * 0.6, rect.top)
      ..lineTo(center.dx, rect.top - size * 0.6)
      ..lineTo(center.dx + w * 0.6, rect.top)
      ..close();
    canvas.drawPath(roof, p);

    final door = Rect.fromCenter(
      center: Offset(center.dx, rect.bottom - h * 0.25),
      width: w * 0.22,
      height: h * 0.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, Radius.circular(w * 0.12)),
      Paint()..color = Colors.black.withOpacity(0.35),
    );
  }

  void _drawTree(Canvas canvas, Offset center, double size, Paint basePaint) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF4F3A27)
      ..style = PaintingStyle.fill;

    final trunkRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size * 0.2),
      width: size * 0.26,
      height: size * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunkRect, Radius.circular(size * 0.12)),
      trunkPaint,
    );

    final foliagePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF8DC47B),
          Color(0xFF3D6D3A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size * 0.9));
    canvas.drawCircle(center, size * 0.9, foliagePaint);
  }

  void _drawLibrary(
      Canvas canvas, Offset center, double size, Paint basePaint) {
    final shelfPaint = Paint()
      ..color = const Color(0xFF3F2E22)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: center,
      width: size * 1.2,
      height: size * 0.9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4)),
      shelfPaint,
    );

    final bookPaint1 = Paint()..color = const Color(0xFFE8D29B);
    final bookPaint2 = Paint()..color = const Color(0xFFCC8E78);
    final shelfY1 = rect.top + rect.height * 0.25;
    final shelfY2 = rect.top + rect.height * 0.63;

    canvas.drawLine(
      Offset(rect.left + 4, shelfY1),
      Offset(rect.right - 4, shelfY1),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(rect.left + 4, shelfY2),
      Offset(rect.right - 4, shelfY2),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1,
    );

    canvas.drawRect(
      Rect.fromLTWH(rect.left + 6, rect.top + 4, 6, rect.height * 0.38),
      bookPaint1,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 16, rect.top + 4, 5, rect.height * 0.38),
      bookPaint2,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 26, rect.top + rect.height * 0.29, 5,
          rect.height * 0.38),
      bookPaint1,
    );
  }

  @override
  bool shouldRepaint(covariant _CrossroadsPainter oldDelegate) {
    return oldDelegate.hoveredPath != hoveredPath;
  }
}

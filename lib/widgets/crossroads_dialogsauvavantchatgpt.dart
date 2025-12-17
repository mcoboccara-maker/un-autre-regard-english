// lib/widgets/crossroads_dialog.dart
// Carrefour des Inspirations - Style paysage désertique réaliste
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

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
    with TickerProviderStateMixin {
  
  static const List<SourceItem> philosophyItems = [
    SourceItem('Stoïcisme', 'stoicisme.png'),
    SourceItem('Épicurisme', 'epicurisme.png'),
    SourceItem('Existentialisme', 'existentialisme.png'),
    SourceItem('Cynisme', 'cynisme.png'),
    SourceItem('Marc Aurèle', 'marc_aurele.png'),
    SourceItem('Épictète', 'epictete.png'),
    SourceItem('Sénèque', 'seneque.png'),
    SourceItem('Nietzsche', 'nietzsche.png'),
    SourceItem('Camus', 'camus.png'),
    SourceItem('Sartre', 'sartre.png'),
    SourceItem('Platon', 'platon.png'),
    SourceItem('Aristote', 'aristote.png'),
  ];

  static const List<SourceItem> psychologyItems = [
    SourceItem('TCC', 'TCC.png'),
    SourceItem('Logothérapie', 'logotherapie_frankl.png'),
    SourceItem('Schémas Young', 'schemas_young.png'),
    SourceItem('Jungienne', 'jungienne.png'),
    SourceItem('Pleine Conscience', 'pleine_conscience.png'),
    SourceItem('The Work', 'theworkkb.png'),
  ];

  static const List<SourceItem> literatureItems = [
    SourceItem('Poésie', 'poesie.png'),
    SourceItem('Romantisme', 'romantisme.png'),
    SourceItem('Réalisme', 'realisme.png'),
    SourceItem('Symbolisme', 'symbolisme.png'),
    SourceItem('Modernisme', 'modernisme.png'),
    SourceItem('Tragédie', 'tragedie_classique.png'),
  ];

  late AnimationController _spinController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool _isSpinning = false;
  bool _hasSpun = false;
  int _rebuildKey = 0;

  int _target1 = 0;
  int _target2 = 0;
  int _target3 = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    _target1 = _random.nextInt(philosophyItems.length);
    _target2 = _random.nextInt(psychologyItems.length);
    _target3 = _random.nextInt(literatureItems.length);

    setState(() {
      _rebuildKey++;
      _isSpinning = true;
      _hasSpun = false;
    });

    _spinController.reset();
    _spinController.forward();

    await Future.delayed(const Duration(milliseconds: 2700));

    if (mounted) {
      setState(() {
        _isSpinning = false;
        _hasSpun = true;
      });
    }
  }

  List<String> _getSelectedSources() {
    return [
      philosophyItems[_target1].name,
      psychologyItems[_target2].name,
      literatureItems[_target3].name,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 380,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              // FOND BLEU CLAIR MARBRÉ
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA),  // Cyan très clair
                  Color(0xFFB2EBF2),  // Cyan clair
                  Color(0xFF80DEEA),  // Cyan
                  Color(0xFFB2DFDB),  // Teal très clair
                  Color(0xFFE0F2F1),  // Teal clair
                  Color(0xFFE8F5E9),  // Vert très clair
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.amber.withOpacity(_glowAnimation.value),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(_glowAnimation.value * 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildLandscape(),
                  const SizedBox(height: 16),
                  _buildButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.blueGrey[700], size: 20),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚏', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'CARREFOUR DES INSPIRATIONS',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Laissez le destin guider vos pas...',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.blueGrey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscape() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Fond paysage désertique
            CustomPaint(
              size: const Size(380, 300),
              painter: DesertLandscapePainter(),
            ),
            
            // Les 3 panneaux en bois sur poteaux
            AnimatedBuilder(
              animation: _spinController,
              builder: (context, child) {
                return Stack(
                  key: ValueKey('signs_$_rebuildKey'),
                  children: [
                    // Panneau gauche - Philosophie
                    Positioned(
                      left: 30,
                      top: 80,
                      child: _buildWoodenSignPost(
                        label: 'Philosophie',
                        item: philosophyItems[_target1],
                        color: const Color(0xFF8B4513),
                        textColor: const Color(0xFF3E2723),
                        rotation: _isSpinning ? _spinController.value * 6 * pi : 0,
                        items: philosophyItems,
                        direction: SignDirection.left,
                      ),
                    ),
                    
                    // Panneau droite - Psychologie
                    Positioned(
                      right: 30,
                      top: 80,
                      child: _buildWoodenSignPost(
                        label: 'Psychologie',
                        item: psychologyItems[_target2],
                        color: const Color(0xFF6D4C41),
                        textColor: const Color(0xFF3E2723),
                        rotation: _isSpinning ? _spinController.value * 7 * pi : 0,
                        items: psychologyItems,
                        direction: SignDirection.right,
                      ),
                    ),
                    
                    // Panneau centre bas - Littérature
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 40,
                      child: Center(
                        child: _buildWoodenSignPost(
                          label: 'Littérature',
                          item: literatureItems[_target3],
                          color: const Color(0xFF795548),
                          textColor: const Color(0xFF3E2723),
                          rotation: _isSpinning ? _spinController.value * 8 * pi : 0,
                          items: literatureItems,
                          direction: SignDirection.center,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWoodenSignPost({
    required String label,
    required SourceItem item,
    required Color color,
    required Color textColor,
    required double rotation,
    required List<SourceItem> items,
    required SignDirection direction,
  }) {
    final displayIndex = _isSpinning
        ? ((rotation / (2 * pi) * items.length) % items.length).floor().clamp(0, items.length - 1)
        : items.indexOf(item);
    final displayItem = items[displayIndex];

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(_isSpinning ? rotation * 0.3 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panneau en bois avec forme de flèche
          CustomPaint(
            painter: WoodenArrowPainter(
              color: color,
              direction: direction,
            ),
            child: Container(
              width: direction == SignDirection.center ? 140 : 120,
              height: 50,
              padding: EdgeInsets.only(
                left: direction == SignDirection.right ? 8 : 14,
                right: direction == SignDirection.left ? 8 : 14,
                top: 6,
                bottom: 6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Label
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Nom de la source
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(
                            'assets/univers_visuel/${displayItem.icon}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                displayItem.name.substring(0, 1),
                                style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          displayItem.name,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Poteau en bois
          Container(
            width: 8,
            height: direction == SignDirection.center ? 50 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.brown[700]!,
                  Colors.brown[500]!,
                  Colors.brown[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Bouton Explorer
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSpinning ? null : _spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.brown[900],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSpinning)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.brown[900]),
                  )
                else
                  Icon(Icons.explore, size: 22, color: Colors.brown[900]),
                const SizedBox(width: 10),
                Text(
                  _isSpinning ? 'Le destin tourne...' : '🧭 EXPLORER !',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                ),
              ],
            ),
          ),
        ),

        if (_hasSpun) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  '🌟 Votre chemin est tracé :',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey[700], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildChip(philosophyItems[_target1].name, Colors.brown[600]!),
                    _buildChip(psychologyItems[_target2].name, Colors.teal[600]!),
                    _buildChip(literatureItems[_target3].name, Colors.green[600]!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _getSelectedSources()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_walk, size: 20),
                  const SizedBox(width: 8),
                  Text('Suivre ce chemin', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum SignDirection { left, right, center }

/// Painter pour le panneau en bois en forme de flèche
class WoodenArrowPainter extends CustomPainter {
  final Color color;
  final SignDirection direction;

  WoodenArrowPainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.9),
          color,
          color.withOpacity(0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    const arrowTip = 15.0;

    if (direction == SignDirection.left) {
      // Flèche pointant vers la gauche
      path.moveTo(arrowTip, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(arrowTip, size.height);
      path.lineTo(0, size.height / 2);
      path.close();
    } else if (direction == SignDirection.right) {
      // Flèche pointant vers la droite
      path.moveTo(0, 0);
      path.lineTo(size.width - arrowTip, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - arrowTip, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Panneau rectangulaire avec coins arrondis pour le centre
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ));
    }

    // Ombre
    canvas.drawPath(path.shift(const Offset(2, 2)), shadowPaint);
    // Panneau
    canvas.drawPath(path, paint);

    // Effet de bois (lignes horizontales)
    final woodGrainPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1;

    for (double y = 8; y < size.height - 5; y += 12) {
      canvas.drawLine(
        Offset(direction == SignDirection.left ? arrowTip + 5 : 5, y),
        Offset(direction == SignDirection.right ? size.width - arrowTip - 5 : size.width - 5, y),
        woodGrainPaint,
      );
    }

    // Bordure
    final borderPaint = Paint()
      ..color = Colors.brown[900]!.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter pour le paysage désertique avec montagnes
class DesertLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ciel dégradé
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB),  // Bleu ciel clair
          Color(0xFFB0E0E6),  // Bleu poudré
          Color(0xFFF5DEB3),  // Blé (horizon)
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6), skyPaint);

    // Montagnes lointaines (gauche)
    final mountainPaint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mountain1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.15, size.height * 0.25)
      ..lineTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(0, size.height * 0.5)
      ..close();
    canvas.drawPath(mountain1, mountainPaint1);

    // Montagnes lointaines (droite)
    final mountain2 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.3)
      ..lineTo(size.width * 0.85, size.height * 0.35)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..close();
    canvas.drawPath(mountain2, mountainPaint1);

    // Sol désertique
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD2B48C),  // Tan
          Color(0xFFC19A6B),  // Camel
          Color(0xFFCD853F),  // Peru
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55));
    
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55), groundPaint);

    // Routes vers l'horizon
    _drawRoad(canvas, size, size.width / 2, size.height * 0.5, size.width * 0.2, size.height * 0.35, 30, 8);
    _drawRoad(canvas, size, size.width / 2, size.height * 0.5, size.width * 0.8, size.height * 0.35, 30, 8);
    _drawRoad(canvas, size, size.width / 2, size.height * 0.5, size.width / 2, size.height, 25, 40);

    // Rond-point central
    final roundaboutPaint = Paint()..color = const Color(0xFF696969);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.52), 20, roundaboutPaint);
    
    final roundaboutBorder = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.52), 20, roundaboutBorder);

    // Quelques touffes d'herbe sèche
    _drawGrassTuft(canvas, size.width * 0.1, size.height * 0.7);
    _drawGrassTuft(canvas, size.width * 0.85, size.height * 0.65);
    _drawGrassTuft(canvas, size.width * 0.15, size.height * 0.85);
    _drawGrassTuft(canvas, size.width * 0.9, size.height * 0.8);

    // Nuages
    _drawCloud(canvas, size.width * 0.15, size.height * 0.1, 25);
    _drawCloud(canvas, size.width * 0.7, size.height * 0.08, 30);
    _drawCloud(canvas, size.width * 0.45, size.height * 0.15, 20);
  }

  void _drawRoad(Canvas canvas, Size size, double startX, double startY, double endX, double endY, double startWidth, double endWidth) {
    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF505050),
          const Color(0xFF606060),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(startX - startWidth / 2, startY);
    path.lineTo(endX - endWidth / 2, endY);
    path.lineTo(endX + endWidth / 2, endY);
    path.lineTo(startX + startWidth / 2, startY);
    path.close();

    canvas.drawPath(path, roadPaint);

    // Ligne centrale jaune
    final linePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.7)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      linePaint,
    );
  }

  void _drawGrassTuft(Canvas canvas, double x, double y) {
    final grassPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(x + i * 3, y),
        Offset(x + i * 2, y - 8 - (i.abs() * 2)),
        grassPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double size) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(x, y), size * 0.5, cloudPaint);
    canvas.drawCircle(Offset(x + size * 0.4, y - size * 0.1), size * 0.4, cloudPaint);
    canvas.drawCircle(Offset(x + size * 0.7, y + size * 0.05), size * 0.35, cloudPaint);
    canvas.drawCircle(Offset(x - size * 0.3, y + size * 0.05), size * 0.35, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SourceItem {
  final String name;
  final String icon;

  const SourceItem(this.name, this.icon);
}

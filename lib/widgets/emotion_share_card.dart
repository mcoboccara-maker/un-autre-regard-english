// lib/widgets/emotion_share_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/mood_entry.dart';
import '../config/emotion_config.dart';

/// Widget de carte de partage elegante pour les emotions
/// Design : fond bleu degrade, radar circulaire avec emojis, info-bulle centrale
class EmotionShareCard extends StatefulWidget {
  final DateTime date;
  final Map<String, EmotionDetail> emotions;
  final VoidCallback? onShareComplete;
  final bool showShareButton;

  const EmotionShareCard({
    super.key,
    required this.date,
    required this.emotions,
    this.onShareComplete,
    this.showShareButton = true,
  });

  @override
  State<EmotionShareCard> createState() => _EmotionShareCardState();
}

class _EmotionShareCardState extends State<EmotionShareCard> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;
  String? _selectedEmotionKey;

  // Mapping emoji pour chaque emotion
  static const Map<String, String> _emotionEmojis = {
    'blesse': '😢',
    'confus': '😕',
    'critique': '🤨',
    'deprime': '😞',
    'effraye': '😨',
    'encolere': '😠',
    'impuissant': '😔',
    'triste': '😢',
    'aimant': '🥰',
    'detendu': '😌',
    'paisible': '🕊️',
    'ouvert': '😊',
    'tourmente': '😣',
    'inquiet': '😟',
    'isole': '😶',
    'positif': '😍',
    'interesse': '🤩',
    'heureux': '😄',
    'vivant': '✨',
    'fort': '💪',
    'indifferent': '😐',
  };

  // Top 3 emotions pour l'affichage en bas
  List<MapEntry<String, EmotionDetail>> get _topEmotions {
    final sorted = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList()
      ..sort((a, b) => b.value.intensity.compareTo(a.value.intensity));
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carte a capturer pour le partage
        RepaintBoundary(
          key: _cardKey,
          child: _buildShareableCard(),
        ),
        
        if (widget.showShareButton) ...[
          const SizedBox(height: 24),
          _buildShareButton(),
        ],
      ],
    );
  }

  Widget _buildShareableCard() {
    final dateStr = _formatDate(widget.date);
    
    return Container(
      width: 380,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        // Degrade bleu plus clair
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A365D),  // Bleu nuit en haut
            Color(0xFF2A4A7F),  // Bleu moyen
            Color(0xFF3B5998),  // Bleu plus clair en bas
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          _buildTitle(dateStr),
          
          const SizedBox(height: 24),
          
          // Radar circulaire avec emojis
          _buildCircularRadar(),
          
          const SizedBox(height: 24),
          
          // Top 3 emotions
          _buildTopEmotions(),
          
          const SizedBox(height: 16),
          
          // Footer branding
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTitle(String dateStr) {
    return Column(
      children: [
        Text(
          'MON ÉTAT',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        Text(
          'ÉMOTIONNEL',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateStr,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularRadar() {
    final activeEmotions = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList();

    return SizedBox(
      width: 320,
      height: 320,
      child: GestureDetector(
        onTapDown: (details) => _handleTap(details.localPosition, activeEmotions),
        onTapUp: (_) => setState(() => _selectedEmotionKey = null),
        onTapCancel: () => setState(() => _selectedEmotionKey = null),
        onPanUpdate: (details) => _handleTap(details.localPosition, activeEmotions),
        onPanEnd: (_) => setState(() => _selectedEmotionKey = null),
        child: CustomPaint(
          painter: _RadarPainter(
            emotions: widget.emotions,
            emotionEmojis: _emotionEmojis,
            selectedEmotionKey: _selectedEmotionKey,
          ),
          child: Center(
            child: _buildCenterInfo(),
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position, List<MapEntry<String, EmotionDetail>> activeEmotions) {
    final center = const Offset(160, 160);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Si on est dans la zone du radar
    if (distance > 30 && distance < 140 && activeEmotions.isNotEmpty) {
      // Calculer l'angle
      var angle = math.atan2(dy, dx) + math.pi / 2;
      if (angle < 0) angle += 2 * math.pi;
      
      final sectionAngle = 2 * math.pi / activeEmotions.length;
      final index = (angle / sectionAngle).floor() % activeEmotions.length;
      setState(() {
        _selectedEmotionKey = activeEmotions[index].key;
      });
    }
  }

  Widget _buildCenterInfo() {
    String? keyToShow = _selectedEmotionKey;
    
    // Si aucune selection, montrer l'emotion dominante
    if (keyToShow == null && _topEmotions.isNotEmpty) {
      keyToShow = _topEmotions.first.key;
    }
    
    if (keyToShow == null) return const SizedBox.shrink();

    final emotion = widget.emotions[keyToShow];
    if (emotion == null) return const SizedBox.shrink();
    
    final name = _getEmotionName(keyToShow);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6FA5).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            '${emotion.intensity}/100',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7DD3FC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmotions() {
    if (_topEmotions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _topEmotions.map((entry) {
        final name = _getEmotionName(entry.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '$name : ${entry.value.intensity}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Partagé depuis ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        Text(
          'UN AUTRE REGARD',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton() {
    return ElevatedButton.icon(
      onPressed: _isSharing ? null : _shareCard,
      icon: _isSharing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.share),
      label: Text(
        _isSharing ? 'Préparation...' : 'Partager mon état émotionnel',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B5998),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _shareCard() async {
    // Garder l'emotion dominante affichee pour la capture
    if (_topEmotions.isNotEmpty) {
      setState(() => _selectedEmotionKey = _topEmotions.first.key);
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    setState(() => _isSharing = true);

    try {
      RenderRepaintBoundary boundary = _cardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final fileName = 'etat_emotionnel_${widget.date.day}_${widget.date.month}_${widget.date.year}.png';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(pngBytes);

      // Partager UNIQUEMENT l'image - PAS de texte = PAS de pave vert
      await Share.shareXFiles([XFile(file.path)]);

      widget.onShareComplete?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image partagée !', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _selectedEmotionKey = null;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN',
      'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getEmotionName(String key) {
    const names = {
      'blesse': 'Blessé',
      'confus': 'Confus',
      'critique': 'Critique',
      'deprime': 'Déprimé',
      'effraye': 'Effrayé',
      'encolere': 'En Colère',
      'impuissant': 'Impuissant',
      'triste': 'Triste',
      'aimant': 'Aimant',
      'detendu': 'Détendu',
      'paisible': 'Paisible',
      'ouvert': 'Ouvert',
      'tourmente': 'Tourmenté',
      'inquiet': 'Inquiet',
      'isole': 'Isolé',
      'positif': 'Positif',
      'interesse': 'Intéressé',
      'heureux': 'Heureux',
      'vivant': 'Vivant',
      'fort': 'Fort',
      'indifferent': 'Indifférent',
    };
    return names[key] ?? key;
  }
}

/// Custom painter pour le radar circulaire avec emojis
class _RadarPainter extends CustomPainter {
  final Map<String, EmotionDetail> emotions;
  final Map<String, String> emotionEmojis;
  final String? selectedEmotionKey;

  _RadarPainter({
    required this.emotions,
    required this.emotionEmojis,
    this.selectedEmotionKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 50;

    final activeEmotions = emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList();

    if (activeEmotions.isEmpty) return;

    // Dessiner les cercles de grille
    _drawGrid(canvas, center, maxRadius, activeEmotions.length);

    // Dessiner le polygone des valeurs
    _drawValuePolygon(canvas, center, maxRadius, activeEmotions);

    // Dessiner les labels et emojis
    _drawLabels(canvas, center, maxRadius + 35, activeEmotions);
  }

  void _drawGrid(Canvas canvas, Offset center, double maxRadius, int segments) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Cercles concentriques (7 niveaux)
    for (int i = 1; i <= 7; i++) {
      canvas.drawCircle(center, maxRadius * i / 7, gridPaint);
    }

    // Lignes radiales
    final angleStep = 2 * math.pi / segments;
    for (int i = 0; i < segments; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawValuePolygon(Canvas canvas, Offset center, double maxRadius,
      List<MapEntry<String, EmotionDetail>> activeEmotions) {
    final angleStep = 2 * math.pi / activeEmotions.length;
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < activeEmotions.length; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final intensity = activeEmotions[i].value.intensity / 100;
      final radius = maxRadius * intensity * 0.95;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      // Remplissage bleu clair translucide
      final fillPaint = Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Contour bleu
      final strokePaint = Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(path, strokePaint);

      // Points sur les sommets
      final pointPaint = Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.fill;
      for (final point in points) {
        canvas.drawCircle(point, 5, pointPaint);
        // Cercle blanc interieur
        canvas.drawCircle(point, 2, Paint()..color = Colors.white);
      }
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double labelRadius,
      List<MapEntry<String, EmotionDetail>> activeEmotions) {
    final angleStep = 2 * math.pi / activeEmotions.length;

    for (int i = 0; i < activeEmotions.length; i++) {
      final entry = activeEmotions[i];
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final isResource = _isResourceEmotion(entry.key);
      final isSelected = entry.key == selectedEmotionKey;

      // Couleur du texte
      Color textColor;
      if (isSelected) {
        textColor = const Color(0xFF7DD3FC); // Bleu clair vif
      } else if (isResource) {
        textColor = const Color(0xFF86EFAC); // Vert clair
      } else {
        textColor = const Color(0xFFFCA5A5); // Rouge clair
      }

      final name = _getEmotionName(entry.key);
      final emoji = emotionEmojis[entry.key] ?? '●';

      // Dessiner le nom
      final textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            color: textColor,
            fontSize: isSelected ? 13 : 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position ajustee selon l'angle
      double textX = x - textPainter.width / 2;
      double textY = y - textPainter.height / 2;

      // Ajustements pour eviter les chevauchements
      if (angle > math.pi / 4 && angle < 3 * math.pi / 4) {
        textY += 8; // Bas - decaler vers le bas
      } else if (angle > -3 * math.pi / 4 && angle < -math.pi / 4) {
        textY -= 8; // Haut - decaler vers le haut
      }

      textPainter.paint(canvas, Offset(textX, textY));

      // Dessiner l'emoji
      final emojiPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: const TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      emojiPainter.layout();

      // Position de l'emoji (a cote du texte)
      double emojiX, emojiY;
      
      // Determiner la position de l'emoji selon le quadrant
      if (math.cos(angle) > 0.3) {
        // Cote droit - emoji apres le texte
        emojiX = textX + textPainter.width + 3;
        emojiY = textY + (textPainter.height - emojiPainter.height) / 2;
      } else if (math.cos(angle) < -0.3) {
        // Cote gauche - emoji avant le texte
        emojiX = textX - emojiPainter.width - 3;
        emojiY = textY + (textPainter.height - emojiPainter.height) / 2;
      } else if (math.sin(angle) > 0) {
        // Bas - emoji en dessous
        emojiX = x - emojiPainter.width / 2;
        emojiY = textY + textPainter.height + 2;
      } else {
        // Haut - emoji au dessus
        emojiX = x - emojiPainter.width / 2;
        emojiY = textY - emojiPainter.height - 2;
      }

      emojiPainter.paint(canvas, Offset(emojiX, emojiY));
    }
  }

  bool _isResourceEmotion(String key) {
    const resourceKeys = [
      'paisible', 'vivant', 'aimant', 'detendu', 'ouvert',
      'positif', 'interesse', 'heureux', 'fort',
    ];
    return resourceKeys.contains(key);
  }

  String _getEmotionName(String key) {
    const names = {
      'blesse': 'Blessé',
      'confus': 'Confus',
      'critique': 'Critique',
      'deprime': 'Déprimé',
      'effraye': 'Effrayé',
      'encolere': 'EnColère',
      'impuissant': 'Impuissant',
      'triste': 'Triste',
      'aimant': 'Aimant',
      'detendu': 'Détendu',
      'paisible': 'Paisible',
      'ouvert': 'Ouvert',
      'tourmente': 'Tourmenté',
      'inquiet': 'Inquiet',
      'isole': 'Isolé',
      'positif': 'Positif',
      'interesse': 'Intéressé',
      'heureux': 'Heureux',
      'vivant': 'Vivant',
      'fort': 'Fort',
      'indifferent': 'Indifférent',
    };
    return names[key] ?? key;
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.selectedEmotionKey != selectedEmotionKey ||
        oldDelegate.emotions != emotions;
  }
}

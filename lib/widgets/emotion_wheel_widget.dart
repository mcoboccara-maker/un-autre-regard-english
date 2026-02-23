// lib/widgets/emotion_wheel_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../config/emotion_config.dart';
import '../models/mood_entry.dart';

class EmotionWheelWidget extends StatefulWidget {
  final Map<String, EmotionDetail> emotions;
  final DateTime date;
  final bool showShareButton;
  
  const EmotionWheelWidget({
    super.key,
    required this.emotions,
    required this.date,
    this.showShareButton = true,
  });

  @override
  State<EmotionWheelWidget> createState() => _EmotionWheelWidgetState();
}

class _EmotionWheelWidgetState extends State<EmotionWheelWidget> {
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isCapturing = false;
  int? _touchedIndex;

  // Ordre des 18 émotions pour le radar (difficiles puis ressources)
  static const List<String> _emotionOrder = [
    // Émotions difficiles (9)
    'BLESSE',
    'CONFUS', 
    'CRITIQUE',
    'DEPRIME',
    'EFFRAYE',
    'EN_COLERE',
    'IMPUISSANT',
    'INDIFFERENT',
    'TRISTE',
    // Émotions ressources (9)
    'AIMANT',
    'DETENDU',
    'FORT',
    'HEUREUX',
    'INTERESSE',
    'OUVERT',
    'PAISIBLE',
    'POSITIF',
    'VIVANT',
  ];

  // Mapping des clés vers les noms de fichiers d'icônes
  static const Map<String, String> _emotionIcons = {
    'BLESSE': 'blesse.png',
    'CONFUS': 'confus.png',
    'CRITIQUE': 'critique.png',
    'DEPRIME': 'deprime.png',
    'EFFRAYE': 'effraye.png',
    'EN_COLERE': 'encolere.png',
    'IMPUISSANT': 'impuissant.png',
    'INDIFFERENT': 'indifferent.png',
    'TRISTE': 'triste.png',
    'AIMANT': 'aimant.png',
    'DETENDU': 'detendu.png',
    'FORT': 'fort.png',
    'HEUREUX': 'heureux.png',
    'INTERESSE': 'interesse.png',
    'OUVERT': 'ouvert.png',
    'PAISIBLE': 'paisible.png',
    'POSITIF': 'positif.png',
    'VIVANT': 'vivant.png',
  };

  // Couleurs spécifiques pour la roue des émotions - Palette distinctive
  static const Map<String, Color> _wheelEmotionColors = {
    // 🔴 Émotions difficiles / en tension
    'EFFRAYE': Color(0xFFC0392B),      // Rouge sombre - Alerte, danger
    'EN_COLERE': Color(0xFFE74C3C),    // Rouge vif - Explosion, feu
    'DEPRIME': Color(0xFF2C3E50),      // Bleu nuit - Retrait, lourdeur
    'IMPUISSANT': Color(0xFF4A4A4A),   // Gris anthracite - Blocage
    'BLESSE': Color(0xFF8E1B3A),       // Bordeaux - Douleur émotionnelle
    'CONFUS': Color(0xFF6C3483),       // Violet sombre - Brouillage cognitif
    'CRITIQUE': Color(0xFF6E2C00),     // Brun foncé - Dureté, rigidité
    'TRISTE': Color(0xFF34495E),       // Bleu gris foncé - Chagrin
    'INDIFFERENT': Color(0xFF7F8C8D),  // Gris bleuté - Neutralité
    // 🟢 Ressources / en appui
    'PAISIBLE': Color(0xFF27AE60),     // Vert doux - Apaisement
    'AIMANT': Color(0xFF2ECC71),       // Vert émeraude - Soutien
    'OUVERT': Color(0xFF1ABC9C),       // Turquoise - Disponibilité
    'DETENDU': Color(0xFF58D68D),      // Vert clair lumineux - Détente
    'INTERESSE': Color(0xFF5DADE2),    // Bleu clair - Attention sereine
    'POSITIF': Color(0xFFF7DC6F),      // Jaune clair - Optimisme
    'FORT': Color(0xFF1F618D),         // Bleu profond - Solidité
    'HEUREUX': Color(0xFFF4D03F),      // Jaune solaire - Joie
    'VIVANT': Color(0xFFF1C40F),       // Jaune doré - Énergie vitale
  };

  // Helper pour obtenir la couleur de la roue
  static Color _getWheelColor(String key) {
    return _wheelEmotionColors[key] ?? Colors.grey;
  }

  // Toutes les émotions actives triées par intensité
  List<MapEntry<String, EmotionDetail>> get _topEmotions {
    final sorted = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList()
      ..sort((a, b) => b.value.intensity.compareTo(a.value.intensity));
    return sorted; // Retourner TOUTES les émotions actives
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenu principal visible
        Column(
          children: [
            _buildWheel(),
            const SizedBox(height: 16),
            _buildLegend(),
            if (widget.showShareButton) ...[
              const SizedBox(height: 24),
              _buildShareButton(),
            ],
          ],
        ),
        // Carte de partage positionnée hors écran mais rendue
        Positioned(
          left: -1000,
          top: -1000,
          child: RepaintBoundary(
            key: _shareCardKey,
            child: _buildShareableCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final activeCount = widget.emotions.values.where((e) => e.intensity > 0).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_graph, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ma roue émotionnelle',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.date.day}/${widget.date.month}/${widget.date.year} • $activeCount émotions actives',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return RepaintBoundary(
      key: _chartKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Indicateurs Appui / Tensions avec les bonnes icônes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _buildHalfCircleLabelWithIcon('Appui', const Color(0xFF10B981), 'assets/univers_visuel/emotionsdujour.png')),
                  const SizedBox(width: 8),
                  Flexible(child: _buildHalfCircleLabelWithIcon('Tensions', const Color(0xFFDC2626), 'assets/univers_visuel/emotionsdujour.png')),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Roue personnalisée avec CustomPainter - responsive et centrée
            LayoutBuilder(
              builder: (context, constraints) {
                // Utiliser toute la largeur disponible
                final availableWidth = constraints.maxWidth;
                // Roue plus grande pour réduire le blanc
                final wheelSize = (availableWidth * 0.65).clamp(200.0, 300.0);
                // Rayon des icônes - plus éloigné de la roue
                final iconRadius = wheelSize * 0.62;
                const iconSize = 28.0;

                return SizedBox(
                  width: availableWidth,
                  height: availableWidth * 0.82,
                  child: GestureDetector(
                    onTapUp: (details) => _handleWheelTapResponsive(details, wheelSize, availableWidth),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Le radar dessiné avec CustomPaint - centré
                        CustomPaint(
                          size: Size(wheelSize, wheelSize),
                          painter: _InteractiveWheelPainter(
                            emotions: widget.emotions,
                            emotionOrder: _emotionOrder,
                            wheelColors: _wheelEmotionColors,
                          ),
                        ),
                        // Les icônes positionnées autour - centrées sur availableWidth
                        ..._buildWheelIconsCentered(availableWidth / 2, availableWidth * 0.95 / 2, iconRadius, iconSize),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Instruction
            Text(
              'Touchez une émotion pour voir ses nuances',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gestion du tap sur la roue (ancienne version)
  void _handleWheelTap(TapUpDetails details, double wheelSize) {
    final containerSize = wheelSize + 80;
    final center = Offset(containerSize / 2, containerSize / 2);
    final tapPosition = details.localPosition;

    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final maxTapRadius = wheelSize * 0.55;
    if (distance < 30 || distance > maxTapRadius) return;

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final segmentAngle = 2 * math.pi / _emotionOrder.length;
    final index = (angle / segmentAngle).floor() % _emotionOrder.length;

    _showNuancesPopup(index);
  }

  // Gestion du tap - version responsive centrée
  void _handleWheelTapResponsive(TapUpDetails details, double wheelSize, double containerWidth) {
    final centerX = containerWidth / 2;
    final centerY = containerWidth * 0.95 / 2;
    final center = Offset(centerX, centerY);
    final tapPosition = details.localPosition;

    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final maxTapRadius = wheelSize * 0.7;
    if (distance < 20 || distance > maxTapRadius) return;

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final segmentAngle = 2 * math.pi / _emotionOrder.length;
    final index = (angle / segmentAngle).floor() % _emotionOrder.length;

    _showNuancesPopup(index);
  }

  // Construire les icônes autour de la roue
  List<Widget> _buildWheelIcons(double containerHalfSize, double iconRadius, double iconSize) {
    final List<Widget> icons = [];
    // Le centre est au milieu du conteneur
    final double centerX = containerHalfSize;
    final double centerY = containerHalfSize;

    for (int i = 0; i < _emotionOrder.length; i++) {
      final key = _emotionOrder[i];
      final angle = -math.pi / 2 + (2 * math.pi * i / _emotionOrder.length);

      final x = centerX + iconRadius * math.cos(angle) - iconSize / 2;
      final y = centerY + iconRadius * math.sin(angle) - iconSize / 2;

      final iconFile = _emotionIcons[key] ?? 'pensee.png';
      final data = widget.emotions[key];
      final isActive = data != null && data.intensity > 0;
      final color = _getWheelColor(key);
      final emotionName = _getEmotionName(key);

      icons.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () => _showNuancesPopup(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? color : Colors.grey[300]!,
                      width: isActive ? 3 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/univers_visuel/$iconFile',
                      width: iconSize - 4,
                      height: iconSize - 4,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.emoji_emotions,
                          size: iconSize - 8,
                          color: color,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  emotionName,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: color, // Toujours la couleur de l'émotion
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return icons;
  }

  // Version centrée des icônes autour de la roue
  List<Widget> _buildWheelIconsCentered(double centerX, double centerY, double iconRadius, double iconSize) {
    final List<Widget> icons = [];

    for (int i = 0; i < _emotionOrder.length; i++) {
      final key = _emotionOrder[i];
      final angle = -math.pi / 2 + (2 * math.pi * i / _emotionOrder.length);

      final x = centerX + iconRadius * math.cos(angle) - iconSize / 2;
      final y = centerY + iconRadius * math.sin(angle) - iconSize / 2;

      final iconFile = _emotionIcons[key] ?? 'pensee.png';
      final data = widget.emotions[key];
      final isActive = data != null && data.intensity > 0;
      final color = _getWheelColor(key);
      final emotionName = _getEmotionName(key);

      icons.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () => _showNuancesPopup(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? color : Colors.grey[300]!,
                      width: isActive ? 2.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/univers_visuel/$iconFile',
                      width: iconSize - 4,
                      height: iconSize - 4,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.emoji_emotions,
                          size: iconSize - 8,
                          color: color,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  emotionName,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return icons;
  }

  Widget _buildHalfCircleLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHalfCircleLabelWithIcon(String text, Color color, String iconPath) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 18,
            height: 18,
            errorBuilder: (_, __, ___) => Icon(
              text == 'Appui' ? Icons.sentiment_satisfied : Icons.sentiment_dissatisfied,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _buildGradientColor() {
    return const Color(0xFF8B5CF6).withOpacity(0.25);
  }

  List<RadarEntry> _buildDataEntries() {
    return _emotionOrder.map((key) {
      final data = widget.emotions[key];
      final intensity = data?.intensity ?? 0;
      return RadarEntry(value: (intensity / 10).clamp(0, 10).toDouble());
    }).toList();
  }

  void _showNuancesPopup(int index) {
    if (index < 0 || index >= _emotionOrder.length) return;
    
    final emotionKey = _emotionOrder[index];
    final emotion = EmotionCategories.findByKey(emotionKey);
    final data = widget.emotions[emotionKey];
    
    if (emotion == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: emotion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(emotion.icon, color: emotion.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emotion.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: emotion.color,
                        ),
                      ),
                      Text(
                        'Intensité : ${data?.intensity ?? 0}%',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              emotion.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (data != null && data.nuances.isNotEmpty) ...[
              Text(
                'Nuances ressenties :',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.nuances.map((nuance) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: emotion.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: emotion.color.withOpacity(0.3)),
                    ),
                    child: Text(
                      nuance,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: emotion.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data?.intensity == 0 || data == null
                            ? 'Cette émotion n\'a pas été sélectionnée'
                            : 'Aucune nuance spécifique sélectionnée',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final activeEmotions = _emotionOrder.where((key) {
      final data = widget.emotions[key];
      return data != null && data.intensity > 0;
    }).toList();
    
    if (activeEmotions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucune émotion sélectionnée',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Détail des émotions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          
          ...activeEmotions
              .where((key) => EmotionCategories.negativeEmotions.any((e) => e.key == key))
              .map((key) => _buildLegendItem(key)),
          
          if (activeEmotions.any((key) => EmotionCategories.negativeEmotions.any((e) => e.key == key)) &&
              activeEmotions.any((key) => EmotionCategories.positiveEmotions.any((e) => e.key == key)))
            const Divider(height: 24),
          
          ...activeEmotions
              .where((key) => EmotionCategories.positiveEmotions.any((e) => e.key == key))
              .map((key) => _buildLegendItem(key)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String key) {
    final emotion = EmotionCategories.findByKey(key);
    final data = widget.emotions[key];
    
    if (emotion == null || data == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: emotion.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              emotion.iconPath,
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => Icon(emotion.icon, color: emotion.color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      emotion.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: emotion.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: emotion.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${data.intensity}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: emotion.color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (data.nuances.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.nuances.join(', '),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return ElevatedButton.icon(
      onPressed: _isCapturing ? null : _captureAndShare,
      icon: _isCapturing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.share),
      label: Text(
        _isCapturing ? 'Préparation...' : '📸 Partager ma roue',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // CARTE DE PARTAGE - Design bleu avec 18 émotions + icônes PNG
  // ============================================================

  Widget _buildShareableCard() {
    final dateStr = _formatDate(widget.date);
    
    return Container(
      width: 420,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          _buildShareCardTitle(dateStr),
          
          const SizedBox(height: 20),
          
          // Radar avec les 18 émotions et icônes PNG
          _buildShareCardRadarWithIcons(),
          
          const SizedBox(height: 20),
          
          // Top 3 émotions actives
          _buildShareCardTopEmotions(),
          
          const SizedBox(height: 16),
          
          // Footer branding
          _buildShareCardFooter(),
        ],
      ),
    );
  }

  Widget _buildShareCardTitle(String dateStr) {
    return Column(
      children: [
        Text(
          'MON ÉTAT',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        Text(
          'ÉMOTIONNEL',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateStr,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildShareCardRadarWithIcons() {
    return SizedBox(
      width: 380,
      height: 380,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Le radar (grille + polygone) dessiné avec CustomPaint
          CustomPaint(
            size: const Size(380, 380),
            painter: _ShareRadarPainter(
              emotions: widget.emotions,
              emotionOrder: _emotionOrder,
            ),
          ),
          // Les icônes PNG positionnées autour du radar
          ..._buildEmotionIconsAround(),
        ],
      ),
    );
  }

  List<Widget> _buildEmotionIconsAround() {
    final List<Widget> icons = [];
    final double centerX = 190;
    final double centerY = 190;
    final double iconRadius = 160; // Distance du centre aux icônes
    final double iconSize = 30;

    for (int i = 0; i < _emotionOrder.length; i++) {
      final key = _emotionOrder[i];
      final angle = -math.pi / 2 + (2 * math.pi * i / _emotionOrder.length);

      // Décalage pour centrer l'ensemble icône + texte
      final x = centerX + iconRadius * math.cos(angle) - iconSize / 2;
      final y = centerY + iconRadius * math.sin(angle) - iconSize / 2;

      final iconFile = _emotionIcons[key] ?? 'pensee.png';
      final data = widget.emotions[key];
      final isActive = data != null && data.intensity > 0;
      final emotionColor = _wheelEmotionColors[key] ?? Colors.white;
      final emotionName = _getEmotionName(key);

      icons.add(
        Positioned(
          left: x,
          top: y,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône PNG avec bordure colorée
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? emotionColor : Colors.white38,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: emotionColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/univers_visuel/$iconFile',
                    width: iconSize - 4,
                    height: iconSize - 4,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback: cercle avec première lettre
                      return Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: emotionColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            emotionName.substring(0, 1),
                            style: TextStyle(
                              color: isActive ? emotionColor : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Nom de l'émotion avec sa couleur spécifique
              const SizedBox(height: 2),
              Text(
                emotionName,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? emotionColor : Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return icons;
  }

  Widget _buildShareCardTopEmotions() {
    if (_topEmotions.isEmpty) {
      return Text(
        'Aucune émotion sélectionnée',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white70,
        ),
      );
    }

    // Ajuster la taille selon le nombre d'émotions
    final fontSize = _topEmotions.length > 5 ? 14.0 : (_topEmotions.length > 3 ? 16.0 : 18.0);
    final verticalPadding = _topEmotions.length > 5 ? 2.0 : 3.0;

    return Column(
      children: _topEmotions.map((entry) {
        final name = _getEmotionName(entry.key);
        final isResource = _isResourceEmotion(entry.key);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Text(
            '$name : ${entry.value.intensity}%',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isResource ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShareCardFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Partagé depuis ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        Text(
          'UN AUTRE REGARD',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN',
      'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getEmotionName(String key) {
    final emotion = EmotionCategories.findByKey(key);
    if (emotion != null) return emotion.name;
    
    // Fallback
    const names = {
      'BLESSE': 'Blessé',
      'CONFUS': 'Confus',
      'CRITIQUE': 'Critique',
      'DEPRIME': 'Déprimé',
      'EFFRAYE': 'Effrayé',
      'EN_COLERE': 'En Colère',
      'IMPUISSANT': 'Impuissant',
      'INDIFFERENT': 'Indifférent',
      'TRISTE': 'Triste',
      'AIMANT': 'Aimant',
      'DETENDU': 'Détendu',
      'FORT': 'Fort',
      'HEUREUX': 'Heureux',
      'INTERESSE': 'Intéressé',
      'OUVERT': 'Ouvert',
      'PAISIBLE': 'Paisible',
      'POSITIF': 'Positif',
      'VIVANT': 'Vivant',
    };
    return names[key] ?? names[key.toUpperCase()] ?? key;
  }

  bool _isResourceEmotion(String key) {
    const resourceKeys = [
      'AIMANT', 'DETENDU', 'FORT', 'HEUREUX', 'INTERESSE', 
      'OUVERT', 'PAISIBLE', 'POSITIF', 'VIVANT',
    ];
    return resourceKeys.contains(key.toUpperCase());
  }

  // ============================================================
  // CAPTURE ET PARTAGE
  // ============================================================

  Future<void> _captureAndShare() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Le partage n\'est disponible que sur mobile (Android/iOS)',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Attendre que le widget soit complètement rendu
      await Future.delayed(const Duration(milliseconds: 800));

      if (_shareCardKey.currentContext == null) {
        throw Exception('Widget de partage non disponible');
      }

      final renderObject = _shareCardKey.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw Exception('RenderRepaintBoundary non disponible');
      }

      RenderRepaintBoundary boundary = renderObject;

      // Attendre un peu plus pour s'assurer que le rendu est terminé
      await Future.delayed(const Duration(milliseconds: 200));

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Impossible de convertir l\'image');
      }
      
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final fileName = 'etat_emotionnel_${widget.date.day}_${widget.date.month}_${widget.date.year}.png';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Roue émotionnelle partagée !',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erreur capture: $e');
      print('❌ Stack: $stackTrace');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Erreur de partage')),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                'Détails:\n$e\n\nStack:\n$stackTrace',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }
}

// ============================================================
// CustomPainter pour la roue interactive avec segments colorés
// ============================================================

class _InteractiveWheelPainter extends CustomPainter {
  final Map<String, EmotionDetail> emotions;
  final List<String> emotionOrder;
  final Map<String, Color> wheelColors;

  _InteractiveWheelPainter({
    required this.emotions,
    required this.emotionOrder,
    required this.wheelColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 20;

    // Dessiner la grille
    _drawGrid(canvas, center, maxRadius);

    // Dessiner le polygone rempli avec couleurs par secteur
    _drawFilledPolygonWithColors(canvas, center, maxRadius);

    // PAS de contour bleu - supprimé pour clarté visuelle

    // Dessiner les points sur les sommets (gris neutre)
    _drawPoints(canvas, center, maxRadius);
  }

  void _drawGrid(Canvas canvas, Offset center, double maxRadius) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Cercles concentriques (5 niveaux)
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * i / 5, gridPaint);
    }

    // Lignes radiales
    final angleStep = 2 * math.pi / emotionOrder.length;
    for (int i = 0; i < emotionOrder.length; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawFilledPolygonWithColors(Canvas canvas, Offset center, double maxRadius) {
    final angleStep = 2 * math.pi / emotionOrder.length;
    final halfAngleStep = angleStep / 2;

    // Pour chaque émotion, dessiner un secteur (arc de tarte) coloré
    for (int i = 0; i < emotionOrder.length; i++) {
      final key = emotionOrder[i];
      final data = emotions[key];
      final intensity = (data?.intensity ?? 0) / 100;

      if (intensity > 0) {
        final color = wheelColors[key] ?? Colors.grey;
        final angle = -math.pi / 2 + i * angleStep;
        final radius = maxRadius * intensity;

        // Calculer les angles de début et fin du secteur
        final startAngle = angle - halfAngleStep;
        final endAngle = angle + halfAngleStep;

        // Points du secteur (forme de "part de gâteau")
        final startX = center.dx + radius * math.cos(startAngle);
        final startY = center.dy + radius * math.sin(startAngle);
        final endX = center.dx + radius * math.cos(endAngle);
        final endY = center.dy + radius * math.sin(endAngle);
        final peakX = center.dx + radius * math.cos(angle);
        final peakY = center.dy + radius * math.sin(angle);

        // Dessiner le secteur comme un triangle arrondi
        final sectorPath = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(startX, startY)
          ..lineTo(peakX, peakY)
          ..lineTo(endX, endY)
          ..close();

        final sectorPaint = Paint()
          ..color = color.withOpacity(0.70)
          ..style = PaintingStyle.fill;

        canvas.drawPath(sectorPath, sectorPaint);
      }
    }
  }

  void _drawPolygonOutline(Canvas canvas, Offset center, double maxRadius) {
    final angleStep = 2 * math.pi / emotionOrder.length;
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < emotionOrder.length; i++) {
      final key = emotionOrder[i];
      final data = emotions[key];
      final intensity = (data?.intensity ?? 0) / 100;

      final angle = -math.pi / 2 + i * angleStep;
      final radius = maxRadius * intensity;
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

      // Contour avec couleur violette
      final strokePaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawPoints(Canvas canvas, Offset center, double maxRadius) {
    final angleStep = 2 * math.pi / emotionOrder.length;
    const bleuNuit = Color(0xFF2C3E50); // Bleu nuit pour les points

    for (int i = 0; i < emotionOrder.length; i++) {
      final key = emotionOrder[i];
      final data = emotions[key];

      if (data != null && data.intensity > 0) {
        final intensity = data.intensity / 100;
        final angle = -math.pi / 2 + i * angleStep;
        final radius = maxRadius * intensity;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);

        // Point bleu nuit avec bordure blanche
        final pointPaint = Paint()
          ..color = bleuNuit
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 6, pointPaint);

        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(x, y), 6, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveWheelPainter oldDelegate) {
    return oldDelegate.emotions != emotions;
  }
}

// ============================================================
// CustomPainter pour le radar (grille + polygone uniquement)
// ============================================================

class _ShareRadarPainter extends CustomPainter {
  final Map<String, EmotionDetail> emotions;
  final List<String> emotionOrder;

  _ShareRadarPainter({
    required this.emotions,
    required this.emotionOrder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 70; // Laisser de la place pour les icônes

    // Dessiner les cercles de grille (pour les 18 émotions)
    _drawGrid(canvas, center, maxRadius, emotionOrder.length);

    // Dessiner le polygone des valeurs
    _drawValuePolygon(canvas, center, maxRadius);
  }

  void _drawGrid(Canvas canvas, Offset center, double maxRadius, int segments) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Cercles concentriques (5 niveaux)
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * i / 5, gridPaint);
    }

    // Lignes radiales (18 lignes pour 18 émotions)
    final angleStep = 2 * math.pi / segments;
    for (int i = 0; i < segments; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawValuePolygon(Canvas canvas, Offset center, double maxRadius) {
    final angleStep = 2 * math.pi / emotionOrder.length;
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < emotionOrder.length; i++) {
      final key = emotionOrder[i];
      final data = emotions[key];
      final intensity = (data?.intensity ?? 0) / 100;
      
      final angle = -math.pi / 2 + i * angleStep;
      final radius = maxRadius * intensity;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty && points.any((p) => p != center)) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      // Remplissage bleu clair translucide
      final fillPaint = Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Contour bleu
      final strokePaint = Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(path, strokePaint);

      // Points sur les sommets (seulement si intensité > 0)
      for (int i = 0; i < emotionOrder.length; i++) {
        final key = emotionOrder[i];
        final data = emotions[key];
        if (data != null && data.intensity > 0) {
          final pointPaint = Paint()
            ..color = const Color(0xFF60A5FA)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(points[i], 5, pointPaint);
          canvas.drawCircle(points[i], 2, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShareRadarPainter oldDelegate) {
    return oldDelegate.emotions != emotions;
  }
}

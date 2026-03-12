// lib/widgets/circular_emotion_wheel.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/mood_entry.dart';
import '../config/emotion_config.dart';

class CircularEmotionWheel extends StatefulWidget {
  final DateTime date;
  final Map<String, EmotionDetail> emotions;
  final bool showShareButton;
  final bool showNuances;

  const CircularEmotionWheel({
    super.key,
    required this.date,
    required this.emotions,
    this.showShareButton = true,
    this.showNuances = true,
  });

  @override
  State<CircularEmotionWheel> createState() => _CircularEmotionWheelState();
}

class _CircularEmotionWheelState extends State<CircularEmotionWheel> {
  // Cle pour capturer la carte complete de partage
  final GlobalKey _shareCardKey = GlobalKey();
  final Set<String> _expandedEmotions = {};
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

  // Separer emotions ressources vs difficiles
  List<MapEntry<String, EmotionDetail>> get _resourceEmotions {
    return widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .where((e) => EmotionCategories.positiveEmotions.any((p) => p.key == e.key))
        .toList()
      ..sort((a, b) => b.value.intensity.compareTo(a.value.intensity));
  }

  List<MapEntry<String, EmotionDetail>> get _difficultEmotions {
    return widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .where((e) => EmotionCategories.negativeEmotions.any((n) => n.key == e.key))
        .toList()
      ..sort((a, b) => b.value.intensity.compareTo(a.value.intensity));
  }

  // Toutes les emotions actives triees par intensite
  List<MapEntry<String, EmotionDetail>> get _topEmotions {
    final sorted = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList()
      ..sort((a, b) => b.value.intensity.compareTo(a.value.intensity));
    return sorted; // Retourner TOUTES les emotions actives
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        
        // Carte de partage complete (sera capturee en image)
        RepaintBoundary(
          key: _shareCardKey,
          child: _buildShareableCard(),
        ),
        
        const SizedBox(height: 24),
        _buildLegendWithNuances(),
        
        if (widget.showShareButton) ...[
          const SizedBox(height: 24),
          _buildShareButton(context),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                  'My emotional wheel',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.date.day}/${widget.date.month}/${widget.date.year}',
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

  /// Carte complete qui sera capturee pour le partage - DESIGN BLEU FONCE
  Widget _buildShareableCard() {
    return Container(
      width: 380,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        // Degrade bleu fonce elegant comme l'image de reference
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
          // Titre style image de reference
          _buildCardTitle(),
          
          const SizedBox(height: 24),
          
          // Radar chart avec labels colores et emojis
          _buildRadarChartStyled(),
          
          const SizedBox(height: 24),
          
          // Top 3 emotions en grand
          _buildTopEmotionsDisplay(),
          
          const SizedBox(height: 16),
          
          // Footer branding
          _buildCardFooter(),
        ],
      ),
    );
  }

  Widget _buildCardTitle() {
    final dateStr = _formatDate(widget.date);
    
    return Column(
      children: [
        Text(
          'MY EMOTIONAL',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        Text(
          'STATE',
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

  String _formatDate(DateTime date) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildRadarChartStyled() {
    final activeEmotions = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList();

    if (activeEmotions.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Text(
          'No emotion selected',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: GestureDetector(
        onTapDown: (details) => _handleRadarTap(details.localPosition, activeEmotions),
        onTapUp: (_) => setState(() => _selectedEmotionKey = null),
        onTapCancel: () => setState(() => _selectedEmotionKey = null),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radar chart
            RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: activeEmotions.map((e) {
                      return RadarEntry(value: e.value.intensity.toDouble());
                    }).toList(),
                    fillColor: const Color(0xFF60A5FA).withOpacity(0.25),
                    borderColor: const Color(0xFF60A5FA),
                    borderWidth: 2.5,
                    entryRadius: 4,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                tickBorderData: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                gridBorderData: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                tickCount: 5,
                ticksTextStyle: const TextStyle(fontSize: 0),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                titlePositionPercentageOffset: 0.2,
                getTitle: (index, angle) {
                  if (index >= activeEmotions.length) return RadarChartTitle(text: '', angle: angle);
                  final entry = activeEmotions[index];
                  final config = _getEmotionConfig(entry.key);
                  final name = config?.name ?? entry.key;
                  final emoji = _emotionEmojis[entry.key.toLowerCase()] ?? '';

                  // Retourner nom + emoji avec couleur
                  return RadarChartTitle(text: '$name $emoji', angle: angle);
                },
              ),
            ),
            
            // Info-bulle centrale
            _buildCenterInfoBubble(activeEmotions),
          ],
        ),
      ),
    );
  }

  void _handleRadarTap(Offset position, List<MapEntry<String, EmotionDetail>> activeEmotions) {
    if (activeEmotions.isEmpty) return;
    
    final center = Offset(140, 140); // Centre approximatif
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    
    // Calculer l'angle et trouver l'emotion
    var angle = (dx.abs() > 0.01 || dy.abs() > 0.01) 
        ? (dy >= 0 ? 1 : -1) * (dx >= 0 ? 1 : -1) * 0.5
        : 0.0;
    
    // Selectionner une emotion basee sur la position
    final index = (position.dx / 40).floor() % activeEmotions.length;
    if (index >= 0 && index < activeEmotions.length) {
      setState(() {
        _selectedEmotionKey = activeEmotions[index].key;
      });
    }
  }

  Widget _buildCenterInfoBubble(List<MapEntry<String, EmotionDetail>> activeEmotions) {
    String? keyToShow = _selectedEmotionKey;
    
    // Si aucune selection, montrer l'emotion dominante
    if (keyToShow == null && _topEmotions.isNotEmpty) {
      keyToShow = _topEmotions.first.key;
    }
    
    if (keyToShow == null) return const SizedBox.shrink();

    final emotion = widget.emotions[keyToShow];
    if (emotion == null) return const SizedBox.shrink();
    
    final config = _getEmotionConfig(keyToShow);
    final name = config?.name ?? keyToShow;
    
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

  bool _isResourceEmotion(String key) {
    return EmotionCategories.positiveEmotions.any((e) => e.key == key);
  }

  Widget _buildTopEmotionsDisplay() {
    if (_topEmotions.isEmpty) return const SizedBox.shrink();

    // Ajuster la taille selon le nombre d'emotions
    final fontSize = _topEmotions.length > 5 ? 14.0 : (_topEmotions.length > 3 ? 18.0 : 22.0);
    final verticalPadding = _topEmotions.length > 5 ? 2.0 : 4.0;

    return Column(
      children: _topEmotions.map((entry) {
        final config = _getEmotionConfig(entry.key);
        final name = config?.name ?? entry.key;
        final isResource = _isResourceEmotion(entry.key);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Text(
            '$name : ${entry.value.intensity}%',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isResource
                  ? const Color(0xFF86EFAC) // Vert pour ressources
                  : const Color(0xFFFCA5A5), // Rouge pour difficiles
            ),
          ),
        );
      }).toList(),
    );
  }

  // Ancienne version du radar pour l'affichage local (fond clair)
  Widget _buildRadarChart() {
    final activeEmotions = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList();

    if (activeEmotions.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No emotion selected',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: activeEmotions.map((e) {
                return RadarEntry(value: e.value.intensity.toDouble());
              }).toList(),
              fillColor: const Color(0xFF6366F1).withOpacity(0.3),
              borderColor: const Color(0xFF6366F1),
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.grey, width: 0.5),
          tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
          gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
          tickCount: 5,
          ticksTextStyle: const TextStyle(fontSize: 0),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
          titlePositionPercentageOffset: 0.15,
          getTitle: (index, angle) {
            if (index >= activeEmotions.length) return RadarChartTitle(text: '', angle: angle);
            final entry = activeEmotions[index];
            final config = _getEmotionConfig(entry.key);
            return RadarChartTitle(text: config?.name ?? entry.key, angle: angle);
          },
        ),
      ),
    );
  }

  Widget _buildScoresSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne Appui (ressources)
        Expanded(
          child: _buildScoreColumn(
            title: 'Support',
            iconPath: 'assets/univers_visuel/appui.png',
            color: const Color(0xFF10B981),
            emotions: _resourceEmotions.take(3).toList(),
          ),
        ),

        const SizedBox(width: 12),

        // Colonne Tensions (difficiles)
        Expanded(
          child: _buildScoreColumn(
            title: 'Tensions',
            iconPath: 'assets/univers_visuel/tension.png',
            color: const Color(0xFFF59E0B),
            emotions: _difficultEmotions.take(3).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreColumn({
    required String title,
    required String iconPath,
    required Color color,
    required List<MapEntry<String, EmotionDetail>> emotions,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(iconPath, width: 18, height: 18),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (emotions.isEmpty)
            Text(
              'None',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...emotions.map((e) {
              final config = _getEmotionConfig(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        config?.name ?? e.key,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value.intensity}/10',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: config?.color ?? color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCardFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Shared from ',
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

  Widget _buildLegendWithNuances() {
    final activeEmotions = widget.emotions.entries
        .where((e) => e.value.intensity > 0)
        .toList();

    if (activeEmotions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Emotional details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        
        ...activeEmotions.map((entry) {
          final emotionConfig = _getEmotionConfig(entry.key);
          if (emotionConfig == null) return const SizedBox.shrink();
          
          final emotion = emotionConfig;
          final hasNuances = entry.value.nuances.isNotEmpty;
          final isExpanded = _expandedEmotions.contains(entry.key);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: emotion.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: emotion.color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: hasNuances && widget.showNuances
                      ? () {
                          setState(() {
                            if (isExpanded) {
                              _expandedEmotions.remove(entry.key);
                            } else {
                              _expandedEmotions.add(entry.key);
                            }
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: emotion.color.withOpacity(0.2),
                            shape: BoxShape.circle,
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
                              Text(
                                emotion.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: emotion.color,
                                ),
                              ),
                              if (hasNuances && widget.showNuances)
                                Text(
                                  '${entry.value.nuances.length} nuance${entry.value.nuances.length > 1 ? 's' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: emotion.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.value.intensity}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: emotion.color,
                            ),
                          ),
                        ),
                        if (hasNuances && widget.showNuances) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: emotion.color,
                            size: 24,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                if (hasNuances && widget.showNuances && isExpanded)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: emotion.color.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Felt nuances:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.value.nuances.map((nuance) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: emotion.color.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                nuance,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: emotion.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSharing ? null : () => _shareWheel(context),
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
        _isSharing ? 'Preparing...' : 'Share my emotional wheel',
        style: GoogleFonts.poppins(
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

  Future<void> _shareWheel(BuildContext context) async {
    // Verifier si on est sur Web (path_provider ne fonctionne pas)
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sharing is only available on mobile (Android/iOS)',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isSharing = true);

    try {
      // Capturer la carte complete comme image
      RenderRepaintBoundary boundary = _shareCardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Sauvegarder temporairement
      final tempDir = await getTemporaryDirectory();
      final fileName = 'emotional_state_${widget.date.day}_${widget.date.month}_${widget.date.year}.png';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(pngBytes);

      // PARTAGER UNIQUEMENT L'IMAGE - PAS DE TEXTE
      // => Plus de pave vert WhatsApp !
      await Share.shareXFiles(
        [XFile(file.path)],
        // PAS de parametre 'text:' ici !
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Emotional wheel shared!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erreur capture: $e');
      print('❌ Stack: $stackTrace');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Sharing error')),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                'Details:\n$e\n\nStack:\n$stackTrace',
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
        setState(() => _isSharing = false);
      }
    }
  }

  EmotionConfig? _getEmotionConfig(String key) {
    try {
      return EmotionCategories.negativeEmotions.firstWhere((e) => e.key == key);
    } catch (_) {
      try {
        return EmotionCategories.positiveEmotions.firstWhere((e) => e.key == key);
      } catch (_) {
        return null;
      }
    }
  }
}

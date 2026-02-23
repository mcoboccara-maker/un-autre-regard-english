// lib/screens/emotion_selection_screen.dart
// Full emotion selection with intensity sliders, nuances, and EmotionalState building
// Restores original UX from emotions_selection_step.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import 'eclairages_carousel_screen.dart';
import 'perspective_room_screen.dart';

class EmotionSelectionScreen extends StatefulWidget {
  final String thoughtText;
  final ReflectionType reflectionType;
  final ApproachConfig? preselectedSource;

  const EmotionSelectionScreen({
    super.key,
    required this.thoughtText,
    required this.reflectionType,
    this.preselectedSource,
  });

  @override
  State<EmotionSelectionScreen> createState() => _EmotionSelectionScreenState();
}

class _EmotionSelectionScreenState extends State<EmotionSelectionScreen>
    with SingleTickerProviderStateMixin {
  late EmotionalState _emotionalState;
  bool _isGenerating = false;

  late AnimationController _hourglassController;

  @override
  void initState() {
    super.initState();
    _emotionalState = EmotionalState(
      emotions: {},
      timestamp: DateTime.now(),
    );
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _hourglassController.dispose();
    super.dispose();
  }

  void _updateEmotionLevel(String emotionKey, int level,
      [List<String>? nuances]) {
    final updatedEmotions =
        Map<String, EmotionLevel>.from(_emotionalState.emotions);

    if (level == 0) {
      updatedEmotions.remove(emotionKey);
    } else {
      updatedEmotions[emotionKey] = EmotionLevel(
        level: level,
        nuances: nuances ?? updatedEmotions[emotionKey]?.nuances ?? [],
      );
    }

    setState(() {
      _emotionalState = _emotionalState.copyWith(
        emotions: updatedEmotions,
        timestamp: DateTime.now(),
      );
    });
  }

  int _calculateIntensity() {
    final activeEmotions =
        _emotionalState.emotions.values.where((e) => e.level > 0);
    if (activeEmotions.isEmpty) return 5;
    final avg =
        activeEmotions.map((e) => e.level).reduce((a, b) => a + b) /
            activeEmotions.length;
    return avg.round();
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final intensity = _calculateIntensity();

      if (widget.preselectedSource != null) {
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: widget.preselectedSource!.key,
          reflectionText: widget.thoughtText,
          reflectionType: widget.reflectionType,
          emotionalState: _emotionalState,
          userProfile: null,
          intensiteEmotionnelle: intensity,
        );

        if (mounted) {
          final meta = AIService.instance.lastFigureMeta;
          final perspective = PerspectiveData(
            approachKey: widget.preselectedSource!.key,
            approachName: widget.preselectedSource!.name,
            responseText: response,
            figureName: meta?['nom'],
            figureReference: meta?['reference'],
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: widget.thoughtText,
                perspectives: [perspective],
              ),
            ),
          );
        }
      } else {
        final sources = _pickRandomSources(3);
        final List<PerspectiveData> perspectives = [];

        for (final source in sources) {
          final response =
              await AIService.instance.generateApproachSpecificResponse(
            approach: source.key,
            reflectionText: widget.thoughtText,
            reflectionType: widget.reflectionType,
            emotionalState: _emotionalState,
            userProfile: null,
            intensiteEmotionnelle: intensity,
          );

          final meta = AIService.instance.lastFigureMeta;
          perspectives.add(PerspectiveData(
            approachKey: source.key,
            approachName: source.name,
            responseText: response,
            figureName: meta?['nom'],
            figureReference: meta?['reference'],
          ));
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: widget.thoughtText,
                perspectives: perspectives,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la generation.')),
        );
      }
    }
  }

  List<ApproachConfig> _pickRandomSources(int count) {
    final all = ApproachCategories.allApproaches.toList()..shuffle();
    return all.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF1A2E5A), Color(0xFF0D1B3E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSummary(),
              ),

              // Emotion list
              Expanded(
                child: _buildEmotionsList(),
              ),

              // Bottom buttons
              if (_isGenerating)
                _buildGeneratingIndicator()
              else
                _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon:
                    const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Comment te sens-tu ?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Exprime ce que tu ressens dans ce contexte',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final activeEmotions = _emotionalState.emotions.entries
        .where((e) => e.value.level > 0)
        .toList();

    if (activeEmotions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app,
                color: Colors.white.withValues(alpha: 0.7), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Touche une carte pour exprimer ce que tu ressens',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          Text(
            '${activeEmotions.length} emotion(s) selectionnee(s)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          // Negative emotions
          ...EmotionCategories.negativeEmotions.map((emotion) {
            final level =
                _emotionalState.emotions[emotion.key]?.level ?? 0;
            final nuances =
                _emotionalState.emotions[emotion.key]?.nuances ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildEmotionCard(emotion, level, nuances),
            );
          }),

          const SizedBox(height: 12),

          // Separator
          Row(
            children: [
              Expanded(
                  child:
                      Divider(color: Colors.white.withValues(alpha: 0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Emotions ressources',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                  child:
                      Divider(color: Colors.white.withValues(alpha: 0.2))),
            ],
          ),

          const SizedBox(height: 12),

          // Positive emotions
          ...EmotionCategories.positiveEmotions.map((emotion) {
            final level =
                _emotionalState.emotions[emotion.key]?.level ?? 0;
            final nuances =
                _emotionalState.emotions[emotion.key]?.nuances ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildEmotionCard(emotion, level, nuances),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmotionCard(
      EmotionConfig emotion, int level, List<String> nuances) {
    final isSelected = level > 0;

    return Column(
      children: [
        // Main card (tappable)
        InkWell(
          onTap: () {
            if (isSelected) {
              _updateEmotionLevel(emotion.key, 0, []);
            } else {
              _updateEmotionLevel(emotion.key, 5, []);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? emotion.color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? emotion.color
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // PNG icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: emotion.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      emotion.iconPath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(emotion.icon, color: emotion.color, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Text(
                    emotion.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? emotion.color
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),

                // Checkbox
                if (isSelected)
                  Icon(Icons.check_circle, color: emotion.color, size: 22),
              ],
            ),
          ),
        ),

        // Intensity panel (if selected)
        if (isSelected) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: emotion.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intensity header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intensite:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '$level/10',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: emotion.color,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Evaluation icon (PNG)
                _buildIntensityScale(emotion, level),

                const SizedBox(height: 10),

                // Nuances button
                OutlinedButton.icon(
                  onPressed: () => _showNuancesDialog(emotion, nuances),
                  icon:
                      Icon(Icons.tune, size: 16, color: emotion.color),
                  label: Text(
                    nuances.isEmpty
                        ? 'Preciser les nuances'
                        : '${nuances.length} nuance(s) selectionnee(s)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: emotion.color,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: emotion.color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Selected nuances chips
                if (nuances.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: nuances.map((nuance) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: emotion.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nuance,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                final newNuances =
                                    List<String>.from(nuances)
                                      ..remove(nuance);
                                _updateEmotionLevel(
                                    emotion.key, level, newNuances);
                              },
                              child: Icon(Icons.close,
                                  size: 14,
                                  color: Colors.white
                                      .withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIntensityScale(EmotionConfig emotion, int currentLevel) {
    return Column(
      children: [
        // Evaluation PNG icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/univers_visuel/evaluation/emotion$currentLevel.png',
              width: 44,
              height: 44,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$currentLevel',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: emotion.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Slider
        Row(
          children: [
            Text(
              '0',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF9FD5A1),
                  inactiveTrackColor:
                      const Color(0xFF2E7D8A).withValues(alpha: 0.3),
                  thumbColor: const Color(0xFF9FD5A1),
                  overlayColor:
                      const Color(0xFF9FD5A1).withValues(alpha: 0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18),
                ),
                child: Slider(
                  value: currentLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (value) {
                    final nuances =
                        _emotionalState.emotions[emotion.key]?.nuances ??
                            [];
                    _updateEmotionLevel(
                        emotion.key, value.round(), nuances);
                  },
                ),
              ),
            ),
            Text(
              '10',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Quick value shortcuts
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0, 5, 10].map((quickValue) {
            final isActive = currentLevel == quickValue;
            return GestureDetector(
              onTap: () {
                final nuances =
                    _emotionalState.emotions[emotion.key]?.nuances ?? [];
                _updateEmotionLevel(emotion.key, quickValue, nuances);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF9FD5A1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF9FD5A1)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '$quickValue',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showNuancesDialog(
      EmotionConfig emotion, List<String> currentNuances) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _NuancesDialog(
        emotion: emotion,
        initialSelected: currentNuances,
      ),
    );

    if (result != null) {
      final level = _emotionalState.emotions[emotion.key]?.level ?? 5;
      _updateEmotionLevel(emotion.key, level, result);
    }
  }

  Widget _buildNavigationButtons() {
    final hasEmotions =
        _emotionalState.emotions.values.any((e) => e.level > 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Image.asset(
                  'assets/univers_visuel/retour.png',
                  width: 16,
                  height: 16,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.arrow_back, size: 16),
                ),
                label: Text(
                  'Retour',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Generate button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasEmotions ? _generate : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  'Voir mes perspectives',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEmotions
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: hasEmotions ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            RotationTransition(
              turns: _hourglassController,
              child: Image.asset(
                'assets/univers_visuel/generationiaencours.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generation en cours...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NUANCES DIALOG
// ============================================================================
class _NuancesDialog extends StatefulWidget {
  final EmotionConfig emotion;
  final List<String> initialSelected;

  const _NuancesDialog({
    required this.emotion,
    required this.initialSelected,
  });

  @override
  State<_NuancesDialog> createState() => _NuancesDialogState();
}

class _NuancesDialogState extends State<_NuancesDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF102A43),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.emotion.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.emotion.icon,
                      color: widget.emotion.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuances de ${widget.emotion.name}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_selected.length} selectionnee(s)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 8),

            // Nuances list
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.emotion.nuances.map((nuance) {
                    final isSelected = _selected.contains(nuance);
                    return FilterChip(
                      label: Text(nuance),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selected.add(nuance);
                          } else {
                            _selected.remove(nuance);
                          }
                        });
                      },
                      selectedColor:
                          widget.emotion.color.withValues(alpha: 0.3),
                      checkmarkColor: widget.emotion.color,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: isSelected
                            ? widget.emotion.color
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected.clear();
                    });
                  },
                  child: Text(
                    'Tout effacer',
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.emotion.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Valider',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

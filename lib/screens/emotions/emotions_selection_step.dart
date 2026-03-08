// lib/screens/emotions/emotions_selection_step.dart
// VERSION 2.0 - Design identique à daily_mood_entry_screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/emotional_state.dart';
import '../../config/emotion_config.dart';

class EmotionsSelectionStep extends StatefulWidget {
  final EmotionalState initialState;
  final Function(EmotionalState) onStateChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const EmotionsSelectionStep({
    super.key,
    required this.initialState,
    required this.onStateChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<EmotionsSelectionStep> createState() => _EmotionsSelectionStepState();
}

class _EmotionsSelectionStepState extends State<EmotionsSelectionStep> {
  late EmotionalState _emotionalState;

  @override
  void initState() {
    super.initState();
    _emotionalState = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFF0F9FF),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header compact
          _buildHeader(),
          
          // Liste des émotions (style daily-mood)
          Expanded(
            child: _buildEmotionsList(),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _emotionalState.emotions.values
        .where((e) => e.level > 0)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '🎭 How are you feeling?',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 4),
          
          Text(
            'Express what you feel in this context',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 12),
          
          // Badge info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  color: const Color(0xFF7C3AED),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${EmotionCategories.allEmotions.length} emotional states available',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Indicateur de drag
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Résumé des émotions sélectionnées
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSummary(),
          ),
          
          // Liste scrollable des émotions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                // Émotions difficiles (négatives)
                ...EmotionCategories.negativeEmotions.map((emotion) {
                  final level = _emotionalState.emotions[emotion.key]?.level ?? 0;
                  final nuances = _emotionalState.emotions[emotion.key]?.nuances ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildEmotionCard(emotion, level, nuances),
                  );
                }),
                
                const SizedBox(height: 16),
                
                // Séparateur visuel
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '✨ Resource emotions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Émotions ressources (positives)
                ...EmotionCategories.positiveEmotions.map((emotion) {
                  final level = _emotionalState.emotions[emotion.key]?.level ?? 0;
                  final nuances = _emotionalState.emotions[emotion.key]?.nuances ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildEmotionCard(emotion, level, nuances),
                  );
                }),
              ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: const Color(0xFF6366F1), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap a card to express how you feel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          Text(
            '${activeEmotions.length} emotion(s) selected',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionCard(EmotionConfig emotion, int level, List<String> nuances) {
    final isSelected = level > 0;
    
    return Column(
      children: [
        // Carte principale (cliquable)
        InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                // Désélectionner
                _updateEmotionLevel(emotion.key, 0, []);
              } else {
                // Sélectionner avec niveau par défaut 5
                _updateEmotionLevel(emotion.key, 5, []);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? emotion.color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? emotion.color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icône PNG de l'émotion
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: emotion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: emotion.iconPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            emotion.iconPath!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(emotion.icon, color: emotion.color, size: 28);
                            },
                          ),
                        )
                      : Icon(emotion.icon, color: emotion.color, size: 28),
                ),
                const SizedBox(width: 12),
                
                // Nom de l'émotion
                Expanded(
                  child: Text(
                    emotion.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? emotion.color : Colors.black87,
                    ),
                  ),
                ),
                
                // Checkbox
                if (isSelected)
                  Icon(Icons.check_circle, color: emotion.color, size: 24),
              ],
            ),
          ),
        ),
        
        // Panneau d'intensité (si sélectionné)
        if (isSelected) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: emotion.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intensité avec échelle 0-10
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intensity:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$level/10',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: emotion.color,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Échelle 0-10 (boutons)
                _buildIntensityScale(emotion, level),
                
                const SizedBox(height: 12),
                
                // Bouton pour préciser les nuances
                OutlinedButton.icon(
                  onPressed: () => _showNuancesDialog(emotion, nuances),
                  icon: Icon(Icons.tune, size: 16, color: emotion.color),
                  label: Text(
                    nuances.isEmpty
                        ? 'Specify nuances'
                        : '${nuances.length} nuance(s) selected',
                    style: GoogleFonts.poppins(
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
                
                // Afficher les nuances sélectionnées
                if (nuances.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: nuances.map((nuance) {
                      return Chip(
                        label: Text(
                          nuance,
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        backgroundColor: emotion.color.withOpacity(0.2),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          final newNuances = List<String>.from(nuances)..remove(nuance);
                          _updateEmotionLevel(emotion.key, level, newNuances);
                        },
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
        // Icône emotion qui change selon la valeur
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
                  color: emotion.color.withOpacity(0.1),
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
        
        // Slider - Couleurs VERT MENTHE (actif) et BLEU PÉTROLE (inactif) des icônes
        Row(
          children: [
            Text(
              '0',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF9FD5A1),  // Vert menthe (icône emotion)
                  inactiveTrackColor: const Color(0xFF2E7D8A).withOpacity(0.3),  // Bleu pétrole
                  thumbColor: const Color(0xFF9FD5A1),  // Vert menthe
                  overlayColor: const Color(0xFF9FD5A1).withOpacity(0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: currentLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (value) {
                    final nuances = _emotionalState.emotions[emotion.key]?.nuances ?? [];
                    _updateEmotionLevel(emotion.key, value.round(), nuances);
                  },
                ),
              ),
            ),
            Text(
              '10',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Raccourcis rapides - Couleur VERT MENTHE
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0, 5, 10].map((quickValue) {
            final isSelected = currentLevel == quickValue;
            return GestureDetector(
              onTap: () {
                final nuances = _emotionalState.emotions[emotion.key]?.nuances ?? [];
                _updateEmotionLevel(emotion.key, quickValue, nuances);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF9FD5A1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF9FD5A1) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$quickValue',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showNuancesDialog(EmotionConfig emotion, List<String> currentNuances) async {
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
    final hasEmotions = _emotionalState.emotions.values
        .any((emotion) => emotion.level > 0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Bouton Retour
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: Image.asset(
                  'assets/univers_visuel/retour.png',
                  width: 16,
                  height: 16,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.arrow_back, size: 16);
                  },
                ),
                label: Text(
                  'Back',
                  style: GoogleFonts.poppins(
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
            
            // Bouton Continuer
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasEmotions ? widget.onNext : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  'See my perspectives',
                  style: GoogleFonts.poppins(
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

  void _updateEmotionLevel(String emotionKey, int level, [List<String>? nuances]) {
    final updatedEmotions = Map<String, EmotionLevel>.from(_emotionalState.emotions);
    
    if (level == 0) {
      updatedEmotions.remove(emotionKey);
    } else {
      updatedEmotions[emotionKey] = EmotionLevel(
        level: level,
        nuances: nuances ?? updatedEmotions[emotionKey]?.nuances ?? [],
      );
    }
    
    final newState = _emotionalState.copyWith(
      emotions: updatedEmotions,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _emotionalState = newState;
    });
    
    widget.onStateChanged(newState);
  }
}

// ============================================================================
// DIALOG POUR SÉLECTIONNER LES NUANCES
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
                    color: widget.emotion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.emotion.icon, color: widget.emotion.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuances of ${widget.emotion.name}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_selected.length} selected',
                        style: GoogleFonts.inter(
                          fontSize: 12,
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
            const Divider(),
            const SizedBox(height: 8),
            
            // Liste des nuances
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
                      selectedColor: widget.emotion.color.withOpacity(0.2),
                      checkmarkColor: widget.emotion.color,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: isSelected ? widget.emotion.color : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons
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
                    'Clear all',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
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
                    'Confirm',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

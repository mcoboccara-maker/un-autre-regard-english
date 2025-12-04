// lib/screens/emotions/emotions_selection_step.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/emotional_state.dart';
import '../../config/emotion_config.dart';
import '../../widgets/emotion_widgets/emotion_card.dart';
import '../../widgets/emotion_widgets/emotion_detail_modal.dart';

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

class _EmotionsSelectionStepState extends State<EmotionsSelectionStep>
    with TickerProviderStateMixin {
  late EmotionalState _emotionalState;

  @override
  void initState() {
    super.initState();
    _emotionalState = widget.initialState;
  }

  /// ✅ OBTENIR TOUTES LES ÉMOTIONS PAR ORDRE ALPHABÉTIQUE
  List<EmotionConfig> get _allEmotionsSorted {
    final allEmotions = List<EmotionConfig>.from(EmotionCategories.allEmotions);
    allEmotions.sort((a, b) => a.name.compareTo(b.name));
    return allEmotions;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ Fond bleu ciel
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
          // ❌ PAS DE TopBar/icône maison - GlobalAppBar s'en occupe
          
          // ✅ Header COMPACT
          _buildHeader(),
          
          // ✅ Contenu émotionnel - ZONE MAXIMISÉE
          Expanded(
            child: _buildEmotionsContent(),
          ),
          
          // ✅ Boutons de navigation COMPACTS
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎭 Comment te sens-tu ?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3, end: 0),
          
          const SizedBox(height: 4),
          
          Text(
            'Exprime ce que tu ressens dans ce contexte',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 8),
          
          // Info Byron Katie - TRÈS COMPACT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  color: const Color(0xFF7C3AED),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_allEmotionsSorted.length} états émotionnels disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

  Widget _buildEmotionsContent() {
    return Container(
      // ✅ Fond blanc pour mieux voir les émotions
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          // Petit indicateur de drag
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Résumé des émotions sélectionnées
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: _buildEmotionSummary(),
          ),
          
          // ✅ GRILLE DES ÉMOTIONS - prend tout l'espace disponible
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95, // ✅ Cartes un peu plus hautes
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _allEmotionsSorted.length,
              itemBuilder: (context, index) {
                final emotion = _allEmotionsSorted[index];
                final emotionLevel = _emotionalState.emotions[emotion.key] ?? 
                    EmotionLevel(level: 0, nuances: []);
                
                return EmotionCard(
                  emotion: emotion,
                  level: emotionLevel.level,
                  nuancesCount: emotionLevel.nuances.length,
                  onTap: () => _showEmotionDetail(emotion),
                  onLevelChanged: (level) => _updateEmotionLevel(emotion.key, level),
                ).animate(delay: Duration(milliseconds: 30 * (index % 6)))
                 .fadeIn()
                 .scale(begin: const Offset(0.95, 0.95));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionSummary() {
    final activeEmotions = _emotionalState.emotions.entries
        .where((entry) => entry.value.level > 0)
        .toList()
      ..sort((a, b) => b.value.level.compareTo(a.value.level));

    if (activeEmotions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app,
              color: const Color(0xFF6366F1),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Touche une carte pour exprimer ce que tu ressens',
                style: GoogleFonts.inter(
                  fontSize: 12,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${activeEmotions.length} émotion(s) sélectionnée(s)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
          const Spacer(),
          // Afficher les premières émotions
          ...activeEmotions.take(3).map((entry) {
            final emotion = EmotionCategories.findByKey(entry.key);
            if (emotion == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: emotion.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${entry.value.level}%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: emotion.color,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// ✅ Boutons de navigation COMPACTS
  Widget _buildNavigationButtons() {
    final hasEmotions = _emotionalState.emotions.values
        .any((emotion) => emotion.level > 0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            // ✅ Bouton Retour - compact
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
                  'Retour',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Bouton continuer - compact
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasEmotions ? widget.onNext : null,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  'Voir mes perspectives',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEmotions 
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: hasEmotions ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmotionDetail(EmotionConfig emotion) {
    final currentLevel = _emotionalState.emotions[emotion.key]?.level ?? 0;
    final currentNuances = _emotionalState.emotions[emotion.key]?.nuances ?? <String>[];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmotionDetailModal(
        emotion: emotion,
        initialLevel: currentLevel,
        initialNuances: currentNuances,
        onSave: (level, nuances) {
          _updateEmotionLevel(emotion.key, level, nuances);
        },
      ),
    );
  }

  void _updateEmotionLevel(String emotionKey, int level, [List<String>? nuances]) {
    final updatedEmotions = Map<String, EmotionLevel>.from(_emotionalState.emotions);
    updatedEmotions[emotionKey] = EmotionLevel(
      level: level,
      nuances: nuances ?? updatedEmotions[emotionKey]?.nuances ?? [],
    );
    
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

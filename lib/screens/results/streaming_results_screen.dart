import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../models/reflection.dart';
import '../../models/emotional_state.dart';
import '../../models/user_profile.dart';
import '../../models/source_evaluation.dart';
import '../../config/approach_config.dart';
import '../../services/ai_service.dart';
import '../../services/persistent_storage_service.dart';
import '../../services/complete_auth_service.dart';
import '../../services/email_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/brain_gestation_widget.dart';
import '../../services/tts_service.dart';
import '../../config/prompts/prompt_synthese.dart';

/// ECRAN STREAMING DES RESULTATS - VERSION FUSIONNEE
/// 
/// Fusionne results_generation_step.dart et results_display_screen.dart
/// Affiche les cartes AU FUR ET A MESURE de leur génération
/// Inclut le système d'évaluation (note 1-10 + commentaire)
class StreamingResultsScreen extends StatefulWidget {
  final String reflectionText;
  final String? declencheur;
  final String? souhait;
  final String? petitPas;
  final ReflectionType reflectionType;
  final EmotionalState emotionalState;
  final List<String> selectedApproaches;
  final VoidCallback onNewReflection;
  final VoidCallback? onBack;

  const StreamingResultsScreen({
    super.key,
    required this.reflectionText,
    this.declencheur,
    this.souhait,
    this.petitPas,
    required this.reflectionType,
    required this.emotionalState,
    required this.selectedApproaches,
    required this.onNewReflection,
    this.onBack,
  });

  @override
  State<StreamingResultsScreen> createState() => _StreamingResultsScreenState();
}

class _StreamingResultsScreenState extends State<StreamingResultsScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _pulseController;
  
  // État de génération
  final Map<String, String> _responses = {};           // Réponses générées
  final Map<String, String> _status = {};              // Status par approche
  final Map<String, SourceEvaluation> _evaluations = {}; // Évaluations
  
  bool _isGenerating = false;
  bool _isComplete = false;
  bool _emailSent = false;
  bool _isSendingEmail = false;
  String? _errorMessage;
  UserProfile? _userProfile;
  
  // Contrôleur pour le scroll automatique
  final ScrollController _scrollController = ScrollController();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TTS & SYNTHÈSE VOCALE
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, String> _syntheses = {};           // Synthèses générées
  final Map<String, bool> _isGeneratingSynthesis = {}; // État de génération
  String? _currentSpeakingKey;                          // Clé en cours de lecture
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialiser les statuts
    for (final approach in widget.selectedApproaches) {
      _status[approach] = 'pending';
    }
    
    // Démarrer la génération
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
      _initTts();
    });
  }
  
  /// Initialiser le service TTS
  Future<void> _initTts() async {
    await TtsService.instance.init();
    TtsService.instance.onStateChanged = (approachKey, isSpeaking) {
      if (mounted) {
        setState(() {
          _currentSpeakingKey = isSpeaking ? approachKey : null;
        });
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    TtsService.instance.stop();  // Arrêter la lecture en cours
    super.dispose();
  }

  /// Calcul de l'intensité émotionnelle
  int _calculateEmotionalIntensity() {
    final activeEmotions = widget.emotionalState.emotions.values
        .where((emotion) => emotion.level > 0)
        .toList();
    
    if (activeEmotions.isEmpty) return 1;
    
    final total = activeEmotions.fold<int>(0, (sum, emotion) => sum + emotion.level);
    return (total / activeEmotions.length).round().clamp(1, 10);
  }

  /// Démarrer la génération des perspectives
  Future<void> _startGeneration() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _isComplete = false;
      _errorMessage = null;
    });
    
    _pulseController.repeat();
    
    print('🚀 DEBUT GENERATION STREAMING');
    
    try {
      // Charger le profil utilisateur
      try {
        _userProfile = PersistentStorageService.instance.getUserProfile();
        print('✅ Profil utilisateur chargé');
      } catch (e) {
        print('⚠️ Impossible de charger le profil: $e');
      }
      
      final intensiteEmotionnelle = _calculateEmotionalIntensity();
      
      // Générer chaque perspective une par une
      for (final approachNameOrKey in widget.selectedApproaches) {
        // Trouver la configuration de l'approche
        ApproachConfig? approach;
        try {
          approach = ApproachCategories.allApproaches
              .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
        } catch (e) {
          print('⚠️ Approche non trouvée: $approachNameOrKey');
          continue;
        }
        
        final approachKey = approach.key;
        
        // Mettre à jour le statut
        setState(() {
          _status[approachNameOrKey] = 'generating';
        });
        
        try {
          print('🔄 Génération pour: ${approach.name}');
          
          // Appel à l'IA
          final response = await AIService.instance.generateApproachSpecificResponse(
            approach: approachKey,
            reflectionText: widget.reflectionText,
            reflectionType: widget.reflectionType,
            emotionalState: widget.emotionalState,
            userProfile: _userProfile,
            declencheur: widget.declencheur,
            souhait: widget.souhait,
            petitPas: widget.petitPas,
            intensiteEmotionnelle: intensiteEmotionnelle,
          );
          
          // Stocker la réponse
          setState(() {
            _responses[approachKey] = response;
            _status[approachNameOrKey] = 'completed';
          });
          
          print('✅ Génération terminée pour: ${approach.name}');
          
          // Scroll vers le bas pour voir la nouvelle carte
          _scrollToBottom();
          
        } catch (e) {
          print('❌ Erreur génération pour ${approach.name}: $e');
          setState(() {
            _status[approachNameOrKey] = 'error';
          });
        }
      }
      
      // Génération terminée
      _pulseController.stop();
      setState(() {
        _isGenerating = false;
        _isComplete = true;
      });
      
      print('🎉 Génération streaming terminée: ${_responses.length} perspectives');
      
      // ✅ IMPORTANT: Sauvegarder la réflexion dans l'historique
      await _saveReflection();
      
      // Sauvegarder les évaluations initiales (vides) localement
      await _saveEvaluationsLocally();
      
    } catch (e) {
      print('❌ Erreur de génération: $e');
      _pulseController.stop();
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  /// Scroll automatique vers le bas
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Mettre à jour une évaluation
  void _updateEvaluation(String sourceKey, String sourceName, int rating, String? comment) {
    setState(() {
      _evaluations[sourceKey] = SourceEvaluation(
        sourceKey: sourceKey,
        sourceName: sourceName,
        rating: rating,
        comment: comment,
        responseText: _responses[sourceKey],
      );
    });
    
    // Sauvegarder immédiatement
    _saveEvaluationsLocally();
  }

  /// Sauvegarder les évaluations localement
  Future<void> _saveEvaluationsLocally() async {
    try {
      // Créer l'objet ReflectionEvaluations
      final reflectionEvaluations = ReflectionEvaluations(
        reflectionId: DateTime.now().millisecondsSinceEpoch.toString(),
        penseeOriginale: widget.reflectionText,
        typeReflexion: widget.reflectionType.displayName,
        emotions: _getEmotionsText(),
        intensite: _calculateEmotionalIntensity(),
        evaluations: _evaluations,
      );
      
      // Sauvegarder via le service
      await PersistentStorageService.instance.saveReflectionEvaluations(reflectionEvaluations);
      
      print('✅ Évaluations sauvegardées localement');
    } catch (e) {
      print('❌ Erreur sauvegarde évaluations: $e');
    }
  }

  /// ✅ Sauvegarder la réflexion dans l'historique (comme l'ancienne version)
  Future<void> _saveReflection() async {
    try {
      final currentUser = await CompleteAuthService.instance.getCurrentUser();
      await PersistentStorageService.instance.setCurrentUser(currentUser ?? '');
      
      final uuid = const Uuid();
      final reflection = Reflection(
        id: uuid.v4(),
        text: widget.reflectionText,
        type: widget.reflectionType,
        emotionalState: widget.emotionalState,
        createdAt: DateTime.now(),
        selectedApproaches: widget.selectedApproaches,
        aiResponses: _responses,
        declencheur: widget.declencheur,
        souhait: widget.souhait,
        petitPas: widget.petitPas,
        intensiteEmotionnelle: _calculateEmotionalIntensity(),
        emotionPrincipale: _getPrincipalEmotion(),
      );

      await PersistentStorageService.instance.saveReflection(reflection);
      print('✅ Réflexion sauvegardée dans l\'historique');
      
    } catch (e) {
      print('❌ Erreur sauvegarde réflexion: $e');
    }
  }

  /// Obtenir l'émotion principale
  String? _getPrincipalEmotion() {
    final activeEmotions = widget.emotionalState.emotions.entries
        .where((e) => e.value.level > 0)
        .toList();
    
    if (activeEmotions.isEmpty) return null;
    
    // Trier par niveau décroissant
    activeEmotions.sort((a, b) => b.value.level.compareTo(a.value.level));
    return activeEmotions.first.key;
  }

  /// Obtenir le texte des émotions
  String _getEmotionsText() {
    final activeEmotions = widget.emotionalState.emotions.entries
        .where((e) => e.value.level > 0)
        .map((e) => e.key)
        .toList();
    return activeEmotions.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tes perspectives',
      headerIconPath: 'assets/univers_visuel/perspectives.png',
      showTitle: false,
      showBackButton: false,
      bottomAction: _isComplete ? _buildNavigationButtons(context) : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4F8),
              Color(0xFFD0E8F0),
              Color(0xFFB8DCE8),
              Color(0xFFD8EEF5),
              Color(0xFFE0F0F5),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              
              if (_errorMessage != null) ...[
                _buildError(),
                const SizedBox(height: 24),
              ],
              
              // Afficher les cartes générées (incluant le widget BrainGestation qui descend)
              ..._buildResultCards(),
              
              // Bouton d'export si terminé
              if (_isComplete && _responses.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildExportButton(),
              ],
              
              const SizedBox(height: 100), // Espace pour le bottomAction
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final completedCount = _status.values.where((s) => s == 'completed').length;
    final totalCount = widget.selectedApproaches.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge avec progression
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isComplete 
                  ? [const Color(0xFF2E8B7B), const Color(0xFF3A9D8C)]
                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (_isComplete ? const Color(0xFF2E8B7B) : const Color(0xFF6366F1)).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isComplete ? Icons.check_circle : Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isComplete 
                      ? '$completedCount perspectives générées'
                      : 'Génération... $completedCount/$totalCount',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 16),
        
        // Titre
        Text(
          _isComplete 
              ? 'Voici différents regards sur ta pensée'
              : 'Génération en cours...',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            height: 1.3,
          ),
        ).animate().fadeIn(delay: 200.ms),
        
        if (_isComplete) ...[
          const SizedBox(height: 8),
          Text(
            'Tu peux noter chaque perspective (optionnel)',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ],
    );
  }

  List<Widget> _buildResultCards() {
    final cards = <Widget>[];
    int numero = 0;
    bool brainWidgetInserted = false;
    
    for (final approachNameOrKey in widget.selectedApproaches) {
      // Trouver l'approche
      ApproachConfig? approach;
      try {
        approach = ApproachCategories.allApproaches
            .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
      } catch (e) {
        continue;
      }
      
      final status = _status[approachNameOrKey] ?? 'pending';
      final response = _responses[approach.key];
      
      // Afficher la carte si complétée ou en cours
      if (status == 'completed' && response != null) {
        numero++;
        cards.add(_buildResultCard(approach, response, numero));
      } else {
        // Insérer le widget BrainGestation AVANT la première carte non complétée
        if (!brainWidgetInserted && _isGenerating) {
          cards.add(_buildBrainGestationWidget());
          brainWidgetInserted = true;
        }
        
        if (status == 'generating') {
          cards.add(_buildGeneratingCard(approach));
        } else if (status == 'pending') {
          cards.add(_buildPendingCard(approach));
        } else if (status == 'error') {
          cards.add(_buildErrorCard(approach));
        }
      }
    }
    
    // Si tout est terminé, afficher l'image finale en bas
    if (_isComplete && _responses.isNotEmpty) {
      cards.add(_buildFinalBrainWidget());
    }
    
    return cards;
  }
  
  /// Widget BrainGestation pendant la génération (descend au fur et à mesure)
  Widget _buildBrainGestationWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            BrainGestationWidget(
              isComplete: false,
              size: 180,
              loadingImagePath: 'assets/univers_visuel/brain_loading.png',
              completeImagePath: 'assets/univers_visuel/brain_complete.png',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Réflexion en gestation...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Widget final quand tout est terminé - Invitation à partager
  Widget _buildFinalBrainWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: Center(
        child: Column(
          children: [
            // Image cerveau terminé
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/univers_visuel/brain_complete.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 60,
                    color: Color(0xFF2E8B7B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Toutes les perspectives sont générées',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF2E8B7B),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            // Icône email d'invitation à partager
            Image.asset(
              'assets/univers_visuel/evaluation/envmail.png',
              width: 60,
              height: 60,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.email_outlined,
                size: 50,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Merci de partager tes évaluations',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildResultCard(ApproachConfig approach, String response, int numero) {
    // Couleurs pour les numéros
    final numeroColors = [
      const Color(0xFF2E8B7B),
      const Color(0xFFD4AF37),
      const Color(0xFF6B5B95),
      const Color(0xFFE67E22),
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
      const Color(0xFF1ABC9C),
      const Color(0xFF9B59B6),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
    ];
    final numeroColor = numeroColors[(numero - 1) % numeroColors.length];
    
    // Récupérer l'évaluation existante
    final evaluation = _evaluations[approach.key];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: approach.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: approach.color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Numéro stylisé
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [numeroColor, numeroColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: numeroColor.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Icône de la source (PNG) - construit dynamiquement à partir de la clé
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: approach.color.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/univers_visuel/${approach.key}.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(approach.icon, size: 20, color: approach.color),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approach.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: approach.color,
                        ),
                      ),
                      Text(
                        'Éclairage IA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge OpenAI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: approach.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 12, color: approach.color),
                      const SizedBox(width: 4),
                      Text(
                        'OpenAI',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: approach.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // CONTENU
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              response,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1E293B),
                height: 1.7,
              ),
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // BOUTONS LECTURE VOCALE
          // ═══════════════════════════════════════════════════════════════════
          _buildVoiceButtons(approach, response),
          
          // SECTION ÉVALUATION
          _buildEvaluationSection(approach, evaluation),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildEvaluationSection(ApproachConfig approach, SourceEvaluation? evaluation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: approach.color.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            children: [
              Icon(Icons.star_outline, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Ton avis sur cet éclairage (optionnel)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Échelle de notation 1-10
          _buildRatingScale(approach, evaluation?.rating),
          
          const SizedBox(height: 12),
          
          // Champ commentaire
          _buildCommentField(approach, evaluation?.comment),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUTONS LECTURE VOCALE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildVoiceButtons(ApproachConfig approach, String response) {
    final isSpeakingFull = _currentSpeakingKey == '${approach.key}_full';
    final isSpeakingSynthesis = _currentSpeakingKey == '${approach.key}_synthesis';
    final isGenerating = _isGeneratingSynthesis[approach.key] == true;
    final hasSynthesis = _syntheses.containsKey(approach.key);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: approach.color.withOpacity(0.03),
        border: Border(
          top: BorderSide(color: approach.color.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Icône haut-parleur
          Icon(
            Icons.volume_up_rounded,
            size: 18,
            color: approach.color.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Écouter',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          
          // Bouton "Texte complet"
          _buildVoiceButton(
            label: isSpeakingFull ? 'Stop' : 'Complet',
            icon: isSpeakingFull ? Icons.stop_rounded : Icons.play_arrow_rounded,
            isActive: isSpeakingFull,
            color: approach.color,
            onTap: () => _speakFullText(approach.key, response),
          ),
          
          const SizedBox(width: 8),
          
          // Bouton "Synthèse"
          _buildVoiceButton(
            label: isGenerating 
                ? '...' 
                : (isSpeakingSynthesis ? 'Stop' : 'Synthèse'),
            icon: isGenerating 
                ? Icons.hourglass_top_rounded
                : (isSpeakingSynthesis ? Icons.stop_rounded : Icons.auto_awesome),
            isActive: isSpeakingSynthesis,
            isLoading: isGenerating,
            color: approach.color,
            onTap: isGenerating 
                ? null 
                : () => _speakSynthesis(approach, response),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color color,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(isActive ? 1 : 0.3),
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive ? Colors.white : color,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : color,
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Lire le texte complet
  Future<void> _speakFullText(String approachKey, String text) async {
    await TtsService.instance.speak(
      text,
      approachKey: '${approachKey}_full',
    );
  }
  
  /// Générer et lire la synthèse
  Future<void> _speakSynthesis(ApproachConfig approach, String originalText) async {
    final synthesisKey = '${approach.key}_synthesis';
    
    // Si déjà en lecture, arrêter
    if (_currentSpeakingKey == synthesisKey) {
      await TtsService.instance.stop();
      return;
    }
    
    // Si synthèse déjà générée, la lire directement
    if (_syntheses.containsKey(approach.key)) {
      await TtsService.instance.speak(
        _syntheses[approach.key]!,
        approachKey: synthesisKey,
      );
      return;
    }
    
    // Générer la synthèse via l'API
    setState(() {
      _isGeneratingSynthesis[approach.key] = true;
    });
    
    try {
      final synthesis = await _generateSynthesis(approach.name, originalText);
      
      if (mounted) {
        setState(() {
          _syntheses[approach.key] = synthesis;
          _isGeneratingSynthesis[approach.key] = false;
        });
        
        // Lire la synthèse générée
        await TtsService.instance.speak(
          synthesis,
          approachKey: synthesisKey,
        );
      }
    } catch (e) {
      print('❌ Erreur génération synthèse: $e');
      if (mounted) {
        setState(() {
          _isGeneratingSynthesis[approach.key] = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(PromptSynthese.errorMessage),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  /// Appeler l'API OpenAI pour générer la synthèse
  Future<String> _generateSynthesis(String sourceName, String originalText) async {
    final userPrompt = PromptSynthese.buildUserPrompt(
      sourceName: sourceName,
      originalText: originalText,
    );
    
    // Utiliser AIService pour l'appel API
    final synthesis = await AIService.instance.generateSynthesis(
      systemPrompt: PromptSynthese.systemPrompt,
      userPrompt: userPrompt,
      model: PromptSynthese.model,
      temperature: PromptSynthese.temperature,
      maxTokens: PromptSynthese.maxTokens,
    );
    
    return synthesis;
  }

  Widget _buildRatingScale(ApproachConfig approach, int? currentRating) {
    final rating = currentRating ?? 5;
    
    return Column(
      children: [
        // Icône evaluation qui change selon la valeur
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/univers_visuel/evaluation/evaluation$rating.png',
              width: 48,
              height: 48,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: approach.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rating',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: approach.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Slider (curseur) - Couleurs BLEU PÉTROLE (actif) et VERT MENTHE (inactif) des icônes
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
                  activeTrackColor: const Color(0xFF2E7D8A),  // Bleu pétrole (icône evaluation)
                  inactiveTrackColor: const Color(0xFF9FD5A1).withOpacity(0.3),  // Vert menthe
                  thumbColor: const Color(0xFF2E7D8A),  // Bleu pétrole
                  overlayColor: const Color(0xFF2E7D8A).withOpacity(0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: rating.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (value) {
                    _updateEvaluation(
                      approach.key,
                      approach.name,
                      value.round(),
                      _evaluations[approach.key]?.comment,
                    );
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
        
        // Raccourcis rapides - Couleur BLEU PÉTROLE
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0, 5, 10].map((quickValue) {
            final isSelected = rating == quickValue;
            return GestureDetector(
              onTap: () {
                _updateEvaluation(
                  approach.key,
                  approach.name,
                  quickValue,
                  _evaluations[approach.key]?.comment,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D8A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2E7D8A) : const Color(0xFFE2E8F0),
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

  Widget _buildCommentField(ApproachConfig approach, String? currentComment) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Commentaire (optionnel)...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: approach.color, width: 1.5),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
      maxLines: 2,
      onChanged: (value) {
        final currentRating = _evaluations[approach.key]?.rating ?? 5;
        _updateEvaluation(approach.key, approach.name, currentRating, value);
      },
      controller: TextEditingController(text: currentComment)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: currentComment?.length ?? 0),
        ),
    );
  }

  Widget _buildGeneratingCard(ApproachConfig approach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: approach.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(approach.icon, size: 20, color: approach.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              approach.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'En cours...',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms);
  }

  Widget _buildPendingCard(ApproachConfig approach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(approach.icon, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              approach.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const Icon(Icons.hourglass_empty, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            'En attente',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ApproachConfig approach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(approach.icon, size: 20, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              approach.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          const Icon(Icons.error_outline, size: 18, color: Colors.red),
          const SizedBox(width: 6),
          Text(
            'Erreur',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // _buildGeneratingIndicator() supprimée - remplacée par _buildBrainGestationWidget() intégré dans _buildResultCards()

  Widget _buildExportButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _emailSent || _isSendingEmail ? null : _sendByEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: _emailSent ? const Color(0xFF10B981) : const Color(0xFF2563EB),
          disabledBackgroundColor: _emailSent ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSendingEmail) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ] else ...[
              Image.asset(
                'assets/univers_visuel/evaluation/envmail.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => Icon(
                  _emailSent ? Icons.check_circle : Icons.email,
                  size: 20,
                ),
              ),
            ],
            const SizedBox(width: 10),
            Text(
              _emailSent 
                  ? 'Évaluations partagées ✓'
                  : _isSendingEmail
                      ? 'Envoi en cours...'
                      : 'Partager mes évaluations par email',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Envoyer les perspectives par email via Brevo
  Future<void> _sendByEmail() async {
    // Récupérer l'email de l'utilisateur connecté
    final userEmail = CompleteAuthService.instance.currentUserEmail;
    
    if (userEmail == null || userEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun email utilisateur trouvé. Connecte-toi d\'abord.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isSendingEmail = true;
    });
    
    try {
      // Préparer les données pour l'email
      final Map<String, String> perspectives = {};
      final Map<String, int> evaluationsMap = {};
      final Map<String, String> commentairesMap = {};
      
      for (final entry in _responses.entries) {
        // Trouver le nom de la source
        final approach = ApproachCategories.allApproaches
            .where((a) => a.key == entry.key)
            .firstOrNull;
        final sourceName = approach?.name ?? entry.key;
        
        perspectives[sourceName] = entry.value;
        
        // Ajouter l'évaluation si elle existe
        final evaluation = _evaluations[entry.key];
        if (evaluation != null) {
          evaluationsMap[sourceName] = evaluation.rating;
          if (evaluation.comment != null && evaluation.comment!.isNotEmpty) {
            commentairesMap[sourceName] = evaluation.comment!;
          }
        }
      }
      
      // Envoyer via EmailService
      final result = await EmailService.instance.sendPerspectives(
        toEmail: userEmail,
        pensee: widget.reflectionText,
        perspectives: perspectives,
        evaluations: evaluationsMap.isNotEmpty ? evaluationsMap : null,
        commentaires: commentairesMap.isNotEmpty ? commentairesMap : null,
      );
      
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
          _emailSent = result.success;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.success 
                        ? 'Email envoyé à $userEmail'
                        : 'Erreur: ${result.message}',
                  ),
                ),
              ],
            ),
            backgroundColor: result.success ? const Color(0xFF10B981) : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: result.success ? 3 : 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Exception envoi email: $e');
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erreur de génération',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Erreur inconnue',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _startGeneration,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton nouvelle réflexion - VA VERS HOME
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(
              'Nouvelle réflexion',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B7B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
              shadowColor: const Color(0xFF2E8B7B).withOpacity(0.4),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton retour accueil
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            icon: Image.asset(
              'assets/univers_visuel/menu_principal.png',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(Icons.home, size: 18),
            ),
            label: Text(
              'Retour au menu',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E8B7B),
              side: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
import '../../config/prompts/fr/prompt_synthese.dart';

/// ECRAN STREAMING DES RESULTATS - VERSION FUSIONNEE
/// 
/// Fusionne results_generation_step.dart et results_display_screen.dart
/// Affiche les cartes AU FUR ET A MESURE de leur génération
/// Inclut le système d'évaluation (note 1-10 + commentaire)
/// 
/// VERSION 2.0 : Ajout approfondissement + relance erreurs + partage évaluation
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
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPTION C : FILE D'ATTENTE DES PERSPECTIVES
  // La première s'affiche auto, les suivantes attendent que l'utilisateur clique
  // ═══════════════════════════════════════════════════════════════════════════
  final Set<String> _revealedKeys = {};                // Perspectives révélées à l'utilisateur
  bool _isFirstReveal = true;                          // Pour savoir si c'est la première carte
  final Map<String, GlobalKey> _cardKeys = {};         // Keys pour scroll vers carte précise
  
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
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: APPROFONDISSEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, bool> _isDeepening = {};           // État d'approfondissement en cours
  final Map<String, String> _deepenedResponses = {};   // Réponses approfondies
  
  // NOUVEAU: Partage d'évaluation
  final Map<String, bool> _evaluationShared = {};      // Évaluations partagées
  
  // NOUVEAU: Compteur de relance erreurs
  int _errorRetryCount = 0;
  static const int _maxErrorRetries = 1;
  
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
            
            // OPTION C : Révéler automatiquement la PREMIÈRE perspective
            if (_isFirstReveal) {
              _revealedKeys.add(approachKey);
              _isFirstReveal = false;
              // Scroll seulement pour la première carte
              _scrollToBottom();
            }
            // Les suivantes restent en attente - pas de scroll auto
          });
          
          print('✅ Génération terminée pour: ${approach.name}');
          
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
      
      // ═══════════════════════════════════════════════════════════════════════
      // NOUVEAU: Relancer les sources en erreur (une seule fois)
      // ═══════════════════════════════════════════════════════════════════════
      if (_errorRetryCount < _maxErrorRetries) {
        final errorSources = _status.entries
            .where((e) => e.value == 'error')
            .map((e) => e.key)
            .toList();
        
        if (errorSources.isNotEmpty) {
          _errorRetryCount++;
          print('🔄 Relance des ${errorSources.length} source(s) en erreur...');
          
          for (final approachNameOrKey in errorSources) {
            // Trouver la configuration de l'approche
            ApproachConfig? approach;
            try {
              approach = ApproachCategories.allApproaches
                  .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
            } catch (e) {
              continue;
            }
            
            final approachKey = approach.key;
            
            setState(() {
              _status[approachNameOrKey] = 'generating';
            });
            
            try {
              print('🔄 Relance pour: ${approach.name}');
              
              final response = await AIService.instance.generateApproachSpecificResponse(
                approach: approachKey,
                reflectionText: widget.reflectionText,
                reflectionType: widget.reflectionType,
                emotionalState: widget.emotionalState,
                userProfile: _userProfile,
                declencheur: widget.declencheur,
                souhait: widget.souhait,
                petitPas: widget.petitPas,
                intensiteEmotionnelle: _calculateEmotionalIntensity(),
              );
              
              setState(() {
                _responses[approachKey] = response;
                _status[approachNameOrKey] = 'completed';
              });
              
              print('✅ Relance réussie pour: ${approach.name}');
              
            } catch (e) {
              print('❌ Échec relance pour ${approach.name}: $e');
              setState(() {
                _status[approachNameOrKey] = 'error';
              });
            }
          }
        }
      }
      
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
    // Calculer le nombre de perspectives en attente
    final pendingCount = _responses.keys.where((key) => !_revealedKeys.contains(key)).length;
    
    return AppScaffold(
      title: 'Tes perspectives',
      headerIconPath: 'assets/univers_visuel/perspectives.png',
      showTitle: false,
      showBackButton: false,
      bottomAction: _isComplete ? _buildNavigationButtons(context) : null,
      body: Stack(
        children: [
          // CONTENU PRINCIPAL
          Container(
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
          
          // ═══════════════════════════════════════════════════════════════════
          // BOUTON FLOTTANT "X perspectives disponibles" (Option C)
          // ═══════════════════════════════════════════════════════════════════
          if (pendingCount > 0)
            Positioned(
              bottom: _isComplete ? 180 : 20,
              left: 20,
              right: 20,
              child: _buildPendingPerspectivesButton(pendingCount),
            ),
        ],
      ),
    );
  }
  
  /// Bouton flottant pour révéler les perspectives en attente
  Widget _buildPendingPerspectivesButton(int count) {
    return GestureDetector(
      onTap: _revealNextPerspective,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                count == 1 
                    ? 'Nouvelle perspective disponible'
                    : 'Nouvelles perspectives disponibles',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .moveY(begin: 0, end: -4, duration: 1000.ms);
  }
  
  /// Révéler la prochaine perspective en attente
  void _revealNextPerspective() {
    // Trouver la prochaine clé non révélée (dans l'ordre de selectedApproaches)
    for (final approachNameOrKey in widget.selectedApproaches) {
      ApproachConfig? approach;
      try {
        approach = ApproachCategories.allApproaches
            .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
      } catch (e) {
        continue;
      }
      
      final key = approach.key;
      if (_responses.containsKey(key) && !_revealedKeys.contains(key)) {
        setState(() {
          _revealedKeys.add(key);
        });
        
        // Scroll vers le DÉBUT de la nouvelle carte (pas vers le bas)
        _scrollToCard(key);
        break;
      }
    }
  }
  
  /// Scroll vers une carte spécifique par sa clé
  void _scrollToCard(String cardKey) {
    // Délai augmenté pour attendre la fin de l'animation (fadeIn 200ms + slideY)
    Future.delayed(const Duration(milliseconds: 600), () {
      final key = _cardKeys[cardKey];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          alignment: 0.05, // Petite marge pour voir le titre complet
        );
      }
    });
  }
  
  /// Nettoyer le texte Markdown pour supprimer les éléments de structure
  /// tout en gardant le gras (**) et l'italique (*)
  String _cleanMarkdown(String text) {
    return text
        // Supprimer les lignes de séparation (underscores multiples)
        .replaceAll(RegExp(r'_{3,}'), '')
        // Supprimer les titres de section ## X. TITRE
        .replaceAll(RegExp(r'##\s*\d+\.\s*[A-ZÉÈÊËÀÂÄÙÛÜÔÖÎÏ\s]+\n'), '')
        // Supprimer les blocs FIGURE_META
        .replaceAll(RegExp(r'\[FIGURE_META\][\s\S]*?\[/FIGURE_META\]'), '')
        // Supprimer les lignes vides multiples
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Widget _buildHeader() {
    final completedCount = _status.values.where((s) => s == 'completed').length;
    final revealedCount = _revealedKeys.length;
    final totalCount = widget.selectedApproaches.length;
    final pendingToReveal = completedCount - revealedCount;
    
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
                      ? '$revealedCount/$completedCount perspectives lues'
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
      
      // OPTION C : Afficher la carte UNIQUEMENT si révélée par l'utilisateur
      if (status == 'completed' && response != null && _revealedKeys.contains(approach.key)) {
        numero++;
        // Créer une GlobalKey pour cette carte si elle n'existe pas
        _cardKeys.putIfAbsent(approach.key, () => GlobalKey());
        cards.add(_buildResultCard(approach, response, numero, _cardKeys[approach.key]!));
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

  Widget _buildResultCard(ApproachConfig approach, String response, int numero, GlobalKey cardKey) {
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
    
    // NOUVEAU: Vérifier si approfondissement disponible
    final hasDeepened = _deepenedResponses.containsKey(approach.key);
    final isDeepening = _isDeepening[approach.key] == true;

    return Container(
      key: cardKey, // Key pour scroll précis
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
                
                // Badge Claude (au lieu d'OpenAI)
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
                        'Claude',
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
          
          // CONTENU - Rendu Markdown (gras, italique)
          Padding(
            padding: const EdgeInsets.all(20),
            child: MarkdownBody(
              data: _cleanMarkdown(response),
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                  height: 1.7,
                ),
                strong: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 1.7,
                ),
                em: GoogleFonts.inter(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1E293B),
                  height: 1.7,
                ),
              ),
              selectable: true,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // NOUVEAU: AFFICHER L'APPROFONDISSEMENT S'IL EXISTE
          // ═══════════════════════════════════════════════════════════════════
          if (hasDeepened) ...[
            const Divider(height: 1),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: approach.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: approach.color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: approach.color),
                      const SizedBox(width: 8),
                      Text(
                        'Approfondissement',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: approach.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: _cleanMarkdown(_deepenedResponses[approach.key]!),
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: const Color(0xFF1E293B),
                      ),
                      strong: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                      em: GoogleFonts.inter(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    selectable: true,
                  ),
                ],
              ),
            ),
          ],
          
          // ═══════════════════════════════════════════════════════════════════
          // BOUTONS LECTURE VOCALE
          // ═══════════════════════════════════════════════════════════════════
          _buildVoiceButtons(approach, response),
          
          // ═══════════════════════════════════════════════════════════════════
          // NOUVEAU: BOUTONS APPROFONDIR + PARTAGER (layout 50/50)
          // ═══════════════════════════════════════════════════════════════════
          _buildActionButtons(approach, evaluation, hasDeepened, isDeepening),
          
          // SECTION ÉVALUATION
          _buildEvaluationSection(approach, evaluation),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: BOUTONS D'ACTION (Approfondir + Partager évaluation)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildActionButtons(ApproachConfig approach, SourceEvaluation? evaluation, bool hasDeepened, bool isDeepening) {
    final hasComment = evaluation?.comment != null && evaluation!.comment!.isNotEmpty;
    final isShared = _evaluationShared[approach.key] == true;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: approach.color.withOpacity(0.03),
        border: Border(
          top: BorderSide(color: approach.color.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Bouton Approfondir (50%)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (isDeepening || hasDeepened) ? null : () => _deepen(approach),
              icon: isDeepening
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      hasDeepened ? Icons.check : Icons.search,
                      size: 18,
                    ),
              label: Text(
                isDeepening ? 'En cours...' : (hasDeepened ? 'Approfondi' : 'Approfondir'),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDeepened 
                    ? const Color(0xFF94A3B8) 
                    : approach.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Bouton Partager évaluation (50%)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (isShared || !hasComment) ? null : () => _shareEvaluation(approach, evaluation),
              icon: Icon(
                isShared ? Icons.check : Icons.send_outlined,
                size: 18,
              ),
              label: Text(
                isShared ? 'Envoyé' : 'Partager avis',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isShared ? const Color(0xFF94A3B8) : approach.color,
                side: BorderSide(
                  color: isShared ? const Color(0xFF94A3B8) : approach.color.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: MÉTHODE APPROFONDISSEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _deepen(ApproachConfig approach) async {
    setState(() {
      _isDeepening[approach.key] = true;
    });
    
    try {
      final reponseCourte = _responses[approach.key] ?? '';
      
      // Extraire le nom de la figure depuis FIGURE_META si disponible
      String figureNom = 'Figure';
      final metaMatch = RegExp(r'\[FIGURE_META\][\s\S]*?nom:\s*(.+?)[\n\[]').firstMatch(reponseCourte);
      if (metaMatch != null) {
        figureNom = metaMatch.group(1)?.trim() ?? 'Figure';
      }
      
      final deepResponse = await AIService.instance.generateDeepening(
        penseeOriginale: widget.reflectionText,
        reponseCourte: reponseCourte,
        sourceNom: approach.name,
        figureNom: figureNom,
      );
      
      setState(() {
        _deepenedResponses[approach.key] = deepResponse;
        _isDeepening[approach.key] = false;
      });
      
    } catch (e) {
      print('❌ Erreur approfondissement: $e');
      setState(() {
        _isDeepening[approach.key] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'approfondissement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: MÉTHODE PARTAGE ÉVALUATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _shareEvaluation(ApproachConfig approach, SourceEvaluation? evaluation) async {
    if (evaluation?.comment == null || evaluation!.comment!.isEmpty) return;
    
    // Afficher un indicateur de chargement
    setState(() {
      _evaluationShared[approach.key] = false; // En cours d'envoi
    });
    
    try {
      print('📧 Envoi évaluation en arrière-plan pour: ${approach.name}');
      
      // Utiliser EmailService.sendPerspectives avec les paramètres d'évaluation
      // On envoie à l'adresse de feedback de l'app
      final result = await EmailService.instance.sendPerspectives(
        toEmail: 'appunautreregard@gmail.com',
        pensee: '[ÉVALUATION] ${approach.name}',
        perspectives: {
          approach.name: 'Note: ${evaluation.rating ?? "Non notée"}/10\nCommentaire: ${evaluation.comment}',
        },
        evaluations: {approach.name: evaluation.rating ?? 0},
        commentaires: {approach.name: evaluation.comment ?? ''},
      );
      
      if (mounted) {
        setState(() {
          _evaluationShared[approach.key] = result.success;
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
                        ? 'Merci pour votre avis !'
                        : 'Erreur: ${result.message}',
                  ),
                ),
              ],
            ),
            backgroundColor: result.success ? const Color(0xFF10B981) : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        if (result.success) {
          print('✅ Évaluation envoyée avec succès');
        } else {
          print('❌ Erreur envoi: ${result.message}');
        }
      }
      
    } catch (e) {
      print('❌ Erreur partage évaluation: $e');
      if (mounted) {
        setState(() {
          _evaluationShared[approach.key] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  
  /// Appeler l'API pour générer la synthèse
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: approach.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(approach.color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Génération ${approach.name}...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: approach.color,
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
      .shimmer(duration: 1500.ms, color: approach.color.withOpacity(0.1));
  }

  Widget _buildPendingCard(ApproachConfig approach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              approach.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approach.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Erreur de génération',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: _emailSent || _isSendingEmail ? null : _sendByEmail,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSendingEmail) ...[
              const SizedBox(
                width: 20,
                height: 20,
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

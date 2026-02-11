// lib/screens/wisdom_wheel_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// ROUE DE LA SAGESSE - ÉCRAN D'ACCUEIL PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
// 
// Premier écran de l'application avec :
// - Roue tournante avec TOUTES les sources (spirituelles, psycho, littéraires, philo)
// - Icône de l'app pour accéder à welcome_screen (app complète)
// - Affichage de la source obtenue
// - Saisie de pensée
// - Double appel API : génération + contrôle qualité (via AIService)
// - Lecture vocale (complète ou synthèse)
// - Bruit de roue de fête foraine (vibrations + son)
// - Pas de connexion, pas d'historique
//
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/approach_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../config/prompts/fr/prompt_synthese.dart';
import '../theme/lighting_profiles.dart';
import 'perspective_room_screen.dart';

class WisdomWheelScreen extends StatefulWidget {
  const WisdomWheelScreen({super.key});

  @override
  State<WisdomWheelScreen> createState() => _WisdomWheelScreenState();
}

class _WisdomWheelScreenState extends State<WisdomWheelScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VARIABLES D'ÉTAT
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Toutes les sources disponibles
  late List<ApproachConfig> _allSources;
  
  /// Construit la liste limitée des sources (sans spirituelles, 6 par type)
  List<ApproachConfig> _buildLimitedSources() {
    final List<ApproachConfig> limited = [];
    
    // Récupérer 6 sources de chaque type (sauf spirituel)
    final psychological = ApproachCategories.allApproaches
        .where((a) => a.type == ApproachType.psychological)
        .take(6)
        .toList();
    
    final literary = ApproachCategories.allApproaches
        .where((a) => a.type == ApproachType.literary)
        .take(6)
        .toList();
    
    final philosophical = ApproachCategories.allApproaches
        .where((a) => a.type == ApproachType.philosophical)
        .take(6)
        .toList();
    
    final philosophers = ApproachCategories.allApproaches
        .where((a) => a.type == ApproachType.philosopher)
        .take(6)
        .toList();
    
    // Combiner toutes les sources
    limited.addAll(psychological);
    limited.addAll(literary);
    limited.addAll(philosophical);
    limited.addAll(philosophers);
    
    return limited;
  }
  
  // Contrôleurs d'animation
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  
  // Animation du sablier (rotation continue)
  late AnimationController _hourglassController;
  
  // Audio pour le son de la roue
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _tickTimer;
  
  // État de la roue
  double _currentRotation = 0;
  bool _isSpinning = false;
  ApproachConfig? _selectedSource;
  
  // Saisie de pensée
  final TextEditingController _thoughtController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Génération IA (double appel : prompt général + contrôle)
  bool _isGenerating = false;
  String? _generatedResponse;
  String? _errorMessage;
  
  // TTS - Lecture vocale
  String? _synthesis;
  bool _isGeneratingSynthesis = false;
  bool _isSpeakingFull = false;
  bool _isSpeakingSynthesis = false;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: Approfondissement
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isDeepening = false;
  String? _deepenedResponse;
  
  // Scroll controller pour la vue résultat
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Charger TOUTES les sources (spirituelles + psycho + littéraires + philo + philosophes)
    // Charger les sources limitées (sans spirituelles, 3 par type = 12 total)
    _allSources = _buildLimitedSources();
    
    // Animation de la roue avec décélération
    _wheelController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    // Animation du sablier (rotation continue)
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Rotation infinie
    
    // Initialiser le service TTS
    _initTts();
  }
  
  Future<void> _initTts() async {
    await TtsService.instance.init();
    TtsService.instance.onStateChanged = (key, isSpeaking) {
      if (mounted) {
        setState(() {
          _isSpeakingFull = key == 'full' && isSpeaking;
          _isSpeakingSynthesis = key == 'synthesis' && isSpeaking;
        });
      }
    };
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _hourglassController.dispose();
    _thoughtController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _tickTimer?.cancel();
    _scrollController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIQUE DE LA ROUE
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _spinWheel() {
    if (_isSpinning) return;
    
    // Reset état
    setState(() {
      _isSpinning = true;
      _selectedSource = null;
      _generatedResponse = null;
      _synthesis = null;
      _deepenedResponse = null;  // ✅ NOUVEAU: Reset approfondissement
      _errorMessage = null;
    });
    
    // Nombre de tours aléatoire (4 à 7 tours) + position finale aléatoire
    final random = math.Random();
    final extraTurns = 4 + random.nextInt(4);
    final finalPosition = random.nextDouble();
    final totalRotation = (extraTurns * 2 * math.pi) + (finalPosition * 2 * math.pi);
    
    // Animation avec décélération réaliste (easeOutCubic)
    _wheelAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + totalRotation,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: Curves.easeOutCubic,
    ));
    
    // Démarrer le son/vibrations de rotation
    _startTickSound();
    
    // Écouter l'animation
    _wheelController.reset();
    _wheelController.forward().then((_) {
      _stopTickSound();
      
      // Calculer la source sélectionnée
      final finalAngle = _wheelAnimation.value % (2 * math.pi);
      final segmentAngle = (2 * math.pi) / _allSources.length;
      // Ajuster pour que l'indicateur soit en haut
      final adjustedAngle = (finalAngle + math.pi / 2) % (2 * math.pi);
      final selectedIndex = (adjustedAngle / segmentAngle).floor() % _allSources.length;
      
      setState(() {
        _isSpinning = false;
        _currentRotation = _wheelAnimation.value;
        _selectedSource = _allSources[selectedIndex];
      });
      
      // Vibration de fin (impact fort)
      HapticFeedback.heavyImpact();
      
      // Annoncer la source sélectionnée vocalement
      _announceSelection();
    });
  }
  
  void _startTickSound() {
    // Simuler le son de la roue avec des vibrations rapides décroissantes
    int tickCount = 0;
    int tickInterval = 30; // Millisecondes entre chaque tick
    
    _tickTimer = Timer.periodic(Duration(milliseconds: tickInterval), (timer) {
      if (!_isSpinning) {
        timer.cancel();
        return;
      }
      
      tickCount++;
      
      // Décélérer les ticks progressivement (comme une vraie roue)
      if (tickCount < 20) {
        HapticFeedback.lightImpact();
      } else if (tickCount < 40) {
        if (tickCount % 2 == 0) HapticFeedback.lightImpact();
      } else if (tickCount < 60) {
        if (tickCount % 3 == 0) HapticFeedback.selectionClick();
      } else if (tickCount < 80) {
        if (tickCount % 4 == 0) HapticFeedback.selectionClick();
      } else {
        if (tickCount % 6 == 0) HapticFeedback.selectionClick();
      }
    });
    
    // Jouer le son de roue si fichier disponible
    _playWheelSound();
  }
  
  void _stopTickSound() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _audioPlayer.stop();
  }
  
  Future<void> _playWheelSound() async {
    try {
      // Essayer de jouer un son de roue depuis les assets
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource('sounds/wheel_spin.mp3'));
    } catch (e) {
      // Si le fichier n'existe pas, on utilise juste les vibrations
      print('🔇 Son de roue non disponible (vibrations uniquement): $e');
    }
  }
  
  void _announceSelection() {
    if (_selectedSource != null) {
      // Petit délai puis annonce vocale
      Future.delayed(const Duration(milliseconds: 600), () {
        TtsService.instance.speak(
          'La roue a choisi : ${_selectedSource!.name}',
          approachKey: 'announce',
        );
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION IA (DOUBLE APPEL : PROMPT GÉNÉRAL + CONTRÔLE)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _generateResponse() async {
    if (_selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tourne d\'abord la roue pour choisir une source !',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    if (_thoughtController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saisis ta pensée ou situation avant de générer',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedResponse = null;
      _synthesis = null;
    });
    
    // Cacher le clavier
    FocusScope.of(context).unfocus();
    
    try {
      // ═══════════════════════════════════════════════════════════════════════
      // APPEL AIService.generateApproachSpecificResponse
      // Cette méthode fait DÉJÀ le double appel :
      // 1. Génération avec le prompt général (PromptGeneral.build)
      // 2. Contrôle qualité (_controlResponse)
      // ═══════════════════════════════════════════════════════════════════════
      
      final response = await AIService.instance.generateApproachSpecificResponse(
        approach: _selectedSource!.key,
        reflectionText: _thoughtController.text.trim(),
        reflectionType: ReflectionType.thought, // Type par défaut
        emotionalState: EmotionalState.empty(), // État émotionnel vide (mode standalone)
        userProfile: null, // Pas de profil en mode standalone (pas de connexion)
        intensiteEmotionnelle: 50, // Intensité par défaut
      );
      
      if (mounted) {
        setState(() {
          _generatedResponse = response;
          _isGenerating = false;
        });

        // Naviguer vers la PerspectiveRoom (CDC cinématique)
        _openPerspectiveRoom(response);
      }
    } catch (e) {
      print('❌ Erreur génération: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la génération. Réessaie.';
          _isGenerating = false;
        });
      }
    }
  }

  /// Ouvrir la PerspectiveRoom avec la réponse générée
  void _openPerspectiveRoom(String response) {
    final perspective = PerspectiveData(
      approachKey: _selectedSource!.key,
      approachName: _selectedSource!.name,
      responseText: response,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PerspectiveRoomScreen(
            thoughtText: _thoughtController.text.trim(),
            perspectives: [perspective],
            onClose: () => Navigator.of(context).pop(),
            onDeepen: (approachKey) {
              _deepenInPerspectiveRoom(approachKey, response);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Approfondissement depuis la PerspectiveRoom
  Future<void> _deepenInPerspectiveRoom(String approachKey, String originalResponse) async {
    try {
      final deepResponse = await AIService.instance.generateDeepening(
        penseeOriginale: _thoughtController.text.trim(),
        reponseCourte: originalResponse,
        sourceNom: _selectedSource!.name,
        figureNom: 'Figure',
      );
      // Note: PerspectiveRoom ne peut pas être mise à jour dynamiquement
      // car c'est un StatefulWidget indépendant. L'approfondissement sera
      // géré en rafraîchissant les données.
      print('✅ Approfondissement généré: ${deepResponse.length} chars');
    } catch (e) {
      print('❌ Erreur approfondissement: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LECTURE VOCALE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _speakFull() async {
    if (_generatedResponse == null) return;
    
    if (_isSpeakingFull) {
      await TtsService.instance.stop();
    } else {
      await TtsService.instance.speak(_generatedResponse!, approachKey: 'full');
    }
  }
  
  Future<void> _speakSynthesis() async {
    if (_generatedResponse == null) return;
    
    if (_isSpeakingSynthesis) {
      await TtsService.instance.stop();
      return;
    }
    
    // Si synthèse déjà générée, la lire directement
    if (_synthesis != null) {
      await TtsService.instance.speak(_synthesis!, approachKey: 'synthesis');
      return;
    }
    
    // Générer la synthèse via API
    setState(() => _isGeneratingSynthesis = true);
    
    try {
      final synthesis = await AIService.instance.generateSynthesis(
        systemPrompt: PromptSynthese.systemPrompt,
        userPrompt: PromptSynthese.buildUserPrompt(
          sourceName: _selectedSource!.name,
          originalText: _generatedResponse!,
        ),
      );
      
      if (mounted) {
        setState(() {
          _synthesis = synthesis;
          _isGeneratingSynthesis = false;
        });
        
        await TtsService.instance.speak(synthesis, approachKey: 'synthesis');
      }
    } catch (e) {
      print('❌ Erreur génération synthèse: $e');
      if (mounted) {
        setState(() => _isGeneratingSynthesis = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synthèse', style: GoogleFonts.inter()),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: APPROFONDISSEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _deepen() async {
    if (_generatedResponse == null || _selectedSource == null) return;
    if (_isDeepening) return;
    
    setState(() {
      _isDeepening = true;
    });
    
    try {
      // Extraire le nom de la figure depuis FIGURE_META si possible
      String figureNom = 'Figure';
      final metaMatch = RegExp(r'\[FIGURE_META\][\s\S]*?nom:\s*([^\n]+)[\s\S]*?\[/FIGURE_META\]')
          .firstMatch(_generatedResponse!);
      if (metaMatch != null) {
        figureNom = metaMatch.group(1)?.trim() ?? 'Figure';
      }
      
      final deepenedResponse = await AIService.instance.generateDeepening(
        penseeOriginale: _thoughtController.text.trim(),
        reponseCourte: _generatedResponse!,
        sourceNom: _selectedSource!.name,
        figureNom: figureNom,
      );
      
      if (mounted) {
        setState(() {
          _deepenedResponse = deepenedResponse;
          _isDeepening = false;
        });
        
        // Scroll vers le bas pour voir l'approfondissement
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
    } catch (e) {
      print('❌ Erreur approfondissement: $e');
      if (mounted) {
        setState(() {
          _isDeepening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'approfondissement: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERFACE UTILISATEUR
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Fond bleu clair marbré comme le reste de l'application
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE), // Bleu clair
              Color(0xFFF0F9FF), // Bleu très clair
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _generatedResponse != null
              ? _buildResultView()
              : _buildWheelView(),
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VUE PRINCIPALE (ROUE)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildWheelView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Titre
          _buildTitle(),
          
          const SizedBox(height: 20),
          
          // ROUE
          _buildWheel(),
          
          const SizedBox(height: 16),

          // BOUTONS D'ACCÈS (App + Tutoriel) - empilés verticalement
          _buildAppAccessButton(),
          const SizedBox(height: 10),
          _buildTutorialButton(),

          const SizedBox(height: 16),

          // SOURCE SÉLECTIONNÉE
          if (_selectedSource != null) _buildSelectedSource(),
          
          const SizedBox(height: 20),
          
          // CHAMP DE PENSÉE
          _buildThoughtInput(),
          
          const SizedBox(height: 16),
          
          // BOUTONS D'ACTION
          _buildActionButtons(),
          
          // Message d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildErrorMessage(),
          ],
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          '✨ Roue de la Sagesse',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B), // Bleu foncé pour fond clair
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tourne la roue, découvre ta perspective',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B), // Gris pour fond clair
          ),
        ),
      ],
    );
  }
  
  // Mapping des clés vers les noms de fichiers PNG réels
  static final Map<String, String> _iconMapping = {
    'judaisme_rabbinique': 'rabbinique',
    'moussar': 'moussar',
    'kabbale': 'kabale',
    'christianisme': 'christianisme',
    'islam': 'islam',
    'soufisme': 'soufisme',
    'bouddhisme': 'boudhisme',
    'hindouisme': 'hindouisme',
    'stoicisme': 'stoicisme',
    'spiritualite_contemporaine': 'contemporaine_et_laique',
    'humanisme': 'humanisme',
    'romantisme': 'romantisme',
    'realisme': 'realisme',
    'existentialisme': 'existentialisme',
    'absurdisme': 'absurdisme',
    'poetique': 'poetique',
    'mystique': 'mystique',
    'symboliste_moderne': 'symbolisme',
    'act': 'pleine_conscience',
    'tcc': 'TCC',
    'jungienne': 'jungienne',
    'logotherapie': 'logotherapie_frankl',
    'schemas_young': 'schemas_young',
    'the_work': 'theworkkb',
    'humaniste_rogers': 'humanisme',
    'stoicisme_philo': 'stoicisme',
    'epicurisme': 'epicurisme',
    'existentialisme_philo': 'existentialisme',
    'phenomenologie': 'phenomenologie',
    'absurdisme_philo': 'absurdisme',
    'pragmatisme': 'pragmatisme',
    'rationalisme': 'rationalisme',
    'empirisme': 'empirisme',
    'idealisme': 'idealisme',
    'nihilisme': 'nihilisme',
    'cynisme': 'cynisme',
    'utilitarisme': 'utilitarisme',
    'socrate': 'socrate',
    'platon': 'platon',
    'aristote': 'aristote',
    'epictete': 'epictete',
    'marc_aurele': 'marc_aurele',
    'seneque': 'seneque',
    'epicure': 'epicure',
    'diogene': 'diogene',
    'descartes': 'descartes',
    'spinoza': 'spinoza',
    'kant': 'kant',
    'nietzsche': 'nietzsche',
    'schopenhauer': 'schopenhauer',
    'kierkegaard': 'kierkegaard',
    'hume': 'hume',
    'rousseau': 'rousseau',
    'montaigne': 'montaigne',
    'sartre': 'sartre',
    'camus': 'camus',
    'simone_de_beauvoir': 'simonedebeauvoir',
    'arendt': 'arendt',
    'foucault': 'foucault',
    'confucius': 'confucius',
    'simone_weil': 'weill',
  };
  
  String _getIconPath(String key) {
    final mappedName = _iconMapping[key] ?? key;
    return 'assets/univers_visuel/$mappedName.png';
  }
  
  Widget _buildWheel() {
    final double wheelSize = 280;
    final int sourceCount = _allSources.length;
    
    // Avec 24 sources, icônes de taille moyenne
    final double iconSize = sourceCount <= 12 ? 36 : (sourceCount <= 24 ? 28 : 22);
    final double iconRadius = wheelSize / 2 - 48;
    
    return GestureDetector(
      onTap: _isSpinning ? null : _spinWheel,
      child: SizedBox(
        width: wheelSize + 20,
        height: wheelSize + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Bordure dorée extérieure
            Container(
              width: wheelSize + 12,
              height: wheelSize + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD4AF37), // Or
                    Color(0xFFF4E4BC), // Or clair
                    Color(0xFFD4AF37), // Or
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            
            // Roue principale (fond bleu foncé uniforme)
            AnimatedBuilder(
              animation: _wheelController,
              builder: (context, child) {
                final rotation = _wheelController.isAnimating
                    ? _wheelAnimation.value
                    : _currentRotation;
                return Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: wheelSize,
                    height: wheelSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E3A5F), // Bleu foncé uniforme
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Icônes sur la roue
                        ..._buildWheelIcons(wheelSize, iconSize, iconRadius),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Indicateur (triangle doré en haut)
            Positioned(
              top: 2,
              child: CustomPaint(
                size: const Size(20, 16),
                painter: _TriangleIndicatorPainter(),
              ),
            ),
            
            // Cercle central doré avec bouton HASARD
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFF4E4BC),
                    Color(0xFFD4AF37),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E3A5F), // Bleu foncé
                ),
                child: Center(
                  child: _isSpinning
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app,
                              color: Color(0xFFD4AF37),
                              size: 26,
                            ),
                            Text(
                              'HASARD',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD4AF37),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construire les icônes positionnées sur la roue
  List<Widget> _buildWheelIcons(double wheelSize, double iconSize, double iconRadius) {
    final List<Widget> icons = [];
    final int count = _allSources.length;
    final double segmentAngle = (2 * math.pi) / count;
    final double center = wheelSize / 2;
    
    for (int i = 0; i < count; i++) {
      final source = _allSources[i];
      // Angle au milieu du segment (décalé de -90° pour commencer en haut)
      final double angle = (i * segmentAngle) + (segmentAngle / 2) - (math.pi / 2);
      
      // Position X, Y de l'icône
      final double x = center + iconRadius * math.cos(angle) - (iconSize / 2);
      final double y = center + iconRadius * math.sin(angle) - (iconSize / 2);
      
      icons.add(
        Positioned(
          left: x,
          top: y,
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  _getIconPath(source.key),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    source.icon,
                    color: source.color,
                    size: iconSize - 6,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return icons;
  }
  
  Widget _buildAppAccessButton() {
    return GestureDetector(
      onTap: () {
        // Naviguer vers welcome_screen (application complète)
        Navigator.pushReplacementNamed(context, '/welcome');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de l'application
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apps, color: Color(0xFF6366F1), size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accéder à l\'application',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Connexion, profil, historique...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF94A3B8), size: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTutorialButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/tutorial');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/univers_visuel/tutoriel.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_outline, color: Color(0xFF6366F1), size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tutoriel vidéo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Découvrir l\'application en 1min30',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow, color: Color(0xFF94A3B8), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSource() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedSource!.color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedSource!.color.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône ou image de la source
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedSource!.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              _getIconPath(_selectedSource!.key),
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => Icon(
                _selectedSource!.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSource!.name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _selectedSource!.credo,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThoughtInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: Color(0xFF64748B), size: 20),
            const SizedBox(width: 8),
            Text(
              'Ta pensée ou situation',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _thoughtController,
            focusNode: _focusNode,
            maxLines: 3,
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Qu\'est-ce qui te traverse l\'esprit ?',
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    // Couleur bleu sombre comme la roue
    const wheelBlue = Color(0xFF1E3A5F);
    
    // Si génération en cours, afficher l'indicateur avec IMAGE SABLIER
    if (_isGenerating) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════════
            // IMAGE DU SABLIER ANIMÉ (rotation continue)
            // ═══════════════════════════════════════════════════════════════════
            RotationTransition(
              turns: _hourglassController,
              child: Image.asset(
                'assets/univers_visuel/generationiaencours.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation(wheelBlue),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Génération en cours...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Bouton Générer (seul bouton, bleu sombre)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedSource == null ? null : _generateResponse,
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: Text(
          'Générer un éclairage',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: wheelBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          disabledBackgroundColor: wheelBlue.withOpacity(0.3),
          disabledForegroundColor: Colors.white60,
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VUE RÉSULTAT
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildResultView() {
    return Column(
      children: [
        // Header avec bouton retour
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Bouton retour à la roue
              IconButton(
                onPressed: () {
                  TtsService.instance.stop();
                  setState(() {
                    _generatedResponse = null;
                    _synthesis = null;
                  });
                },
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E3A5F)),
                tooltip: 'Retour à la roue',
              ),
              Expanded(
                child: Text(
                  _selectedSource?.name ?? 'Résultat',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Bouton retour vers la roue (écran d'accueil)
              IconButton(
                onPressed: () {
                  TtsService.instance.stop();
                  setState(() {
                    _generatedResponse = null;
                    _synthesis = null;
                  });
                },
                icon: Image.asset(
                  'assets/univers_visuel/retour.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.refresh,
                    color: Color(0xFF1E3A5F),
                    size: 26,
                  ),
                ),
                tooltip: 'Retour à la roue',
              ),
            ],
          ),
        ),
        
        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Carte de la source
                _buildResultSourceCard(),
                
                const SizedBox(height: 16),
                
                // Pensée originale
                _buildOriginalThought(),
                
                const SizedBox(height: 16),
                
                // Réponse générée
                _buildResponseCard(),
                
                const SizedBox(height: 16),
                
                // ═══════════════════════════════════════════════════════════════
                // NOUVEAU: Bouton Approfondir + Affichage approfondissement
                // ═══════════════════════════════════════════════════════════════
                if (_deepenedResponse == null)
                  _buildDeepenButton()
                else
                  _buildDeepenedCard(),
                
                const SizedBox(height: 16),
                
                // Boutons lecture vocale
                _buildVoiceButtons(),
                
                const SizedBox(height: 24),
                
                // Bouton nouvelle réflexion
                _buildNewReflectionButton(),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultSourceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _selectedSource!.color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: _selectedSource!.color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _selectedSource!.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              _getIconPath(_selectedSource!.key),
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => Icon(
                _selectedSource!.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSource!.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedSource!.credo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOriginalThought() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote, color: Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 8),
              Text(
                'TA PENSÉE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _thoughtController.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF475569),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedSource!.color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Groupe gauche avec Flexible pour éviter overflow
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: _selectedSource!.color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ÉCLAIRAGE',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedSource!.color,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge "Contrôlé" - taille fixe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green[600], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Contrôlé',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _generatedResponse!,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1E293B),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: Bouton Approfondir
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildDeepenButton() {
    return GestureDetector(
      onTap: _isDeepening ? null : _deepen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDeepening
                ? [Colors.grey[400]!, Colors.grey[500]!]
                : [_selectedSource!.color, _selectedSource!.color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (_isDeepening ? Colors.grey : _selectedSource!.color).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDeepening)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              _isDeepening ? 'Approfondissement en cours...' : 'Approfondir cette perspective',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: Carte d'affichage de l'approfondissement
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildDeepenedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedSource!.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedSource!.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header approfondissement
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedSource!.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: _selectedSource!.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Approfondissement',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedSource!.color,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // Contenu
          Text(
            _deepenedResponse ?? '',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1E293B),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceButtons() {
    return Row(
      children: [
        // Bouton lecture complète
        Expanded(
          child: _buildVoiceButton(
            label: _isSpeakingFull ? 'Stop' : 'Écouter complet',
            icon: _isSpeakingFull ? Icons.stop : Icons.volume_up,
            isActive: _isSpeakingFull,
            onTap: _speakFull,
          ),
        ),
        
        const SizedBox(width: 10),
        
        // Bouton synthèse
        Expanded(
          child: _buildVoiceButton(
            label: _isGeneratingSynthesis
                ? 'Génération...'
                : (_isSpeakingSynthesis ? 'Stop' : 'Synthèse'),
            icon: _isGeneratingSynthesis
                ? Icons.hourglass_top
                : (_isSpeakingSynthesis ? Icons.stop : Icons.auto_awesome),
            isActive: _isSpeakingSynthesis,
            isLoading: _isGeneratingSynthesis,
            onTap: _isGeneratingSynthesis ? null : _speakSynthesis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVoiceButton({
    required String label,
    required IconData icon,
    required bool isActive,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? _selectedSource!.color
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? _selectedSource!.color
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isActive ? Colors.white : const Color(0xFF6366F1),
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : const Color(0xFF6366F1),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNewReflectionButton() {
    return ElevatedButton.icon(
      onPressed: () {
        TtsService.instance.stop();
        setState(() {
          _generatedResponse = null;
          _synthesis = null;
          _deepenedResponse = null;  // ✅ NOUVEAU: Reset approfondissement
          _selectedSource = null;
          _thoughtController.clear();
          _currentRotation = 0;
        });
      },
      icon: const Icon(Icons.refresh, size: 20),
      label: Text(
        'Nouvelle réflexion',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6366F1),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        elevation: 2,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTERS POUR LA ROUE (style bleu avec lignes blanches)
// ═══════════════════════════════════════════════════════════════════════════════

/// Dessine les lignes séparatrices blanches entre les segments
class _WheelLinesPainter extends CustomPainter {
  final int count;
  
  _WheelLinesPainter({required this.count});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / count;
    
    // Paint pour les lignes séparatrices
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Dessiner les lignes de chaque segment
    for (int i = 0; i < count; i++) {
      final angle = i * segmentAngle - math.pi / 2;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      
      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }
    
    // Cercle intérieur (délimitation zone centrale)
    final innerCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawCircle(center, radius * 0.3, innerCirclePaint);
  }
  
  @override
  bool shouldRepaint(covariant _WheelLinesPainter oldDelegate) {
    return oldDelegate.count != count;
  }
}

/// Dessine le triangle indicateur doré en haut
class _TriangleIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37) // Or
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2, size.height); // Pointe vers le bas
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();
    
    // Ombre
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ancien painter (gardé pour compatibilité mais non utilisé)
class _WheelPainter extends CustomPainter {
  final List<ApproachConfig> sources;
  
  _WheelPainter({required this.sources});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / sources.length;
    
    // Dessiner les segments colorés
    for (int i = 0; i < sources.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      
      // Couleur du segment
      final paint = Paint()
        ..color = sources[i].color
        ..style = PaintingStyle.fill;
      
      // Dessiner l'arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );
      
      // Bordure blanche semi-transparente
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );
    }
    
    // Bordure extérieure dorée
    final outerBorderPaint = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius - 2, outerBorderPaint);
    
    // Cercle central (fond sombre)
    final centerPaint = Paint()
      ..color = const Color(0xFF1E1B4B)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.22, centerPaint);
    
    // Bordure dorée du cercle central
    final centerBorderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(center, radius * 0.22, centerBorderPaint);
  }
  
  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return false;
  }
}

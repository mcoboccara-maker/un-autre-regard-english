import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

//  IMPORTS CORRECTS POUR TA STRUCTURE REELLE
import '../../models/reflection.dart';                    
import '../../models/emotional_state.dart';               
import '../../models/user_profile.dart';                  
import '../../services/persistent_storage_service.dart';  
import '../../services/ai_service.dart';
import '../../widgets/app_scaffold.dart';
import '../reflection/reflection_input_step.dart';        
import '../emotions/emotions_selection_step.dart';        
// ✅ CHANGEMENT: Import du nouvel écran fusionné
import '../results/streaming_results_screen.dart';
import '../../config/approach_config.dart';               
import '../../services/complete_auth_service.dart';  

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;

  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Donnees du wizard
  String _reflectionText = '';
  ReflectionType _reflectionType = ReflectionType.thought;
  EmotionalState _emotionalState = EmotionalState.empty();
  List<String> _selectedApproaches = [];
  
  // =========================================================================
  // NOUVEAU: Variables pour arguments de navigation
  // =========================================================================
  List<String>? _randomSources;  // Sources de la roue du hasard
  bool _skipEmotions = false;     // Mode génération directe
  bool _argumentsProcessed = false;  // Éviter double traitement
  
  // Champs supplementaires
  String _declencheur = '';
  String _souhait = '';
  String _petitPas = '';
  int _intensiteEmotionnelle = 5;
  String _emotionPrincipale = '';

  // =========================================================================
  // NOUVEAU: Flag pour savoir si on affiche le streaming screen
  // =========================================================================
  bool _showStreamingResults = false;
  Map<String, String> _generatedResponses = {};

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Note: Les approches sont chargées dans didChangeDependencies
    // après récupération des arguments de navigation
  }

  // =========================================================================
  // NOUVEAU: Récupérer les arguments de navigation
  // =========================================================================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_argumentsProcessed) return;
    _argumentsProcessed = true;
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      print('📥 Arguments reçus: $args');
      
      // Pensée initiale
      if (args['initialThought'] != null) {
        _reflectionText = args['initialThought'] as String;
        print('✅ Pensée pré-remplie: $_reflectionText');
      }
      
      // Type d'entrée
      if (args['entryType'] != null) {
        final typeStr = args['entryType'] as String;
        switch (typeStr) {
          case 'pensee':
            _reflectionType = ReflectionType.thought;
            break;
          case 'situation':
            _reflectionType = ReflectionType.situation;
            break;
          case 'question':
            _reflectionType = ReflectionType.existential;
            break;
          case 'dilemme':
            _reflectionType = ReflectionType.dilemma;
            break;
        }
        print('✅ Type d\'entrée: $_reflectionType');
      }
      
      // Sources aléatoires de la roue
      if (args['randomSources'] != null) {
        _randomSources = List<String>.from(args['randomSources']);
        print('✅ Sources aléatoires: $_randomSources');
      }
      
      // Mode skip emotions
      _skipEmotions = args['skipEmotions'] == true;
      
      // Si pensée fournie, naviguer automatiquement
      if (_reflectionText.isNotEmpty) {
        print('🚀 Pensée fournie depuis HOME - navigation automatique');
        
        if (_skipEmotions) {
          print('⚡ Mode direct (sans émotions) - Génération immédiate');
          // Charger les approches puis naviguer vers génération
          _loadUserApproachesAndNavigate();
        } else {
          // Charger les approches puis passer à l'étape des émotions
          _loadUserApproaches().then((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _nextStep();
            });
          });
        }
      } else {
        // Pas de pensée fournie, juste charger les approches
        _loadUserApproaches();
      }
    } else {
      // Pas d'arguments, charger les approches normalement
      _loadUserApproaches();
    }
  }

  // =========================================================================
  // NOUVEAU: Charger les approches puis naviguer vers génération
  // =========================================================================
  Future<void> _loadUserApproachesAndNavigate() async {
    await _loadUserApproaches();
    // Note: _combineApproaches() est déjà appelé dans _loadUserApproaches()
    
    // Naviguer vers l'étape de génération (streaming)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _currentStep = 2;  // Étape génération
        _showStreamingResults = true;  // ✅ NOUVEAU: Afficher l'écran streaming
      });
    });
  }

  // =========================================================================
  // NOUVEAU: Combiner sources profil + roue (RÈGLE 3)
  // =========================================================================
  void _combineApproaches() {
    if (_randomSources != null && _randomSources!.isNotEmpty) {
      // Créer un Set pour éviter les doublons
      final combinedSet = <String>{
        ..._selectedApproaches,  // Sources du profil
        ..._randomSources!,       // Sources de la roue
      };
      
      _selectedApproaches = combinedSet.toList();
      
      print('🔀 Sources combinées (profil + roue): $_selectedApproaches');
    }
  }

  Future<void> _loadUserApproaches() async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile();
    
      if (profileData != null) {
        final List<String> allApproaches = [];
        
        // 1. Sources spirituelles
        allApproaches.addAll(List<String>.from(profileData['religionsSelectionnees'] ?? []));
        
        // 2. Courants litteraires
        allApproaches.addAll(List<String>.from(profileData['courantsLitteraires'] ?? []));
        
        // 3. Approches psychologiques
        allApproaches.addAll(List<String>.from(profileData['approchesPsychologiques'] ?? []));
        
        // 4. Courants philosophiques (NOUVEAU)
        allApproaches.addAll(List<String>.from(profileData['courantsPhilosophiques'] ?? []));
        
        // 5. Philosophes individuels (NOUVEAU)
        allApproaches.addAll(List<String>.from(profileData['philosophesSelectionnes'] ?? []));

        print('🔍 Approches du profil: ${allApproaches.length} total');

        setState(() {
          _selectedApproaches = allApproaches;
        });

        if (allApproaches.isEmpty) {
          print('⚠️ Aucune approche trouvee dans le profil');
        }
      } else {
        print('⚠️ Aucun profil utilisateur trouve');
        setState(() {
          _selectedApproaches = [];
        });
      }
      
      // =========================================================================
      // NOUVEAU: Combiner avec sources de la roue si présentes (RÈGLE 3)
      // =========================================================================
      _combineApproaches();
    } catch (e) {
      print('Erreur chargement approches: $e');
      setState(() {
        _selectedApproaches = [];
      });
    }
  }

  // NOUVEAU: Obtenir le chemin de l'icône PNG selon le type de réflexion
  String _getTypeIconPath(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'assets/univers_visuel/pensee.png';
      case ReflectionType.situation:
        return 'assets/univers_visuel/situation.png';
      case ReflectionType.existential:
        return 'assets/univers_visuel/question_existentielle.png';
      case ReflectionType.dilemma:
        return 'assets/univers_visuel/dilemme.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // NOUVEAU: Si on doit afficher l'écran streaming, on le fait directement
    // =========================================================================
    if (_showStreamingResults) {
      return StreamingResultsScreen(
        reflectionText: _reflectionText,
        declencheur: _declencheur.isNotEmpty ? _declencheur : null,
        souhait: _souhait.isNotEmpty ? _souhait : null,
        petitPas: _petitPas.isNotEmpty ? _petitPas : null,
        reflectionType: _reflectionType,
        emotionalState: _emotionalState,
        selectedApproaches: _selectedApproaches,
        onNewReflection: () {
          _resetReflection();
        },
        onBack: () {
          setState(() {
            _showStreamingResults = false;
            _currentStep = 1;  // Retour aux émotions
          });
        },
      );
    }

    // ✅ UTILISATION DE APPSCAFFOLD au lieu de Scaffold + GlobalAppBar
    return AppScaffold(
      title: '',
      showTitle: false,
      headerIconPath: _getTypeIconPath(_reflectionType),
      showBackButton: false, // Pas de bouton retour standard en bas
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                //  Etape 1: Saisie de la réflexion
                ReflectionInputStep(
                  initialText: _reflectionText,
                  initialType: _reflectionType,
                  onTextChanged: (text) {
                    setState(() {
                      _reflectionText = text;
                    });
                  },
                  onTypeChanged: (type) {
                    setState(() {
                      _reflectionType = type;
                    });
                  },
                  onNext: _nextStep,
                ),

                //  Etape 2: Sélection des émotions
                EmotionsSelectionStep(
                  initialState: _emotionalState,
                  onStateChanged: (newState) {
                    setState(() {
                      _emotionalState = newState;
                    });
                  },
                  onNext: () {
                    // ✅ CHANGEMENT: Au lieu de _nextStep(), on affiche le streaming
                    setState(() {
                      _currentStep = 2;
                      _showStreamingResults = true;
                    });
                  },
                  onBack: _previousStep,
                ),

                //  Etape 3: Placeholder (l'écran streaming est géré séparément)
                Container(
                  // Ce container ne sera jamais visible car on utilise _showStreamingResults
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < _totalSteps - 1) const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Etape ${_currentStep + 1} sur $_totalSteps',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
              Text(
                _getStepTitle(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Votre reflexion';
      case 1:
        return 'Vos emotions';
      case 2:
        return 'Vos eclairages';
      default:
        return '';
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _updateProgress();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _updateProgress();
    }
  }

  void _updateProgress() {
    final progress = (_currentStep + 1) / _totalSteps;
    _progressController.animateTo(progress);
  }

  // =========================================================================
  // NOTE: _saveReflection n'est plus appelé ici
  // La sauvegarde est gérée par StreamingResultsScreen via les évaluations
  // Tu peux garder cette méthode si tu veux aussi sauvegarder la réflexion
  // =========================================================================
  Future<void> _saveReflection(Map<String, String> aiResponses) async {
    try {
      final currentUser = await CompleteAuthService.instance.getCurrentUser();
      await PersistentStorageService.instance.setCurrentUser(currentUser ?? '');
      print('DEBUG SAUVEGARDE PENSEE:');
      print('   _reflectionText: "$_reflectionText"');
      print('   _reflectionType: $_reflectionType');
      print('   aiResponses.keys: ${aiResponses.keys.toList()}');
      print('   selectedApproaches: $_selectedApproaches');
      print('   declencheur: "$_declencheur"');
      print('EMOTIONS DEBUG:');
      print('   _emotionalState: $_emotionalState');
      print('   emotions actives: ${_emotionalState.emotions.values.where((e) => e.level > 0).length}');
      for (var emotion in _emotionalState.emotions.entries) {
        if (emotion.value.level > 0) {
          print('   - ${emotion.key}: niveau ${emotion.value.level}');
        }
      }
      final uuid = const Uuid();
      final reflection = Reflection(
        id: uuid.v4(),
        text: _reflectionText,
        type: _reflectionType,
        emotionalState: _emotionalState,
        createdAt: DateTime.now(),
        selectedApproaches: _selectedApproaches,
        aiResponses: aiResponses,
        declencheur: _declencheur.isNotEmpty ? _declencheur : null,
        souhait: _souhait.isNotEmpty ? _souhait : null,
        petitPas: _petitPas.isNotEmpty ? _petitPas : null,
        intensiteEmotionnelle: _intensiteEmotionnelle,
        emotionPrincipale: _emotionPrincipale.isNotEmpty ? _emotionPrincipale : null,
      );

      await PersistentStorageService.instance.saveReflection(reflection);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reflexion sauvegardee avec succes'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Erreur sauvegarde reflexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetWizard() {
    setState(() {
      _currentStep = 0;
      _reflectionText = '';
      _reflectionType = ReflectionType.thought;
      _emotionalState = EmotionalState.empty();
      _declencheur = '';
      _souhait = '';
      _petitPas = '';
      _intensiteEmotionnelle = 5;
      _emotionPrincipale = '';
      _showStreamingResults = false;  // ✅ NOUVEAU: Reset du flag
    });
    
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _progressController.reset();
  }

  void _resetReflection() {
    if (!mounted) return;  // CORRIGÉ: vérifier mounted avant setState
    setState(() {
      _currentStep = 0;
      _reflectionText = '';
      _reflectionType = ReflectionType.thought;
      _emotionalState = EmotionalState.empty();
      _declencheur = '';
      _souhait = '';
      _petitPas = '';
      _intensiteEmotionnelle = 5;
      _emotionPrincipale = '';
      _showStreamingResults = false;  // ✅ NOUVEAU: Reset du flag
    });
    
    _pageController.jumpToPage(0);
    _progressController.reset();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

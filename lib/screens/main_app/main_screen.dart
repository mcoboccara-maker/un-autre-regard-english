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
import '../../widgets/global_app_bar.dart';               
import '../reflection/reflection_input_step.dart';        
import '../emotions/emotions_selection_step.dart';        
import '../results/results_generation_step.dart';
import '../results/results_display_screen.dart';     
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
  
  // Champs supplementaires
  String _declencheur = '';
  String _souhait = '';
  String _petitPas = '';
  int _intensiteEmotionnelle = 5;
  String _emotionPrincipale = '';

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadUserApproaches();
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

        print('Approches du profil: $allApproaches');
        print('  Religions: ${(profileData['religionsSelectionnees'] as List?)?.length ?? 0}');
        print('  Litterature: ${(profileData['courantsLitteraires'] as List?)?.length ?? 0}');
        print('  Psychologie: ${(profileData['approchesPsychologiques'] as List?)?.length ?? 0}');
        print('  Philosophie: ${(profileData['courantsPhilosophiques'] as List?)?.length ?? 0}');
        print('  Philosophes: ${(profileData['philosophesSelectionnes'] as List?)?.length ?? 0}');
        print('  TOTAL: ${allApproaches.length}');

        setState(() {
          _selectedApproaches = allApproaches;
        });

        if (allApproaches.isEmpty) {
          print('Aucune approche trouvee dans le profil');
        }
      } else {
        print('Aucun profil utilisateur trouve');
        setState(() {
          _selectedApproaches = [];
        });
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // MODIFIÉ: Passer headerIconPath au lieu du titre texte
      appBar: GlobalAppBar(
        title: '',  // Pas de titre texte
        showTitle: false,  // Désactiver le titre texte
        showBackButton: false,  // Pas de flèche retour
        headerIconPath: _getTypeIconPath(_reflectionType),  // NOUVEAU: icône du type
        additionalActions: const [],  // Pas d'actions supplémentaires
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  //  Etape 1: VRAIS CONSTRUCTEURS
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
                    // Callbacks pour les champs Byron Katie
                    onDeclencheurChanged: (declencheur) {
                      setState(() {
                        _declencheur = declencheur;
                      });
                    },
                    onSouhaitChanged: (souhait) {
                      setState(() {
                        _souhait = souhait;
                      });
                    },
                    onPetitPasChanged: (petitPas) {
                      setState(() {
                        _petitPas = petitPas;
                      });
                    },
                  ),

                  //  Etape 2: VRAIS CONSTRUCTEURS d'EmotionsSelectionStep
                  EmotionsSelectionStep(
                    initialState: _emotionalState,
                    onStateChanged: (newState) {
                      setState(() {
                        _emotionalState = newState;
                      });
                    },
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),

                  //  Etape 3: VRAIS CONSTRUCTEURS de ResultsGenerationStep
                  ResultsGenerationStep(
                    reflectionText: _reflectionText,
                    declencheur: _declencheur,
                    souhait: _souhait,
                    petitPas: _petitPas,
                    reflectionType: _reflectionType,
                    emotionalState: _emotionalState,
                    selectedApproaches: _selectedApproaches,
                    onBack: () => setState(() => _currentStep = 2),
                    onGenerationComplete: (responses) async {
                      print(' Generation terminee - Navigation vers affichage');
                    
                      // Sauvegarder la reflexion
                      await _saveReflection(responses);
                    
                      // Naviguer vers l'ecran d'affichage
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ResultsDisplayScreen(
                              aiResponses: responses,
                              selectedApproaches: _selectedApproaches,
                              onNewReflection: () {
                                Navigator.of(context).pop();
                                _resetReflection();
                              },
                            ),
                          ),
                        );
                      }
                    },
                    onGenerationError: () {
                      print('Erreur de generation');
                      // L'utilisateur peut reessayer depuis l'ecran de generation
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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

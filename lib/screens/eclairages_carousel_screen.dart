// lib/screens/eclairages_carousel_screen.dart
// CDC - Cinematique complete des eclairages
// CardCarousel3D + brain widget, compteurs, questions, approfondissement

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../config/approach_config.dart';
import '../models/emotional_state.dart';
import '../models/reflection.dart';
import '../models/saved_eclairage.dart';
import '../services/ai_service.dart';
import '../services/persistent_storage_service.dart';
import '../services/emotional_tracking_service.dart';
import '../services/tts_service.dart';
import '../widgets/cosmic_eye_widget.dart';
import '../widgets/carousel_3d/card_carousel_3d.dart';
import '../widgets/nav_cartouche.dart';
import '../widgets/neon_brain_button.dart';
import 'perspective_room_screen.dart';

// ============================================================================
// QUESTIONS COMPLEMENTAIRES PAR FAMILLE DE SOURCE (CDC S5)
// ============================================================================

const Map<String, List<String>> _kSourceQuestions = {
  'philosophie': [
    'What does this perspective change for you?',
    'Where does your freedom lie here?',
  ],
  'stoicisme': [
    'What truly depends on you?',
    'What happens if you stop fighting against the rest?',
  ],
  'existentialisme': [
    'What are you already taking on in this situation?',
    'What are you choosing, even implicitly?',
  ],
  'litterature': [
    'How does this character resemble you?',
    'What does this story reveal about your situation?',
  ],
  'psychologie': [
    'What are you trying to protect here?',
    'What keeps repeating?',
  ],
  'spiritualite': [
    'What could you let go of?',
    'Where do you feel resistance?',
  ],
  'hasard': [
    'What had you not considered?',
    'What if you trusted this movement?',
  ],
  'emotions': [
    'Where do you feel this emotion?',
    'What is it trying to tell you?',
  ],
};

List<String> _getQuestionsForSource(String approachKey, ApproachType? type) {
  const stoicKeys = [
    'stoicisme', 'stoicisme_philo', 'epicurisme', 'epicure',
    'seneque', 'epictete', 'marc_aurele',
  ];
  if (stoicKeys.contains(approachKey)) return _kSourceQuestions['stoicisme']!;

  const existKeys = [
    'existentialisme', 'existentialisme_philo', 'absurdisme',
    'sartre', 'camus', 'kierkegaard',
  ];
  if (existKeys.contains(approachKey)) {
    return _kSourceQuestions['existentialisme']!;
  }

  switch (type) {
    case ApproachType.spiritual:
      return _kSourceQuestions['spiritualite']!;
    case ApproachType.psychological:
      return _kSourceQuestions['psychologie']!;
    case ApproachType.literary:
      return _kSourceQuestions['litterature']!;
    case ApproachType.philosophical:
    case ApproachType.philosopher:
      return _kSourceQuestions['philosophie']!;
    default:
      return _kSourceQuestions['philosophie']!;
  }
}

// ============================================================================
// WIDGET PRINCIPAL
// ============================================================================

class EclairagesCarouselScreen extends StatefulWidget {
  final String thoughtText;
  final List<PerspectiveData> perspectives;

  /// Mode lecture seule (depuis home_carousel, non connecte)
  final bool readOnly;

  /// Etat emotionnel de l'utilisateur (transmis depuis le mandala)
  final EmotionalState? emotionalState;

  /// Intensite emotionnelle globale (1-10)
  final int? intensiteEmotionnelle;

  /// Sources en attente de generation (ecart 1 - transition progressive)
  final List<ApproachConfig>? pendingSources;

  /// Type de reflexion pour la generation des sources en attente
  final ReflectionType? reflectionType;

  const EclairagesCarouselScreen({
    super.key,
    required this.thoughtText,
    required this.perspectives,
    this.readOnly = false,
    this.emotionalState,
    this.intensiteEmotionnelle,
    this.pendingSources,
    this.reflectionType,
  });

  @override
  State<EclairagesCarouselScreen> createState() =>
      _EclairagesCarouselScreenState();
}

class _EclairagesCarouselScreenState extends State<EclairagesCarouselScreen> {
  late List<PerspectiveData> _perspectives;
  final Map<int, bool> _savedMap = {}; // true=saved, false=rejected
  bool _showFinalPage = false;

  // Focus state
  int _focusedIndex = 0;
  final Set<int> _readIndices = {};

  // Carousel 3D controller
  final Carousel3DController _carouselController = Carousel3DController();

  // Progressive loading (ecart 1)
  int _totalExpected = 0;
  bool get _allArrived => _perspectives.length >= _totalExpected;

  // Deepening (ecart 6)
  final Map<int, String> _deepeningTexts = {};
  final Map<int, DeepeningState> _deepeningStates = {};
  // Track whether to show deepening view for a perspective
  final Map<int, bool> _showDeepeningView = {};

  // User responses
  final Map<int, TextEditingController> _responseControllers = {};

  // Scroll controllers per card (for Scrollbar to work on Web)
  final Map<int, ScrollController> _scrollControllers = {};

  int get _unreadCount =>
      _perspectives.length - _readIndices.length;

  @override
  void initState() {
    super.initState();
    _perspectives = List.from(widget.perspectives);
    _totalExpected =
        _perspectives.length + (widget.pendingSources?.length ?? 0);

    for (int i = 0; i < _perspectives.length; i++) {
      _responseControllers[i] = TextEditingController();
      _scrollControllers[i] = ScrollController();
    }

    if (_perspectives.isNotEmpty) {
      _readIndices.add(0);
    }

    _generatePendingSources();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    for (final controller in _responseControllers.values) {
      controller.dispose();
    }
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ============================================================================
  // GENERATION PROGRESSIVE (Ecart 1)
  // ============================================================================

  Future<void> _generatePendingSources() async {
    final pending = widget.pendingSources;
    if (pending == null || pending.isEmpty) return;

    final userProfile = PersistentStorageService.instance.getUserProfile();

    for (final source in pending) {
      try {
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: source.key,
          reflectionText: widget.thoughtText,
          reflectionType: widget.reflectionType ?? ReflectionType.thought,
          emotionalState: widget.emotionalState ?? EmotionalState.empty(),
          userProfile: userProfile,
          intensiteEmotionnelle: widget.intensiteEmotionnelle ?? 5,
        );

        if (mounted) {
          final meta = AIService.instance.lastFigureMeta;
          final newIndex = _perspectives.length;
          setState(() {
            _perspectives.add(PerspectiveData(
              approachKey: source.key,
              approachName: source.name,
              responseText: response,
              figureName: meta?['nom'],
              figureReference: meta?['reference'],
            ));
            _responseControllers[newIndex] = TextEditingController();
            _scrollControllers[newIndex] = ScrollController();
          });
        }
      } catch (e) {
        print('\u274c Erreur generation ${source.name}: $e');
        if (mounted) {
          setState(() {
            _totalExpected--;
          });
        }
      }
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  ApproachConfig? _getApproachConfig(String key) {
    return ApproachCategories.findByKey(key);
  }

  Color _lightBg(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(0.94)
        .withSaturation(hsl.saturation * 0.4)
        .toColor();
  }

  Color _darkText(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(0.15)
        .withSaturation(hsl.saturation * 0.7)
        .toColor();
  }

  void _focusOn(int index) {
    // Arrêter la lecture vocale en cours lors du changement de carte
    TtsService.instance.stop();
    setState(() {
      _focusedIndex = index.clamp(0, _perspectives.length - 1);
      _readIndices.add(_focusedIndex);
      // Reset deepening view when switching perspectives
      _showDeepeningView[_focusedIndex] ??= false;
    });
  }

  // ============================================================================
  // DEEPENING (Ecart 6)
  // ============================================================================

  void _requestDeepening(int index) {
    if (_deepeningStates[index] == DeepeningState.loading ||
        _deepeningStates[index] == DeepeningState.ready) {
      // Already loading or ready — just show it
      if (_deepeningStates[index] == DeepeningState.ready) {
        setState(() {
          _showDeepeningView[index] = true;
        });
      }
      return;
    }

    setState(() {
      _deepeningStates[index] = DeepeningState.loading;
    });

    final perspective = _perspectives[index];
    final figureName = perspective.figureName ?? 'Figure non identifiee';

    AIService.instance
        .generateDeepening(
      penseeOriginale: widget.thoughtText,
      reponseCourte: perspective.responseText,
      sourceNom: perspective.approachName,
      figureNom: figureName,
    )
        .then((response) {
      if (mounted) {
        setState(() {
          _deepeningTexts[index] = response;
          _deepeningStates[index] = DeepeningState.ready;
          _showDeepeningView[index] = true;
        });
      }
    }).catchError((e) {
      print('\u274c Erreur approfondissement: $e');
      if (mounted) {
        setState(() {
          _deepeningStates[index] = DeepeningState.failed;
        });
      }
    });
  }

  // ============================================================================
  // SAVE / REJECT (via boutons bas)
  // ============================================================================

  bool _isCurrentDeepeningLoading() {
    return _deepeningStates[_focusedIndex] == DeepeningState.loading;
  }

  void _onCardDecision(int index, {required bool saved}) {
    if (index < 0 || index >= _perspectives.length) return;
    if (_savedMap.containsKey(index)) return; // deja traite

    if (saved) {
      setState(() { _savedMap[index] = true; });
      _saveEclairageComplet(index);
      // Overlay vert puis avancer
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _advanceToNext();
      });
    } else {
      // Passer : retirer la carte du carousel
      _removeCardAt(index);
    }
  }

  void _removeCardAt(int index) {
    setState(() {
      _perspectives.removeAt(index);
      _totalExpected = _totalExpected > 0 ? _totalExpected - 1 : 0;

      // Réindexer les maps
      final newSavedMap = <int, bool>{};
      final newDeepeningTexts = <int, String>{};
      final newDeepeningStates = <int, DeepeningState>{};
      final newShowDeepeningView = <int, bool>{};
      final newResponseControllers = <int, TextEditingController>{};
      final newScrollControllers = <int, ScrollController>{};

      for (final entry in _savedMap.entries) {
        final oldIdx = entry.key;
        if (oldIdx < index) {
          newSavedMap[oldIdx] = entry.value;
        } else if (oldIdx > index) {
          newSavedMap[oldIdx - 1] = entry.value;
        }
      }
      for (final entry in _deepeningTexts.entries) {
        final oldIdx = entry.key;
        if (oldIdx < index) {
          newDeepeningTexts[oldIdx] = entry.value;
        } else if (oldIdx > index) {
          newDeepeningTexts[oldIdx - 1] = entry.value;
        }
      }
      for (final entry in _deepeningStates.entries) {
        final oldIdx = entry.key;
        if (oldIdx < index) {
          newDeepeningStates[oldIdx] = entry.value;
        } else if (oldIdx > index) {
          newDeepeningStates[oldIdx - 1] = entry.value;
        }
      }
      for (final entry in _showDeepeningView.entries) {
        final oldIdx = entry.key;
        if (oldIdx < index) {
          newShowDeepeningView[oldIdx] = entry.value;
        } else if (oldIdx > index) {
          newShowDeepeningView[oldIdx - 1] = entry.value;
        }
      }

      // Dispose old controllers at removed index
      _responseControllers[index]?.dispose();
      _scrollControllers[index]?.dispose();

      for (final entry in _responseControllers.entries) {
        final oldIdx = entry.key;
        if (oldIdx < index) {
          newResponseControllers[oldIdx] = entry.value;
        } else if (oldIdx > index) {
          newResponseControllers[oldIdx - 1] = entry.value;
        }
      }
      for (final entry in _scrollControllers.entries) {
        final oldIdx = entry.key;
        if (oldIdx < index) {
          newScrollControllers[oldIdx] = entry.value;
        } else if (oldIdx > index) {
          newScrollControllers[oldIdx - 1] = entry.value;
        }
      }

      _savedMap.clear();
      _savedMap.addAll(newSavedMap);
      _deepeningTexts.clear();
      _deepeningTexts.addAll(newDeepeningTexts);
      _deepeningStates.clear();
      _deepeningStates.addAll(newDeepeningStates);
      _showDeepeningView.clear();
      _showDeepeningView.addAll(newShowDeepeningView);
      _responseControllers.clear();
      _responseControllers.addAll(newResponseControllers);
      _scrollControllers.clear();
      _scrollControllers.addAll(newScrollControllers);

      // Réindexer readIndices
      final newReadIndices = <int>{};
      for (final idx in _readIndices) {
        if (idx < index) {
          newReadIndices.add(idx);
        } else if (idx > index) {
          newReadIndices.add(idx - 1);
        }
      }
      _readIndices.clear();
      _readIndices.addAll(newReadIndices);

      // Ajuster le focus
      if (_perspectives.isEmpty) {
        _checkAllProcessed();
        return;
      }
      _focusedIndex = _focusedIndex.clamp(0, _perspectives.length - 1);
    });
    // Après rebuild, naviguer
    if (_perspectives.isNotEmpty) {
      Future.microtask(() {
        if (mounted) _advanceToNext();
      });
    }
  }

  void _advanceToNext() {
    // Avancer au prochain éclairage non traité
    for (int i = 0; i < _perspectives.length; i++) {
      if (!_savedMap.containsKey(i)) {
        _carouselController.animateToIndex(i);
        return;
      }
    }
    // Tous traités
    _checkAllProcessed();
  }

  void _checkAllProcessed() {
    if (_savedMap.length == _perspectives.length && _allArrived) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Retour automatique au menu central
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/menu',
            (route) => false,
          );
        }
      });
    }
  }

  String? _extractFigureName(String responseText) {
    final regex =
        RegExp(r'FIGURE_META\s*\{[^}]*nom\s*:\s*"?([^"\n,}]+)"?');
    final match = regex.firstMatch(responseText);
    return match?.group(1)?.trim();
  }

  String? _extractFigureReference(String responseText) {
    final regex =
        RegExp(r'FIGURE_META\s*\{[^}]*reference\s*:\s*"?([^"\n,}]+)"?');
    final match = regex.firstMatch(responseText);
    return match?.group(1)?.trim();
  }

  Future<void> _saveEclairageComplet(int index) async {
    final perspective = _perspectives[index];

    // Ne pas sauvegarder les erreurs API
    if (perspective.responseText.startsWith('[ERREUR_API]') ||
        perspective.responseText.startsWith('❌')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save an insight with an error'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final userResponse = _responseControllers[index]?.text.trim();
    final deepText = _deepeningTexts[index];

    final savedEclairage = SavedEclairage(
      eclairageText: perspective.responseText,
      deepeningText:
          (deepText != null && deepText.isNotEmpty) ? deepText : null,
      userResponse:
          (userResponse != null && userResponse.isNotEmpty) ? userResponse : null,
      thoughtText: widget.thoughtText,
      sourceKey: perspective.approachKey,
      sourceName: perspective.approachName,
      figureName: perspective.figureName ??
          _extractFigureName(perspective.responseText),
      figureReference: perspective.figureReference ??
          _extractFigureReference(perspective.responseText),
      emotionalState: widget.emotionalState?.toJson(),
      intensiteEmotionnelle: widget.intensiteEmotionnelle,
      savedAt: DateTime.now(),
    );

    try {
      final success = await PersistentStorageService.instance
          .saveEclairage(savedEclairage.toJson());
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('${perspective.approachName} saved')),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Sign in to save your insights')),
                ],
              ),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('\u274c Erreur sauvegarde eclairage: $e');
    }
  }

  /// Partager un éclairage via les apps/réseaux sociaux
  void _shareEclairage(int index) {
    if (index < 0 || index >= _perspectives.length) return;
    final perspective = _perspectives[index];
    final isShowingDeepening = _showDeepeningView[index] == true;
    final deepeningText = _deepeningTexts[index];

    final buffer = StringBuffer();
    buffer.writeln('✨ Insight — ${perspective.approachName}');
    if (perspective.figureName != null) {
      buffer.writeln('Figure: ${perspective.figureName}');
    }
    buffer.writeln('');
    buffer.writeln('💭 "${widget.thoughtText}"');
    buffer.writeln('');
    if (isShowingDeepening && deepeningText != null) {
      buffer.writeln('📖 Deep Dive:');
      buffer.writeln(deepeningText);
    } else {
      buffer.writeln(perspective.responseText);
    }
    buffer.writeln('');
    buffer.writeln('— Un Autre Regard');
    Share.share(buffer.toString());
  }

  void _showPositiveThought() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PositiveThoughtDialog(),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (_showFinalPage && !widget.readOnly) {
      return _buildFinalPage();
    }

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
              _buildHeader(),
              // Ecart 2+3: Brain widget toujours visible, centre sous Eclairages
              _buildBrainSection(),
              // CardCarousel3D avec contenu enrichi dans chaque carte
              Expanded(
                child: _perspectives.isEmpty
                    ? _buildEmptyState()
                    : CardCarousel3D(
                        cards: _buildCarouselCards(),
                        controller: _carouselController,
                        mode: CarouselMode.face,
                        cardHeight: MediaQuery.sizeOf(context).height * 0.65,
                        cardWidth: MediaQuery.sizeOf(context).width * 0.85,
                        enableSwipeActions: false,
                        onCardChanged: (index) => _focusOn(index),
                        initialIndex: _focusedIndex,
                        // Navigation autorisée même pendant approfondissement (point 11)
                      ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // CAROUSEL CARDS BUILDER
  // ============================================================================

  List<CarouselCardData> _buildCarouselCards() {
    return List.generate(_perspectives.length, (index) {
      final perspective = _perspectives[index];
      final config = _getApproachConfig(perspective.approachKey);
      final color = config?.color ?? const Color(0xFF4A90A4);

      return CarouselCardData(
        id: perspective.approachKey,
        backgroundColor: _lightBg(color),
        label: perspective.approachName,
        child: _buildCardContent(index),
      );
    });
  }

  // ============================================================================
  // CARD CONTENT (contenu scrollable complet d'une carte)
  // ============================================================================

  Widget _buildCardContent(int index) {
    final perspective = _perspectives[index];
    final config = _getApproachConfig(perspective.approachKey);
    final color = config?.color ?? const Color(0xFF4A90A4);
    final bgLight = _lightBg(color);
    final bgLight2 = HSLColor.fromColor(color)
        .withLightness(0.88)
        .withSaturation(HSLColor.fromColor(color).saturation * 0.3)
        .toColor();
    final textDark = _darkText(color);
    final savedState = _savedMap[index];
    final isShowingDeepening = _showDeepeningView[index] == true;
    final deepeningState = _deepeningStates[index];
    final deepeningText = _deepeningTexts[index];
    final questions = _getQuestionsForSource(
      perspective.approachKey,
      config?.type,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgLight, bgLight2],
              ),
            ),
            child: Column(
              children: [
                // Header avec icone PNG (ecart 10) + TTS
                _buildCartoucheHeader(
                    index, perspective, config, color, textDark, isShowingDeepening),
                Divider(
                    height: 1,
                    color: color.withValues(alpha: 0.2)),
                // Ecart 5: Scrollbar visible + contenu scrollable
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollControllers[index],
                    child: SingleChildScrollView(
                      controller: _scrollControllers[index],
                      padding: const EdgeInsets.all(16),
                      child: _buildScrollableContent(
                        index,
                        perspective,
                        config,
                        color,
                        textDark,
                        isShowingDeepening,
                        deepeningState,
                        deepeningText,
                        questions,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Save overlay (vert uniquement, pas de croix rouge)
          if (savedState == true && !widget.readOnly)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bookmark,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              TtsService.instance.stop();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Insights',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.readOnly)
            IconButton(
              onPressed: () {
                TtsService.instance.stop();
                Navigator.pushNamed(context, '/login');
              },
              icon: Image.asset(
                'assets/univers_visuel/connexion.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              tooltip: 'Sign in',
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NavCartouche(
                  assetPath: 'assets/univers_visuel/profil.png',
                  fallbackIcon: Icons.person_rounded,
                  tooltip: 'My profile',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(width: 6),
                NavCartouche(
                  assetPath: 'assets/univers_visuel/pensee_positive.png',
                  fallbackIcon: Icons.lightbulb_outline,
                  tooltip: 'Positive thought',
                  onTap: _showPositiveThought,
                ),
                const SizedBox(width: 6),
                NavCartouche(
                  assetPath: 'assets/univers_visuel/menu_principal.png',
                  fallbackIcon: Icons.grid_view_rounded,
                  tooltip: 'Main menu',
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/menu', (route) => false,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // ECART 2+3: BRAIN WIDGET (toujours visible, centre sous Eclairages)
  // ============================================================================

  Widget _buildBrainSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          // Oeil cosmique centre sous Eclairages
          const CosmicEyeWidget(
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 4),
          // Compteurs sous le cerveau
          if (!_allArrived) ...[
            Text(
              '${_perspectives.length}/$_totalExpected insights received',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ] else if (_savedMap.isNotEmpty && !widget.readOnly) ...[
            Text(
              '${_savedMap.length}/${_perspectives.length} processed',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (_unreadCount > 0 && !_allArrived)
            Text(
              '$_unreadCount unread',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF64FFDA),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // EMPTY STATE (waiting for first eclairage)
  // ============================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CosmicEyeWidget(width: 180, height: 180),
          const SizedBox(height: 24),
          Text(
            'Generating...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CARTOUCHE HEADER (ecart 10: icone PNG)
  // ============================================================================

  Widget _buildCartoucheHeader(
    int index,
    PerspectiveData perspective,
    ApproachConfig? config,
    Color color,
    Color textDark,
    bool isShowingDeepening,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Row(
        children: [
          // Ecart 10: Icone PNG univers_visuel
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/univers_visuel/${perspective.approachKey}.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                config?.icon ?? Icons.auto_awesome,
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isShowingDeepening
                      ? 'Deep Dive'
                      : perspective.approachName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                if (!isShowingDeepening && config != null)
                  Text(
                    config.credo,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: textDark.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (isShowingDeepening)
                  Text(
                    perspective.approachName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // TTS button
          IconButton(
            onPressed: () {
              final textToSpeak = isShowingDeepening
                  ? (_deepeningTexts[index] ?? perspective.responseText)
                  : perspective.responseText;
              // Ne pas lire les erreurs API
              if (textToSpeak.startsWith('[ERREUR_API]') || textToSpeak.startsWith('❌')) {
                return;
              }
              TtsService.instance.speak(
                textToSpeak,
                approachKey: perspective.approachKey,
              );
            },
            icon: Icon(Icons.volume_up, color: color, size: 20),
            tooltip: 'Listen',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Toggle original/deepening — icone PNG eclairage_initial
          if (_deepeningStates[index] == DeepeningState.ready)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showDeepeningView[index] =
                      !(_showDeepeningView[index] ?? false);
                });
              },
              child: Tooltip(
                message: isShowingDeepening
                    ? 'View initial insight'
                    : 'View deep dive',
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: isShowingDeepening
                      ? Image.asset(
                          'assets/univers_visuel/eclairage_initial.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.short_text,
                            color: color,
                            size: 20,
                          ),
                        )
                      : Icon(Icons.zoom_in, color: color, size: 20),
                ),
              ),
            ),
          // Icône Partager
          GestureDetector(
            onTap: () => _shareEclairage(index),
            child: Tooltip(
              message: 'Share',
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'assets/univers_visuel/partage.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.share,
                      color: color.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SCROLLABLE CONTENT (ecarts 5, 6, 7, 8, 9)
  // ============================================================================

  Widget _buildScrollableContent(
    int index,
    PerspectiveData perspective,
    ApproachConfig? config,
    Color color,
    Color textDark,
    bool isShowingDeepening,
    DeepeningState? deepeningState,
    String? deepeningText,
    List<String> questions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main text
        if (isShowingDeepening && deepeningText != null) ...[
          // Deepening text
          Text(
            deepeningText,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF1A2A3A),
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          // Original text collapsed
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.short_text, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Initial insight',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  perspective.responseText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textDark.withValues(alpha: 0.45),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ] else ...[
          // Original eclairage text
          Text(
            perspective.responseText,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF1A2A3A),
              height: 1.7,
            ),
          ),
        ],

        // Ecart 6: Approfondissement button (visible aussi en mode teaser)
        if (!isShowingDeepening) ...[
          const SizedBox(height: 16),
          _buildDeepeningButton(index, color, deepeningState),
        ],

        // Ecart 7+8: Questions en bas du contenu scrollable (visible aussi en mode teaser)
        if (questions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildQuestionsSection(index, questions, color, textDark),
        ],

        // Ecart 9: Hint swipe pour garder/passer (uniquement mode connecté)
        if (!widget.readOnly && _savedMap[index] == null) ...[
          const SizedBox(height: 24),
          _buildSwipeHint(color),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  // ============================================================================
  // DEEPENING BUTTON — Bouton cerveau neon glow (ecart 6)
  // ============================================================================

  Widget _buildDeepeningButton(
      int index, Color color, DeepeningState? state) {
    // Loading: NeonBrainButton avec pulse (en attente de reponse)
    if (state == DeepeningState.loading) {
      return Center(
        child: Column(
          children: [
            NeonBrainButton(
              size: 110,
              pulse: true,  // pulse uniquement pendant l'attente
              glowColor: const Color(0xFF00D4FF),
            ),
            const SizedBox(height: 8),
            Text(
              'Deep dive in progress...',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Failed: retry avec overlay rouge
    if (state == DeepeningState.failed) {
      return Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _deepeningStates[index] = DeepeningState.notRequested;
            });
            _requestDeepening(index);
          },
          child: Column(
            children: [
              NeonBrainButton(
                size: 110,
                pulse: false,
                glowColor: Colors.redAccent,
                overlayIcon: Icons.refresh,
              ),
              const SizedBox(height: 8),
              Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ready: glow vert
    if (state == DeepeningState.ready) {
      return Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showDeepeningView[index] = true;
            });
          },
          child: Column(
            children: [
              NeonBrainButton(
                size: 110,
                isComplete: true,
                pulse: false,
                glowColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              Text(
                'View deep dive',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not requested: bouton neon statique (pas de pulse, juste les particules)
    return Center(
      child: GestureDetector(
        onTap: () => _requestDeepening(index),
        child: Column(
          children: [
            NeonBrainButton(
              size: 110,
              pulse: false,  // pas de pulse avant la demande
              glowColor: const Color(0xFF00D4FF),
            ),
            const SizedBox(height: 8),
            Text(
              'Deep Dive',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF00D4FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ECART 7+8: QUESTIONS
  // ============================================================================

  Widget _buildQuestionsSection(
    int index,
    List<String> questions,
    Color color,
    Color textDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              'Reflection questions',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...questions.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u2022 ',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: color, height: 1.5)),
                  Expanded(
                    child: Text(
                      q,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textDark.withValues(alpha: 0.7),
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 10),
        // User response field
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: TextField(
            controller: _responseControllers[index],
            maxLines: 4,
            minLines: 2,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF1A2A3A),
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'What this insight inspires in you, your answers to the questions...',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color:
                    const Color(0xFF1A2A3A).withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ECART 9: HINT DECISION (boutons bas)
  // ============================================================================

  Widget _buildSwipeHint(Color color) {
    return Column(
      children: [
        Divider(color: color.withValues(alpha: 0.15)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_rounded,
                size: 14, color: color.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              'Swipe to explore the insights',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color.withValues(alpha: 0.35),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // BOTTOM BAR
  // ============================================================================

  Widget _buildBottomBar() {
    final bool hasCards = _perspectives.isNotEmpty && !_showFinalPage;
    final bool currentAlreadyProcessed = hasCards && _savedMap.containsKey(_focusedIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton PASSER (gauche)
          if (hasCards && !widget.readOnly && !currentAlreadyProcessed)
            GestureDetector(
              onTap: () => _onCardDecision(_focusedIndex, saved: false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.skip_next_rounded,
                        size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bouton RETOUR (centre)
          GestureDetector(
            onTap: () {
              TtsService.instance.stop();
              Navigator.of(context).pop();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E8B7B).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bouton GARDER (droite)
          if (hasCards && !widget.readOnly && !currentAlreadyProcessed)
            GestureDetector(
              onTap: () => _onCardDecision(_focusedIndex, saved: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E8B7B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Keep',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // FINAL PAGE
  // ============================================================================

  Widget _buildFinalPage() {
    final savedCount = _savedMap.values.where((v) => v).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF102A43), Color(0xFF0B1C2D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 32),
                Text(
                  'Has your perspective shifted?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '$savedCount insight${savedCount > 1 ? 's' : ''} kept',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),
                _buildFinalOption(
                  icon: Icons.refresh,
                  label: 'New reflection',
                  subtitle: 'Start over with another thought',
                  onTap: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 12),
                _buildFinalOption(
                  icon: Icons.auto_awesome,
                  label: 'More insights',
                  subtitle: 'Explore other perspectives',
                  onTap: () {
                    setState(() {
                      _savedMap.clear();
                      _showFinalPage = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildFinalOption(
                  icon: Icons.home,
                  label: 'Back to home',
                  subtitle: 'Return to the sources carousel',
                  onTap: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: Colors.white.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DIALOG PENSEE POSITIVE (générée par l'IA)
// ============================================================================

class _PositiveThoughtDialog extends StatefulWidget {
  @override
  State<_PositiveThoughtDialog> createState() => _PositiveThoughtDialogState();
}

class _PositiveThoughtDialogState extends State<_PositiveThoughtDialog> {
  String? _thought;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    try {
      final userProfile = PersistentStorageService.instance.getUserProfile();

      // Charger les émotions du jour si disponibles
      String? historique7Jours;
      try {
        final entries = await EmotionalTrackingService.instance.getEntriesForLastDays(7);
        if (entries.isNotEmpty) {
          final buffer = StringBuffer();
          for (final entry in entries) {
            final dateStr = '${entry.date.day}/${entry.date.month}/${entry.date.year}';
            final emotionsStr = entry.emotions.entries
                .map((e) => '${e.key} ${e.value.intensity}/100')
                .join(', ');
            buffer.writeln('$dateStr : $emotionsStr');
          }
          historique7Jours = buffer.toString().trim();
        }
      } catch (_) {}

      final result = await AIService.instance.generatePositiveThought(
        userProfile: userProfile,
        historique7Jours: historique7Jours,
      );

      if (mounted) {
        final isErr = result.startsWith('❌');
        setState(() {
          _thought = isErr ? null : result;
          _isLoading = false;
          _isError = isErr;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/univers_visuel/pensee_positive.png',
              width: 64,
              height: 64,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Thought of the moment',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                  ),
                ),
              )
            else if (_isError)
              Text(
                'Unable to generate a thought at the moment.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF78350F),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                _thought ?? '',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF78350F),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF78350F),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Thank you!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

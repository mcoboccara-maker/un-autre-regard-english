// Perspective Room — Un Autre Regard
// Version V2: Cinématiques CDC + Densité atmosphérique + Approfondissement
// Implémente: cdc_cinematique_rectangles, cdc_affichage_approfondissement, densité perceptive

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/lighting_profiles.dart';

// ============================================================================
// CONSTANTS & ENUMS
// ============================================================================

/// Types de cinématiques selon CDC
enum CinematicType {
  c1RespirVerticale,    // Translation Y + opacity
  c2MiseAuPoint,        // Blur + opacity (focus)
  c3GlissementLateral,  // Translation X + opacity
  c4ApparitionSeuil,    // Clip rect vertical
  c5Profondeur,         // Scale + parallax léger
  c6BattementUnique,    // Scale pulse (ONLY for Perspective)
}

/// Familles de sources pour attribution cinématique
enum SourceFamily {
  realismeLitterature,      // Réalisme, Littérature, Psychologie
  existentialismeTragique,  // Existentialisme, Tragique, Absurde
  spiritualiteMystique,     // Spiritualités, Mystique, Judaïsme
  stoicismeSagesses,        // Stoïcisme, Sagesses antiques
  mythesArchetypes,         // Mythes, Archétypes, Symbolique
}

/// Structure de section de texte
class _TextSection {
  final String title;
  final String content;
  final int index; // 0=Motif, 1=Personnage, 2=Contexte, 3=Perspective
  _TextSection({required this.title, required this.content, required this.index});

  bool get isMotif => index == 0;
  bool get isPersonnage => index == 1;
  bool get isContexte => index == 2;
  bool get isPerspective => index == 3;
}

// ============================================================================
// FAMILY DETECTION
// ============================================================================

SourceFamily _getSourceFamily(String approachKey, String group) {
  // Existentialisme / Tragique / Absurde
  const existentialistKeys = [
    'existentialisme', 'existentialisme_philo', 'absurdisme', 'absurdisme_philo',
    'tragedie_classique', 'sartre', 'camus', 'kierkegaard', 'schopenhauer',
  ];
  if (existentialistKeys.contains(approachKey)) {
    return SourceFamily.existentialismeTragique;
  }

  // Spiritualités / Mystique
  if (group == 'spiritual' || approachKey == 'mystique' || approachKey == 'kabbale' || approachKey == 'soufisme') {
    return SourceFamily.spiritualiteMystique;
  }

  // Stoïcisme / Sagesses antiques
  const stoicKeys = [
    'stoicisme', 'stoicisme_philo', 'epicurisme', 'epicure',
    'seneque', 'epictete', 'marc_aurele', 'philosophies_orientales',
    'theravada', 'zen', 'advaita_vedanta', 'bhakti', 'confucius',
  ];
  if (stoicKeys.contains(approachKey)) {
    return SourceFamily.stoicismeSagesses;
  }

  // Mythes / Archétypes / Symbolique
  const mythKeys = [
    'mythologie', 'symbolisme', 'symboliste_moderne', 'fantasy',
    'surrealisme', 'jungienne',
  ];
  if (mythKeys.contains(approachKey)) {
    return SourceFamily.mythesArchetypes;
  }

  // Par défaut: Réalisme / Littérature / Psychologie
  return SourceFamily.realismeLitterature;
}

// ============================================================================
// SCROLL BEHAVIOR
// ============================================================================

class WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

// ============================================================================
// DATA MODEL
// ============================================================================

class PerspectiveData {
  final String approachKey;
  final String approachName;
  final String responseText;
  final String? deepeningText;
  final DeepeningState deepeningState;
  final String? figureName;
  final String? figureReference;

  const PerspectiveData({
    required this.approachKey,
    required this.approachName,
    required this.responseText,
    this.deepeningText,
    this.deepeningState = DeepeningState.notRequested,
    this.figureName,
    this.figureReference,
  });
}

enum DeepeningState { notRequested, loading, ready, failed }

// ============================================================================
// QUESTIONS COMPLÉMENTAIRES PAR FAMILLE DE SOURCE (CDC §5)
// ============================================================================

const Map<String, List<String>> kSourceQuestions = {
  'philosophie': [
    'What does this perspective change for you?',
    'Where does your freedom lie here?',
  ],
  'stoicisme': [
    'What truly depends on you?',
    'What happens if you stop fighting the rest?',
  ],
  'existentialisme': [
    'What are you already taking on in this situation?',
    'What are you choosing, even implicitly?',
  ],
  'litterature': [
    'In what way does this character resemble you?',
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
    'What hadn\'t you considered?',
    'What if you trusted this movement?',
  ],
  'emotions': [
    'Where do you feel this emotion?',
    'What is it trying to tell you?',
  ],
};

/// Obtenir les questions pour une approche donnée
List<String> _getQuestionsForApproach(String approachKey, String group) {
  // Essayer le groupe d'abord
  if (group == 'spiritual') return kSourceQuestions['spiritualite']!;
  if (group == 'psychological') return kSourceQuestions['psychologie']!;
  if (group == 'literary') return kSourceQuestions['litterature']!;
  if (group == 'philosophical') return kSourceQuestions['philosophie']!;
  if (group == 'philosopher') return kSourceQuestions['philosophie']!;

  // Essayer par clé spécifique
  const stoicKeys = ['stoicisme', 'stoicisme_philo', 'epicurisme', 'epicure',
    'seneque', 'epictete', 'marc_aurele'];
  if (stoicKeys.contains(approachKey)) return kSourceQuestions['stoicisme']!;

  const existKeys = ['existentialisme', 'existentialisme_philo', 'absurdisme',
    'sartre', 'camus', 'kierkegaard'];
  if (existKeys.contains(approachKey)) return kSourceQuestions['existentialisme']!;

  // Par défaut: questions de philosophie générale
  return kSourceQuestions['philosophie']!;
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class PerspectiveRoomScreen extends StatefulWidget {
  const PerspectiveRoomScreen({
    super.key,
    required this.thoughtText,
    required this.perspectives,
    this.initialIndex = 0,
    this.onEvaluate,
    this.onDeepen,
    this.onSave,
    this.onReject,
    this.onShiftAnswer,
    this.onClose,
  });

  final String thoughtText;
  final List<PerspectiveData> perspectives;
  final int initialIndex;
  final void Function(String approachKey, int rating)? onEvaluate;
  final void Function(String approachKey)? onDeepen;
  final void Function(String approachKey)? onSave;
  final void Function(String approachKey)? onReject;
  final void Function(String answer)? onShiftAnswer; // "Ton regard a-t-il bougé ?"
  final VoidCallback? onClose;

  @override
  State<PerspectiveRoomScreen> createState() => _PerspectiveRoomScreenState();
}

class _PerspectiveRoomScreenState extends State<PerspectiveRoomScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;
  late final AnimationController _breathController;
  double _parallaxOffset = 0.0;

  // Swipe save/reject (CDC §3.6)
  final Set<String> _savedKeys = {};
  final Set<String> _rejectedKeys = {};
  String? _swipeFeedback; // 'save', 'reject', ou null
  late final AnimationController _feedbackController;

  // Active perspectives (removed as user keeps/discards)
  late List<PerspectiveData> _activePerspectives;
  final Set<String> _processedKeys = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, math.max(0, widget.perspectives.length - 1));
    _pageController = PageController(initialPage: _currentIndex);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pageController.addListener(_onScroll);
    _activePerspectives = List.from(widget.perspectives);
  }

  @override
  void didUpdateWidget(PerspectiveRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Add new perspectives from parent (streaming in progress)
    for (final p in widget.perspectives) {
      if (!_processedKeys.contains(p.approachKey) &&
          !_activePerspectives.any((a) => a.approachKey == p.approachKey)) {
        _activePerspectives.add(p);
      }
    }
    // Update existing perspectives (e.g. deepening text loaded)
    for (int i = 0; i < _activePerspectives.length; i++) {
      final key = _activePerspectives[i].approachKey;
      try {
        final updated = widget.perspectives.firstWhere((p) => p.approachKey == key);
        _activePerspectives[i] = updated;
      } catch (_) {
        // Perspective no longer in parent (should not happen)
      }
    }
  }

  void _onScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _parallaxOffset = (_pageController.page ?? 0) - _currentIndex;
      });
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _feedbackController.dispose();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  /// Save current insight (CDC §3.6 - swipe right)
  void _saveCurrent() {
    if (_activePerspectives.isEmpty) return;
    final idx = _currentIndex.clamp(0, _activePerspectives.length - 1);
    final perspective = _activePerspectives[idx];
    if (_savedKeys.contains(perspective.approachKey)) return;

    setState(() {
      _savedKeys.add(perspective.approachKey);
      _rejectedKeys.remove(perspective.approachKey);
      _swipeFeedback = 'save';
    });

    widget.onSave?.call(perspective.approachKey);
    widget.onEvaluate?.call(perspective.approachKey, 1);

    _feedbackController.forward(from: 0).then((_) {
      if (mounted) {
        _processedKeys.add(perspective.approachKey);
        setState(() => _swipeFeedback = null);
        _removeCurrentAndAdvance();
      }
    });
  }

  /// Reject current insight (CDC §3.6 - swipe left)
  void _rejectCurrent() {
    if (_activePerspectives.isEmpty) return;
    final idx = _currentIndex.clamp(0, _activePerspectives.length - 1);
    final perspective = _activePerspectives[idx];
    if (_rejectedKeys.contains(perspective.approachKey)) return;

    setState(() {
      _rejectedKeys.add(perspective.approachKey);
      _savedKeys.remove(perspective.approachKey);
      _swipeFeedback = 'reject';
    });

    widget.onReject?.call(perspective.approachKey);

    _feedbackController.forward(from: 0).then((_) {
      if (mounted) {
        _processedKeys.add(perspective.approachKey);
        setState(() => _swipeFeedback = null);
        _removeCurrentAndAdvance();
      }
    });
  }

  /// Remove current card and advance to the next one
  void _removeCurrentAndAdvance() {
    if (_activePerspectives.isEmpty) return;
    final idx = _currentIndex.clamp(0, _activePerspectives.length - 1);
    _activePerspectives.removeAt(idx);

    if (_activePerspectives.isEmpty) {
      // All processed - show final page
      setState(() => _currentIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      return;
    }

    // Adjust index if needed
    if (_currentIndex >= _activePerspectives.length) {
      _currentIndex = _activePerspectives.length - 1;
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openDeepening(PerspectiveData perspective, LightingProfile profile) {
    // Appeler le callback pour déclencher le chargement si nécessaire
    widget.onDeepen?.call(perspective.approachKey);

    // Ouvrir le bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeepeningSheet(
        perspective: perspective,
        profile: profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.perspectives.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: Deep background
          _buildDeepBackground(),

          // Layer 2: PageView (perspectives + page finale)
          ScrollConfiguration(
            behavior: WebScrollBehavior(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _activePerspectives.length + 1, // +1 for final page
              itemBuilder: (context, index) {
                // Last page: "Has your perspective shifted?"
                if (index == _activePerspectives.length) {
                  return _FinalShiftPage(
                    breathController: _breathController,
                    onAnswer: (answer) {
                      widget.onShiftAnswer?.call(answer);
                    },
                    onClose: widget.onClose,
                  );
                }

                final perspective = _activePerspectives[index];
                final profile = getLightingProfile(perspective.approachKey);
                return _ImmersivePerspectivePage(
                  profile: profile,
                  perspective: perspective,
                  thoughtText: widget.thoughtText,
                  breathController: _breathController,
                  isActive: index == _currentIndex,
                  parallaxOffset: index == _currentIndex ? _parallaxOffset : 0,
                  onOpenDeepening: () => _openDeepening(perspective, profile),
                );
              },
            ),
          ),

          // Layer 3: Vignette de profondeur
          _buildDepthVignette(),

          // Layer 4: Feedback overlay save/reject (CDC §3.6)
          if (_swipeFeedback != null)
            _buildSwipeFeedbackOverlay(),

          // Layer 5: Header flottant
          _buildFloatingHeader(),

          // Layer 6: Navigation + actions save/reject
          _buildFloatingNavigation(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _PulsingOrb(),
            const SizedBox(height: 24),
            const Text(
              'Preparing the space...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            if (widget.onClose != null)
              TextButton(
                onPressed: widget.onClose,
                child: const Text('Back', style: TextStyle(color: Colors.white54)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepBackground() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final breathValue = _breathController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.3 * math.sin(breathValue * math.pi * 2),
                -0.2 + 0.1 * math.cos(breathValue * math.pi * 2),
              ),
              radius: 1.5 + 0.2 * breathValue,
              colors: const [
                Color(0xFF1a1a2e),
                Color(0xFF0d0d1a),
                Color(0xFF000000),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepthVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.4, 0.75, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    // Page finale : pas de header source
    final bool isOnFinalPage = _activePerspectives.isEmpty || _currentIndex >= _activePerspectives.length;
    final profile = isOnFinalPage
        ? kDefaultLightingProfile
        : getLightingProfile(_activePerspectives[_currentIndex].approachKey);
    final accentColor = Color(profile.accentColor);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  if (!isOnFinalPage)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _activePerspectives[_currentIndex].approachName,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (widget.onClose != null)
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white70, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Overlay visuel de feedback save/reject (CDC §3.6)
  Widget _buildSwipeFeedbackOverlay() {
    final isSave = _swipeFeedback == 'save';
    final color = isSave
        ? const Color(0xFF10B981) // Emerald
        : const Color(0xFFEF4444); // Red
    final icon = isSave ? Icons.bookmark_added : Icons.close_rounded;
    final label = isSave ? 'Saved' : 'Dismissed';

    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        // Fade in puis fade out
        final progress = _feedbackController.value;
        final opacity = progress < 0.3
            ? (progress / 0.3) // fade in
            : 1.0 - ((progress - 0.3) / 0.7); // fade out

        return IgnorePointer(
          child: Center(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingNavigation() {
    final bool isOnFinalPage = _currentIndex >= _activePerspectives.length;
    final currentKey = isOnFinalPage ? null : _activePerspectives[_currentIndex].approachKey;
    final isSaved = currentKey != null && _savedKeys.contains(currentKey);
    final isRejected = currentKey != null && _rejectedKeys.contains(currentKey);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ligne 1: Boutons Save / Reject (CDC §3.6)
                  // Masqués sur la page finale
                  if (!isOnFinalPage)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rejeter (swipe gauche)
                        _ActionButton(
                          icon: Icons.close_rounded,
                          label: 'Dismiss',
                          color: isRejected
                              ? const Color(0xFFEF4444)
                              : Colors.white.withValues(alpha: 0.6),
                          isActive: isRejected,
                          onTap: _rejectCurrent,
                        ),
                        const SizedBox(width: 32),
                        // Sauvegarder (swipe droite)
                        _ActionButton(
                          icon: Icons.bookmark_outline,
                          activeIcon: Icons.bookmark,
                          label: 'Keep',
                          color: isSaved
                              ? const Color(0xFF10B981)
                              : Colors.white.withValues(alpha: 0.6),
                          isActive: isSaved,
                          onTap: _saveCurrent,
                        ),
                      ],
                    ),
                  if (!isOnFinalPage) const SizedBox(height: 10),
                  // Ligne 2: Navigation dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NavArrow(
                        icon: Icons.arrow_back_ios_rounded,
                        enabled: _currentIndex > 0,
                        onTap: () => _goToPage(_currentIndex - 1),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dots pour les perspectives
                          ...List.generate(
                            _activePerspectives.length,
                            (index) {
                              final key = _activePerspectives[index].approachKey;
                              final dotColor = _savedKeys.contains(key)
                                  ? const Color(0xFF10B981)
                                  : _rejectedKeys.contains(key)
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                      : Color(getLightingProfile(key).accentColor);
                              return _PageDot(
                                isActive: index == _currentIndex,
                                accentColor: dotColor,
                                onTap: () => _goToPage(index),
                              );
                            },
                          ),
                          // Dot final (question)
                          _PageDot(
                            isActive: isOnFinalPage,
                            accentColor: Colors.white70,
                            onTap: () => _goToPage(_activePerspectives.length),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      _NavArrow(
                        icon: Icons.arrow_forward_ios_rounded,
                        enabled: _currentIndex < _activePerspectives.length, // includes final page
                        onTap: () => _goToPage(_currentIndex + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// IMMERSIVE PAGE (avec cinématiques CDC)
// ============================================================================

class _ImmersivePerspectivePage extends StatefulWidget {
  const _ImmersivePerspectivePage({
    required this.profile,
    required this.perspective,
    required this.thoughtText,
    required this.breathController,
    required this.isActive,
    required this.parallaxOffset,
    required this.onOpenDeepening,
  });

  final LightingProfile profile;
  final PerspectiveData perspective;
  final String thoughtText;
  final AnimationController breathController;
  final bool isActive;
  final double parallaxOffset;
  final VoidCallback onOpenDeepening;

  @override
  State<_ImmersivePerspectivePage> createState() => _ImmersivePerspectivePageState();
}

class _ImmersivePerspectivePageState extends State<_ImmersivePerspectivePage>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;

  late final SourceFamily _family;
  late final int _initialDelayMs;
  late final int _staggerMs;

  @override
  void initState() {
    super.initState();

    // Déterminer la famille et les paramètres de timing
    _family = _getSourceFamily(widget.perspective.approachKey, widget.profile.group);

    // Délai initial (silence) pour existentialisme
    _initialDelayMs = _family == SourceFamily.existentialismeTragique ? 400 : 0;

    // Délai entre cartouches: 450ms recommandé
    _staggerMs = 450;

    // Durée totale: délai initial + 4 cartouches * stagger + durée animation
    final totalDuration = _initialDelayMs + (4 * _staggerMs) + 700;

    _revealController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration),
    );

    if (widget.isActive) {
      _revealController.forward();
    }
  }

  @override
  void didUpdateWidget(_ImmersivePerspectivePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _revealController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final isDark = ThemeData.estimateBrightnessForColor(Color(p.backgroundColor)) == Brightness.dark;
    final textColor = Color(p.textColor);
    final accentColor = Color(p.accentColor);

    return Stack(
      children: [
        // Background avec parallax
        _buildParallaxBackground(),

        // Contenu principal
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 100),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pensée utilisateur (ancrage)
                  _buildThoughtAnchor(textColor, accentColor, isDark),
                  const SizedBox(height: 32),

                  // Cartouches avec cinématiques CDC
                  _buildTextCartouches(textColor, accentColor, isDark),

                  const SizedBox(height: 24),

                  // Poignée "Approfondir" (doorway)
                  _buildDeepeningDoorway(accentColor),
                ],
              ),
            ),
          ),
        ),

        // Focus gradient
        _buildFocusGradient(),
      ],
    );
  }

  Widget _buildParallaxBackground() {
    final p = widget.profile;
    final c1 = Color(p.animatedGradient[0]);
    final c2 = Color(p.animatedGradient[1]);

    return AnimatedBuilder(
      animation: widget.breathController,
      builder: (context, child) {
        final breath = widget.breathController.value;
        final parallax = widget.parallaxOffset * 50;

        return Stack(
          children: [
            // Layer 1: Fond profond
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(parallax * 0.3, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + breath * 0.2, -1),
                      end: Alignment(1 - breath * 0.2, 1),
                      colors: [c1, c2],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Orbes lumineux
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(parallax * 0.5, 0),
                child: CustomPaint(
                  painter: _OrbsPainter(
                    color: Color(p.accentColor),
                    breathValue: breath,
                  ),
                ),
              ),
            ),

            // Layer 3: Particules
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(parallax * 0.8, 0),
                child: CustomPaint(
                  painter: _ParticlesPainter(
                    color: Colors.white,
                    breathValue: breath,
                  ),
                ),
              ),
            ),

            // Layer 4: Texture grain (effet film/papier)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GrainTexturePainter(
                    opacity: 0.025,
                    seed: 42,
                  ),
                ),
              ),
            ),

            // Layer 5: Lignes subtiles (texture toile)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LineTexturePainter(
                    color: Color(p.accentColor),
                    opacity: 0.012,
                  ),
                ),
              ),
            ),

            // Layer 6: Vignette douce
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SoftVignettePainter(
                    color: Colors.black,
                    intensity: 0.25,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThoughtAnchor(Color textColor, Color accentColor, bool isDark) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // L'ancrage apparaît immédiatement (pas de délai initial)
        final progress = (_revealController.value * 4).clamp(0.0, 1.0);
        final opacity = Curves.easeOut.transform(progress);
        final translateY = (1 - opacity) * 20;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: _DensityContainer(
        accentColor: accentColor,
        isDark: isDark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.thoughtText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCartouches(Color textColor, Color accentColor, bool isDark) {
    final sections = _parseTextIntoSections(widget.perspective.responseText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++)
          _AnimatedCartouche(
            section: sections[i],
            textColor: textColor,
            accentColor: accentColor,
            isDark: isDark,
            revealController: _revealController,
            fontFamily: widget.profile.fontFamilyBody,
            family: _family,
            initialDelayMs: _initialDelayMs,
            staggerMs: _staggerMs,
            totalDuration: _revealController.duration!.inMilliseconds,
          ),
      ],
    );
  }

  List<_TextSection> _parseTextIntoSections(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return [_TextSection(title: 'Perspective', content: text, index: 3)];
    }

    final titles = ['Motif', 'Personnage', 'Contexte', 'Perspective'];
    final sections = <_TextSection>[];
    final chunkSize = (lines.length / 4).ceil().clamp(1, lines.length);

    for (int i = 0; i < 4 && i * chunkSize < lines.length; i++) {
      final start = i * chunkSize;
      final end = ((i + 1) * chunkSize).clamp(0, lines.length);
      final chunk = lines.sublist(start, end).join('\n');
      if (chunk.trim().isNotEmpty) {
        sections.add(_TextSection(
          title: titles[i],
          content: chunk,
          index: i,
        ));
      }
    }

    return sections.isEmpty
        ? [_TextSection(title: 'Perspective', content: text, index: 3)]
        : sections;
  }

  Widget _buildDeepeningDoorway(Color accentColor) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Apparaît après tous les cartouches
        final startTime = (_initialDelayMs + 4 * _staggerMs) / _revealController.duration!.inMilliseconds;
        final progress = ((_revealController.value - startTime) / (1 - startTime)).clamp(0.0, 1.0);
        final opacity = Curves.easeOut.transform(progress);

        return Opacity(opacity: opacity, child: child);
      },
      child: GestureDetector(
        onTap: widget.onOpenDeepening,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // Ligne fine (handle)
              Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 12),

              // Chevron + label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.expand_more_rounded,
                    color: accentColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Go Deeper',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusGradient() {
    // Gradient fixe pour encadrer le contenu (vignette douce)
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.25),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
            ],
            stops: const [0.0, 0.15, 0.85, 1.0],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ANIMATED CARTOUCHE (avec cinématiques CDC)
// ============================================================================

class _AnimatedCartouche extends StatefulWidget {
  const _AnimatedCartouche({
    required this.section,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    required this.revealController,
    required this.fontFamily,
    required this.family,
    required this.initialDelayMs,
    required this.staggerMs,
    required this.totalDuration,
  });

  final _TextSection section;
  final Color textColor;
  final Color accentColor;
  final bool isDark;
  final AnimationController revealController;
  final String fontFamily;
  final SourceFamily family;
  final int initialDelayMs;
  final int staggerMs;
  final int totalDuration;

  @override
  State<_AnimatedCartouche> createState() => _AnimatedCartoucheState();
}

class _AnimatedCartoucheState extends State<_AnimatedCartouche>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  // Cinématique pour ce cartouche
  late final CinematicType _cinematic;
  late final CinematicType? _accent;

  @override
  void initState() {
    super.initState();

    // Pulse controller pour C6 (battement unique)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Déterminer les cinématiques selon la famille et le type de section
    _determineCinematics();
  }

  void _determineCinematics() {
    switch (widget.family) {
      case SourceFamily.realismeLitterature:
        // C1 principal, C2 renfort, C6 optionnel sur Perspective
        _cinematic = CinematicType.c1RespirVerticale;
        _accent = widget.section.isPerspective ? CinematicType.c6BattementUnique : null;

      case SourceFamily.existentialismeTragique:
        // Motif: C2, autres: C1, Perspective: C6
        _cinematic = widget.section.isMotif
            ? CinematicType.c2MiseAuPoint
            : CinematicType.c1RespirVerticale;
        _accent = widget.section.isPerspective ? CinematicType.c6BattementUnique : null;

      case SourceFamily.spiritualiteMystique:
        // C4 principal, C2 renfort
        _cinematic = CinematicType.c4ApparitionSeuil;
        _accent = null;

      case SourceFamily.stoicismeSagesses:
        // C1 uniquement, pas de renfort
        _cinematic = CinematicType.c1RespirVerticale;
        _accent = null;

      case SourceFamily.mythesArchetypes:
        // C5 principal, C1 renfort
        _cinematic = CinematicType.c5Profondeur;
        _accent = null;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculer le timing d'apparition
    final startMs = widget.initialDelayMs + (widget.section.index * widget.staggerMs);
    final endMs = startMs + 700; // Durée d'animation
    final startTime = startMs / widget.totalDuration;
    final endTime = endMs / widget.totalDuration;

    return AnimatedBuilder(
      animation: widget.revealController,
      builder: (context, child) {
        final rawProgress = ((widget.revealController.value - startTime) / (endTime - startTime)).clamp(0.0, 1.0);

        // Appliquer la cinématique
        return _buildWithCinematic(child!, rawProgress);
      },
      child: _buildCartoucheContent(),
    );
  }

  Widget _buildWithCinematic(Widget child, double progress) {
    final eased = _getEasedProgress(progress);

    switch (_cinematic) {
      case CinematicType.c1RespirVerticale:
        // Translation Y: +14px → 0, Opacity: 0 → 1
        return Transform.translate(
          offset: Offset(0, (1 - eased) * 14),
          child: Opacity(opacity: eased, child: child),
        );

      case CinematicType.c2MiseAuPoint:
        // Blur: 6px → 0, Opacity: 0.35 → 1
        final blur = (1 - eased) * 6;
        final opacity = 0.35 + (eased * 0.65);
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Opacity(opacity: opacity, child: child),
        );

      case CinematicType.c3GlissementLateral:
        // Translation X: +10px → 0, Opacity: 0 → 1
        return Transform.translate(
          offset: Offset((1 - eased) * 10, 0),
          child: Opacity(opacity: eased, child: child),
        );

      case CinematicType.c4ApparitionSeuil:
        // Clip vertical progressif
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: eased.clamp(0.01, 1.0),
            child: Opacity(opacity: eased, child: child),
          ),
        );

      case CinematicType.c5Profondeur:
        // Scale: 0.98 → 1
        final scale = 0.98 + (eased * 0.02);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: eased, child: child),
        );

      case CinematicType.c6BattementUnique:
        // Scale pulse: 1 → 1.015 → 1 (une seule fois)
        // Ce n'est pas utilisé comme cinématique principale, seulement accent
        return child;
    }
  }

  double _getEasedProgress(double progress) {
    switch (_cinematic) {
      case CinematicType.c1RespirVerticale:
      case CinematicType.c3GlissementLateral:
        return Curves.easeOutCubic.transform(progress);
      case CinematicType.c2MiseAuPoint:
        return Curves.easeOut.transform(progress);
      case CinematicType.c4ApparitionSeuil:
        return Curves.easeInOut.transform(progress);
      case CinematicType.c5Profondeur:
        return Curves.easeOutQuart.transform(progress);
      case CinematicType.c6BattementUnique:
        return Curves.easeInOut.transform(progress);
    }
  }

  Widget _buildCartoucheContent() {
    return _DensityContainer(
      accentColor: widget.accentColor,
      isDark: widget.isDark,
      isPerspective: widget.section.isPerspective,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec marque structurelle
          _buildSectionHeader(),
          const SizedBox(height: 14),
          // Contenu avec interligne augmenté (≥1.4)
          Text(
            widget.section.content,
            style: TextStyle(
              fontFamily: widget.fontFamily,
              fontSize: 15,
              height: 1.7, // Interligne augmenté
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    // Marques structurelles discrètes selon CDC
    Widget marker;
    TextStyle titleStyle;

    switch (widget.section.index) {
      case 0: // Motif - point ou barre colorée (accent)
        marker = Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.accentColor,
            shape: BoxShape.circle,
          ),
        );
        titleStyle = TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: widget.accentColor,
          letterSpacing: 1.5,
        );

      case 1: // Personnage/Référence - typographie distincte (italique)
        marker = Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        );
        titleStyle = TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: widget.accentColor.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        );

      case 2: // Contexte - cartouche neutre
        marker = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.textColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        );
        titleStyle = TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: widget.textColor.withValues(alpha: 0.6),
          letterSpacing: 1.0,
        );

      case 3: // Perspective - accent visuel renforcé
      default:
        marker = Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
        titleStyle = TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: widget.accentColor,
          letterSpacing: 1.8,
        );
    }

    return Row(
      children: [
        marker,
        const SizedBox(width: 10),
        Text(widget.section.title.toUpperCase(), style: titleStyle),
      ],
    );
  }
}

// ============================================================================
// DENSITY CONTAINER (Épaisseur atmosphérique)
// ============================================================================

class _DensityContainer extends StatelessWidget {
  const _DensityContainer({
    required this.accentColor,
    required this.isDark,
    required this.child,
    this.isPerspective = false,
  });

  final Color accentColor;
  final bool isDark;
  final Widget child;
  final bool isPerspective;

  @override
  Widget build(BuildContext context) {
    // Calculs de densité atmosphérique
    final baseOpacity = isDark ? 0.08 : 0.06;

    // Ombre de diffusion (pas d'élévation)
    // offset Y: 2-4px, blur: 24-32px, opacity: 4-6%
    final shadowOpacity = isPerspective ? 0.10 : 0.06;

    // Bordure uniforme subtile
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Ombre de diffusion très large et très floue
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowOpacity),
              offset: const Offset(0, 3),
              blurRadius: 28,
              spreadRadius: 0,
            ),
            // Légère lueur de couleur pour la Perspective
            if (isPerspective)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                offset: Offset.zero,
                blurRadius: 24,
                spreadRadius: 0,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Fond translucide légèrement plus opaque pour lisibilité
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: baseOpacity),
                borderRadius: BorderRadius.circular(16),
                // Bordure uniforme subtile
                border: Border.all(color: borderColor, width: 1),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DEEPENING SHEET (Bottom Sheet Approfondissement)
// ============================================================================

class _DeepeningSheet extends StatefulWidget {
  const _DeepeningSheet({
    required this.perspective,
    required this.profile,
  });

  final PerspectiveData perspective;
  final LightingProfile profile;

  @override
  State<_DeepeningSheet> createState() => _DeepeningSheetState();
}

class _DeepeningSheetState extends State<_DeepeningSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentRevealController;
  final TextEditingController _commentController = TextEditingController();
  late final List<String> _questions;

  @override
  void initState() {
    super.initState();
    _contentRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Charger les questions pour cette source
    _questions = _getQuestionsForApproach(
      widget.perspective.approachKey,
      widget.profile.group,
    );

    // Si le contenu est prêt, révéler
    if (widget.perspective.deepeningState == DeepeningState.ready) {
      _contentRevealController.forward();
    }
  }

  @override
  void dispose() {
    _contentRevealController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final isDark = ThemeData.estimateBrightnessForColor(Color(p.backgroundColor)) == Brightness.dark;
    final textColor = Color(p.textColor);
    final accentColor = Color(p.accentColor);
    final bgColor = Color(p.backgroundColor);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle de fermeture
              _buildSheetHandle(accentColor),

              // Header
              _buildSheetHeader(textColor, accentColor),

              // Contenu
              Expanded(
                child: _buildSheetContent(
                  scrollController,
                  textColor,
                  accentColor,
                  isDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          // Titre
          Text(
            'Deepening',
            style: TextStyle(
              fontFamily: widget.profile.fontFamilyTitle,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Bouton fermer
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: textColor.withValues(alpha: 0.7), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent(
    ScrollController scrollController,
    Color textColor,
    Color accentColor,
    bool isDark,
  ) {
    switch (widget.perspective.deepeningState) {
      case DeepeningState.notRequested:
      case DeepeningState.loading:
        return _buildAntichambre(textColor, accentColor);

      case DeepeningState.ready:
        return _buildReadyContent(scrollController, textColor, accentColor, isDark);

      case DeepeningState.failed:
        return _buildFailedState(textColor, accentColor);
    }
  }

  Widget _buildAntichambre(Color textColor, Color accentColor) {
    // "Antichambre" pendant le chargement
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lueur discrète (pas de spinner technique)
          _PulsingOrb(color: accentColor),
          const SizedBox(height: 24),
          Text(
            'Deepening in progress',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can close at any time',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyContent(
    ScrollController scrollController,
    Color textColor,
    Color accentColor,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _contentRevealController,
      builder: (context, child) {
        final opacity = Curves.easeOut.transform(_contentRevealController.value);
        return Opacity(opacity: opacity, child: child);
      },
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenu de l'approfondissement
            Text(
              widget.perspective.deepeningText ?? 'Contenu non disponible.',
              style: TextStyle(
                fontFamily: widget.profile.fontFamilyBody,
                fontSize: 15,
                height: 1.7,
                color: textColor,
              ),
            ),

            const SizedBox(height: 32),

            // ── Questions complémentaires par source (CDC §5) ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'QUESTIONS',
                        style: TextStyle(
                          fontFamily: widget.profile.fontFamilyTitle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final question in _questions) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question,
                              style: TextStyle(
                                fontFamily: widget.profile.fontFamilyBody,
                                fontSize: 15,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                color: textColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Champ commentaire libre ──
            Text(
              'Your feelings',
              style: TextStyle(
                fontFamily: widget.profile.fontFamilyTitle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                style: TextStyle(
                  fontFamily: widget.profile.fontFamilyBody,
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Note what this perspective awakens in you...',
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.3),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState(Color textColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: textColor.withValues(alpha: 0.4),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load the deepening',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Retry logic
            },
            child: Text(
              'Retry',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGE FINALE : "TON REGARD A-T-IL BOUGÉ ?" (CDC §5)
// ============================================================================

class _FinalShiftPage extends StatefulWidget {
  const _FinalShiftPage({
    required this.breathController,
    required this.onAnswer,
    this.onClose,
  });

  final AnimationController breathController;
  final void Function(String answer) onAnswer;
  final VoidCallback? onClose;

  @override
  State<_FinalShiftPage> createState() => _FinalShiftPageState();
}

class _FinalShiftPageState extends State<_FinalShiftPage>
    with SingleTickerProviderStateMixin {
  String? _selectedAnswer;
  late final AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond avec respiration
        AnimatedBuilder(
          animation: widget.breathController,
          builder: (context, child) {
            final breath = widget.breathController.value;
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    0.2 * math.sin(breath * math.pi * 2),
                    -0.1 + 0.1 * math.cos(breath * math.pi * 2),
                  ),
                  radius: 1.4,
                  colors: const [
                    Color(0xFF1a1a2e),
                    Color(0xFF0d0d1a),
                    Color(0xFF000000),
                  ],
                ),
              ),
            );
          },
        ),

        // Contenu centré
        SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) {
                final opacity = Curves.easeOut.transform(_revealController.value);
                final translateY = (1 - opacity) * 30;
                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Question
                    Text(
                      'Has your perspective shifted?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Options
                    _buildOption('Yes', Icons.check_circle_outline),
                    const SizedBox(height: 12),
                    _buildOption('A little', Icons.change_history_outlined),
                    const SizedBox(height: 12),
                    _buildOption('Not at all', Icons.radio_button_unchecked),

                    const SizedBox(height: 40),

                    // Bouton fermer après réponse
                    if (_selectedAnswer != null && widget.onClose != null)
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Text(
                            'Finish',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(String label, IconData icon) {
    final isSelected = _selectedAnswer == label;
    final accentColor = const Color(0xFF60A5FA);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAnswer = label);
        widget.onAnswer(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// UTILITY WIDGETS
// ============================================================================

/// Bouton d'action save/reject (CDC §3.6)
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? color.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Icon(
              isActive ? (activeIcon ?? icon) : icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _PulsingOrb extends StatefulWidget {
  const _PulsingOrb({this.color});
  final Color? color;

  @override
  State<_PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<_PulsingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white54;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 + 0.3 * _controller.value),
                blurRadius: 30 + 20 * _controller.value,
                spreadRadius: 5 + 10 * _controller.value,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.3 + 0.2 * _controller.value),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

class _OrbsPainter extends CustomPainter {
  final Color color;
  final double breathValue;

  _OrbsPainter({required this.color, required this.breathValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * (0.3 + breathValue * 0.05)),
      100 + breathValue * 20,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * (0.6 - breathValue * 0.05)),
      80 + breathValue * 15,
      paint..color = color.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(_OrbsPainter oldDelegate) =>
      oldDelegate.breathValue != breathValue || oldDelegate.color != color;
}

class _ParticlesPainter extends CustomPainter {
  final Color color;
  final double breathValue;

  _ParticlesPainter({required this.color, required this.breathValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = baseY + math.sin(breathValue * math.pi * 2 + i) * 8;
      final radius = 1.0 + random.nextDouble() * 1.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      oldDelegate.breathValue != breathValue;
}

/// Texture de grain/bruit procédural
class _GrainTexturePainter extends CustomPainter {
  final double opacity;
  final int seed;

  _GrainTexturePainter({this.opacity = 0.03, this.seed = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    // Grain fin - petits points dispersés
    final grainCount = (size.width * size.height / 400).toInt().clamp(500, 3000);

    for (int i = 0; i < grainCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final grainOpacity = random.nextDouble() * opacity;

      paint.color = (random.nextBool() ? Colors.white : Colors.black)
          .withValues(alpha: grainOpacity);

      canvas.drawCircle(Offset(x, y), 0.5 + random.nextDouble() * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainTexturePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.opacity != opacity;
}

/// Texture de lignes subtiles (effet papier/toile)
class _LineTexturePainter extends CustomPainter {
  final Color color;
  final double opacity;

  _LineTexturePainter({required this.color, this.opacity = 0.02});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Lignes horizontales subtiles (effet toile)
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LineTexturePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Texture de vignette douce
class _SoftVignettePainter extends CustomPainter {
  final Color color;
  final double intensity;

  _SoftVignettePainter({required this.color, this.intensity = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) * 0.8;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        color.withValues(alpha: intensity * 0.3),
        color.withValues(alpha: intensity),
      ],
      stops: const [0.3, 0.7, 1.0],
    );

    final rect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);
    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SoftVignettePainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.color != color;
}

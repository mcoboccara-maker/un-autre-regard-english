// lib/screens/thought_input_screen.dart
// CDC §3.3 - Saisie de pensee avec selecteur de type + 2 boutons (direct / emotions)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import '../services/persistent_storage_service.dart';
import '../services/emotional_tracking_service.dart';
import '../widgets/nav_cartouche.dart';
import '../widgets/brain_gestation_widget.dart';
import 'eclairages_carousel_screen.dart';
import 'emotion_wheel_screen.dart';
import 'perspective_room_screen.dart';

class ThoughtInputScreen extends StatefulWidget {
  final ApproachConfig? preselectedSource;
  final EmotionConfig? preselectedEmotion;
  final String? emotionComment;
  final List<String>? selectedNuances;
  final int? emotionIntensity;

  const ThoughtInputScreen({
    super.key,
    this.preselectedSource,
    this.preselectedEmotion,
    this.emotionComment,
    this.selectedNuances,
    this.emotionIntensity,
  });

  @override
  State<ThoughtInputScreen> createState() => _ThoughtInputScreenState();
}

class _ThoughtInputScreenState extends State<ThoughtInputScreen> {
  final TextEditingController _thoughtController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isGenerating = false;
  String? _errorMessage;
  ReflectionType _selectedType = ReflectionType.thought;
  bool _showSuggestions = false;

  /// Active user sources (or defaults) — resolved from AIService
  List<ApproachConfig> _activeSources = [];

  final List<String> _thoughtSuggestions = [
    "I'm not good enough...",
    "I feel stuck",
    "This person makes me angry",
    "I'm afraid of failure",
  ];

  final List<String> _situationSuggestions = [
    "Conflict with a loved one",
    "Stress at work",
    "Communication problem",
  ];

  final List<String> _existentialSuggestions = [
    "What is the meaning of my life?",
    "Am I on the right path?",
  ];

  final List<String> _dilemmaSuggestions = [
    "Change jobs or stay?",
    "Tell the truth or stay silent?",
  ];

  @override
  void initState() {
    super.initState();
    _thoughtController.addListener(() {
      setState(() {});
    });
    // Load user's active sources
    _loadActiveSources();
  }

  /// Load active sources from AIService (user profile or defaults)
  Future<void> _loadActiveSources() async {
    try {
      // Ensure approaches are loaded (including defaults if empty)
      if (AIService.instance.userApproches.isEmpty) {
        await AIService.instance.loadUserApproaches();
      }
      final sourceKeys = AIService.instance.userApproches;
      final List<ApproachConfig> resolved = [];
      for (final key in sourceKeys) {
        final config = ApproachCategories.findByKey(key);
        if (config != null) {
          resolved.add(config);
        }
      }
      if (mounted) {
        setState(() {
          _activeSources = resolved;
        });
      }
    } catch (e) {
      print('ThoughtInputScreen: Error _loadActiveSources: $e');
    }
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getPlaceholderText() {
    switch (_selectedType) {
      case ReflectionType.thought:
        return 'I think that...\nI feel...\nI have the impression that...';
      case ReflectionType.situation:
        return 'Describe the situation that worries you...';
      case ReflectionType.existential:
        return 'What existential question is on your mind?';
      case ReflectionType.dilemma:
        return 'What difficult choice do you have to make?';
    }
  }

  List<String> _getSuggestionsForType() {
    switch (_selectedType) {
      case ReflectionType.thought:
        return _thoughtSuggestions;
      case ReflectionType.situation:
        return _situationSuggestions;
      case ReflectionType.existential:
        return _existentialSuggestions;
      case ReflectionType.dilemma:
        return _dilemmaSuggestions;
    }
  }

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

  IconData _getFallbackIcon(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return Icons.psychology;
      case ReflectionType.situation:
        return Icons.place;
      case ReflectionType.existential:
        return Icons.help_outline;
      case ReflectionType.dilemma:
        return Icons.compare_arrows;
    }
  }

  /// Direct generation (skip emotions)
  Future<void> _generateDirect() async {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your thought before continuing.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final userProfile = PersistentStorageService.instance.getUserProfile();

      if (widget.preselectedSource != null) {
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: widget.preselectedSource!.key,
          reflectionText: text,
          reflectionType: _selectedType,
          emotionalState: EmotionalState.empty(),
          userProfile: userProfile,
          intensiteEmotionnelle: 5,
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
                thoughtText: text,
                perspectives: [perspective],
              ),
            ),
          );
        }
      } else {
        final sources = _pickRandomSources(_activeSources.length > 0 ? _activeSources.length : 3);

        // Step 1: Generate the first source, navigate immediately,
        // pass the remaining ones to EclairagesCarouselScreen for progressive generation
        final firstSource = sources.first;
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: firstSource.key,
          reflectionText: text,
          reflectionType: _selectedType,
          emotionalState: EmotionalState.empty(),
          userProfile: userProfile,
          intensiteEmotionnelle: 5,
        );
        final meta = AIService.instance.lastFigureMeta;
        final firstPerspective = PerspectiveData(
          approachKey: firstSource.key,
          approachName: firstSource.name,
          responseText: response,
          figureName: meta?['nom'],
          figureReference: meta?['reference'],
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: text,
                perspectives: [firstPerspective],
                pendingSources: sources.length > 1 ? sources.sublist(1) : null,
                reflectionType: _selectedType,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error during generation. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Navigate to emotion selection screen
  void _navigateToEmotions() {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your thought before continuing.';
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/emotions'),
        builder: (_) => EmotionWheelScreen(
          entryMode: EmotionWheelEntryMode.exprime,
          thoughtText: text,
          reflectionType: _selectedType,
          preselectedSource: widget.preselectedSource,
        ),
      ),
    );
  }

  void _showPositiveThought() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PositiveThoughtDialog(),
    );
  }

  List<ApproachConfig> _pickRandomSources(int count) {
    // Use user's active sources (or defaults) if available
    if (_activeSources.isNotEmpty) {
      final shuffled = List<ApproachConfig>.from(_activeSources)..shuffle();
      return shuffled.take(count).toList();
    }
    // Fallback: all sources
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
              // Header with menu logo + title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/univers_visuel/exprime_ce_qui_te_traverse.png',
                        width: 32, height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Express what\'s on your mind',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/pensee_positive.png',
                      fallbackIcon: Icons.lightbulb_outline,
                      tooltip: 'Positive thought',
                      onTap: _showPositiveThought,
                    ),
                    const SizedBox(width: 8),
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
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // If source preselected — show single source badge
                      if (widget.preselectedSource != null) ...[
                        _buildSourceBadge(),
                        const SizedBox(height: 16),
                      ],

                      // If NO preselected source — show active sources badges
                      if (widget.preselectedSource == null && _activeSources.isNotEmpty) ...[
                        _buildActiveSourcesBadges(),
                        const SizedBox(height: 16),
                      ],

                      // If emotion preselected
                      if (widget.preselectedEmotion != null) ...[
                        _buildEmotionBadge(),
                        const SizedBox(height: 16),
                      ],

                      // Type selector (4 PNG icons)
                      _buildTypeSelector(),
                      const SizedBox(height: 16),

                      // Main input area
                      _buildMainInput(),
                      const SizedBox(height: 8),

                      // Suggestions
                      if (_showSuggestions) _buildSuggestions(),

                      // Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorMessage(),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              if (_isGenerating)
                _buildGeneratingIndicator()
              else
                _buildTwoButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // === TYPE SELECTOR (4 PNG icons, row) ===
  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ReflectionType.values.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    _getTypeIconPath(type),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getFallbackIcon(type),
                          size: 30,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === MAIN INPUT ===
  Widget _buildMainInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/univers_visuel/exprimetoilibrement.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.edit_note,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Express what\'s on your mind',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                // Toggle suggestions
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSuggestions = !_showSuggestions;
                    });
                  },
                  icon: Icon(
                    _showSuggestions
                        ? Icons.lightbulb
                        : Icons.lightbulb_outline,
                    color: _showSuggestions
                        ? const Color(0xFFFBBF24)
                        : Colors.white.withValues(alpha: 0.4),
                    size: 22,
                  ),
                  tooltip: 'See examples',
                ),
              ],
            ),
          ),

          // Text field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _thoughtController,
              focusNode: _focusNode,
              maxLines: 6,
              minLines: 4,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: _getPlaceholderText(),
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 15,
                  height: 1.5,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Char counter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_thoughtController.text.length} characters',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === SUGGESTIONS ===
  Widget _buildSuggestions() {
    List<String> suggestions = _getSuggestionsForType();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Examples',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _thoughtController.text = suggestion;
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    suggestion,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // === ERROR ===
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.red[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === BOTTOM BUTTONS — 2 cartouches side by side + back ===
  Widget _buildTwoButtons() {
    final canContinue = _thoughtController.text.trim().isNotEmpty;
    final activeColor = const Color(0xFF2E8B7B);
    final disabledColor = const Color(0xFF2E8B7B).withValues(alpha: 0.3);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2 cartouches side by side
            Row(
              children: [
                // Cartouche 1: See differently
                Expanded(
                  child: GestureDetector(
                    onTap: canContinue ? _generateDirect : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: canContinue ? activeColor : disabledColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/univers_visuel/regardeautrement.png',
                            width: 24, height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('regardeautrement.png ERROR: $error');
                              return const Icon(Icons.auto_awesome, size: 20, color: Colors.white);
                            },
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'See\ndifferently',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Cartouche 2: Enter your emotions and see differently
                Expanded(
                  child: GestureDetector(
                    onTap: canContinue ? _navigateToEmotions : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: canContinue ? activeColor : disabledColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/univers_visuel/emotionsdujour.png',
                            width: 24, height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('emotionsdujour.png ERROR: $error');
                              return const Icon(Icons.favorite_rounded, size: 20, color: Colors.white);
                            },
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Enter your emotions\nand see differently',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Back cartouche
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === GENERATING INDICATOR (Brain Gestation Widget) ===
  Widget _buildGeneratingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: BrainGestationWidget(
          isComplete: false,
          size: 180,
        ),
      ),
    );
  }

  // === ACTIVE SOURCES (scrollable badges) ===
  Widget _buildActiveSourcesBadges() {
    if (_activeSources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Your sources of inspiration',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _activeSources.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final source = _activeSources[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: source.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: source.color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(source.icon, color: source.color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      source.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // === BADGES ===
  Widget _buildSourceBadge() {
    final source = widget.preselectedSource!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: source.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: source.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(source.icon, color: source.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  source.credo,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionBadge() {
    final emotion = widget.preselectedEmotion!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emotion.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: emotion.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(emotion.icon, color: emotion.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emotion.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.emotionComment != null)
                      Text(
                        widget.emotionComment!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Intensity indicator
              if (widget.emotionIntensity != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: emotion.color.withValues(alpha: 0.2),
                    border: Border.all(color: emotion.color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.emotionIntensity}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: emotion.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Selected nuances
          if (widget.selectedNuances != null &&
              widget.selectedNuances!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: widget.selectedNuances!.map((nuance) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: emotion.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    nuance,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// POSITIVE THOUGHT DIALOG (AI-generated)
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
                'Thanks!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

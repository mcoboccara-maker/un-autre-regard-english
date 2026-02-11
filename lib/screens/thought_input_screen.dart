// lib/screens/thought_input_screen.dart
// CDC §3.3 - Saisie de pensee avec selecteur de type + 2 boutons (direct / emotions)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import 'eclairages_carousel_screen.dart';
import 'emotion_selection_screen.dart';
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

class _ThoughtInputScreenState extends State<ThoughtInputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _thoughtController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isGenerating = false;
  String? _errorMessage;
  ReflectionType _selectedType = ReflectionType.thought;
  bool _showSuggestions = false;

  late AnimationController _hourglassController;

  final List<String> _thoughtSuggestions = [
    "Je ne suis pas a la hauteur...",
    "Je me sens bloque(e)",
    "Cette personne me met en colere",
    "J'ai peur de l'echec",
  ];

  final List<String> _situationSuggestions = [
    "Conflit avec un proche",
    "Stress au travail",
    "Probleme de communication",
  ];

  final List<String> _existentialSuggestions = [
    "Quel est le sens de ma vie ?",
    "Suis-je sur la bonne voie ?",
  ];

  final List<String> _dilemmaSuggestions = [
    "Changer de travail ou rester ?",
    "Dire la verite ou me taire ?",
  ];

  @override
  void initState() {
    super.initState();
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _thoughtController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    _focusNode.dispose();
    _hourglassController.dispose();
    super.dispose();
  }

  String _getPlaceholderText() {
    switch (_selectedType) {
      case ReflectionType.thought:
        return 'Je pense que...\nJe me sens...\nJ\'ai l\'impression que...';
      case ReflectionType.situation:
        return 'Decris la situation qui te preoccupe...';
      case ReflectionType.existential:
        return 'Quelle question existentielle te traverse ?';
      case ReflectionType.dilemma:
        return 'Quel choix difficile dois-tu faire ?';
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
        _errorMessage = 'Saisis ta pensee avant de continuer.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    try {
      if (widget.preselectedSource != null) {
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: widget.preselectedSource!.key,
          reflectionText: text,
          reflectionType: _selectedType,
          emotionalState: EmotionalState.empty(),
          userProfile: null,
          intensiteEmotionnelle: 5,
        );

        if (mounted) {
          final perspective = PerspectiveData(
            approachKey: widget.preselectedSource!.key,
            approachName: widget.preselectedSource!.name,
            responseText: response,
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
        final sources = _pickRandomSources(3);
        final List<PerspectiveData> perspectives = [];

        for (final source in sources) {
          final response =
              await AIService.instance.generateApproachSpecificResponse(
            approach: source.key,
            reflectionText: text,
            reflectionType: _selectedType,
            emotionalState: EmotionalState.empty(),
            userProfile: null,
            intensiteEmotionnelle: 5,
          );

          perspectives.add(PerspectiveData(
            approachKey: source.key,
            approachName: source.name,
            responseText: response,
          ));
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: text,
                perspectives: perspectives,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la generation. Reessaie.';
          _isGenerating = false;
        });
      }
    }
  }

  /// Navigate to emotion selection screen
  void _navigateToEmotions() {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Saisis ta pensee avant de continuer.';
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmotionSelectionScreen(
          thoughtText: text,
          reflectionType: _selectedType,
          preselectedSource: widget.preselectedSource,
        ),
      ),
    );
  }

  List<ApproachConfig> _pickRandomSources(int count) {
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
              // Header
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
                    Expanded(
                      child: Text(
                        'Ta pensee',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/menu', (route) => false,
                      ),
                      icon: const Icon(Icons.home_rounded,
                          color: Colors.white),
                      tooltip: 'Menu',
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
                      // If source preselected
                      if (widget.preselectedSource != null) ...[
                        _buildSourceBadge(),
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
                    'Exprime ce qui te traverse',
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
                  tooltip: 'Voir des exemples',
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
                border: InputBorder.none,
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
                  '${_thoughtController.text.length} caracteres',
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
            'Exemples',
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

  // === TWO BUTTONS (direct / via emotions) ===
  Widget _buildTwoButtons() {
    final canContinue = _thoughtController.text.trim().isNotEmpty;

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
            // Button 1: Voir autrement (direct generation, skip emotions)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canContinue ? _generateDirect : null,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(
                  'Voir autrement',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: canContinue ? 2 : 0,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Button 2: Emotions liees et autre regard
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canContinue ? _navigateToEmotions : null,
                icon: Image.asset(
                  'assets/univers_visuel/emotionsdujour.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.mood, size: 20),
                ),
                label: Text(
                  'Emotions liees et autre regard',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: canContinue
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF94A3B8),
                  side: BorderSide(
                    color: canContinue
                        ? const Color(0xFF7C3AED)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Back button (small)
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Image.asset(
                'assets/univers_visuel/retour.png',
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.arrow_back, size: 16),
              ),
              label: Text(
                'Retour au menu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === GENERATING INDICATOR ===
  Widget _buildGeneratingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            RotationTransition(
              turns: _hourglassController,
              child: Image.asset(
                'assets/univers_visuel/generationiaencours.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generation en cours...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
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
              // Indicateur d'intensité
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
          // Nuances sélectionnées
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

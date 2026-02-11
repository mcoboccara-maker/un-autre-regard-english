// LightingScreen — Un Autre Regard
// CDC: "Champ perceptif + Nappe lumineuse (glisse)"
// Version: 1.0 - 2026-02-04
//
// Principe: 3 couches visuelles
// 1) Fond perceptif (image gradient bleu-vert)
// 2) Texture grain (overlay répétable)
// 3) Nappe lumineuse (spotlight qui glisse vers la section active)

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tts_service.dart';

// ============================================================================
// DATA MODEL
// ============================================================================

class LightingSection {
  final String id;
  final String title;
  final String content;
  final String? iconPath;

  const LightingSection({
    required this.id,
    required this.title,
    required this.content,
    this.iconPath,
  });
}

class LightingPerspective {
  final String approachKey;
  final String approachName;
  final String? iconPath;
  final List<LightingSection> sections;
  final bool isLoading;
  final bool hasDeepening;
  final String? deepeningContent;

  const LightingPerspective({
    required this.approachKey,
    required this.approachName,
    this.iconPath,
    required this.sections,
    this.isLoading = false,
    this.hasDeepening = false,
    this.deepeningContent,
  });
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class LightingScreen extends StatefulWidget {
  const LightingScreen({
    super.key,
    required this.thoughtText,
    required this.perspective,
    this.onClose,
    this.onDeepen,
    this.onHome,
    this.onNewThought,
  });

  final String thoughtText;
  final LightingPerspective perspective;
  final VoidCallback? onClose;
  final VoidCallback? onDeepen;
  final VoidCallback? onHome;
  final VoidCallback? onNewThought;

  @override
  State<LightingScreen> createState() => _LightingScreenState();
}

class _LightingScreenState extends State<LightingScreen>
    with SingleTickerProviderStateMixin {

  // Assets paths
  static const String _bgPath = 'assets/univers_visuel/bg_perception_blue_green.png';
  static const String _grainPath = 'assets/univers_visuel/grain_tile.png';
  static const String _spotSoftPath = 'assets/univers_visuel/light_focus_soft.png';
  static const String _spotStrongPath = 'assets/univers_visuel/light_focus_strong.png';

  // Scroll & Focus
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = [];

  // Spotlight state
  double _spotY = 0;
  double _targetSpotY = 0;
  int _activeIndex = 0;
  bool _useStrongSpot = false;

  // Animation
  late Ticker _ticker;
  bool _isInitialized = false;

  // TTS
  bool _isSpeaking = false;

  // Constants from CDC
  static const double _focusRatio = 0.45; // focusY = screenHeight * 0.45
  static const double _dampingFactor = 0.12; // lerp factor (0.08-0.18)
  static const double _spotSizeRatio = 1.05; // spotSize = screenWidth * 1.05

  @override
  void initState() {
    super.initState();

    // Initialize section keys
    for (int i = 0; i < widget.perspective.sections.length; i++) {
      _sectionKeys.add(GlobalKey());
    }

    // Setup ticker for smooth animation
    _ticker = createTicker(_onTick);
    _ticker.start();

    // Setup scroll listener
    _scrollController.addListener(_onScroll);

    // Precache images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAssets();
      _initializeSpotlight();
    });
  }

  void _precacheAssets() {
    precacheImage(const AssetImage(_bgPath), context);
    precacheImage(const AssetImage(_grainPath), context);
    precacheImage(const AssetImage(_spotSoftPath), context);
    precacheImage(const AssetImage(_spotStrongPath), context);
  }

  void _initializeSpotlight() {
    final screenHeight = MediaQuery.of(context).size.height;
    final focusY = screenHeight * _focusRatio;

    setState(() {
      _spotY = focusY;
      _targetSpotY = focusY;
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  // Ticker callback - smooth lerp animation
  void _onTick(Duration elapsed) {
    if (!_isInitialized) return;

    // Lerp towards target with damping
    final diff = _targetSpotY - _spotY;
    if (diff.abs() > 0.5) {
      setState(() {
        _spotY += diff * _dampingFactor;
      });
    }
  }

  // Scroll listener - calculate active section
  void _onScroll() {
    if (!mounted || _sectionKeys.isEmpty) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final focusY = screenHeight * _focusRatio;

    double closestDistance = double.infinity;
    int closestIndex = 0;
    double closestCenterY = focusY;

    for (int i = 0; i < _sectionKeys.length; i++) {
      final key = _sectionKeys[i];
      final context = key.currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final position = box.localToGlobal(Offset.zero);
      final sectionCenterY = position.dy + box.size.height / 2;

      final distance = (sectionCenterY - focusY).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
        closestCenterY = sectionCenterY;
      }
    }

    // Update target position for spotlight
    final screenWidth = MediaQuery.of(context).size.width;
    final spotSize = screenWidth * _spotSizeRatio;

    setState(() {
      _targetSpotY = closestCenterY - spotSize / 2;

      // Change active index with brief "strong" spotlight
      if (_activeIndex != closestIndex) {
        _activeIndex = closestIndex;
        _flashStrongSpot();
      }
    });
  }

  // Brief flash of strong spotlight when changing section
  void _flashStrongSpot() {
    setState(() => _useStrongSpot = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _useStrongSpot = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final spotSize = screenSize.width * _spotSizeRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ══════════════════════════════════════════════════════════════
          // LAYER A: Background perceptif
          // ══════════════════════════════════════════════════════════════
          Image.asset(
            _bgPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A3A4A), Color(0xFF0D2832), Color(0xFF1A4A5A)],
                ),
              ),
            ),
          ),

          // ══════════════════════════════════════════════════════════════
          // LAYER B: Grain overlay (texture)
          // ══════════════════════════════════════════════════════════════
          Opacity(
            opacity: 0.08,
            child: Image.asset(
              _grainPath,
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              colorBlendMode: BlendMode.softLight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // ══════════════════════════════════════════════════════════════
          // LAYER C: Spotlight (nappe lumineuse) - GLISSE
          // Animation fluide via Transform.translate + ticker lerp
          // ══════════════════════════════════════════════════════════════
          if (_isInitialized)
            IgnorePointer(
              child: RepaintBoundary(
                child: Transform.translate(
                  offset: Offset(-spotSize * 0.025, _spotY),
                  child: SizedBox(
                    width: spotSize,
                    height: spotSize,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Image.asset(
                        _useStrongSpot ? _spotStrongPath : _spotSoftPath,
                        key: ValueKey(_useStrongSpot),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildFallbackSpotlight(spotSize),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ══════════════════════════════════════════════════════════════
          // LAYER D: Scroll content (sections)
          // ══════════════════════════════════════════════════════════════
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),

              // Thought anchor (pensée originale)
              SliverToBoxAdapter(
                child: _buildThoughtAnchor(),
              ),

              // Source header
              SliverToBoxAdapter(
                child: _buildSourceHeader(),
              ),

              // Sections
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= widget.perspective.sections.length) {
                      return null;
                    }
                    return _buildSection(index);
                  },
                  childCount: widget.perspective.sections.length,
                ),
              ),

              // Deepening button
              SliverToBoxAdapter(
                child: _buildDeepeningTrigger(),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),

          // ══════════════════════════════════════════════════════════════
          // LAYER E: UI Controls
          // ══════════════════════════════════════════════════════════════
          _buildTopBar(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  // Fallback spotlight if image fails
  Widget _buildFallbackSpotlight(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFFBF0).withOpacity(0.15),
            const Color(0xFF4A9E8C).withOpacity(0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTENT WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildThoughtAnchor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFF8ECFC0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ta pensée',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.thoughtText,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Source icon
          if (widget.perspective.iconPath != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                widget.perspective.iconPath!,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF8ECFC0),
                  size: 28,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF8ECFC0),
                size: 28,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.perspective.approachName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Éclairage',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(int index) {
    final section = widget.perspective.sections[index];
    final isActive = index == _activeIndex;

    // Opacity based on focus state (CDC: 0.55-0.65 unfocused, 0.92-1.0 focused)
    final textOpacity = isActive ? 0.95 : 0.58;
    final titleOpacity = isActive ? 0.85 : 0.50;

    return Container(
      key: _sectionKeys[index],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        style: GoogleFonts.inter(
          fontSize: 16,
          height: 1.55,
          color: Colors.white.withOpacity(textOpacity),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: titleOpacity,
              child: Row(
                children: [
                  Icon(
                    _getSectionIcon(section.id),
                    size: 14,
                    color: const Color(0xFF8ECFC0),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    section.title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8ECFC0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Section content
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: textOpacity,
              child: widget.perspective.isLoading && section.content.isEmpty
                  ? _buildLoadingPlaceholder()
                  : Text(
                      section.content,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.55,
                        color: Colors.white.withOpacity(textOpacity),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSectionIcon(String sectionId) {
    switch (sectionId.toLowerCase()) {
      case 'motif':
        return Icons.lightbulb_outline;
      case 'personnage':
        return Icons.person_outline;
      case 'contexte':
        return Icons.landscape_outlined;
      case 'perspective':
        return Icons.visibility_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildDeepeningTrigger() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GestureDetector(
        onTap: widget.onDeepen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_red_eye_outlined, // iris icon ◉
                size: 18,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 10),
              Text(
                'Approfondir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI CONTROLS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white70),
              tooltip: 'Fermer',
            ),

            // Right actions
            Row(
              children: [
                // Home button
                IconButton(
                  onPressed: widget.onHome,
                  icon: Image.asset(
                    'assets/univers_visuel/menu principal.png',
                    width: 22,
                    height: 22,
                    color: Colors.white70,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.home_outlined,
                      color: Colors.white70,
                    ),
                  ),
                  tooltip: 'Menu principal',
                ),
                // New thought button
                IconButton(
                  onPressed: widget.onNewThought,
                  icon: Image.asset(
                    'assets/univers_visuel/pensee.png',
                    width: 22,
                    height: 22,
                    color: Colors.white70,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white70,
                    ),
                  ),
                  tooltip: 'Nouvelle pensée',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 20,
          right: 20,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Voice - Full text
            _buildVoiceButton(
              icon: _isSpeaking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: _isSpeaking ? 'Stop' : 'Écouter',
              onTap: _toggleSpeech,
            ),
            const SizedBox(width: 16),
            // Voice - Synthesis
            _buildVoiceButton(
              icon: Icons.auto_awesome,
              label: 'Synthèse',
              onTap: _playSynthesis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TTS METHODS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await TtsService.instance.stop();
      setState(() => _isSpeaking = false);
    } else {
      final fullText = widget.perspective.sections
          .map((s) => '${s.title}. ${s.content}')
          .join('\n\n');

      setState(() => _isSpeaking = true);
      await TtsService.instance.speak(
        fullText,
        approachKey: widget.perspective.approachKey,
      );
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _playSynthesis() async {
    // TODO: Generate synthesis via API and play
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Génération de la synthèse...',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF2E8B7B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// DEEPENING BOTTOM SHEET (CDC: modal plein écran)
// ============================================================================

class DeepeningSheet extends StatelessWidget {
  const DeepeningSheet({
    super.key,
    required this.content,
    required this.sourceName,
  });

  final String content;
  final String sourceName;

  static void show(BuildContext context, {
    required String content,
    required String sourceName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeepeningSheet(
        content: content,
        sourceName: sourceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A3A4A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // Background grain
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Opacity(
                    opacity: 0.06,
                    child: Image.asset(
                      'assets/univers_visuel/grain_tile.png',
                      repeat: ImageRepeat.repeat,
                      color: Colors.white,
                      colorBlendMode: BlendMode.softLight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF8ECFC0),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Approfondissement · $sourceName',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        content,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.white.withOpacity(0.88),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

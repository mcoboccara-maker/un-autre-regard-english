// lib/screens/home_carousel_screen.dart
// CDC §3.1 - Accueil Sources en mode SPINE
// "Tous les regards existent, tu n'en convoques qu'un."

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import '../services/background_music_service.dart';
import '../widgets/carousel_3d/card_carousel_3d.dart';
import '../widgets/brain_gestation_widget.dart';
import 'eclairages_carousel_screen.dart';
import 'perspective_room_screen.dart';

class HomeCarouselScreen extends StatefulWidget {
  const HomeCarouselScreen({super.key});

  @override
  State<HomeCarouselScreen> createState() => _HomeCarouselScreenState();
}

class _HomeCarouselScreenState extends State<HomeCarouselScreen> {
  late List<ApproachConfig> _sources;
  late List<CarouselCardData> _cards;
  final Carousel3DController _carouselController = Carousel3DController();
  final TextEditingController _thoughtController = TextEditingController();
  int _selectedIndex = 0;
  bool _isGenerating = false;
  String? _errorMessage;

  // Pastel version of a source color
  Color _pastelOf(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(0.85).withSaturation(0.3).toColor();
  }

  // Mapping des cles vers les noms de fichiers PNG
  static final Map<String, String> _iconMapping = {
    'judaisme_rabbinique': 'rabbinique',
    'moussar': 'moussar',
    'kabbale': 'kabale',
    'christianisme': 'christianisme',
    'islam': 'islam',
    'soufisme': 'soufisme',
    'theravada': 'theravada',
    'zen': 'zen',
    'advaita_vedanta': 'advaita_vedanta',
    'bhakti': 'bhakti',
    'stoicisme': 'stoicisme',
    'spiritualite_contemporaine': 'contemporaine et laique',
    'humanisme': 'humanisme',
    'romantisme': 'romantisme',
    'realisme': 'realisme',
    'existentialisme': 'existentialisme',
    'absurdisme': 'absurdisme',
    'poetique': 'poetique',
    'mystique': 'mystique',
    'symboliste_moderne': 'symbolisme',
    'act': 'act',
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
    'hannah_arendt': 'arendt',
    'foucault': 'foucault',
    'confucius': 'confucius',
  };

  String _getIconPath(String key) {
    final mappedName = _iconMapping[key] ?? key;
    return 'assets/univers_visuel/$mappedName.png';
  }

  @override
  void initState() {
    super.initState();
    BackgroundMusicService.instance.play('sounds/the_journey_before_dawn.mp3');
    _sources = _buildLimitedSources()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cards = _buildCards();
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    super.dispose();
  }

  /// Sources limitees (sans spirituelles, 6 par type)
  List<ApproachConfig> _buildLimitedSources() {
    final List<ApproachConfig> limited = [];

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

    limited.addAll(psychological);
    limited.addAll(literary);
    limited.addAll(philosophical);
    limited.addAll(philosophers);

    return limited;
  }

  List<CarouselCardData> _buildCards() {
    return _sources.map((source) {
      final pastel = _pastelOf(source.color);
      return CarouselCardData(
        id: source.key,
        backgroundColor: pastel,
        label: source.name,
        child: _buildSourceCard(source, pastel),
      );
    }).toList();
  }

  Widget _buildSourceCard(ApproachConfig source, Color pastel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Icône PNG couvre toute la carte (pas de fond visible)
        Positioned.fill(
          child: Image.asset(
            _getIconPath(source.key),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: pastel,
              child: Icon(source.icon, color: Colors.white, size: 80),
            ),
          ),
        ),
        // Nom en bas
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Text(
              source.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _onCardChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Spin roulette : plusieurs tours complets puis atterrissage aléatoire
  void _spinRandom() {
    final random = Random();
    final targetIndex = random.nextInt(_sources.length);
    // Ajouter 2-3 tours complets avant d'arriver sur la cible
    final extraTurns = (2 + random.nextInt(2)) * _sources.length;
    _carouselController.spinToIndex(targetIndex, extraCards: extraTurns);
  }

  /// Generate eclairage for selected source
  Future<void> _generateResponse() async {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your thought before generating.';
      });
      return;
    }

    final source = _sources[_selectedIndex];

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final response =
          await AIService.instance.generateApproachSpecificResponse(
        approach: source.key,
        reflectionText: text,
        reflectionType: ReflectionType.thought,
        emotionalState: EmotionalState.empty(),
        userProfile: null,
        intensiteEmotionnelle: 5,
      );

      if (mounted) {
        final meta = AIService.instance.lastFigureMeta;
        final perspective = PerspectiveData(
          approachKey: source.key,
          approachName: source.name,
          responseText: response,
          figureName: meta?['nom'],
          figureReference: meta?['reference'],
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EclairagesCarouselScreen(
              thoughtText: text,
              perspectives: [perspective],
              readOnly: true,
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ── Mobile : carrousel plein écran ─────────────────────────────────────────

  Widget _buildMobileLayout() {
    final selectedSource =
        _selectedIndex < _sources.length ? _sources[_selectedIndex] : null;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          CardCarousel3D(
            cards: _cards,
            mode: CarouselMode.spine,
            angleSpacing: 15,
            cardHeight: 260,
            cardWidth: 240,
            onCardChanged: _onCardChanged,
            controller: _carouselController,
            verticalOffset: -20,
          ),
          _buildTitleOverlay(),
          _buildBottomSection(selectedSource),
        ],
      ),
    );
  }

  // ── Desktop : carrousel (gauche) + panneau connexion (droite) ──────────────

  Widget _buildDesktopLayout() {
    final selectedSource =
        _selectedIndex < _sources.length ? _sources[_selectedIndex] : null;

    return Stack(
      children: [
        CardCarousel3D(
          cards: _cards,
          mode: CarouselMode.spine,
          angleSpacing: 15,
          cardHeight: 300,
          cardWidth: 280,
          onCardChanged: _onCardChanged,
          controller: _carouselController,
          verticalOffset: -40,
        ),
        _buildTitleOverlay(),
        _buildBottomSection(selectedSource),
      ],
    );
  }

  Widget _buildTitleOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Titre centré avec logo à côté + sous-titre
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icon/app_icon.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Un Autre Regard',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Every perspective exists, you only summon one.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          // Icône connexion en haut à droite
          Positioned(
            right: 12,
            top: 0,
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
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
              tooltip: 'Sign In',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ApproachConfig? selectedSource) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton vert spin
            Center(
              child: _ArcadeButton(
                imagePath: 'assets/univers_visuel/boutons_vert.webp',
                legend: 'Spin the wheel',
                onPressed: _spinRandom,
                size: 56,
              ),
            ),
            const SizedBox(height: 8),

            if (selectedSource != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  selectedSource.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Enter a thought and submit it to this source',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _thoughtController,
                maxLines: 2,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_isGenerating)
              _buildGeneratingIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      selectedSource != null ? _generateResponse : null,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    'Generate an insight',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    disabledBackgroundColor:
                        const Color(0xFF2E8B7B).withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white60,
                  ),
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red[300]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Center(
        child: BrainGestationWidget(
          isComplete: false,
          size: 120,
        ),
      ),
    );
  }

}

/// Widget bouton arcade générique avec animation d'appui et légende
class _ArcadeButton extends StatefulWidget {
  final String imagePath;
  final String? overlayIconPath;
  final String legend;
  final VoidCallback onPressed;
  final double size;

  const _ArcadeButton({
    required this.imagePath,
    this.overlayIconPath,
    required this.legend,
    required this.onPressed,
    this.size = 64,
  });

  @override
  State<_ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<_ArcadeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Column(
          children: [
            // Bouton rond avec image (+ overlay icône optionnel)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.35),
                    blurRadius: _isPressed ? 4 : 12,
                    spreadRadius: _isPressed ? 0 : 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base : image du bouton (bouton vert arcade)
                  ClipOval(
                    child: Image.asset(
                      widget.imagePath,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Overlay : icône par-dessus le bouton (remplit le bouton)
                  if (widget.overlayIconPath != null)
                    ClipOval(
                      child: Image.asset(
                        widget.overlayIconPath!,
                        width: widget.size * 0.88,
                        height: widget.size * 0.88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Légende
            SizedBox(
              width: 90,
              child: Text(
                widget.legend,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

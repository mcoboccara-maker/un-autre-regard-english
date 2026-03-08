// lib/screens/introduction_screen.dart
// Écran d'introduction — premier écran au lancement
// Logo centré, proposition de valeur dévoilée pas-à-pas (bouton Continue),
// musique ambient d'introspection en fond.
// "Expérimente" → HomeCarouselScreen, "Se connecter" → /login

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/background_music_service.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with TickerProviderStateMixin {
  // ── Couleurs ───────────────────────────────────────────────────────────────
  static const _textPrimary = Color(0xFFEAF2F7);
  static const _textSecondary = Color(0xFFB9C7D6);
  static const _accentGreen = Color(0xFF2BBFA6);
  static const _bgCenter = Color(0xFF102A43);
  static const _bgEdge = Color(0xFF0B1C2D);

  // ── Textes — proposition de valeur ───────────────────────────────────────
  static const _phrases = [
    "There is something that puzzles you, that feels wrong, that keeps repeating and overwhelms you.",
    "The difficulty is not always the situation itself.",
    "Sometimes, it is the way you look at it that makes it painful and confining.",
    "I invite you to consider the possibility of another perspective.",
    "How? By questioning sources that have shed light on these thoughts, situations, dilemmas and existential questions that are universal.",
    "To find perspectives, sources of inspiration and inner peace.",
  ];

  // Segments avec mise en couleur verte pour la phrase 5 (index 4)
  // "are universal" sera coloré en vert
  static const _greenSegment = "are universal";

  static const _modeEmploi = [
    "Try it right away: a random source, a thought, an insight.",
    "Sign in or stay in guest mode to choose your sources.",
    "Let yourself be guided by a quiz or a wheel of fortune.",
    "Fill in your profile for more tailored insights.",
    "Name the emotions of the day or those linked to a thought.",
    "Receive insights: read, listen, explore further, save.",
    "Revisit your journey: history of insights and emotions.",
  ];

  // ── État d'avancement des phrases ────────────────────────────────────────
  // La 1ère phrase (index 0) s'affiche automatiquement.
  // Les suivantes apparaissent au tap sur "Continuer".
  int _visiblePhraseCount = 1;
  bool _showModeEmploi = false;
  bool _showClosing = false;

  // ── Animations individuelles ─────────────────────────────────────────────
  final List<AnimationController> _phraseControllers = [];
  final List<Animation<double>> _phraseFades = [];
  final List<Animation<double>> _phraseSlides = [];

  AnimationController? _modeEmploiController;
  final List<Animation<double>> _modeEmploiFades = [];
  final List<Animation<double>> _modeEmploiSlides = [];

  AnimationController? _closingController;
  late Animation<double> _closingFade;
  late Animation<double> _closingSlide;

  // ── Logo ─────────────────────────────────────────────────────────────────
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // ── Musique ambient ──────────────────────────────────────────────────────
  bool _musicStarted = false;

  // ── ScrollController pour auto-scroll ────────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // --- Logo : fade-in + scale de 0.8→1.0 sur 1.5s ---
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // --- Prépare les controllers pour chaque phrase ---
    for (int i = 0; i < _phrases.length; i++) {
      final ctrl = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _phraseControllers.add(ctrl);
      _phraseFades.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _phraseSlides.add(
        Tween<double>(begin: 24.0, end: 0.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
        ),
      );
    }

    // --- Mode d'emploi (toutes les lignes en stagger, rythme lent) ---
    _modeEmploiController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    for (int i = 0; i < _modeEmploi.length + 1; i++) {
      // +1 pour le titre "Comment ça marche"
      final start = i / (_modeEmploi.length + 1);
      final end = (i + 1) / (_modeEmploi.length + 1);
      _modeEmploiFades.add(CurvedAnimation(
        parent: _modeEmploiController!,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
      _modeEmploiSlides.add(
        Tween<double>(begin: 20.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _modeEmploiController!,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // --- Closing ---
    _closingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _closingFade = CurvedAnimation(
      parent: _closingController!,
      curve: Curves.easeOut,
    );
    _closingSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _closingController!, curve: Curves.easeOut),
    );

    // Lancer : logo d'abord, puis 1ère phrase après un délai
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _phraseControllers[0].forward();
    });

    // Musique ambient — lancée au premier tap utilisateur (autoplay bloqué par navigateur)
  }

  void _playBackgroundMusic() {
    BackgroundMusicService.instance.play('sounds/universfield-silent-universe-351473.mp3');
  }

  // ── Bouton Continuer : dévoile la phrase suivante ────────────────────────
  void _onContinue() {
    // Lancer la musique au premier tap (contourne la restriction navigateur)
    if (!_musicStarted) {
      _musicStarted = true;
      _playBackgroundMusic();
    }

    if (_visiblePhraseCount < _phrases.length) {
      // Dévoiler la phrase suivante
      setState(() => _visiblePhraseCount++);
      _phraseControllers[_visiblePhraseCount - 1].forward();
      _scrollToBottom();
    } else if (!_showModeEmploi) {
      // Afficher le mode d'emploi
      setState(() => _showModeEmploi = true);
      _modeEmploiController!.forward();
      _scrollToBottom();
    } else if (!_showClosing) {
      // Afficher la phrase de clôture
      setState(() => _showClosing = true);
      _closingController!.forward();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _allRevealed => _showClosing;

  @override
  void dispose() {
    _logoController.dispose();
    for (final c in _phraseControllers) {
      c.dispose();
    }
    _modeEmploiController?.dispose();
    _closingController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgEdge,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [_bgCenter, _bgEdge],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Contenu scrollable
              _buildContent(),
              // Boutons flottants (bas)
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contenu principal (responsive) ───────────────────────────────────────

  Widget _buildContent() {
    final isWide = MediaQuery.of(context).size.width > 700;
    return isWide ? _buildDesktop() : _buildMobile();
  }

  // ── Mobile ───────────────────────────────────────────────────────────────

  Widget _buildMobile() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 160),
      child: Column(
        children: [
          // Logo centré
          _buildLogo(),
          const SizedBox(height: 40),
          // Phrases dévoilées
          ..._buildPhrases(),
          if (_showModeEmploi) ...[
            const SizedBox(height: 28),
            ..._buildModeEmploi(),
          ],
          if (_showClosing) ...[
            const SizedBox(height: 28),
            _buildClosingPhrase(),
          ],
        ],
      ),
    );
  }

  // ── Desktop ──────────────────────────────────────────────────────────────

  Widget _buildDesktop() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 160),
      child: Column(
        children: [
          // Logo centré, proéminent
          _buildLogo(),
          const SizedBox(height: 24),
          // 2 colonnes : phrases + mode d'emploi
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche : proposition de valeur
                Expanded(
                  flex: 55,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildPhrases(),
                    ),
                  ),
                ),
                // Colonne droite : mode d'emploi
                if (_showModeEmploi)
                  Expanded(
                    flex: 45,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 40, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: _buildModeEmploi(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Phrase de clôture — centrée sur toute la largeur
          if (_showClosing) ...[
            const SizedBox(height: 32),
            _buildClosingPhrase(),
          ],
        ],
      ),
    );
  }

  // ── Logo centré au milieu ────────────────────────────────────────────────

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoFade.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Halo lumineux derrière le logo
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accentGreen.withValues(alpha: 0.12),
                  _accentGreen.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 100,
                height: 100,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Another Perspective',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A space for introspection & inspiration',
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Phrases de la proposition de valeur ───────────────────────────────────

  List<Widget> _buildPhrases() {
    return List.generate(_visiblePhraseCount, (i) {
      final isAccent = i == 3; // "I invite you..." tout en vert
      final hasGreenSegment = i == 4; // "are universal" en vert
      return AnimatedBuilder(
        animation: _phraseControllers[i],
        builder: (context, child) {
          return Opacity(
            opacity: _phraseFades[i].value,
            child: Transform.translate(
              offset: Offset(0, _phraseSlides[i].value),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: hasGreenSegment
              ? _buildRichPhrase(_phrases[i], _greenSegment)
              : Text(
                  _phrases[i],
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isAccent ? 22 : 18,
                    fontWeight: isAccent ? FontWeight.bold : FontWeight.w500,
                    color: isAccent ? _accentGreen : _textPrimary,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      );
    });
  }

  /// Construit une phrase avec un segment coloré en vert
  Widget _buildRichPhrase(String fullText, String greenPart) {
    final idx = fullText.indexOf(greenPart);
    if (idx < 0) {
      return Text(
        fullText,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 18, fontWeight: FontWeight.w500,
          color: _textPrimary, height: 1.55,
        ),
        textAlign: TextAlign.center,
      );
    }
    final before = fullText.substring(0, idx);
    final after = fullText.substring(idx + greenPart.length);
    final baseStyle = GoogleFonts.cormorantGaramond(
      fontSize: 18, fontWeight: FontWeight.w500,
      color: _textPrimary, height: 1.55,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: greenPart,
            style: baseStyle.copyWith(
              color: _accentGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  // ── Mode d'emploi ────────────────────────────────────────────────────────

  List<Widget> _buildModeEmploi() {
    return [
      // Titre
      AnimatedBuilder(
        animation: _modeEmploiController!,
        builder: (context, child) {
          return Opacity(
            opacity: _modeEmploiFades[0].value,
            child: Transform.translate(
              offset: Offset(0, _modeEmploiSlides[0].value),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            'How it works',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _accentGreen,
            ),
          ),
        ),
      ),
      // Items
      ...List.generate(_modeEmploi.length, (i) {
        return AnimatedBuilder(
          animation: _modeEmploiController!,
          builder: (context, child) {
            return Opacity(
              opacity: _modeEmploiFades[i + 1].value,
              child: Transform.translate(
                offset: Offset(0, _modeEmploiSlides[i + 1].value),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _modeEmploi[i],
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: _textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  // ── Phrase de clôture ────────────────────────────────────────────────────

  Widget _buildClosingPhrase() {
    return Center(
      child: AnimatedBuilder(
        animation: _closingController!,
        builder: (context, child) {
          return Opacity(
            opacity: _closingFade.value,
            child: Transform.translate(
              offset: Offset(0, _closingSlide.value),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'What you experience is universal.\nWhat you choose to see in it is yours.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: _textPrimary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ── Barre du bas : Continuer / Expérimente / Se connecter ────────────────

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // Dégradé pour lisibilité sur le contenu scrollé
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _bgEdge.withValues(alpha: 0.0),
              _bgEdge.withValues(alpha: 0.85),
              _bgEdge,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Bouton Continuer (tant que tout n'est pas dévoilé) ──
            if (!_allRevealed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 220,
                  child: OutlinedButton.icon(
                    onPressed: _onContinue,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: Text(
                      'Continue',
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentGreen,
                      side: BorderSide(
                        color: _accentGreen.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            // ── Boutons d'action ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home-carousel');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                    textStyle: GoogleFonts.raleway(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Try it'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'Sign in',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

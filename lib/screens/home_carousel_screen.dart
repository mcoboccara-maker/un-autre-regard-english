// lib/screens/home_carousel_screen.dart
// CDC §3.1 - Accueil Sources en mode SPINE
// "Tous les regards existent, tu n'en convoques qu'un."

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/complete_auth_service.dart';
import '../services/email_service.dart';
import '../widgets/carousel_3d/card_carousel_3d.dart';
import 'eclairages_carousel_screen.dart';
import 'perspective_room_screen.dart';

class HomeCarouselScreen extends StatefulWidget {
  const HomeCarouselScreen({super.key});

  @override
  State<HomeCarouselScreen> createState() => _HomeCarouselScreenState();
}

class _HomeCarouselScreenState extends State<HomeCarouselScreen>
    with SingleTickerProviderStateMixin {
  late List<ApproachConfig> _sources;
  late List<CarouselCardData> _cards;
  final Carousel3DController _carouselController = Carousel3DController();
  final TextEditingController _thoughtController = TextEditingController();
  int _selectedIndex = 0;
  bool _isGenerating = false;
  String? _errorMessage;

  late AnimationController _hourglassController;

  // ── Auth state (panneau connexion desktop) ─────────────────────────────────
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _authFormKey = GlobalKey<FormState>();
  bool _authLoading = false;
  bool _authGuestLoading = false;
  bool _obscurePassword = true;
  bool _isNewUser = true;
  bool _showAuthForm = false;
  static const String _guestEmail = 'invite@unautreregard.app';
  static const String _guestPassword = 'invite';

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
    'bouddhisme': 'boudhisme',
    'hindouisme': 'hindouisme',
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
    _sources = _buildLimitedSources()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cards = _buildCards();
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    _hourglassController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
        _errorMessage = 'Saisis ta pensee avant de generer.';
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
        setState(() {
          _isGenerating = false;
        });

        final perspective = PerspectiveData(
          approachKey: source.key,
          approachName: source.name,
          responseText: response,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EclairagesCarouselScreen(
              thoughtText: text,
              perspectives: [perspective],
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      backgroundColor: const Color(0xFF8B7FC7),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ── Mobile : carrousel plein écran ─────────────────────────────────────────

  Widget _buildMobileLayout() {
    final selectedSource =
        _selectedIndex < _sources.length ? _sources[_selectedIndex] : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Carousel en haut
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
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
                  verticalOffset: -60,
                ),
                _buildTitleOverlay(),
                _buildBottomSection(selectedSource),
              ],
            ),
          ),
          // Auth panel en dessous
          _buildAuthPanel(),
        ],
      ),
    );
  }

  // ── Desktop : carrousel (gauche) + panneau connexion (droite) ──────────────

  Widget _buildDesktopLayout() {
    final selectedSource =
        _selectedIndex < _sources.length ? _sources[_selectedIndex] : null;

    return Row(
      children: [
        // Carrousel (65%)
        Expanded(
          flex: 65,
          child: Stack(
            children: [
              CardCarousel3D(
                cards: _cards,
                mode: CarouselMode.spine,
                angleSpacing: 15,
                cardHeight: 300,
                cardWidth: 280,
                onCardChanged: _onCardChanged,
                controller: _carouselController,
                verticalOffset: -80,
              ),
              _buildTitleOverlay(),
              _buildBottomSection(selectedSource),
            ],
          ),
        ),
        // Panneau connexion (35%)
        Expanded(
          flex: 35,
          child: _buildAuthPanel(fillHeight: true),
        ),
      ],
    );
  }

  Widget _buildTitleOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Column(
        children: [
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
          const SizedBox(height: 2),
          Text(
            'Tous les regards existent, tu n\'en convoques qu\'un.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF7B6FB7).withValues(alpha: 0.7),
              const Color(0xFF7B6FB7).withValues(alpha: 0.95),
              const Color(0xFF7B6FB7),
            ],
            stops: const [0.0, 0.2, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton vert spin
            Center(
              child: _ArcadeButton(
                imagePath: 'assets/univers_visuel/boutons_vert.webp',
                legend: 'Fais tourner',
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
                'Saisis une pensée et soumets-la à cette source',
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
                  hintText: 'Qu\'est-ce qui te traverse l\'esprit ?',
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
                    'Générer un éclairage',
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PANNEAU CONNEXION (desktop, colonne droite)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Couleurs du thème auth (violet, comme login_screen) ─────────────────
  static const _authViolet = Color(0xFF8B7FC7);
  static const _authVioletLight = Color(0xFFA89ED8);
  static const _authTeal = Color(0xFF2E8B7B);
  static const _authCream = Color(0xFFFFFBF8);
  static const _authFieldBg = Color(0xFFF5F9F8);

  Widget _buildAuthPanel({bool fillHeight = false}) {
    return Container(
      height: fillHeight ? double.infinity : null,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_authViolet, _authVioletLight],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _authFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Icône cerveau
                Image.asset(
                  'assets/univers_visuel/brain_loading.png',
                  width: 72,
                  height: 72,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.visibility, size: 48, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choisis comment commencer',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ── Carte Mode Invité ──
                _buildGuestCard(),
                const SizedBox(height: 16),

                // ── Séparateur ──
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: GoogleFonts.raleway(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Cartes Inscription / Connexion ──
                Row(
                  children: [
                    Expanded(child: _buildAuthCard('Inscription', 'Créer un\ncompte', 'assets/univers_visuel/inscription.png', true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAuthCard('Connexion', 'Se\nconnecter', 'assets/univers_visuel/connexion.png', false)),
                  ],
                ),

                // ── Formulaire email/password ──
                if (_showAuthForm) ...[
                  const SizedBox(height: 16),
                  _buildAuthFormFields(),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Carte Mode Invité (style login_screen)
  Widget _buildGuestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _authCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/univers_visuel/invite.png',
                  width: 48, height: 48,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: _authTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_outline, color: _authTeal, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode Invité', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _authTeal)),
                    Text('Essaie l\'application librement', style: GoogleFonts.inter(fontSize: 12, color: _authTeal.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rappel
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE6D5A8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFB8960C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Accès à toutes les fonctionnalités mais pas de sauvegarde de ton historique.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8B7355), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _authGuestLoading ? null : _loginAsGuest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _authTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _authGuestLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Entrer en tant qu\'invité', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte Inscription / Connexion (style login_screen)
  Widget _buildAuthCard(String label, String displayText, String iconPath, bool isNew) {
    final selected = _showAuthForm && _isNewUser == isNew;
    return GestureDetector(
      onTap: () => setState(() {
        _isNewUser = isNew;
        _showAuthForm = true;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _authTeal : _authCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _authTeal : Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                iconPath,
                width: 40, height: 40,
                errorBuilder: (_, __, ___) => Icon(
                  isNew ? Icons.person_add_outlined : Icons.login,
                  size: 32, color: selected ? Colors.white : _authTeal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1A3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthFormFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _authCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Email avec icône
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/univers_visuel/mail.png',
                  width: 40, height: 40,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _authFieldBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.email_outlined, color: _authTeal, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A3A3A)),
                  decoration: _authInputDecoration('votre.email@exemple.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) return 'Email invalide';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Password avec icône
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/univers_visuel/password.png',
                  width: 40, height: 40,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _authFieldBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_outlined, color: _authTeal, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A3A3A)),
                  decoration: _authInputDecoration(
                    _isNewUser ? 'Créez un mot de passe sécurisé' : 'Votre mot de passe',
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF5A8A8A), size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (_isNewUser && v.length < 6) return 'Min 6 caractères';
                    return null;
                  },
                ),
              ),
            ],
          ),
          // Mot de passe oublié (mode connexion uniquement)
          if (!_isNewUser) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleForgotPassword,
                child: Text(
                  'Mot de passe oublié ?',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: _authTeal,
                    decoration: TextDecoration.underline,
                    decorationColor: _authTeal,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _authLoading ? null : _handleAuthAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _authTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _authLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isNewUser ? 'Créer mon compte' : 'Se connecter',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _authInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF5A8A8A).withValues(alpha: 0.5), fontSize: 13),
      filled: true,
      fillColor: _authFieldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _authTeal, width: 2),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  /// Forgot password (copié du login_screen)
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Veuillez d\'abord saisir votre adresse email', style: GoogleFonts.inter())),
          ]),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.lock_reset, color: _authTeal),
          const SizedBox(width: 12),
          Text('Mot de passe oublié', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ]),
        content: Text(
          'Un nouveau mot de passe temporaire sera envoyé à :\n\n$email\n\nVoulez-vous continuer ?',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _authTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Envoyer', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: _authTeal)),
    );

    try {
      final tempPassword = await CompleteAuthService.instance.resetPassword(email);
      if (tempPassword == null) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucun compte trouvé avec cet email', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await EmailService.instance.sendPasswordReset(toEmail: email, tempPassword: tempPassword);
      if (!mounted) return;
      Navigator.pop(context);

      if (result.success) {
        await _showSetNewPasswordDialog(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.message}', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// Dialogue nouveau mot de passe
  Future<void> _showSetNewPasswordDialog(String email) async {
    final tempPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.lock_reset, color: _authTeal),
            const SizedBox(width: 12),
            Expanded(child: Text('Définir un nouveau mot de passe', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16))),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Un mot de passe temporaire a été envoyé à $email', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 20),
                Text('Mot de passe temporaire', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: tempPwdCtrl,
                  decoration: InputDecoration(
                    hintText: 'Entrez le mot de passe reçu par email',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nouveau mot de passe', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: newPwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Choisissez votre nouveau mot de passe',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMsg!, style: GoogleFonts.inter(fontSize: 12, color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final t = tempPwdCtrl.text.trim();
                final n = newPwdCtrl.text.trim();
                if (t.isEmpty || n.isEmpty) { setDialogState(() => errorMsg = 'Veuillez remplir les deux champs'); return; }
                if (n.length < 4) { setDialogState(() => errorMsg = 'Au moins 4 caractères'); return; }
                setDialogState(() { isLoading = true; errorMsg = null; });
                final ok = await CompleteAuthService.instance.verifyTempAndSetNewPassword(email, t, n);
                if (ok) {
                  Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Mot de passe modifié avec succès !', style: GoogleFonts.inter()), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
                    );
                  }
                } else {
                  setDialogState(() { isLoading = false; errorMsg = 'Mot de passe temporaire incorrect'; });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _authTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Valider', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auth actions ───────────────────────────────────────────────────────────

  Future<void> _loginAsGuest() async {
    setState(() => _authGuestLoading = true);
    try {
      final users = await CompleteAuthService.instance.getAllUsers();
      if (!users.contains(_guestEmail)) {
        await CompleteAuthService.instance.register(_guestEmail, _guestPassword);
      }
      final success = await CompleteAuthService.instance.login(_guestEmail, _guestPassword);
      if (success && mounted) {
        // Effacer historique invité
        final reflections = await CompleteAuthService.instance.getAllReflections();
        for (var r in reflections) {
          if (r['id'] != null) await CompleteAuthService.instance.deleteReflection(r['id']);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenue en mode invité !', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.pushReplacementNamed(context, '/menu');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _authGuestLoading = false);
    }
  }

  Future<void> _handleAuthAction() async {
    if (!_authFormKey.currentState!.validate()) return;
    setState(() => _authLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      bool success;

      if (_isNewUser) {
        success = await CompleteAuthService.instance.register(email, password);
        if (success) {
          final profile = UserProfile.empty().copyWith(email: email, lastUpdated: DateTime.now());
          await CompleteAuthService.instance.saveProfile(profile.toJson());
        }
      } else {
        success = await CompleteAuthService.instance.login(email, password);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNewUser ? 'Compte créé !' : 'Connexion réussie !', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pushReplacementNamed(context, '/menu');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNewUser ? 'Email déjà utilisé' : 'Email ou mot de passe incorrect',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Widget _buildGeneratingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: RotationTransition(
              turns: _hourglassController,
              child: Image.asset(
                'assets/univers_visuel/generationiaencours.png',
                width: 36,
                height: 36,
                color: Colors.white.withValues(alpha: 0.8),
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Generation en cours...',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
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

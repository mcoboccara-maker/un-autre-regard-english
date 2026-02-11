// lib/screens/menu_carousel_screen.dart
// Menu principal — 4 cartes empilées scrollables sur fond pastel clair

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../services/complete_auth_service.dart';
import '../services/ai_service.dart';
import 'emotion_wheel_screen.dart';
import 'thought_input_screen.dart';

class MenuCarouselScreen extends StatefulWidget {
  final ApproachConfig? preselectedSource;

  const MenuCarouselScreen({super.key, this.preselectedSource});

  @override
  State<MenuCarouselScreen> createState() => _MenuCarouselScreenState();
}

class _MenuCarouselScreenState extends State<MenuCarouselScreen>
    with TickerProviderStateMixin {
  // ── 4 cartes ─────────────────────────────────────────────────────────────
  static const List<_MenuItem> _menuItems = [
    _MenuItem(
      id: 'exprime',
      label: 'Exprime ce qui te traverse',
      imagePath: 'assets/univers_visuel/penseejour.png',
      subtitle: 'Pensée, situation, question, dilemme',
    ),
    _MenuItem(
      id: 'ressens',
      label: 'Partage ce que tu ressens',
      imagePath: 'assets/univers_visuel/emotionsdujour.png',
      subtitle: 'Nomme tes émotions',
    ),
    _MenuItem(
      id: 'sources',
      label: 'Explore des sources',
      imagePath: 'assets/univers_visuel/ressources.png',
      subtitle: '~65 regards, quiz, roue du hasard',
    ),
    _MenuItem(
      id: 'regards',
      label: 'Mes regards',
      imagePath: 'assets/univers_visuel/historique_des_pensees.png',
      subtitle: 'Historique vivant des éclairages',
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  late List<AnimationController> _entryControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    // Animations d'apparition progressive
    _entryControllers = List.generate(
      _menuItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _fadeAnimations = _entryControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .map((a) => Tween<double>(begin: 0.0, end: 1.0).animate(a))
        .toList();

    _slideAnimations = _entryControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((a) =>
            Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(a))
        .toList();

    // Écouter le scroll pour le parallaxe
    _scrollController.addListener(() {
      if (mounted) setState(() {});
    });

    // Lancer les animations en séquence
    _startEntryAnimations();

    if (widget.preselectedSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPreselectedPrompt();
      });
    }
  }

  Future<void> _startEntryAnimations() async {
    for (int i = 0; i < _entryControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) _entryControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _entryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Tap sur une carte ─────────────────────────────────────────────────────
  void _onMenuTap(String id) {
    switch (id) {
      case 'exprime':
        _showExprimeSheet();
        break;
      case 'ressens':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmotionWheelScreen(
              preselectedSource: widget.preselectedSource,
            ),
          ),
        );
        break;
      case 'sources':
        Navigator.pushNamed(context, '/sources-explorer');
        break;
      case 'regards':
        Navigator.pushNamed(context, '/history');
        break;
    }
  }

  // ── Bottom sheet "Exprime" avec 2 actions ─────────────────────────────────
  void _showExprimeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF102A43),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/univers_visuel/penseejour.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Exprime ce qui te traverse',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Pensée, situation, question ou dilemme',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToThought();
                },
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(
                  'Regarde autrement',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B7B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToEmotionsThenThought();
                },
                icon: const Icon(Icons.favorite_rounded, size: 20),
                label: Text(
                  'Saisis tes émotions liées\net regarde autrement',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToThought() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThoughtInputScreen(
          preselectedSource: widget.preselectedSource,
        ),
      ),
    );
  }

  void _navigateToEmotionsThenThought() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmotionWheelScreen(
          preselectedSource: widget.preselectedSource,
        ),
      ),
    );
  }

  // ── Source pré-sélectionnée ────────────────────────────────────────────────
  void _showPreselectedPrompt() {
    final source = widget.preselectedSource!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF102A43),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(source.icon, color: source.color, size: 40),
            const SizedBox(height: 12),
            Text(
              source.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              source.credo,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToThought();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: source.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Partager une pensée',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS HAUT-DROITE (Profil, Pensée positive, Déconnexion)
  // ═══════════════════════════════════════════════════════════════════════════

  void _goToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _showPositiveThought() {
    final thoughts = [
      "Chaque jour est une nouvelle opportunité de grandir.",
      "Tu as déjà surmonté tant d'obstacles. Tu es plus fort(e) que tu ne le penses.",
      "Prends le temps de respirer. Ce moment difficile passera.",
      "Tu mérites d'être heureux(se) et en paix.",
      "Tes émotions sont valides. Accueille-les avec bienveillance.",
      "Un petit pas aujourd'hui peut mener à un grand changement demain.",
      "Tu n'as pas besoin d'être parfait(e), juste authentique.",
      "La tempête finit toujours par se calmer. Tiens bon.",
      "Tu es exactement là où tu dois être en ce moment.",
      "Chaque émotion est un message. Écoute ce qu'elle a à te dire.",
    ];
    final random = DateTime.now().millisecondsSinceEpoch % thoughts.length;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.lightbulb,
                  color: Color(0xFFFBBF24),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pensée du moment',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                thoughts[random],
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF78350F),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF78350F),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Merci !',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset(
              'assets/univers_visuel/deconnexion.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.logout,
                  color: Color(0xFFE57373), size: 28),
            ),
            const SizedBox(width: 12),
            Text('Déconnexion',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Es-tu sûr(e) de vouloir te déconnecter ?',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              AIService.instance.clearUserData();
              await CompleteAuthService.instance.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/welcome', (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Déconnecter',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FD), // bleu pâle
              Color(0xFFFFF8E7), // jaune pâle
              Color(0xFFE8F8E8), // vert pâle
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Barre du haut ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Un Autre Regard',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2E5A),
                      ),
                    ),
                    const Spacer(),
                    _buildTopBarIcon(
                      assetPath: 'assets/univers_visuel/profil.png',
                      fallbackIcon: Icons.person_rounded,
                      tooltip: 'Mon profil',
                      onTap: _goToProfile,
                    ),
                    _buildTopBarIcon(
                      assetPath: 'assets/univers_visuel/pensee_positive.png',
                      fallbackIcon: Icons.lightbulb_outline,
                      tooltip: 'Pensée positive',
                      onTap: _showPositiveThought,
                    ),
                    _buildTopBarIcon(
                      assetPath: 'assets/univers_visuel/deconnexion.png',
                      fallbackIcon: Icons.logout,
                      tooltip: 'Déconnexion',
                      onTap: _showLogoutConfirmation,
                    ),
                  ],
                ),
              ),

              // ── 4 cartes empilées ──────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    return _buildCard(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final item = _menuItems[index];

    // Calcul parallaxe
    double parallaxOffset = 0;
    if (_scrollController.hasClients) {
      final scrollOffset = _scrollController.offset;
      // Chaque carte a ~200px de hauteur totale (180 + marges)
      final cardTop = index * 200.0;
      parallaxOffset = (scrollOffset - cardTop) * 0.3;
    }

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: GestureDetector(
          onTap: () => _onMenuTap(item.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image avec parallaxe
                  Transform.translate(
                    offset: Offset(0, parallaxOffset.clamp(-30, 30)),
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.cover,
                      // Agrandir légèrement pour le parallaxe
                      height: 240,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: Icon(Icons.image,
                            color: Colors.grey[400], size: 60),
                      ),
                    ),
                  ),

                  // Gradient overlay en bas
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Texte
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarIcon({
    required String assetPath,
    required IconData fallbackIcon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Image.asset(
        assetPath,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          color: const Color(0xFF1A2E5A).withValues(alpha: 0.7),
          size: 24,
        ),
      ),
    );
  }
}

// ── Modèle ──────────────────────────────────────────────────────────────────
class _MenuItem {
  final String id;
  final String label;
  final String imagePath;
  final String subtitle;

  const _MenuItem({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.subtitle,
  });
}

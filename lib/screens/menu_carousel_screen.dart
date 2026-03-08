// lib/screens/menu_carousel_screen.dart
// Menu principal — 4 cartes animées en grille 2×2 sur fond pastel clair

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../services/background_music_service.dart';
import '../services/complete_auth_service.dart';
import '../services/ai_service.dart';
import '../services/persistent_storage_service.dart';
import '../services/emotional_tracking_service.dart';
import '../widgets/animated_menu_cards.dart';
import '../widgets/nav_cartouche.dart';
import 'emotion_wheel_screen.dart';
import 'thought_input_screen.dart';

class MenuCarouselScreen extends StatefulWidget {
  final ApproachConfig? preselectedSource;

  const MenuCarouselScreen({super.key, this.preselectedSource});

  @override
  State<MenuCarouselScreen> createState() => _MenuCarouselScreenState();
}

class _MenuCarouselScreenState extends State<MenuCarouselScreen> {
  @override
  void initState() {
    super.initState();
    // Musique gérée par BackgroundMusicService (NavigatorObserver)
    BackgroundMusicService.instance.play('sounds/the_journey_before_dawn.mp3');

    if (widget.preselectedSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPreselectedPrompt();
      });
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _navigateToExprime() {
    // Navigation directe vers saisie (pas de bottom sheet intermédiaire)
    _navigateToThought();
  }

  void _navigateToRessens() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/emotions'),
        builder: (_) => EmotionWheelScreen(
          preselectedSource: widget.preselectedSource,
        ),
      ),
    );
  }

  void _navigateToCheminParcouru() {
    Navigator.pushNamed(context, '/history');
  }

  void _navigateToSources() {
    Navigator.pushNamed(context, '/sources-explorer');
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
                'assets/univers_visuel/exprime_ce_qui_te_traverse.png',
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
              'Express What Moves You',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'A thought, situation, question or dilemma',
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
                  'See it differently',
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
                icon: Image.asset(
                  'assets/univers_visuel/coeur.png',
                  width: 22, height: 22,
                  errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, size: 20),
                ),
                label: Text(
                  'Enter your related emotions\nand see it differently',
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
        settings: const RouteSettings(name: '/emotions'),
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
                  'Share a thought',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PositiveThoughtDialog(),
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
            Text('Log out',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
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
            child: Text('Log out',
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
      backgroundColor: const Color(0xFF0A1628), // Bleu nuit
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A), // Bleu nuit profond
              Color(0xFF1B2838), // Bleu nuit moyen
              Color(0xFF0A1628), // Bleu nuit sombre
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Barre du haut ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icon/app_icon.png',
                      width: 32, height: 32,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Another Look',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/profil.png',
                      fallbackIcon: Icons.person_rounded,
                      tooltip: 'My profile',
                      onTap: _goToProfile,
                    ),
                    const SizedBox(width: 8),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/pensee_positive.png',
                      fallbackIcon: Icons.lightbulb_outline,
                      tooltip: 'Positive thought',
                      onTap: _showPositiveThought,
                    ),
                    const SizedBox(width: 8),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/deconnexion.png',
                      fallbackIcon: Icons.logout,
                      tooltip: 'Log out',
                      onTap: _showLogoutConfirmation,
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: BackgroundMusicService.instance.isMutedNotifier,
                      builder: (context, isMuted, _) => NavCartouche(
                        assetPath: isMuted
                            ? 'assets/univers_visuel/sonoff.png'
                            : 'assets/univers_visuel/sonon.png',
                        fallbackIcon: isMuted ? Icons.volume_off : Icons.volume_up,
                        tooltip: isMuted ? 'Enable music' : 'Mute music',
                        onTap: () => BackgroundMusicService.instance.toggleMute(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 4 cartes animées plein écran (2 rangées × 2 colonnes) ──
              // Limiter la largeur sur écrans larges (web) pour garder
              // un ratio proche du carré sur chaque carte
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ExprimeCeQuiTeTraverseCard(
                                onTap: _navigateToExprime,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PartageCeQueTuRessensCard(
                                onTap: _navigateToRessens,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TonCheminParcouruCard(
                                onTap: _navigateToCheminParcouru,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ConnecteToiAuxSourcesCard(
                                onTap: _navigateToSources,
                              ),
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
            ],
          ),
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
              width: 64, height: 64,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Thought of the moment',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                  ),
                ),
              )
            else if (_isError)
              Text(
                'Unable to generate a thought at this time.',
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF78350F), height: 1.5),
                textAlign: TextAlign.center,
              )
            else
              Text(
                _thought ?? '',
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF78350F), height: 1.5),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF78350F),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Thank you!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

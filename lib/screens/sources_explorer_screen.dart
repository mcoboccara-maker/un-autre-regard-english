// lib/screens/sources_explorer_screen.dart
// Écran d'exploration des sources — accordéons par famille + quiz + roue du hasard

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../widgets/wisdom_wheel_dialog.dart';
import 'orientation/orientation_welcome_screen.dart';

class SourcesExplorerScreen extends StatefulWidget {
  const SourcesExplorerScreen({super.key});

  @override
  State<SourcesExplorerScreen> createState() => _SourcesExplorerScreenState();
}

class _SourcesExplorerScreenState extends State<SourcesExplorerScreen> {
  // ── Couleurs ─────────────────────────────────────────────────────────────
  static const _bgDark = Color(0xFF0E1C2F);
  static const _bgLight = Color(0xFF132A44);
  static const _textPrimary = Color(0xFFEAF2F7);
  static const _textSecondary = Color(0xFFB9C7D6);
  static const _accentTeal = Color(0xFF2E8B7B);

  // ── Sources sélectionnées ────────────────────────────────────────────────
  final Set<String> _selectedSources = {};

  // ── Mapping clé → nom de fichier PNG (copié de HomeCarouselScreen) ──────
  static const Map<String, String> _iconMapping = {
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

  // ── Définition des sections ──────────────────────────────────────────────
  static const List<_SourceSection> _sections = [
    _SourceSection(
      type: ApproachType.spiritual,
      title: 'Sources spirituelles',
      icon: Icons.self_improvement,
      color: Color(0xFF6366F1),
    ),
    // Quiz + Roue insérés entre spirituelles et littéraires (via build)
    _SourceSection(
      type: ApproachType.literary,
      title: 'Sources littéraires',
      icon: Icons.auto_stories,
      color: Color(0xFFEC4899),
    ),
    _SourceSection(
      type: ApproachType.psychological,
      title: 'Sources psychologiques',
      icon: Icons.psychology,
      color: Color(0xFF0EA5E9),
    ),
    _SourceSection(
      type: ApproachType.philosophical,
      title: 'Courants philosophiques',
      icon: Icons.account_balance,
      color: Color(0xFF10B981),
    ),
    _SourceSection(
      type: ApproachType.philosopher,
      title: 'Philosophes',
      icon: Icons.person,
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDark, _bgLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar custom ──
              _buildAppBar(),
              // ── Contenu scrollable ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      // 1. Sources spirituelles
                      _buildSourceSection(_sections[0]),
                      const SizedBox(height: 16),
                      // 2. Quiz + Roue du hasard
                      _buildQuizAndWheelButtons(),
                      const SizedBox(height: 16),
                      // 3-6. Autres sections
                      for (int i = 1; i < _sections.length; i++) ...[
                        _buildSourceSection(_sections[i]),
                        if (i < _sections.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/menu', (route) => false,
            ),
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
            tooltip: 'Menu',
          ),
          Expanded(
            child: Text(
              'Explore des sources',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // équilibre avec le bouton gauche
        ],
      ),
    );
  }

  // ── Section dépliable ────────────────────────────────────────────────────
  Widget _buildSourceSection(_SourceSection section) {
    final sources = ApproachCategories.getByType(section.type);
    final selectedCount = sources.where((s) => _selectedSources.contains(s.key)).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(section.icon, color: section.color, size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              // Badge compteur
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedCount > 0
                      ? section.color.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  selectedCount > 0 ? '$selectedCount/${sources.length}' : '${sources.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selectedCount > 0 ? section.color : _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          iconColor: _textSecondary,
          collapsedIconColor: _textSecondary,
          children: sources.map((source) => _buildSourceTile(source, section.color)).toList(),
        ),
      ),
    );
  }

  // ── Tile d'une source individuelle ───────────────────────────────────────
  Widget _buildSourceTile(ApproachConfig source, Color sectionColor) {
    final isSelected = _selectedSources.contains(source.key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSources.remove(source.key);
          } else {
            _selectedSources.add(source.key);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? sectionColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? sectionColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Icône PNG
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _getIconPath(source.key),
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: sectionColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(source.icon, color: sectionColor, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nom + credo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.credo,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Indicateur sélection
            if (isSelected)
              Icon(Icons.check_circle, color: sectionColor, size: 22)
            else
              Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.2), size: 22),
          ],
        ),
      ),
    );
  }

  // ── Boutons Quiz + Roue du hasard ────────────────────────────────────────
  Widget _buildQuizAndWheelButtons() {
    return Row(
      children: [
        // Quiz d'orientation
        Expanded(
          child: _buildActionCard(
            icon: Icons.quiz_rounded,
            label: 'Quiz\nd\'orientation',
            color: const Color(0xFF6366F1),
            onTap: _openQuiz,
          ),
        ),
        const SizedBox(width: 12),
        // Roue du hasard
        Expanded(
          child: _buildActionCard(
            icon: Icons.casino_rounded,
            label: 'Roue\ndu hasard',
            color: const Color(0xFFF59E0B),
            onTap: _openWheel,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Ouvrir le quiz en dialog plein écran ─────────────────────────────────
  void _openQuiz() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer quiz',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const OrientationWelcomeScreen(),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  // ── Ouvrir la roue du hasard (popup existant) ────────────────────────────
  void _openWheel() {
    WisdomWheelDialog.show(context);
  }
}

// ── Modèle de section ──────────────────────────────────────────────────────
class _SourceSection {
  final ApproachType type;
  final String title;
  final IconData icon;
  final Color color;

  const _SourceSection({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
  });
}

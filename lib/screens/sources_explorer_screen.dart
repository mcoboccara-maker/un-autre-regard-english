// lib/screens/sources_explorer_screen.dart
// Écran d'exploration des sources — accordéons par famille + quiz + roue du hasard

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../widgets/wisdom_wheel_dialog.dart';
import '../services/complete_auth_service.dart';
import '../services/ai_service.dart';
import '../services/persistent_storage_service.dart';
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
  final Set<String> _savedSources = {}; // Sources déjà sauvegardées (pour détecter les changements)
  bool _isSaving = false;

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
  void initState() {
    super.initState();
    _loadExistingSources();
  }

  Future<void> _loadExistingSources() async {
    // Charger UNIQUEMENT les sources EXPLICITEMENT choisies par l'utilisateur
    // On appelle directement PersistentStorageService (pas AIService qui injecte les défauts)
    // Règle MEMORY : "Dès que l'utilisateur choisit explicitement une source → les défauts ne sont plus valides"
    final existing = await PersistentStorageService.instance.getUserApproaches();
    if (existing.isNotEmpty && mounted) {
      setState(() {
        _selectedSources.addAll(existing);
        _savedSources.addAll(existing);
      });
    }
  }

  bool get _hasUnsavedChanges {
    if (_selectedSources.length != _savedSources.length) return true;
    return !_selectedSources.containsAll(_savedSources) || !_savedSources.containsAll(_selectedSources);
  }

  Future<void> _saveSelectedSources() async {
    if (_selectedSources.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final success = await CompleteAuthService.instance.saveSelectedSources(_selectedSources.toList());

    if (success) {
      await AIService.instance.loadUserApproaches();
      if (mounted) {
        setState(() {
          _savedSources.clear();
          _savedSources.addAll(_selectedSources);
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedSources.length} source${_selectedSources.length > 1 ? 's' : ''} sauvegardée${_selectedSources.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF2E8B7B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la sauvegarde. Réessaie.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
              // ── Bouton Sauvegarder (visible si changements non sauvegardés) ──
              if (_hasUnsavedChanges && _selectedSources.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSelectedSources,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Sauvegarde...'
                            : 'Sauvegarder mes ${_selectedSources.length} source${_selectedSources.length > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              // ── Bouton retour en bas ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/menu', (route) => false,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Retour au menu',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ── AppBar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
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
          // Cartouche droite : pensée positive + menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _showPositiveThought,
                icon: Image.asset(
                  'assets/univers_visuel/pensee_positive.png',
                  width: 26,
                  height: 26,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                tooltip: 'Pensée positive',
              ),
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/menu', (route) => false,
                ),
                icon: Image.asset(
                  'assets/univers_visuel/profil.png',
                  width: 26,
                  height: 26,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                tooltip: 'Menu principal',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPositiveThought() {
    final thoughts = [
      "Chaque jour est une nouvelle opportunité de grandir.",
      "Tu as déjà surmonté tant d'obstacles.",
      "Prends le temps de respirer. Ce moment difficile passera.",
      "Tu mérites d'être heureux(se) et en paix.",
      "Tes émotions sont valides. Accueille-les avec bienveillance.",
    ];
    final random = DateTime.now().millisecondsSinceEpoch % thoughts.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFEF3C7),
        title: Text('Pensée du moment', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
        content: Text(thoughts[random], style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF78350F), height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24), foregroundColor: const Color(0xFF78350F)),
            child: const Text('Merci !'),
          ),
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
  void _openWheel() async {
    final selectedIds = await WisdomWheelDialog.show(context);

    // Si l'utilisateur a validé des sources
    if (selectedIds != null && selectedIds.isNotEmpty) {
      // RÈGLE : les choix se CUMULENT, on AJOUTE les sources de la roue aux existantes
      final mergedSources = Set<String>.from(_selectedSources)..addAll(selectedIds);

      // 1. Sauvegarder le tout dans le profil utilisateur
      final success = await CompleteAuthService.instance.saveSelectedSources(mergedSources.toList());

      if (success) {
        // 2. Recharger les approches dans AIService pour prise en compte immédiate
        await AIService.instance.loadUserApproaches();

        // 3. Mettre à jour l'affichage local (cocher toutes les sources cumulées)
        if (mounted) {
          setState(() {
            _selectedSources.clear();
            _selectedSources.addAll(mergedSources);
            _savedSources.clear();
            _savedSources.addAll(mergedSources);
          });

          final newCount = selectedIds.where((id) => !_selectedSources.contains(id)).length;
          // 4. Feedback utilisateur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedIds.length} sagesse${selectedIds.length > 1 ? 's' : ''} ajoutée${selectedIds.length > 1 ? 's' : ''} — ${mergedSources.length} source${mergedSources.length > 1 ? 's' : ''} au total',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: const Color(0xFF2E8B7B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
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

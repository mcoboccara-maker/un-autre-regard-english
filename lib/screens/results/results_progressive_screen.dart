import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/approach_config.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';
import '../../models/source_evaluation.dart';

/// ECRAN D'AFFICHAGE DES RESULTATS - VERSION PROGRESSIVE
///
/// Mise en scène progressive du contenu :
/// - Niveau 1 : Accroche (reformulation + insight clé) - visible immédiatement
/// - Niveau 2 : Développement complet - révélé au tap/scroll
/// - Niveau 3 : Approfondissement - bouton optionnel
///
/// AUCUN CONTENU N'EST PERDU - seulement la présentation change
class ResultsProgressiveScreen extends StatefulWidget {
  final Map<String, String> aiResponses;
  final List<String> selectedApproaches;
  final String reflectionText;
  final VoidCallback onNewReflection;
  final VoidCallback? onBack;

  const ResultsProgressiveScreen({
    super.key,
    required this.aiResponses,
    required this.selectedApproaches,
    required this.reflectionText,
    required this.onNewReflection,
    this.onBack,
  });

  @override
  State<ResultsProgressiveScreen> createState() => _ResultsProgressiveScreenState();
}

class _ResultsProgressiveScreenState extends State<ResultsProgressiveScreen> {
  // État pour la révélation progressive
  final Map<String, bool> _isExpanded = {};

  // État pour l'approfondissement
  final Map<String, bool> _isDeepening = {};
  final Map<String, String> _deepenedResponses = {};

  // État pour l'évaluation
  final Map<String, SourceEvaluation> _evaluations = {};
  final Map<String, bool> _showEvaluation = {};

  // État pour le TTS
  String? _speakingKey;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await TtsService.instance.init();
    TtsService.instance.onStateChanged = (approachKey, isSpeaking) {
      if (mounted && !isSpeaking) {
        setState(() {
          _speakingKey = null;
        });
      }
    };
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    TtsService.instance.onStateChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your perspectives',
      headerIconPath: 'assets/univers_visuel/perspectives.png',
      showTitle: false,
      showBackButton: false,
      bottomAction: _buildNavigationButtons(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4F8),
              Color(0xFFD0E8F0),
              Color(0xFFB8DCE8),
              Color(0xFFD8EEF5),
              Color(0xFFE0F0F5),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              ...widget.selectedApproaches.asMap().entries.map((entry) {
                final index = entry.key;
                final approachKey = entry.value;
                return _buildProgressiveCard(approachKey, index + 1);
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E8B7B), Color(0xFF3A9D8C)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E8B7B).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/univers_visuel/perspectives.png',
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.selectedApproaches.length} perspectives',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        Text(
          'Here are different perspectives on your thought',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            height: 1.3,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  /// Construit une carte avec révélation progressive
  Widget _buildProgressiveCard(String approachNameOrKey, int numero) {
    late final ApproachConfig approach;
    try {
      approach = ApproachCategories.allApproaches
          .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
    } catch (e) {
      return const SizedBox();
    }

    final response = widget.aiResponses[approachNameOrKey];
    if (response == null || response.isEmpty) {
      return const SizedBox();
    }

    final isExpanded = _isExpanded[approach.key] ?? false;
    final hasDeepened = _deepenedResponses.containsKey(approach.key);
    final isDeepening = _isDeepening[approach.key] == true;
    final showEval = _showEvaluation[approach.key] == true;
    final evaluation = _evaluations[approach.key];
    final isSpeaking = _speakingKey == approach.key;

    // Extraire l'accroche et le contenu complet
    final parts = _splitContent(response);
    final accroche = parts['accroche'] ?? response;
    final developpement = parts['developpement'] ?? '';

    // Chemin de l'icône personnalisée
    final iconPath = _getIconPath(approach.key);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: approach.color.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // NIVEAU 1 : ACCROCHE (toujours visible)
          // ═══════════════════════════════════════════════════════════════
          _buildAccrocheSection(approach, iconPath, accroche, numero),

          // Séparateur élégant
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: approach.color.withOpacity(0.15))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Builder(
                    builder: (context) {
                      final approachColor = approach.color;
                      return Image.asset(
                        'assets/univers_visuel/pensee.png',
                        width: 16,
                        height: 16,
                        color: approachColor.withOpacity(0.4),
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: approachColor.withOpacity(0.4),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(child: Container(height: 1, color: approach.color.withOpacity(0.15))),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // BOUTON DE REVELATION
          // ═══════════════════════════════════════════════════════════════
          if (developpement.isNotEmpty)
            _buildRevealButton(approach, isExpanded),

          // ═══════════════════════════════════════════════════════════════
          // NIVEAU 2 : DEVELOPPEMENT (révélé progressivement)
          // ═══════════════════════════════════════════════════════════════
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0),
            secondChild: _buildDeveloppementSection(approach, developpement),
          ),

          // ═══════════════════════════════════════════════════════════════
          // NIVEAU 3 : APPROFONDISSEMENT (si existe)
          // ═══════════════════════════════════════════════════════════════
          if (hasDeepened)
            _buildApprofondissementSection(approach),

          // SECTION ÉVALUATION (si ouverte)
          if (showEval)
            _buildEvaluationSection(approach, evaluation),

          // ═══════════════════════════════════════════════════════════════
          // BARRE D'ACTIONS
          // ═══════════════════════════════════════════════════════════════
          _buildActionBar(approach, response, isDeepening, hasDeepened, isSpeaking, evaluation, showEval),
        ],
      ),
    ).animate().fadeIn(delay: (200 + numero * 100).ms).slideY(begin: 0.15, end: 0);
  }

  /// Section Accroche - Niveau 1
  Widget _buildAccrocheSection(ApproachConfig approach, String iconPath, String accroche, int numero) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et nom
          Row(
            children: [
              // Icône personnalisée
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: approach.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Icon(
                      approach.icon,
                      size: 24,
                      color: approach.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  approach.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: approach.color,
                  ),
                ),
              ),
              // Badge numéro
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: approach.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: approach.color,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Citation / Accroche principale - en grand, centré
          Text(
            _extractMainQuote(accroche),
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF1E293B),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Insight clé
          if (_extractInsight(accroche).isNotEmpty)
            Text(
              _extractInsight(accroche),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }

  /// Bouton de révélation
  Widget _buildRevealButton(ApproachConfig approach, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded[approach.key] = !isExpanded;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICONE A CREER: decouvrir.png / reduire.png
            Image.asset(
              isExpanded
                  ? 'assets/univers_visuel/reduire.png'  // A CREER
                  : 'assets/univers_visuel/decouvrir.png', // A CREER
              width: 18,
              height: 18,
              color: approach.color,
              errorBuilder: (_, __, ___) => Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: approach.color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isExpanded ? 'Collapse' : 'Discover why',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: approach.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Développement - Niveau 2
  Widget _buildDeveloppementSection(ApproachConfig approach, String developpement) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: MarkdownBody(
        data: _cleanMarkdown(developpement),
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF1E293B),
            height: 1.7,
          ),
          strong: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            height: 1.7,
          ),
          em: GoogleFonts.inter(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
            height: 1.7,
          ),
          blockquote: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: approach.color,
            height: 1.5,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: approach.color.withOpacity(0.4),
                width: 3,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 16),
        ),
        selectable: true,
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Section Approfondissement - Niveau 3
  Widget _buildApprofondissementSection(ApproachConfig approach) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: approach.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: approach.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/univers_visuel/pensee2.png', // Utilise ton icône existante
                width: 16,
                height: 16,
                color: approach.color,
                errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome, size: 16, color: approach.color),
              ),
              const SizedBox(width: 8),
              Text(
                'Deepening',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: approach.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: _cleanMarkdown(_deepenedResponses[approach.key]!),
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF1E293B),
              ),
              strong: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre d'actions
  Widget _buildActionBar(
    ApproachConfig approach,
    String response,
    bool isDeepening,
    bool hasDeepened,
    bool isSpeaking,
    SourceEvaluation? evaluation,
    bool showEval,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Bouton Approfondir
          if (!hasDeepened)
            _buildActionButton(
              iconPath: 'assets/univers_visuel/pensee2.png',
              fallbackIcon: isDeepening ? Icons.hourglass_top : Icons.auto_awesome,
              label: isDeepening ? 'In progress...' : 'Deepen',
              color: approach.color,
              onPressed: isDeepening ? null : () => _deepen(approach),
            ),

          // Bouton TTS
          _buildActionButton(
            iconPath: isSpeaking
                ? 'assets/univers_visuel/stop.png'  // A CREER si besoin
                : 'assets/univers_visuel/ecouter.png', // A CREER si besoin
            fallbackIcon: isSpeaking ? Icons.stop : Icons.volume_up,
            label: isSpeaking ? 'Stop' : 'Listen',
            color: const Color(0xFF64748B),
            onPressed: () => _toggleTts(approach, response),
          ),

          const Spacer(),

          // Bouton Évaluer
          _buildActionButton(
            iconPath: evaluation != null
                ? 'assets/univers_visuel/evaluation/evaluation${evaluation.rating}.png'
                : 'assets/univers_visuel/evaluation/evaluation5.png',
            fallbackIcon: evaluation != null ? Icons.star : Icons.star_border,
            label: 'Rate',
            color: evaluation != null ? const Color(0xFFD4AF37) : const Color(0xFF64748B),
            onPressed: () {
              setState(() {
                _showEvaluation[approach.key] = !showEval;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String iconPath,
    required IconData fallbackIcon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    final effectiveColor = isDisabled ? color.withOpacity(0.5) : color;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 16,
            height: 16,
            color: effectiveColor,
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 16, color: effectiveColor),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationSection(ApproachConfig approach, SourceEvaluation? evaluation) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your opinion on this perspective',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                'Rating:',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF78350F)),
              ),
              Expanded(
                child: Slider(
                  value: (evaluation?.rating ?? 5).toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '${(evaluation?.rating ?? 5)}/10',
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) {
                    setState(() {
                      _evaluations[approach.key] = SourceEvaluation(
                        sourceKey: approach.key,
                        sourceName: approach.name,
                        rating: value.toInt(),
                        comment: evaluation?.comment,
                      );
                    });
                  },
                ),
              ),
              // Icône d'évaluation
              Image.asset(
                'assets/univers_visuel/evaluation/evaluation${(evaluation?.rating ?? 5)}.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(evaluation?.rating ?? 5)}/10',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'A comment? (optional)',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              setState(() {
                _evaluations[approach.key] = SourceEvaluation(
                  sourceKey: approach.key,
                  sourceName: approach.name,
                  rating: evaluation?.rating ?? 5,
                  comment: value,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retourne le chemin de l'icône personnalisée pour une approche
  String _getIconPath(String approachKey) {
    // Mapping des clés vers les fichiers PNG
    final iconMap = {
      'stoicisme': 'assets/univers_visuel/stoicisme.png',
      'realisme': 'assets/univers_visuel/realisme.png',
      'existentialisme': 'assets/univers_visuel/existentialisme.png',
      'absurdisme': 'assets/univers_visuel/absurdisme.png',
      'humanisme': 'assets/univers_visuel/humanisme.png',
      'romantisme': 'assets/univers_visuel/romantisme.png',
      'symbolisme': 'assets/univers_visuel/symbolisme.png',
      'surrealisme': 'assets/univers_visuel/surrealisme.png',
      'modernisme': 'assets/univers_visuel/modernisme.png',
      'postmodernisme': 'assets/univers_visuel/postmodernisme.png',
      'naturalisme': 'assets/univers_visuel/naturalisme.png',
      'poetique': 'assets/univers_visuel/poetique.png',
      'mystique': 'assets/univers_visuel/mystique.png',
      'mythologie': 'assets/univers_visuel/mythologie.png',
      'science_fiction': 'assets/univers_visuel/science_fiction.png',
      'fantasy': 'assets/univers_visuel/fantasy.png',
      'tragedie_classique': 'assets/univers_visuel/tragedie_classique.png',
      'litterature': 'assets/univers_visuel/litterature.png',
      // Psychologie
      'act': 'assets/univers_visuel/act.png',
      'tcc': 'assets/univers_visuel/TCC.png',
      'jungienne': 'assets/univers_visuel/jungienne.png',
      'logotherapie': 'assets/univers_visuel/logotherapie_frankl.png',
      'schemas_young': 'assets/univers_visuel/schemas_young.png',
      'the_work': 'assets/univers_visuel/theworkkb.png',
      'humaniste_rogers': 'assets/univers_visuel/approche_humaniste.png',
      'psychanalyse': 'assets/univers_visuel/psychanalyse.png',
      'analyse_transactionnelle': 'assets/univers_visuel/analyse_transactionnelle.png',
      'systemique': 'assets/univers_visuel/approche_systemique.png',
      // Spirituel
      'judaisme_rabbinique': 'assets/univers_visuel/rabbinique.png',
      'moussar': 'assets/univers_visuel/moussar.png',
      'kabbale': 'assets/univers_visuel/kabale.png',
      'christianisme': 'assets/univers_visuel/christianisme.png',
      'islam': 'assets/univers_visuel/islam.png',
      'soufisme': 'assets/univers_visuel/soufisme.png',
      'bouddhisme': 'assets/univers_visuel/boudhisme.png',
      'hindouisme': 'assets/univers_visuel/hindouisme.png',
      'spiritualite_contemporaine': 'assets/univers_visuel/contemporaine et laique.png',
      // Philosophie
      'epicurisme': 'assets/univers_visuel/epicurisme.png',
      'phenomenologie': 'assets/univers_visuel/phenomenologie.png',
      'rationalisme': 'assets/univers_visuel/rationalisme.png',
      'empirisme': 'assets/univers_visuel/empirisme.png',
      'idealisme': 'assets/univers_visuel/idealisme.png',
      'pragmatisme': 'assets/univers_visuel/pragmatisme.png',
      'vitalisme': 'assets/univers_visuel/vitalisme.png',
      'utilitarisme': 'assets/univers_visuel/utilitarisme.png',
      'structuralisme': 'assets/univers_visuel/structuralisme.png',
      'cynisme': 'assets/univers_visuel/cynisme.png',
      'nihilisme': 'assets/univers_visuel/nihilisme.png',
      // Philosophes
      'socrate': 'assets/univers_visuel/socrate.png',
      'platon': 'assets/univers_visuel/platon.png',
      'aristote': 'assets/univers_visuel/aristote.png',
      'epicure': 'assets/univers_visuel/epicure.png',
      'seneque': 'assets/univers_visuel/seneque.png',
      'epictete': 'assets/univers_visuel/epictete.png',
      'marc_aurele': 'assets/univers_visuel/marc_aurele.png',
      'spinoza': 'assets/univers_visuel/spinoza.png',
      'kant': 'assets/univers_visuel/kant.png',
      'nietzsche': 'assets/univers_visuel/nietzsche.png',
      'kierkegaard': 'assets/univers_visuel/kierkegaard.png',
      'sartre': 'assets/univers_visuel/sartre.png',
      'camus': 'assets/univers_visuel/camus.png',
      'simone_de_beauvoir': 'assets/univers_visuel/simonedebeauvoir.png',
      'hannah_arendt': 'assets/univers_visuel/arendt.png',
      'schopenhauer': 'assets/univers_visuel/schopenhauer.png',
      'montaigne': 'assets/univers_visuel/montaigne.png',
      'diogene': 'assets/univers_visuel/diogene.png',
      'confucius': 'assets/univers_visuel/confucius.png',
      'rousseau': 'assets/univers_visuel/rousseau.png',
      'hume': 'assets/univers_visuel/hume.png',
      'foucault': 'assets/univers_visuel/foucault.png',
      'descartes': 'assets/univers_visuel/descartes.png',
    };

    return iconMap[approachKey] ?? 'assets/univers_visuel/philosophie.png';
  }

  /// Sépare le contenu en accroche et développement
  Map<String, String> _splitContent(String response) {
    final cleaned = _cleanMarkdown(response);
    final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.length <= 3) {
      return {'accroche': cleaned, 'developpement': ''};
    }

    // Chercher un point de séparation naturel (après 2-3 paragraphes ou ~200 caractères)
    int splitIndex = 0;
    int charCount = 0;

    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length;
      if (charCount > 200 || i >= 2) {
        splitIndex = i + 1;
        break;
      }
    }

    if (splitIndex == 0 || splitIndex >= lines.length) {
      splitIndex = (lines.length / 3).ceil();
    }

    final accroche = lines.take(splitIndex).join('\n\n');
    final developpement = lines.skip(splitIndex).join('\n\n');

    return {'accroche': accroche, 'developpement': developpement};
  }

  /// Extrait la citation principale (première phrase entre guillemets ou première phrase)
  String _extractMainQuote(String text) {
    // Chercher une citation entre guillemets
    final quoteMatch = RegExp(r'[«"]([^»"]+)[»"]').firstMatch(text);
    if (quoteMatch != null) {
      return '« ${quoteMatch.group(1)?.trim()} »';
    }

    // Sinon prendre la première phrase significative
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().length > 20).toList();
    if (sentences.isNotEmpty) {
      return sentences.first.trim();
    }

    return text.split('\n').first.trim();
  }

  /// Extrait l'insight (phrase après la citation)
  String _extractInsight(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length > 1) {
      // Retourne la 2ème ou 3ème phrase comme insight
      return lines.skip(1).take(1).join(' ').trim();
    }
    return '';
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'_{3,}'), '')
        .replaceAll(RegExp(r'##\s*\d+\.\s*[A-ZÉÈÊËÀÂÄÙÛÜÔÖÎÏ\s]+\n'), '')
        .replaceAll(RegExp(r'\[FIGURE_META\][\s\S]*?\[/FIGURE_META\]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPROFONDISSEMENT & TTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _deepen(ApproachConfig approach) async {
    setState(() {
      _isDeepening[approach.key] = true;
    });

    try {
      final shortResponse = widget.aiResponses[approach.key] ?? widget.aiResponses[approach.name] ?? '';

      String figureNom = 'Figure';
      final metaMatch = RegExp(r'\[FIGURE_META\][\s\S]*?nom:\s*([^\n]+)[\s\S]*?\[/FIGURE_META\]')
          .firstMatch(shortResponse);
      if (metaMatch != null) {
        figureNom = metaMatch.group(1)?.trim() ?? 'Figure';
      }

      final deepenedResponse = await AIService.instance.generateDeepening(
        penseeOriginale: widget.reflectionText,
        reponseCourte: shortResponse,
        sourceNom: approach.name,
        figureNom: figureNom,
      );

      if (mounted) {
        setState(() {
          _deepenedResponses[approach.key] = deepenedResponse;
          _isDeepening[approach.key] = false;
          _isExpanded[approach.key] = true; // Auto-expand quand on approfondit
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeepening[approach.key] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleTts(ApproachConfig approach, String text) async {
    if (_speakingKey == approach.key) {
      await TtsService.instance.stop();
      setState(() {
        _speakingKey = null;
      });
    } else {
      if (_speakingKey != null) {
        await TtsService.instance.stop();
      }

      setState(() {
        _speakingKey = approach.key;
      });

      final cleanText = _cleanMarkdown(text);
      await TtsService.instance.speak(cleanText, approachKey: approach.key);
    }
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onNewReflection,
            icon: Image.asset(
              'assets/univers_visuel/pensee.png',
              width: 20,
              height: 20,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(Icons.refresh, size: 20),
            ),
            label: Text(
              'New reflection',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B7B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false),
            icon: Image.asset(
              'assets/univers_visuel/menu principal.png',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(Icons.home, size: 18),
            ),
            label: Text(
              'Back to menu',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E8B7B),
              side: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

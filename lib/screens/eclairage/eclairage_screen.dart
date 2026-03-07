import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/eclairage_service.dart';
import '../../services/language_detector.dart';
import '../../services/sefaria_api_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// ÉCRAN ÉCLAIRAGE
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Module principal pour transformer une question en éclairage juif vivant.
///
/// Flux:
/// 1. Saisie texte (ou voix)
/// 2. Éclairage existentiel (LLM)
/// 3. Contexte historique (Encyclopaedia Judaica)
/// 4. Sources textuelles (Sefaria)
///

class EclairageScreen extends StatefulWidget {
  const EclairageScreen({super.key});

  @override
  State<EclairageScreen> createState() => _EclairageScreenState();
}

class _EclairageScreenState extends State<EclairageScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  EclairageResponse? _response;
  bool _isGenerating = false;

  // Suggestions de questions
  final List<String> _suggestions = [
    'What is the meaning of suffering?',
    'How to find inner peace?',
    'Why is Shabbat so important?',
    'How to forgive someone who has hurt me?',
    'What is the purpose of life according to Judaism?',
    'How to manage anger?',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateEclairage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _response = null;
    });

    // Scroll vers le haut pour voir la réponse
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      await for (final response in EclairageService.instance.generateEclairageStreaming(
        question: question,
        language: LanguageDetector.detect(question),
      )) {
        if (mounted) {
          setState(() => _response = response);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Réponse (si disponible)
                    if (_response != null) ...[
                      _buildResponse(),
                      const SizedBox(height: 24),
                    ],

                    // Zone de saisie
                    _buildInputSection(),

                    // Suggestions (si pas de réponse)
                    if (_response == null) ...[
                      const SizedBox(height: 32),
                      _buildSuggestions(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Insight',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Bouton micro (pour saisie vocale future)
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.white70),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice input coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Transform a thought, situation or question into a living Jewish insight',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _questionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ask your question or share a reflection...',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            style: GoogleFonts.inter(fontSize: 16),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Compteur de caractères
                Text(
                  '${_questionController.text.length} characters',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                // Bouton Éclairer
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateEclairage,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isGenerating ? 'Generating...' : 'Illuminate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) => _SuggestionChip(
            text: s,
            onTap: () {
              _questionController.text = s;
              setState(() {});
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildResponse() {
    final response = _response!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicateur de statut
        if (response.isLoading)
          _buildStatusIndicator(response.status),

        // Éclairage principal
        if (response.insight != null)
          _EclairageCard(insight: response.insight!),

        // Contexte historique
        if (response.historicalContext.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ContextSection(contexts: response.historicalContext),
        ],

        // Sources textuelles
        if (response.textualSources.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SourcesSection(sources: response.textualSources),
        ],

        // Erreur
        if (response.hasError)
          _buildError(response.error ?? 'Unknown error'),
      ],
    );
  }

  Widget _buildStatusIndicator(EclairageStatus status) {
    String message;
    IconData icon;

    switch (status) {
      case EclairageStatus.loading:
        message = 'Preparing...';
        icon = Icons.hourglass_empty;
        break;
      case EclairageStatus.generatingInsight:
        message = 'Generating insight...';
        icon = Icons.auto_awesome;
        break;
      case EclairageStatus.loadingContext:
        message = 'Searching historical context...';
        icon = Icons.history_edu;
        break;
      case EclairageStatus.loadingSources:
        message = 'Searching textual sources...';
        icon = Icons.menu_book;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              color: const Color(0xFF6366F1),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de suggestion
class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

/// Carte d'éclairage principal
class _EclairageCard extends StatelessWidget {
  final LlmInsight insight;

  const _EclairageCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Insight',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Texte de l'éclairage
          Text(
            insight.eclairage,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.7,
              color: const Color(0xFF334155),
            ),
          ),

          // Citation
          if (insight.citation != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Citation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${insight.citation!.texte}"',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— ${insight.citation!.source}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Question de réflexion
          if (insight.reflexion != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Color(0xFF059669), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Food for Thought',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.reflexion!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mots-clés
          if (insight.motsCles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insight.motsCles.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  m,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section contexte historique
class _ContextSection extends StatelessWidget {
  final List<EncyclopediaContext> contexts;

  const _ContextSection({required this.contexts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_edu, color: Color(0xFF6366F1), size: 20),
            const SizedBox(width: 8),
            Text(
              'Historical Context',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Text(
              'Encyclopaedia Judaica',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...contexts.map((c) => _ContextCard(context: c)),
      ],
    );
  }
}

/// Carte de contexte
class _ContextCard extends StatelessWidget {
  final EncyclopediaContext context;

  const _ContextCard({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  this.context.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  this.context.source,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            this.context.excerpt,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section sources textuelles
class _SourcesSection extends StatelessWidget {
  final List<SefariaSource> sources;

  const _SourcesSection({required this.sources});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 8),
            Text(
              'Textual Sources',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Text(
              'Sefaria',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sources.map((s) => _SourceCard(source: s)),
      ],
    );
  }
}

/// Carte de source
class _SourceCard extends StatefulWidget {
  final SefariaSource source;

  const _SourceCard({required this.source});

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // En-tête
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.source.ref,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (widget.source.heRef.isNotEmpty)
                          Text(
                            widget.source.heRef,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.source.category,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Contenu expandable
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.source.hebrewText.isNotEmpty) ...[
                    Text(
                      widget.source.hebrewText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.source.englishText.isNotEmpty)
                    Text(
                      widget.source.englishText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Lien vers Sefaria
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Ouvrir le lien Sefaria
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ouvrir: ${widget.source.sefariaUrl}')),
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View on Sefaria'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

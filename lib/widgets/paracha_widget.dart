import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sefaria_api_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// PARACHA WIDGET
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Widget pour afficher la paracha de la semaine avec:
/// - Texte hébreu
/// - Traduction
/// - Commentaires de Rashi interactifs
/// - Aliyot
///

/// Carte d'aperçu de la Paracha (pour le menu principal)
class ParashaPreviewCard extends StatefulWidget {
  final VoidCallback? onTap;
  final bool diaspora;

  const ParashaPreviewCard({
    super.key,
    this.onTap,
    this.diaspora = true,
  });

  @override
  State<ParashaPreviewCard> createState() => _ParashaPreviewCardState();
}

class _ParashaPreviewCardState extends State<ParashaPreviewCard> {
  CalendarItem? _parasha;
  CalendarItem? _haftarah;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParasha();
  }

  Future<void> _loadParasha() async {
    try {
      final calendar = await SefariaApiService.instance.getCalendar(
        diaspora: widget.diaspora,
      );
      setState(() {
        _parasha = calendar.parasha;
        _haftarah = calendar.haftarah;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white70, size: 32),
        const SizedBox(height: 8),
        Text(
          'Impossible de charger la paracha',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'פרשת השבוע',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: Colors.white70),
          ],
        ),

        const SizedBox(height: 16),

        // Nom de la paracha (hébreu)
        Text(
          _parasha?.displayValue.he ?? '',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // Nom anglais/français
        Text(
          _parasha?.displayValue.en ?? '',
          style: GoogleFonts.inter(
            fontSize: 18,
            color: Colors.white.withOpacity(0.8),
          ),
        ),

        const SizedBox(height: 12),

        // Référence
        Text(
          _parasha?.ref ?? '',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),

        if (_haftarah != null) ...[
          const SizedBox(height: 8),
          Text(
            'Haftarah: ${_haftarah!.displayValue.en}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],

        // Description si disponible
        if (_parasha?.description != null) ...[
          const SizedBox(height: 16),
          Text(
            _parasha!.description!.en,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Page complète de la Paracha
class ParashaDetailPage extends StatefulWidget {
  final String? parashaRef;
  final bool diaspora;

  const ParashaDetailPage({
    super.key,
    this.parashaRef,
    this.diaspora = true,
  });

  @override
  State<ParashaDetailPage> createState() => _ParashaDetailPageState();
}

class _ParashaDetailPageState extends State<ParashaDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  CalendarItem? _parasha;
  SefariaText? _text;
  SefariaRelated? _related;
  bool _isLoading = true;
  String? _error;

  int _currentAliyah = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Charger la paracha
      if (widget.parashaRef != null) {
        _text = await SefariaApiService.instance.getText(widget.parashaRef!);
      } else {
        final calendar = await SefariaApiService.instance.getCalendar(
          diaspora: widget.diaspora,
        );
        _parasha = calendar.parasha;
        if (_parasha != null) {
          _text = await SefariaApiService.instance.getText(_parasha!.ref);
          // Charger les commentaires liés
          _related = await SefariaApiService.instance.getRelated(_parasha!.ref);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _parasha?.displayValue.he ?? 'פרשה',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Texte'),
            Tab(text: 'Rashi'),
            Tab(text: 'Aliyot'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTextTab(),
                    _buildRashiTab(),
                    _buildAliyotTab(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: GoogleFonts.inter(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadData();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    if (_text == null) {
      return const Center(child: Text('Texte non disponible'));
    }

    final hebrewVerses = _text!.hebrew?.textAsList ?? [];
    final englishVerses = _text!.english?.textAsList ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hebrewVerses.length,
      itemBuilder: (context, index) {
        final heVerse = index < hebrewVerses.length ? hebrewVerses[index] : '';
        final enVerse = index < englishVerses.length ? englishVerses[index] : '';

        return _VerseCard(
          verseNumber: index + 1,
          hebrewText: heVerse,
          englishText: enVerse,
          onTap: () => _showVerseDetails(index + 1, heVerse, enVerse),
        );
      },
    );
  }

  Widget _buildRashiTab() {
    final commentators = _related?.availableCommentators ?? [];

    if (commentators.isEmpty) {
      return const Center(
        child: Text('Aucun commentaire disponible'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Liste des commentateurs disponibles
        Text(
          'Commentateurs disponibles',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commentators.map((c) => _CommentatorChip(
            name: c,
            onTap: () => _loadCommentary(c),
          )).toList(),
        ),

        const SizedBox(height: 24),

        // Commentaires de Rashi
        if (_related?.rashi.isNotEmpty ?? false) ...[
          Text(
            'Rashi - רש"י',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 12),
          ..._related!.rashi.map((link) => _CommentaryCard(
            commentator: 'Rashi',
            reference: link.sourceRef,
            onTap: () => _showCommentary(link),
          )),
        ],
      ],
    );
  }

  Widget _buildAliyotTab() {
    final aliyot = _parasha?.aliyot ?? [];

    if (aliyot.isEmpty) {
      return const Center(
        child: Text('Aliyot non disponibles'),
      );
    }

    final aliyotNames = [
      'ראשון (Kohen)',
      'שני (Levi)',
      'שלישי (3ème)',
      'רביעי (4ème)',
      'חמישי (5ème)',
      'שישי (6ème)',
      'שביעי (7ème)',
      'מפטיר (Maftir)',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: aliyot.length,
      itemBuilder: (context, index) {
        final aliyah = aliyot[index];
        final name = index < aliyotNames.length ? aliyotNames[index] : 'Aliyah ${index + 1}';
        final isSelected = index == _currentAliyah;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: Color(0xFF6366F1), width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade200,
              foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
              child: Text('${index + 1}'),
            ),
            title: Text(
              name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              aliyah,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() => _currentAliyah = index);
              _loadAliyah(aliyah);
            },
          ),
        );
      },
    );
  }

  void _showVerseDetails(int number, String hebrew, String english) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verset $number',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hebrew,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              Text(
                english,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadCommentary(String commentator) {
    // TODO: Charger le commentaire complet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chargement de $commentator...')),
    );
  }

  void _showCommentary(RelatedLink link) {
    // TODO: Afficher le commentaire
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${link.collectiveTitle.en}: ${link.sourceRef}')),
    );
  }

  void _loadAliyah(String ref) {
    // TODO: Charger le texte de l'aliyah spécifique
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chargement de $ref...')),
    );
  }
}

/// Carte de verset
class _VerseCard extends StatelessWidget {
  final int verseNumber;
  final String hebrewText;
  final String englishText;
  final VoidCallback? onTap;

  const _VerseCard({
    required this.verseNumber,
    required this.hebrewText,
    required this.englishText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Numéro de verset
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$verseNumber',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.touch_app, size: 16, color: Colors.grey.shade400),
                ],
              ),

              const SizedBox(height: 12),

              // Texte hébreu
              Text(
                hebrewText,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  height: 1.8,
                  color: const Color(0xFF0F172A),
                ),
                textDirection: TextDirection.rtl,
              ),

              if (englishText.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  englishText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pour commentateur
class _CommentatorChip extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _CommentatorChip({
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(name),
      onPressed: onTap,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: GoogleFonts.inter(
        color: const Color(0xFF475569),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Carte de commentaire
class _CommentaryCard extends StatelessWidget {
  final String commentator;
  final String reference;
  final VoidCallback? onTap;

  const _CommentaryCard({
    required this.commentator,
    required this.reference,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          reference,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

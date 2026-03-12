import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/complete_auth_service.dart';
import '../../widgets/app_scaffold.dart'; // ✅ NOUVEAU

class LiterarySource {
  final String id;
  final String name;
  final String iconPath;
  final String description;
  final String modeOfThought;
  final String worldView;

  const LiterarySource({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.modeOfThought,
    required this.worldView,
  });
}

class SourcesLitterairesScreen extends StatefulWidget {
  const SourcesLitterairesScreen({super.key});

  @override
  State<SourcesLitterairesScreen> createState() => _SourcesLitterairesScreenState();
}

class _SourcesLitterairesScreenState extends State<SourcesLitterairesScreen> {
  final Set<String> _selectedSources = {};
  bool _isLoading = true;
  bool _authorsExpanded = false;

  final List<LiterarySource> _authors = [
    LiterarySource(
      id: 'kafka',
      name: 'Franz Kafka',
      iconPath: 'assets/univers_visuel/kafka.png',
      description: 'Master of bureaucratic absurdity — the individual confronted with incomprehensible systems that overwhelm and transform him.',
      modeOfThought: 'Anguish as lucidity; the logic of nightmare reveals the cracks in reality.',
      worldView: 'The world is a labyrinth with no visible exit — yet the quest for meaning persists despite everything.',
    ),
    LiterarySource(
      id: 'dostoievski',
      name: 'Fyodor Dostoevsky',
      iconPath: 'assets/univers_visuel/dostoievsky.png',
      description: 'Explorer of the soul\'s depths — inner turmoil, guilt, redemption through suffering.',
      modeOfThought: 'Descent into the depths of consciousness; each character carries an absolute moral struggle.',
      worldView: 'Man is a battlefield between good and evil — suffering can lead to light.',
    ),
  ];

  final List<LiterarySource> _sources = [
    LiterarySource(
      id: 'romantisme',
      name: 'Romanticism',
      iconPath: 'assets/univers_visuel/romantisme.png',
      description: '19th-century movement valuing emotional expression, nature and the individual.',
      modeOfThought: 'Primacy of the heart, heightened sensitivity, quest for intensity.',
      worldView: 'The world is a mirror of the soul; personal destiny is central.',
    ),
    LiterarySource(
      id: 'realisme',
      name: 'Realism',
      iconPath: 'assets/univers_visuel/realisme.png',
      description: '19th-century movement seeking to represent social reality as it is.',
      modeOfThought: 'Meticulous observation, rationality, social lucidity.',
      worldView: 'The world is harsh, structured by social classes and material constraints.',
    ),
    LiterarySource(
      id: 'naturalisme',
      name: 'Naturalism',
      iconPath: 'assets/univers_visuel/naturalisme.png',
      description: 'Radicalized version of realism, influenced by science and determinism.',
      modeOfThought: 'Analysis of heredity, instincts, environments; quasi-scientific approach.',
      worldView: 'The world determines individuals, choices are limited.',
    ),
    LiterarySource(
      id: 'symbolisme',
      name: 'Symbolism',
      iconPath: 'assets/univers_visuel/symbolisme.png',
      description: 'Late 19th-century movement exploring dreams, allegory and symbols.',
      modeOfThought: 'Intuition, mystery, suggestive poetic language.',
      worldView: 'Reality is a veil; deep truths are hidden.',
    ),
    LiterarySource(
      id: 'surrealisme',
      name: 'Surrealism',
      iconPath: 'assets/univers_visuel/surrealisme.png',
      description: '20th-century movement centered on the unconscious, dreams and uncensored imagination.',
      modeOfThought: 'Free association, break with logic, inner exploration.',
      worldView: 'The world is a space to be freed from mental constraints.',
    ),
    LiterarySource(
      id: 'existentialisme',
      name: 'Existentialism',
      iconPath: 'assets/univers_visuel/existentialisme.png',
      description: 'Literature centered on freedom, responsibility and existential anxiety.',
      modeOfThought: 'Ethical questioning, radical lucidity, search for authenticity.',
      worldView: 'The world has no given meaning: the individual must create their own.',
    ),
    LiterarySource(
      id: 'humanisme',
      name: 'Humanism',
      iconPath: 'assets/univers_visuel/humanisme.png',
      description: 'Movement valuing human dignity, reason and fulfillment.',
      modeOfThought: 'Rational reflection, measured optimism, moral contemplation.',
      worldView: 'The world is perfectible through thought and dialogue.',
    ),
    LiterarySource(
      id: 'absurdisme',
      name: 'Absurdism',
      iconPath: 'assets/univers_visuel/absurdisme.png',
      description: 'Movement addressing the senselessness of the human condition and the impossible quest for meaning.',
      modeOfThought: 'Irony, lucidity, confrontation with existential void.',
      worldView: 'The world is absurd but humans can oppose it with their dignity.',
    ),
    LiterarySource(
      id: 'modernisme',
      name: 'Modernism',
      iconPath: 'assets/univers_visuel/modernisme.png',
      description: 'Early 20th-century literary movement that disrupted classical forms.',
      modeOfThought: 'Narrative fragmentation, subjectivity, introspection.',
      worldView: 'Reality is multiple, unstable, subjective.',
    ),
    LiterarySource(
      id: 'postmodernisme',
      name: 'Postmodernism',
      iconPath: 'assets/univers_visuel/postmodernisme.png',
      description: 'Movement playing with codes, plurality of truths and intertwined narratives.',
      modeOfThought: 'Irony, genre mixing, questioning of meta-narratives.',
      worldView: 'The world is complex, hybrid, with no single center.',
    ),
    LiterarySource(
      id: 'tragedie_classique',
      name: 'Classical Tragedy',
      iconPath: 'assets/univers_visuel/tragedie_classique.png',
      description: 'Dramatic genre exploring destiny, fatality and human passions.',
      modeOfThought: 'Catharsis, confrontation with fate, nobility in the face of the inevitable.',
      worldView: 'Humanity is subject to forces beyond its control; greatness lies in acceptance.',
    ),
    LiterarySource(
      id: 'roman_psychologique',
      name: 'Psychological Novel',
      iconPath: 'assets/univers_visuel/roman_psychologique.png',
      description: 'Literary genre focused on the fine analysis of inner states.',
      modeOfThought: 'Introspection, emotional nuances, complexity of motivations.',
      worldView: 'Truth is found in the depths of the human psyche.',
    ),
    LiterarySource(
      id: 'mythologie',
      name: 'Mythology',
      iconPath: 'assets/univers_visuel/mythologie.png',
      description: 'Founding narratives exploring universal archetypes of humanity.',
      modeOfThought: 'Symbolism, initiatory tales, transformative ordeals.',
      worldView: 'The world is animated by archetypal forces; myths illuminate our condition.',
    ),
    LiterarySource(
      id: 'science_fiction',
      name: 'Science Fiction',
      iconPath: 'assets/univers_visuel/science_fiction.png',
      description: 'Genre exploring possible futures and the implications of technology.',
      modeOfThought: 'Extrapolation, ethical questioning, prospective imagination.',
      worldView: 'The future is a mirror of our present choices; technology transforms humanity.',
    ),
    LiterarySource(
      id: 'fantasy',
      name: 'Fantasy',
      iconPath: 'assets/univers_visuel/fantasy.png',
      description: 'Imaginative genre exploring magical worlds and heroic quests.',
      modeOfThought: 'Initiatory journey, battle of good against evil, inner transformation.',
      worldView: 'The world holds hidden dimensions; heroism reveals our true nature.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedSources();
  }

  Future<void> _loadSelectedSources() async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile();
      if (profileData != null && profileData['courantsLitteraires'] != null) {
        final List<dynamic> saved = profileData['courantsLitteraires'];
        setState(() {
          _selectedSources.addAll(saved.cast<String>());
        });
      }
    } catch (e) {
      print('Erreur chargement sources littéraires: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndReturn() async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile();
      final Map<String, dynamic> updatedProfile = Map<String, dynamic>.from(profileData ?? {});

      updatedProfile['courantsLitteraires'] = _selectedSources.toList();
      updatedProfile['lastUpdated'] = DateTime.now().toIso8601String();

      await CompleteAuthService.instance.saveProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSources.length} literary movement(s) saved'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Literary Movements',
      showMenuButton: true,
      showPositiveButton: true,
      showBackButton: true,
      bottomAction: _buildValidateButton(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : Column(
              children: [
                // Badge de sélection
                if (_selectedSources.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedSources.length} selected',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      ..._sources.map((source) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSourceCard(source),
                      )),
                      const SizedBox(height: 8),
                      _buildAuthorsSection(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedSources.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedSources.length} selected',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Image.asset(
            'assets/univers_visuel/categorie_litteraires.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book, size: 60, color: Color(0xFF10B981)),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Literary Movements',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the movements that speak to you',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(LiterarySource source) {
    final isSelected = _selectedSources.contains(source.id);

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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSources.remove(source.id);
                    } else {
                      _selectedSources.add(source.id);
                    }
                  });
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              )
                            : null,
                        child: Image.asset(
                          source.iconPath,
                          width: 110,
                          height: 110,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu_book,
                                color: Color(0xFF10B981),
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(Icons.check, color: Colors.white, size: 16),
                            if (isSelected)
                              const SizedBox(width: 4),
                            Text(
                              isSelected ? 'Selected' : 'Select',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey.shade600,
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

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      source.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Way of Thinking',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.modeOfThought,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Worldview',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.worldView,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorsSection() {
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _authorsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _authorsExpanded = expanded);
          },
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/univers_visuel/authors.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.menu_book,
                size: 48,
                color: Color(0xFF7C2D12),
              ),
            ),
          ),
          title: Text(
            'Authors',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            'Singular perspectives on the human condition',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          children: _authors.map((author) => Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
            child: _buildSourceCard(author),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildValidateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveAndReturn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC4899),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Confirm my choices',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

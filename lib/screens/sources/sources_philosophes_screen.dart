import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/complete_auth_service.dart';
import '../../widgets/app_scaffold.dart'; // ✅ NOUVEAU

class Philosopher {
  final String id;
  final String name;
  final String iconPath;
  final String description;
  final String modeOfThought;
  final String worldView;

  const Philosopher({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.modeOfThought,
    required this.worldView,
  });
}

class SourcesPhilosophesScreen extends StatefulWidget {
  const SourcesPhilosophesScreen({super.key});

  @override
  State<SourcesPhilosophesScreen> createState() => _SourcesPhilosophesScreenState();
}

class _SourcesPhilosophesScreenState extends State<SourcesPhilosophesScreen> {
  final Set<String> _selectedSources = {};
  bool _isLoading = true;

  final List<Philosopher> _sources = [
    // ANCIENT PHILOSOPHERS
    Philosopher(
      id: 'socrate',
      name: 'Socrates',
      iconPath: 'assets/univers_visuel/socrate.png',
      description: 'Greek philosopher, founder of critical questioning.',
      modeOfThought: 'Maieutics: questioning to reveal inner truth.',
      worldView: 'Truth is sought within oneself through dialogue.',
    ),
    Philosopher(
      id: 'platon',
      name: 'Plato',
      iconPath: 'assets/univers_visuel/platon.png',
      description: 'Greek philosopher, founder of idealism.',
      modeOfThought: 'Return to the essential, quest for truth, separation between illusion and reality.',
      worldView: 'The visible world is only an imperfect copy of the Ideas.',
    ),
    Philosopher(
      id: 'aristote',
      name: 'Aristotle',
      iconPath: 'assets/univers_visuel/aristote.png',
      description: 'Greek philosopher, father of logic and virtue ethics.',
      modeOfThought: 'Logical rigor, observation, classification, virtue through moderation.',
      worldView: 'Reality is analyzed through observation; happiness comes from virtue.',
    ),
    Philosopher(
      id: 'epicure',
      name: 'Epicurus',
      iconPath: 'assets/univers_visuel/epicure.png',
      description: 'Greek philosopher, founder of Epicureanism.',
      modeOfThought: 'Analysis of desires, voluntary sobriety, pursuit of peace.',
      worldView: 'Happiness = absence of suffering + friendships + simplicity.',
    ),

    // STOICS
    Philosopher(
      id: 'seneque',
      name: 'Seneca',
      iconPath: 'assets/univers_visuel/seneque.png',
      description: 'Great Roman Stoic, master of practical wisdom.',
      modeOfThought: 'Mastery of emotions, discipline, refocusing on what depends on us.',
      worldView: 'The world is unstable, but peace comes from within.',
    ),
    Philosopher(
      id: 'epictete',
      name: 'Epictetus',
      iconPath: 'assets/univers_visuel/epictete.png',
      description: 'Slave who became a Stoic philosopher.',
      modeOfThought: 'Radical acceptance, distinction between the controllable and the uncontrollable.',
      worldView: 'Freedom lies in our judgment, not in circumstances.',
    ),
    Philosopher(
      id: 'marc_aurele',
      name: 'Marcus Aurelius',
      iconPath: 'assets/univers_visuel/marc_aurele.png',
      description: 'Philosopher emperor, late Stoic.',
      modeOfThought: 'Lucidity, responsibility, serenity in the face of social role constraints.',
      worldView: 'Everything is part of a greater natural order.',
    ),

    // MODERN PHILOSOPHERS
    Philosopher(
      id: 'spinoza',
      name: 'Spinoza',
      iconPath: 'assets/univers_visuel/spinoza.png',
      description: '17th-century rationalist philosopher, thinker of joy.',
      modeOfThought: 'Rational thought, liberation through understanding affects.',
      worldView: 'God = Nature; everything follows necessary laws.',
    ),
    Philosopher(
      id: 'kant',
      name: 'Kant',
      iconPath: 'assets/univers_visuel/kant.png',
      description: 'German philosopher of moral reason.',
      modeOfThought: 'Rigor, duty, moral coherence, autonomy.',
      worldView: 'The world must be understood through reason and responsibility.',
    ),
    Philosopher(
      id: 'schopenhauer',
      name: 'Schopenhauer',
      iconPath: 'assets/univers_visuel/schopenhauer.png',
      description: 'Philosopher of lucid pessimism.',
      modeOfThought: 'Acceptance, lucidity, subduing the will to ease suffering.',
      worldView: 'The world is blind will, a source of suffering.',
    ),
    Philosopher(
      id: 'nietzsche',
      name: 'Nietzsche',
      iconPath: 'assets/univers_visuel/nietzsche.png',
      description: 'Philosopher of self-overcoming.',
      modeOfThought: 'Self-affirmation, critique of illusions, creation of personal meaning.',
      worldView: 'The world is creative chaos, to be transformed, not endured.',
    ),

    // EXISTENTIALISTS
    Philosopher(
      id: 'kierkegaard',
      name: 'Kierkegaard',
      iconPath: 'assets/univers_visuel/kierkegaard.png',
      description: 'Precursor of Christian existentialism.',
      modeOfThought: 'Inner passion, authenticity, decisive existential choices.',
      worldView: 'The individual stands alone before themselves and their choices.',
    ),
    Philosopher(
      id: 'sartre',
      name: 'Sartre',
      iconPath: 'assets/univers_visuel/sartre.png',
      description: 'French existentialist philosopher, thinker of freedom.',
      modeOfThought: 'Radical freedom, commitment, authenticity, total responsibility.',
      worldView: 'Existence precedes essence; humans are condemned to be free.',
    ),
    Philosopher(
      id: 'simone_de_beauvoir',
      name: 'Simone de Beauvoir',
      iconPath: 'assets/univers_visuel/simonedebeauvoir.png',
      description: 'Existentialist philosopher and feminist.',
      modeOfThought: 'Freedom, responsibility, refusal of imposed roles.',
      worldView: 'Human beings construct themselves through their choices.',
    ),
    Philosopher(
      id: 'camus',
      name: 'Camus',
      iconPath: 'assets/univers_visuel/camus.png',
      description: 'Philosopher of the absurd.',
      modeOfThought: 'Lucid revolt, dignity, presence in the world, refusal of despair.',
      worldView: 'The world is devoid of objective meaning; meaning must be built.',
    ),

    // POLITICAL PHILOSOPHERS
    Philosopher(
      id: 'hannah_arendt',
      name: 'Hannah Arendt',
      iconPath: 'assets/univers_visuel/arendt.png',
      description: '20th-century political philosopher.',
      modeOfThought: 'Civic lucidity, moral vigilance, political humanism.',
      worldView: 'The human world is built through action, dialogue and responsibility.',
    ),

    // EASTERN PHILOSOPHERS
    Philosopher(
      id: 'confucius',
      name: 'Confucius',
      iconPath: 'assets/univers_visuel/confucius.png',
      description: 'Chinese thinker; relational ethics; concepts of Ren, Li, Yi, Xiao; importance of self-cultivation.',
      modeOfThought: 'Case-by-case analysis; moral exemplarity; harmonization of relationships; transformation through study and rites.',
      worldView: 'Human reality is a network of relationships; harmony is built through individual virtue; the Junzi model as an ideal.',
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
      if (profileData != null && profileData['philosophesSelectionnes'] != null) {
        final List<dynamic> saved = profileData['philosophesSelectionnes'];
        setState(() {
          _selectedSources.addAll(saved.cast<String>());
        });
      }
    } catch (e) {
      print('Erreur chargement philosophes: $e');
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

      updatedProfile['philosophesSelectionnes'] = _selectedSources.toList();
      updatedProfile['lastUpdated'] = DateTime.now().toIso8601String();

      await CompleteAuthService.instance.saveProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSources.length} philosopher(s) saved'),
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
      title: 'Philosophers',
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
                            color: const Color(0xFFF59E0B),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _sources.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSourceCard(_sources[index]),
                      );
                    },
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
            'assets/univers_visuel/philosophes.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/univers_visuel/categorie_philosophes.png',
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
                    child: const Icon(Icons.person, size: 60, color: Color(0xFF10B981)),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Philosophers',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the thinkers who inspire you',
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

  Widget _buildSourceCard(Philosopher source) {
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
                                Icons.person,
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

  Widget _buildValidateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveAndReturn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
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

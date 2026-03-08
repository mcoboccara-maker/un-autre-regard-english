import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/complete_auth_service.dart';
import '../../widgets/app_scaffold.dart'; // ✅ NOUVEAU

class PhilosophicalCurrent {
  final String id;
  final String name;
  final String iconPath;
  final String description;
  final String modeOfThought;
  final String worldView;

  const PhilosophicalCurrent({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.modeOfThought,
    required this.worldView,
  });
}

class SourcesPhilosophiquesScreen extends StatefulWidget {
  const SourcesPhilosophiquesScreen({super.key});

  @override
  State<SourcesPhilosophiquesScreen> createState() => _SourcesPhilosophiquesScreenState();
}

class _SourcesPhilosophiquesScreenState extends State<SourcesPhilosophiquesScreen> {
  final Set<String> _selectedSources = {};
  bool _isLoading = true;

  final List<PhilosophicalCurrent> _sources = [
    PhilosophicalCurrent(
      id: 'stoicisme',
      name: 'Stoicism',
      iconPath: 'assets/univers_visuel/stoicisme.png',
      description: 'Ancient philosophy centered on self-mastery.',
      modeOfThought: 'Discernment, self-control, acceptance of fate.',
      worldView: 'Reality must be accepted; only our judgments matter.',
    ),
    PhilosophicalCurrent(
      id: 'epicurisme',
      name: 'Epicureanism',
      iconPath: 'assets/univers_visuel/epicurisme.png',
      description: 'Pursuit of simple pleasure and tranquility.',
      modeOfThought: 'Sorting desires, friendship, sobriety.',
      worldView: 'Happiness comes from the absence of disturbance.',
    ),
    PhilosophicalCurrent(
      id: 'existentialisme_philo',
      name: 'Existentialism',
      iconPath: 'assets/univers_visuel/existentialisme.png',
      description: 'Existence precedes essence.',
      modeOfThought: 'Radical freedom, responsibility.',
      worldView: 'Humans create their meaning through their choices.',
    ),
    PhilosophicalCurrent(
      id: 'humanisme_philo',
      name: 'Humanism',
      iconPath: 'assets/univers_visuel/humanisme.png',
      description: 'Primary value: the human being and their dignity.',
      modeOfThought: 'Ethical reflection, autonomy.',
      worldView: 'Trust in reason and moral progress.',
    ),
    PhilosophicalCurrent(
      id: 'vitalisme',
      name: 'Vitalism',
      iconPath: 'assets/univers_visuel/vitalisme.png',
      description: 'Life rests on an irreducible vital force.',
      modeOfThought: 'Intuition, power of living.',
      worldView: 'Life is creative energy.',
    ),
    PhilosophicalCurrent(
      id: 'absurdisme_philo',
      name: 'Absurdism',
      iconPath: 'assets/univers_visuel/absurdisme.png',
      description: 'The world is devoid of objective meaning.',
      modeOfThought: 'Revolt, lucidity, inner freedom.',
      worldView: 'One can invent meaning despite absurdity.',
    ),
    PhilosophicalCurrent(
      id: 'rationalisme',
      name: 'Rationalism',
      iconPath: 'assets/univers_visuel/rationalisme.png',
      description: 'Reason is the primary source of knowledge.',
      modeOfThought: 'Logical deduction, coherence.',
      worldView: 'Reality is intelligible.',
    ),
    PhilosophicalCurrent(
      id: 'empirisme',
      name: 'Empiricism',
      iconPath: 'assets/univers_visuel/empirisme.png',
      description: 'Knowledge comes from experience.',
      modeOfThought: 'Observation, experimentation.',
      worldView: 'The mind is shaped by perception.',
    ),
    PhilosophicalCurrent(
      id: 'pragmatisme',
      name: 'Pragmatism',
      iconPath: 'assets/univers_visuel/pragmatisme.png',
      description: 'An idea is true if it works.',
      modeOfThought: 'Action, adaptation, results.',
      worldView: 'The true = useful, effective.',
    ),
    PhilosophicalCurrent(
      id: 'phenomenologie',
      name: 'Phenomenology',
      iconPath: 'assets/univers_visuel/phenomenologie.png',
      description: 'Describing lived experience.',
      modeOfThought: 'Attention, fine description of lived experience.',
      worldView: 'The world reveals itself through consciousness.',
    ),
    PhilosophicalCurrent(
      id: 'idealisme',
      name: 'Idealism',
      iconPath: 'assets/univers_visuel/idealisme.png',
      description: 'Reality is grounded in the mind or ideas.',
      modeOfThought: 'Analysis of mental forms.',
      worldView: 'The mind structures reality.',
    ),
    PhilosophicalCurrent(
      id: 'utilitarisme',
      name: 'Utilitarianism',
      iconPath: 'assets/univers_visuel/utilitarisme.png',
      description: 'The good = maximizing collective happiness.',
      modeOfThought: 'Calculation of effects, consequences.',
      worldView: 'Ethics of the greatest good for the greatest number.',
    ),
    PhilosophicalCurrent(
      id: 'structuralisme',
      name: 'Structuralism',
      iconPath: 'assets/univers_visuel/structuralisme.png',
      description: 'Analysis of structures governing thought and culture.',
      modeOfThought: 'Detached analysis, systems, deconstruction.',
      worldView: 'The world is structured by invisible rules.',
    ),
    PhilosophicalCurrent(
      id: 'philosophies_orientales',
      name: 'Eastern Philosophies',
      iconPath: 'assets/univers_visuel/mysticisme.png',
      description: 'Non-dogmatic Asian thought (Taoism, philosophical Buddhism, etc.).',
      modeOfThought: 'Harmony, unity, fluidity, non-attachment.',
      worldView: 'The world is interconnected.',
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
      if (profileData != null && profileData['courantsPhilosophiques'] != null) {
        final List<dynamic> saved = profileData['courantsPhilosophiques'];
        setState(() {
          _selectedSources.addAll(saved.cast<String>());
        });
      }
    } catch (e) {
      print('Erreur chargement courants philosophiques: $e');
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

      updatedProfile['courantsPhilosophiques'] = _selectedSources.toList();
      updatedProfile['lastUpdated'] = DateTime.now().toIso8601String();

      await CompleteAuthService.instance.saveProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSources.length} philosophical current(s) saved'),
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
      title: 'Philosophical Currents',
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
            'assets/univers_visuel/categorie_philosophiques.png',
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
                child: const Icon(Icons.lightbulb_outline, size: 60, color: Color(0xFF10B981)),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Philosophical Currents',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the currents that inspire you',
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

  Widget _buildSourceCard(PhilosophicalCurrent source) {
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
                                Icons.lightbulb_outline,
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
          backgroundColor: const Color(0xFF10B981),
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

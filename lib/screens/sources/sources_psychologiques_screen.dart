import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/complete_auth_service.dart';
import '../../widgets/app_scaffold.dart'; // ✅ NOUVEAU

class PsychologicalSource {
  final String id;
  final String name;
  final String iconPath;
  final String description;
  final String modeOfThought;
  final String worldView;

  const PsychologicalSource({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.modeOfThought,
    required this.worldView,
  });
}

class SourcesPsychologiquesScreen extends StatefulWidget {
  const SourcesPsychologiquesScreen({super.key});

  @override
  State<SourcesPsychologiquesScreen> createState() => _SourcesPsychologiquesScreenState();
}

class _SourcesPsychologiquesScreenState extends State<SourcesPsychologiquesScreen> {
  final Set<String> _selectedSources = {};
  bool _isLoading = true;

  final List<PsychologicalSource> _sources = [
    PsychologicalSource(
      id: 'act',
      name: 'ACT (Acceptance & Commitment)',
      iconPath: 'assets/univers_visuel/act.png',
      description: 'Therapy based on acceptance and value-aligned action.',
      modeOfThought: 'Acceptance, cognitive defusion, value-driven actions.',
      worldView: 'Suffering is part of life, but commitment gives it meaning.',
    ),
    PsychologicalSource(
      id: 'tcc',
      name: 'CBT (Cognitive Behavioral Therapy)',
      iconPath: 'assets/univers_visuel/TCC.png',
      description: 'Therapy focused on identifying and modifying dysfunctional thoughts.',
      modeOfThought: 'Cognitive restructuring, behavioral experiments.',
      worldView: 'Thoughts influence emotions and behaviors.',
    ),
    PsychologicalSource(
      id: 'jungienne',
      name: 'Jungian Psychology',
      iconPath: 'assets/univers_visuel/jungienne.png',
      description: 'Approach based on archetypes, symbolism and the collective unconscious.',
      modeOfThought: 'Dreams, myths, symbols, individuation.',
      worldView: 'The psyche is a symbolic system to explore.',
    ),
    PsychologicalSource(
      id: 'logotherapie',
      name: 'Logotherapy (Frankl)',
      iconPath: 'assets/univers_visuel/logotherapie_frankl.png',
      description: 'Therapy centered on the quest for meaning as an existential driver.',
      modeOfThought: 'Value orientation, responsibility, personal meaning.',
      worldView: 'Meaning can be found in any situation, even suffering.',
    ),
    PsychologicalSource(
      id: 'schemas_young',
      name: 'Schema Therapy (Young)',
      iconPath: 'assets/univers_visuel/schemas_young.png',
      description: 'Identifies early schemas that influence present reactions.',
      modeOfThought: 'Reparenting, dialogues, deep emotional work.',
      worldView: 'Childhood experiences shape emotional schemas.',
    ),
    PsychologicalSource(
      id: 'the_work',
      name: 'The Work (Byron Katie)',
      iconPath: 'assets/univers_visuel/theworkkb.png',
      description: 'Process of questioning stressful thoughts to return to reality.',
      modeOfThought: 'Observing a thought > 4 questions > turnarounds.',
      worldView: 'Suffering comes from resistance to reality.',
    ),
    PsychologicalSource(
      id: 'humaniste_rogers',
      name: 'Humanistic Approach (Rogers)',
      iconPath: 'assets/univers_visuel/approche_humaniste.png',
      description: 'Person-centered approach based on benevolence.',
      modeOfThought: 'Empathy, authenticity, non-judgment.',
      worldView: 'Every individual has a natural tendency to grow.',
    ),
    PsychologicalSource(
      id: 'psychanalyse',
      name: 'Psychoanalysis',
      iconPath: 'assets/univers_visuel/psychanalyse.png',
      description: 'Exploration of the unconscious, drives and internal conflicts.',
      modeOfThought: 'Free association, dream analysis, transference, interpretation.',
      worldView: 'The unconscious determines our behaviors; understanding it liberates.',
    ),
    PsychologicalSource(
      id: 'analyse_transactionnelle',
      name: 'Transactional Analysis',
      iconPath: 'assets/univers_visuel/analyse_transactionnelle.png',
      description: 'Model of ego states (Parent, Adult, Child) and transactions.',
      modeOfThought: 'Identification of ego states, analysis of psychological games, life scripts.',
      worldView: 'We are influenced by modifiable relational patterns.',
    ),
    PsychologicalSource(
      id: 'systemique',
      name: 'Systemic Approach',
      iconPath: 'assets/univers_visuel/approche_systemique.png',
      description: 'View of problems within the context of relational systems.',
      modeOfThought: 'Interaction analysis, feedback loops, reframing.',
      worldView: 'The individual is part of a system; changing one element changes the whole.',
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
      if (profileData != null && profileData['approchesPsychologiques'] != null) {
        final List<dynamic> saved = profileData['approchesPsychologiques'];
        setState(() {
          _selectedSources.addAll(saved.cast<String>());
        });
      }
    } catch (e) {
      print('Erreur chargement sources psychologiques: $e');
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

      updatedProfile['approchesPsychologiques'] = _selectedSources.toList();
      updatedProfile['lastUpdated'] = DateTime.now().toIso8601String();

      await CompleteAuthService.instance.saveProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSources.length} psychological approach(es) saved'),
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
      title: 'Psychological Approaches',
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
                            color: const Color(0xFF0EA5E9),
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
            'assets/univers_visuel/categorie_psychologiques.png',
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
                child: const Icon(Icons.psychology, size: 60, color: Color(0xFF10B981)),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Psychological Approaches',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the approaches that resonate with you',
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

  Widget _buildSourceCard(PsychologicalSource source) {
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
                                Icons.psychology,
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
          backgroundColor: const Color(0xFF0EA5E9),
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

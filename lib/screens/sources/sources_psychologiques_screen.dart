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
      iconPath: 'assets/univers_visuel/pleine_conscience.png',
      description: 'Thérapie basée sur l\'acceptation et l\'action alignée avec les valeurs.',
      modeOfThought: 'Acceptation, défusion cognitive, actions guidées par les valeurs.',
      worldView: 'La souffrance fait partie de la vie, mais l\'engagement donne du sens.',
    ),
    PsychologicalSource(
      id: 'tcc',
      name: 'TCC (Thérapie Cognitive Comportementale)',
      iconPath: 'assets/univers_visuel/TCC.png',
      description: 'Thérapie centrée sur l\'identification et la modification des pensées dysfonctionnelles.',
      modeOfThought: 'Restructuration cognitive, expériences comportementales.',
      worldView: 'Les pensées influencent émotions et comportements.',
    ),
    PsychologicalSource(
      id: 'jungienne',
      name: 'Psychologie Jungienne',
      iconPath: 'assets/univers_visuel/jungienne.png',
      description: 'Approche basée sur les archétypes, le symbolique, l\'inconscient collectif.',
      modeOfThought: 'Rêves, mythes, symboles, individuation.',
      worldView: 'La psyché est un système symbolique à explorer.',
    ),
    PsychologicalSource(
      id: 'logotherapie',
      name: 'Logothérapie (Frankl)',
      iconPath: 'assets/univers_visuel/logotherapie_frankl.png',
      description: 'Thérapie centrée sur la quête de sens comme moteur existentiel.',
      modeOfThought: 'Orientation vers les valeurs, responsabilité, sens personnel.',
      worldView: 'Le sens peut être trouvé dans toute situation, même la souffrance.',
    ),
    PsychologicalSource(
      id: 'schemas_young',
      name: 'Thérapie des schémas (Young)',
      iconPath: 'assets/univers_visuel/schemas_young.png',
      description: 'Identifie des schémas précoces qui influencent les réactions présentes.',
      modeOfThought: 'Reparentage, dialogues, travail émotionnel profond.',
      worldView: 'Les expériences d\'enfance façonnent les schémas émotionnels.',
    ),
    PsychologicalSource(
      id: 'the_work',
      name: 'The Work (Byron Katie)',
      iconPath: 'assets/univers_visuel/theworkkb.png',
      description: 'Processus de questionnement des pensées stressantes pour revenir au réel.',
      modeOfThought: 'Observation d\'une pensée → 4 questions → retournements.',
      worldView: 'La souffrance vient de la résistance à la réalité.',
    ),
    PsychologicalSource(
      id: 'humaniste_rogers',
      name: 'Approche Humaniste (Rogers)',
      iconPath: 'assets/univers_visuel/humanisme_philo.png',
      description: 'Approche centrée sur la personne et la bienveillance.',
      modeOfThought: 'Empathie, authenticité, non-jugement.',
      worldView: 'Chaque individu a une tendance naturelle à croître.',
    ),
    PsychologicalSource(
      id: 'psychanalyse',
      name: 'Psychanalyse',
      iconPath: 'assets/univers_visuel/psychanalyse.png',
      description: 'Exploration de l\'inconscient, des pulsions et des conflits internes.',
      modeOfThought: 'Association libre, analyse des rêves, transfert, interprétation.',
      worldView: 'L\'inconscient détermine nos comportements ; le comprendre libère.',
    ),
    PsychologicalSource(
      id: 'analyse_transactionnelle',
      name: 'Analyse Transactionnelle',
      iconPath: 'assets/univers_visuel/analyse_transactionnelle.png',
      description: 'Modèle des états du moi (Parent, Adulte, Enfant) et des transactions.',
      modeOfThought: 'Identification des états du moi, analyse des jeux psychologiques, scénarios de vie.',
      worldView: 'Nous sommes influencés par des schémas relationnels modifiables.',
    ),
    PsychologicalSource(
      id: 'systemique',
      name: 'Approche Systémique',
      iconPath: 'assets/univers_visuel/systemique.png',
      description: 'Vision des problèmes dans le contexte des systèmes relationnels.',
      modeOfThought: 'Analyse des interactions, boucles de rétroaction, recadrage.',
      worldView: 'L\'individu fait partie d\'un système ; changer un élément change le tout.',
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
            content: Text('${_selectedSources.length} approche(s) psychologique(s) enregistrée(s)'),
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
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Approches Psychologiques',
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
                            '${_selectedSources.length} sélectionnée(s)',
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
                    '${_selectedSources.length} sélectionnée(s)',
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
            'Approches Psychologiques',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Choisissez les approches qui vous correspondent',
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
                              isSelected ? 'Choisi' : 'Choisir',
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
                      'Mode de pensée',
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
                      'Vision du monde',
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
          'Valider mes choix',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

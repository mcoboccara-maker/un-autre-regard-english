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
      name: 'Stoïcisme',
      iconPath: 'assets/univers_visuel/stoicisme.png',
      description: 'Philosophie antique centrée sur la maîtrise de soi.',
      modeOfThought: 'Discernement, contrôle de soi, acceptation du destin.',
      worldView: 'Le réel doit être accepté ; seuls nos jugements comptent.',
    ),
    PhilosophicalCurrent(
      id: 'epicurisme',
      name: 'Épicurisme',
      iconPath: 'assets/univers_visuel/epicurisme.png',
      description: 'Recherche du plaisir simple et de la tranquillité.',
      modeOfThought: 'Tri des désirs, amitié, sobriété.',
      worldView: 'Le bonheur vient de l\'absence de troubles.',
    ),
    PhilosophicalCurrent(
      id: 'existentialisme_philo',
      name: 'Existentialisme',
      iconPath: 'assets/univers_visuel/existentialisme.png',
      description: 'L\'existence précède l\'essence.',
      modeOfThought: 'Liberté radicale, responsabilité.',
      worldView: 'L\'humain crée son sens par ses choix.',
    ),
    PhilosophicalCurrent(
      id: 'humanisme_philo',
      name: 'Humanisme',
      iconPath: 'assets/univers_visuel/humanisme.png',
      description: 'Valeur première : l\'humain et sa dignité.',
      modeOfThought: 'Réflexion éthique, autonomie.',
      worldView: 'Confiance en la raison et le progrès moral.',
    ),
    PhilosophicalCurrent(
      id: 'vitalisme',
      name: 'Vitalisme',
      iconPath: 'assets/univers_visuel/vitalisme.png',
      description: 'La vie repose sur une force vitale non réductible.',
      modeOfThought: 'Intuition, puissance de vivre.',
      worldView: 'La vie est énergie créatrice.',
    ),
    PhilosophicalCurrent(
      id: 'absurdisme_philo',
      name: 'Absurdisme',
      iconPath: 'assets/univers_visuel/absurdisme.png',
      description: 'Le monde est dépourvu de sens objectif.',
      modeOfThought: 'Révolte, lucidité, liberté intérieure.',
      worldView: 'On peut inventer un sens malgré l\'absurdité.',
    ),
    PhilosophicalCurrent(
      id: 'rationalisme',
      name: 'Rationalisme',
      iconPath: 'assets/univers_visuel/rationalisme.png',
      description: 'La raison est la source principale de connaissance.',
      modeOfThought: 'Déduction logique, cohérence.',
      worldView: 'Le réel est intelligible.',
    ),
    PhilosophicalCurrent(
      id: 'empirisme',
      name: 'Empirisme',
      iconPath: 'assets/univers_visuel/empirisme.png',
      description: 'La connaissance vient de l\'expérience.',
      modeOfThought: 'Observation, expérimentation.',
      worldView: 'L\'esprit est modulé par la perception.',
    ),
    PhilosophicalCurrent(
      id: 'pragmatisme',
      name: 'Pragmatisme',
      iconPath: 'assets/univers_visuel/pragmatisme.png',
      description: 'Une idée est vraie si elle fonctionne.',
      modeOfThought: 'Action, adaptation, résultats.',
      worldView: 'Le vrai = utile, efficace.',
    ),
    PhilosophicalCurrent(
      id: 'phenomenologie',
      name: 'Phénoménologie',
      iconPath: 'assets/univers_visuel/phenomenologie.png',
      description: 'Décrire l\'expérience vécue.',
      modeOfThought: 'Attention, description fine du vécu.',
      worldView: 'Le monde se donne dans la conscience.',
    ),
    PhilosophicalCurrent(
      id: 'idealisme',
      name: 'Idéalisme',
      iconPath: 'assets/univers_visuel/idealisme.png',
      description: 'Le réel est fondé dans l\'esprit ou les idées.',
      modeOfThought: 'Analyse des formes mentales.',
      worldView: 'L\'esprit structure la réalité.',
    ),
    PhilosophicalCurrent(
      id: 'utilitarisme',
      name: 'Utilitarisme',
      iconPath: 'assets/univers_visuel/utilitarisme.png',
      description: 'Le bien = maximiser le bonheur collectif.',
      modeOfThought: 'Calcul des effets, conséquences.',
      worldView: 'Éthique du plus grand bien pour le plus grand nombre.',
    ),
    PhilosophicalCurrent(
      id: 'structuralisme',
      name: 'Structuralisme',
      iconPath: 'assets/univers_visuel/structuralisme.png',
      description: 'Analyse des structures qui régissent pensée et culture.',
      modeOfThought: 'Analyse froide, systèmes, déconstruction.',
      worldView: 'Le monde est structuré par des règles invisibles.',
    ),
    PhilosophicalCurrent(
      id: 'philosophies_orientales',
      name: 'Philosophies orientales',
      iconPath: 'assets/univers_visuel/mysticisme.png',
      description: 'Pensées asiatiques non dogmatiques (taoïsme, bouddhisme philosophique, etc.).',
      modeOfThought: 'Harmonie, unité, fluidité, non-attachement.',
      worldView: 'Le monde est interconnecté.',
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
            content: Text('${_selectedSources.length} courant(s) philosophique(s) enregistré(s)'),
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
      title: 'Courants Philosophiques',
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
                            '${_selectedSources.length} sélectionné(s)',
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
                    '${_selectedSources.length} sélectionné(s)',
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
            'Courants Philosophiques',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Choisissez les courants qui vous inspirent',
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
          backgroundColor: const Color(0xFF10B981),
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

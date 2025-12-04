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

  final List<LiterarySource> _sources = [
    LiterarySource(
      id: 'romantisme',
      name: 'Romantisme',
      iconPath: 'assets/univers_visuel/romantisme.png',
      description: 'Mouvement du XIXᵉ valorisant l\'expression des émotions, la nature et l\'individu.',
      modeOfThought: 'Primauté du cœur, sensibilité exacerbée, quête d\'intensité.',
      worldView: 'Le monde est un miroir de l\'âme ; le destin personnel est central.',
    ),
    LiterarySource(
      id: 'realisme',
      name: 'Réalisme',
      iconPath: 'assets/univers_visuel/realisme.png',
      description: 'Courant du XIXᵉ cherchant à représenter la réalité sociale telle qu\'elle est.',
      modeOfThought: 'Observation minutieuse, rationalité, lucidité sociale.',
      worldView: 'Le monde est dur, structuré par classes sociales, contraintes matérielles.',
    ),
    LiterarySource(
      id: 'naturalisme',
      name: 'Naturalisme',
      iconPath: 'assets/univers_visuel/naturalisme.png',
      description: 'Version radicalisée du réalisme, influencée par la science et le déterminisme.',
      modeOfThought: 'Analyse des hérédités, des instincts, des milieux ; approche quasi-scientifique.',
      worldView: 'Le monde détermine les individus, les choix sont limités.',
    ),
    LiterarySource(
      id: 'symbolisme',
      name: 'Symbolisme',
      iconPath: 'assets/univers_visuel/symbolisme.png',
      description: 'Mouvement de la fin du XIXᵉ explorant le rêve, l\'allégorie, les symboles.',
      modeOfThought: 'Intuition, mystère, langage poétique suggestif.',
      worldView: 'Le réel est un voile ; les vérités profondes sont cachées.',
    ),
    LiterarySource(
      id: 'surrealisme',
      name: 'Surréalisme',
      iconPath: 'assets/univers_visuel/surrealisme.png',
      description: 'Mouvement du XXᵉ centré sur l\'inconscient, le rêve, l\'imaginaire sans censure.',
      modeOfThought: 'Association libre, rupture avec la logique, exploration intérieure.',
      worldView: 'Le monde est un espace à libérer des contraintes mentales.',
    ),
    LiterarySource(
      id: 'existentialisme',
      name: 'Existentialisme',
      iconPath: 'assets/univers_visuel/existentialisme.png',
      description: 'Littérature centrée sur la liberté, la responsabilité et l\'angoisse existentielle.',
      modeOfThought: 'Questionnement éthique, lucidité radicale, recherche d\'authenticité.',
      worldView: 'Le monde n\'a pas de sens donné : l\'individu doit créer le sien.',
    ),
    LiterarySource(
      id: 'humanisme',
      name: 'Humanisme',
      iconPath: 'assets/univers_visuel/humanisme.png',
      description: 'Courant valorisant la dignité humaine, la raison et l\'épanouissement.',
      modeOfThought: 'Réflexion rationnelle, optimisme mesuré, contemplation morale.',
      worldView: 'Le monde est perfectible grâce à la pensée et au dialogue.',
    ),
    LiterarySource(
      id: 'absurdisme',
      name: 'Absurdisme',
      iconPath: 'assets/univers_visuel/absurdisme.png',
      description: 'Mouvement abordant l\'insensé de la condition humaine et la quête de sens impossible.',
      modeOfThought: 'Ironie, lucidité, confrontation au vide existentiel.',
      worldView: 'Le monde est absurde mais l\'humain peut y opposer sa dignité.',
    ),
    LiterarySource(
      id: 'modernisme',
      name: 'Modernisme',
      iconPath: 'assets/univers_visuel/modernisme.png',
      description: 'Courant littéraire du début XXᵉ bouleversant les formes classiques.',
      modeOfThought: 'Fragmentation du récit, subjectivité, introspection.',
      worldView: 'La réalité est multiple, instable, subjective.',
    ),
    LiterarySource(
      id: 'postmodernisme',
      name: 'Postmodernisme',
      iconPath: 'assets/univers_visuel/postmodernisme.png',
      description: 'Mouvement jouant avec les codes, la pluralité des vérités, les récits entrecroisés.',
      modeOfThought: 'Ironie, mélange des genres, remise en cause des méta-récits.',
      worldView: 'Le monde est complexe, hybride, sans centre unique.',
    ),
    LiterarySource(
      id: 'tragedie_classique',
      name: 'Tragédie classique',
      iconPath: 'assets/univers_visuel/tragedie_classique.png',
      description: 'Genre dramatique explorant le destin, la fatalité et les passions humaines.',
      modeOfThought: 'Catharsis, confrontation au destin, noblesse face à l\'inévitable.',
      worldView: 'L\'homme est soumis à des forces qui le dépassent ; la grandeur est dans l\'acceptation.',
    ),
    LiterarySource(
      id: 'roman_psychologique',
      name: 'Roman psychologique',
      iconPath: 'assets/univers_visuel/roman_psychologique.png',
      description: 'Genre littéraire centré sur l\'analyse fine des états intérieurs.',
      modeOfThought: 'Introspection, nuances émotionnelles, complexité des motivations.',
      worldView: 'La vérité se trouve dans les profondeurs de la psyché humaine.',
    ),
    LiterarySource(
      id: 'mythologie',
      name: 'Mythologie',
      iconPath: 'assets/univers_visuel/mythologie.png',
      description: 'Récits fondateurs explorant les archétypes universels de l\'humanité.',
      modeOfThought: 'Symbolisme, récits initiatiques, épreuves transformatrices.',
      worldView: 'Le monde est animé par des forces archétypales ; les mythes éclairent notre condition.',
    ),
    LiterarySource(
      id: 'science_fiction',
      name: 'Science-fiction',
      iconPath: 'assets/univers_visuel/science_fiction.png',
      description: 'Genre explorant les futurs possibles et les implications de la technologie.',
      modeOfThought: 'Extrapolation, questionnement éthique, imagination prospective.',
      worldView: 'Le futur est un miroir de nos choix présents ; la technologie transforme l\'humain.',
    ),
    LiterarySource(
      id: 'fantasy',
      name: 'Fantasy',
      iconPath: 'assets/univers_visuel/fantasy.png',
      description: 'Genre imaginaire explorant des mondes magiques et des quêtes héroïques.',
      modeOfThought: 'Voyage initiatique, combat du bien contre le mal, transformation intérieure.',
      worldView: 'Le monde recèle des dimensions cachées ; l\'héroïsme révèle notre vraie nature.',
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
            content: Text('${_selectedSources.length} courant(s) littéraire(s) enregistré(s)'),
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
      title: 'Courants Littéraires',
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
            'Courants Littéraires',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Choisissez les courants qui vous parlent',
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
          backgroundColor: const Color(0xFFEC4899),
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

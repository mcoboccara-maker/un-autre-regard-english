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
    // PHILOSOPHES ANTIQUES
    Philosopher(
      id: 'socrate',
      name: 'Socrate',
      iconPath: 'assets/univers_visuel/socrate.png',
      description: 'Philosophe grec fondateur du questionnement critique.',
      modeOfThought: 'Maïeutique : questionner pour révéler la vérité intérieure.',
      worldView: 'La vérité se cherche en soi-même à travers le dialogue.',
    ),
    Philosopher(
      id: 'platon',
      name: 'Platon',
      iconPath: 'assets/univers_visuel/platon.png',
      description: 'Philosophe grec fondateur de l\'idéalisme.',
      modeOfThought: 'Retour vers l\'essentiel, quête de vérité, séparation entre illusion et réalité.',
      worldView: 'Le réel visible n\'est qu\'une copie imparfaite des Idées.',
    ),
    Philosopher(
      id: 'aristote',
      name: 'Aristote',
      iconPath: 'assets/univers_visuel/aristote.png',
      description: 'Philosophe grec, père de la logique et de l\'éthique de la vertu.',
      modeOfThought: 'Rigueur logique, observation, classification, vertu par mesure.',
      worldView: 'Le réel s\'analyse par observation ; le bonheur vient de la vertu.',
    ),
    Philosopher(
      id: 'epicure',
      name: 'Épicure',
      iconPath: 'assets/univers_visuel/epicure.png',
      description: 'Philosophe grec fondateur de l\'épicurisme.',
      modeOfThought: 'Analyse des désirs, sobriété volontaire, recherche de paix.',
      worldView: 'Le bonheur = absence de souffrance + amitiés + simplicité.',
    ),
    
    // STOÏCIENS
    Philosopher(
      id: 'seneque',
      name: 'Sénèque',
      iconPath: 'assets/univers_visuel/seneque.png',
      description: 'Grand stoïcien romain, maître de la sagesse pratique.',
      modeOfThought: 'Maîtrise des émotions, discipline, recentrage sur ce qui dépend de soi.',
      worldView: 'Le monde est instable, mais la paix vient de l\'intérieur.',
    ),
    Philosopher(
      id: 'epictete',
      name: 'Épictète',
      iconPath: 'assets/univers_visuel/epictete.png',
      description: 'Esclave devenu philosophe stoïcien.',
      modeOfThought: 'Acceptation radicale, distinction entre le contrôlable et l\'incontrôlable.',
      worldView: 'La liberté réside dans notre jugement, pas dans les circonstances.',
    ),
    Philosopher(
      id: 'marc_aurele',
      name: 'Marc Aurèle',
      iconPath: 'assets/univers_visuel/marc_aurele.png',
      description: 'Empereur philosophe, stoïcien tardif.',
      modeOfThought: 'Lucidité, responsabilité, sérénité face aux contraintes du rôle social.',
      worldView: 'Tout fait partie d\'un ordre naturel plus vaste.',
    ),
    
    // PHILOSOPHES MODERNES
    Philosopher(
      id: 'spinoza',
      name: 'Spinoza',
      iconPath: 'assets/univers_visuel/spinoza.png',
      description: 'Philosophe rationaliste du XVIIe siècle, penseur de la joie.',
      modeOfThought: 'Pensée rationnelle, libération par la compréhension des affects.',
      worldView: 'Dieu = Nature ; tout suit des lois nécessaires.',
    ),
    Philosopher(
      id: 'kant',
      name: 'Kant',
      iconPath: 'assets/univers_visuel/kant.png',
      description: 'Philosophe allemand de la raison morale.',
      modeOfThought: 'Rigueur, devoir, cohérence morale, autonomie.',
      worldView: 'Le monde doit être compris par la raison et la responsabilité.',
    ),
    Philosopher(
      id: 'schopenhauer',
      name: 'Schopenhauer',
      iconPath: 'assets/univers_visuel/schopenhauer.png',
      description: 'Philosophe du pessimisme lucide.',
      modeOfThought: 'Acceptation, lucidité, estomper le vouloir pour apaiser la souffrance.',
      worldView: 'Le monde est volonté aveugle, source de souffrance.',
    ),
    Philosopher(
      id: 'nietzsche',
      name: 'Nietzsche',
      iconPath: 'assets/univers_visuel/nietzsche.png',
      description: 'Philosophe du dépassement de soi.',
      modeOfThought: 'Affirmation de soi, critique des illusions, création de sens personnel.',
      worldView: 'Le monde est chaos créateur, à transformer, pas à subir.',
    ),
    
    // EXISTENTIALISTES
    Philosopher(
      id: 'kierkegaard',
      name: 'Kierkegaard',
      iconPath: 'assets/univers_visuel/kierkegaard.png',
      description: 'Précurseur de l\'existentialisme chrétien.',
      modeOfThought: 'Passion intérieure, authenticité, choix existentiels décisifs.',
      worldView: 'L\'individu est seul face à lui-même et à ses choix.',
    ),
    Philosopher(
      id: 'sartre',
      name: 'Sartre',
      iconPath: 'assets/univers_visuel/sartre.png',
      description: 'Philosophe existentialiste français, penseur de la liberté.',
      modeOfThought: 'Liberté radicale, engagement, authenticité, responsabilité totale.',
      worldView: 'L\'existence précède l\'essence ; l\'humain est condamné à être libre.',
    ),
    Philosopher(
      id: 'simone_de_beauvoir',
      name: 'Simone de Beauvoir',
      iconPath: 'assets/univers_visuel/simonedebeauvoir.png',
      description: 'Philosophe existentialiste et féministe.',
      modeOfThought: 'Liberté, responsabilité, refus des rôles imposés.',
      worldView: 'L\'être humain se construit par ses choix.',
    ),
    Philosopher(
      id: 'camus',
      name: 'Camus',
      iconPath: 'assets/univers_visuel/camus.png',
      description: 'Philosophe de l\'absurde.',
      modeOfThought: 'Révolte lucide, dignité, présence au monde, refus du désespoir.',
      worldView: 'Le monde est dénué de sens objectif ; le sens est à construire.',
    ),
    
    // PHILOSOPHES POLITIQUES
    Philosopher(
      id: 'hannah_arendt',
      name: 'Hannah Arendt',
      iconPath: 'assets/univers_visuel/arendt.png',
      description: 'Philosophe politique du XXe siècle.',
      modeOfThought: 'Lucidité civique, vigilance morale, humanisme politique.',
      worldView: 'Le monde humain se construit par l\'action, le dialogue et la responsabilité.',
    ),
    
    // PHILOSOPHES ORIENTAUX
    Philosopher(
      id: 'confucius',
      name: 'Confucius',
      iconPath: 'assets/univers_visuel/confucius.png',
      description: 'Penseur chinois ; éthique relationnelle ; notions de Ren, Li, Yi, Xiao ; importance de l\'auto-cultivation.',
      modeOfThought: 'Analyse du cas précis ; exemplarité morale ; harmonisation des relations ; transformation par l\'étude et les rites.',
      worldView: 'La réalité humaine est un réseau de relations ; l\'harmonie se construit par la vertu individuelle ; le modèle du Junzi comme idéal.',
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
            content: Text('${_selectedSources.length} philosophe(s) enregistré(s)'),
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
      title: 'Philosophes',
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
            'Philosophes',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Choisissez les penseurs qui vous inspirent',
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
          backgroundColor: const Color(0xFFF59E0B),
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

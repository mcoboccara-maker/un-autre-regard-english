import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/complete_auth_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/app_scaffold.dart'; // ✅ NOUVEAU

class SourcesSpirituellesScreen extends StatefulWidget {
  const SourcesSpirituellesScreen({super.key});

  @override
  State<SourcesSpirituellesScreen> createState() => _SourcesSpirituellesScreenState();
}

class _SourcesSpirituellesScreenState extends State<SourcesSpirituellesScreen> {
  // Liste des spiritualités sélectionnées
  Set<String> _selectedSources = {};
  bool _isLoading = true;

  // Données des sources spirituelles
  final List<SpiritualSource> _sources = [
    SpiritualSource(
      id: 'judaisme_rabbinique',
      name: 'Judaïsme rabbinique',
      iconPath: 'assets/univers_visuel/judaisme rabbinique akiva.png',
      description: 'Tradition issue de la Torah et du Talmud, structurée autour de l\'étude, de la loi (Halakha) et de l\'interprétation rabbinique.',
      modeOfThought: 'Centralité du texte, dialogue entre la loi et l\'expérience humaine ; importance de la responsabilité individuelle et collective.',
      worldView: 'Le monde est un lieu où l\'être humain participe à réparer l\'imperfection (Tikkoun Olam) ; Dieu agit à travers l\'histoire.',
    ),
    SpiritualSource(
      id: 'moussar',
      name: 'Moussar (éthique juive)',
      iconPath: 'assets/univers_visuel/moussar.png',
      description: 'Courant éthique du judaïsme né au XIXe siècle, centré sur le raffinement moral et émotionnel.',
      modeOfThought: 'Travail intérieur, observation de soi, transformation progressive par la conscience et la pratique.',
      worldView: 'Le monde est un terrain d\'entraînement pour l\'âme ; chaque émotion ou situation révèle une opportunité de croissance.',
    ),
    SpiritualSource(
      id: 'kabbale',
      name: 'Kabbale (mystique juive)',
      iconPath: 'assets/univers_visuel/kabale.png',
      description: 'Tradition mystique qui explore les dimensions cachées du divin, l\'arbre des Sephirot, et les énergies qui structurent la réalité.',
      modeOfThought: 'Vision symbolique, recherche des causes invisibles, lecture métaphorique et profonde des expériences.',
      worldView: 'Le monde est une émanation fragmentée du divin ; l\'être humain participe à l\'unification spirituelle.',
    ),
    SpiritualSource(
      id: 'christianisme',
      name: 'Christianisme',
      iconPath: 'assets/univers_visuel/christianisme.png',
      description: 'Tradition fondée sur la vie et l\'enseignement de Jésus, centrée sur l\'amour, le pardon et la relation personnelle avec Dieu.',
      modeOfThought: 'Perspective morale et relationnelle : transformation par l\'amour, la grâce, la compassion.',
      worldView: 'Le monde est un chemin vers la réconciliation spirituelle ; la souffrance peut devenir lieu de sens.',
    ),
    SpiritualSource(
      id: 'islam',
      name: 'Islam',
      iconPath: 'assets/univers_visuel/islam.png',
      description: 'Tradition fondée sur le Coran et les enseignements du Prophète, structurée par une relation harmonieuse entre foi, pratique et communauté (Ummah).',
      modeOfThought: 'Soumission confiante à Dieu (Allah), discipline intérieure et extérieure, recherche de justice et de paix.',
      worldView: 'Le monde est signe (ayat), chaque événement porte un enseignement ; l\'équilibre spirituel et moral mène à la paix intérieure.',
    ),
    SpiritualSource(
      id: 'soufisme',
      name: 'Soufisme (mystique musulmane)',
      iconPath: 'assets/univers_visuel/soufisme.png',
      description: 'Courant intérieur de l\'Islam visant la proximité intime avec Dieu par l\'amour, l\'humilité et la purification du cœur.',
      modeOfThought: 'Vision poétique, symbolique, basée sur la quête intérieure, l\'union au divin et le dépouillement de l\'ego.',
      worldView: 'Le monde est un miroir ; ce que l\'on vit révèle le chemin vers le cœur. Le divin se trouve dans l\'expérience intime.',
    ),
    SpiritualSource(
      id: 'bouddhisme',
      name: 'Bouddhisme',
      iconPath: 'assets/univers_visuel/boudhisme.png',
      description: 'Tradition fondée sur l\'enseignement du Bouddha visant à réduire la souffrance en comprenant la nature de l\'esprit et de l\'attachement.',
      modeOfThought: 'Observation, non-attachement, pleine conscience, transformation progressive par l\'expérience directe.',
      worldView: 'Le monde est impermanent ; la souffrance vient de l\'attente, non de l\'événement. La liberté est intérieure.',
    ),
    SpiritualSource(
      id: 'hindouisme',
      name: 'Hindouisme',
      iconPath: 'assets/univers_visuel/hindouisme.png',
      description: 'Ensemble de traditions spirituelles originaires de l\'Inde, centrées sur le dharma, le karma et la quête de libération (moksha).',
      modeOfThought: 'Acceptation des cycles de vie, recherche de l\'unité entre l\'âme individuelle (Atman) et l\'absolu (Brahman).',
      worldView: 'Le monde est une manifestation divine (maya) ; chaque être est en chemin vers la réalisation de sa vraie nature.',
    ),
    // Stoïcisme retiré - déplacé vers courants philosophiques
    SpiritualSource(
      id: 'spiritualite_contemporaine',
      name: 'Spiritualité contemporaine / laïque',
      iconPath: 'assets/univers_visuel/contemporaine_et_laique.png',
      description: 'Ensemble de pratiques modernes non dogmatiques inspirées de psychologie, méditation, développement personnel, symbolisme ou traditions diverses.',
      modeOfThought: 'Approche expérimentale, introspective, souvent émotionnelle ; priorité donnée au bien-être, à la sensibilité et à la conscience de soi.',
      worldView: 'Le monde est un espace d\'expérience et d\'évolution personnelle ; l\'important est l\'authenticité et la présence.',
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
      if (profileData != null) {
        final profile = UserProfile.fromJson(profileData);
        setState(() {
          _selectedSources = Set.from(profile.religionsSelectionnees);
        });
      }
    } catch (e) {
      print('Erreur chargement sources: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndReturn() async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile();
      if (profileData != null) {
        final profile = UserProfile.fromJson(profileData);
        final updatedProfile = profile.copyWith(
          religionsSelectionnees: _selectedSources.toList(),
          lastUpdated: DateTime.now(),
        );
        await CompleteAuthService.instance.saveProfile(updatedProfile.toJson());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _selectedSources.isEmpty 
                    ? 'Aucune source spirituelle sélectionnée'
                    : '${_selectedSources.length} source(s) spirituelle(s) enregistrée(s)',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sources Spirituelles',
      showMenuButton: true,
      showPositiveButton: true,
      showBackButton: true, // ✅ Bouton retour EN HAUT du bouton Valider
      bottomAction: _buildValidateButton(), // ✅ Bouton Valider EN BAS
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
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
                            color: const Color(0xFF6366F1),
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
                
                // Liste scrollable
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
          // Barre de navigation
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(),
              // Badge nombre de sélections
              if (_selectedSources.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
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
          
          // Icône centrale spiritualités - GRANDE
          Image.asset(
            'assets/univers_visuel/spiritualites.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              // Essayer avec l'accent si sans accent échoue
              return Image.asset(
                'assets/univers_visuel/spiritualités.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, size: 60, color: Color(0xFF6366F1)),
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Sources Spirituelles',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Choisissez les traditions qui vous inspirent',
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

  Widget _buildSourceCard(SpiritualSource source) {
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
            // Zone icône cliquable à gauche
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
                      // Icône avec halo si sélectionné
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
                                Icons.auto_awesome,
                                color: Color(0xFF10B981),
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bouton Choisir/Choisi
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
            
            // Contenu à droite - aligné à gauche
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de la source
                    Text(
                      source.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description - alignée sur le titre
                    Text(
                      source.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Mode de pensée - titre en dégradé vert
                    Text(
                      'Mode de pensée',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981), // Vert
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
                    
                    // Vision du monde - titre en dégradé vert plus foncé
                    Text(
                      'Vision du monde',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669), // Vert plus foncé
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
          backgroundColor: const Color(0xFF6366F1),
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

// Modèle de données pour une source spirituelle
class SpiritualSource {
  final String id;
  final String name;
  final String iconPath;
  final String description;
  final String modeOfThought;
  final String worldView;

  SpiritualSource({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.modeOfThought,
    required this.worldView,
  });
}

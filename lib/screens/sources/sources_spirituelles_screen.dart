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
      name: 'Rabbinic Judaism',
      iconPath: 'assets/univers_visuel/judaisme rabbinique akiva.png',
      description: 'Tradition rooted in the Torah and Talmud, structured around study, law (Halakha) and rabbinic interpretation.',
      modeOfThought: 'Centrality of the text, dialogue between law and human experience; importance of individual and collective responsibility.',
      worldView: 'The world is a place where human beings participate in repairing imperfection (Tikkun Olam); God acts through history.',
    ),
    SpiritualSource(
      id: 'moussar',
      name: 'Mussar (Jewish Ethics)',
      iconPath: 'assets/univers_visuel/moussar.png',
      description: 'Ethical movement within Judaism born in the 19th century, focused on moral and emotional refinement.',
      modeOfThought: 'Inner work, self-observation, gradual transformation through awareness and practice.',
      worldView: 'The world is a training ground for the soul; every emotion or situation reveals an opportunity for growth.',
    ),
    SpiritualSource(
      id: 'kabbale',
      name: 'Kabbalah (Jewish Mysticism)',
      iconPath: 'assets/univers_visuel/kabale.png',
      description: 'Mystical tradition that explores the hidden dimensions of the divine, the Tree of Sefirot, and the energies that structure reality.',
      modeOfThought: 'Symbolic vision, search for invisible causes, metaphorical and deep reading of experiences.',
      worldView: 'The world is a fragmented emanation of the divine; human beings participate in spiritual unification.',
    ),
    SpiritualSource(
      id: 'christianisme',
      name: 'Christianity',
      iconPath: 'assets/univers_visuel/christianisme.png',
      description: 'Tradition founded on the life and teachings of Jesus, centered on love, forgiveness and a personal relationship with God.',
      modeOfThought: 'Moral and relational perspective: transformation through love, grace, compassion.',
      worldView: 'The world is a path toward spiritual reconciliation; suffering can become a place of meaning.',
    ),
    SpiritualSource(
      id: 'islam',
      name: 'Islam',
      iconPath: 'assets/univers_visuel/islam.png',
      description: 'Tradition founded on the Quran and the teachings of the Prophet, structured by a harmonious relationship between faith, practice and community (Ummah).',
      modeOfThought: 'Trusting submission to God (Allah), inner and outer discipline, pursuit of justice and peace.',
      worldView: 'The world is a sign (ayat), each event carries a teaching; spiritual and moral balance leads to inner peace.',
    ),
    SpiritualSource(
      id: 'soufisme',
      name: 'Sufism (Islamic Mysticism)',
      iconPath: 'assets/univers_visuel/soufisme.png',
      description: 'Inner current of Islam seeking intimate closeness with God through love, humility and purification of the heart.',
      modeOfThought: 'Poetic, symbolic vision, based on the inner quest, union with the divine and shedding of the ego.',
      worldView: 'The world is a mirror; what one experiences reveals the path to the heart. The divine is found in intimate experience.',
    ),
    SpiritualSource(
      id: 'bouddhisme',
      name: 'Buddhism',
      iconPath: 'assets/univers_visuel/boudhisme.png',
      description: 'Tradition founded on the teachings of the Buddha, aimed at reducing suffering by understanding the nature of the mind and attachment.',
      modeOfThought: 'Observation, non-attachment, mindfulness, gradual transformation through direct experience.',
      worldView: 'The world is impermanent; suffering comes from expectation, not from events. Freedom is within.',
    ),
    SpiritualSource(
      id: 'hindouisme',
      name: 'Hinduism',
      iconPath: 'assets/univers_visuel/hindouisme.png',
      description: 'Collection of spiritual traditions originating from India, centered on dharma, karma and the quest for liberation (moksha).',
      modeOfThought: 'Acceptance of life cycles, search for unity between the individual soul (Atman) and the absolute (Brahman).',
      worldView: 'The world is a divine manifestation (maya); every being is on a path toward realizing their true nature.',
    ),
    // Stoïcisme retiré - déplacé vers courants philosophiques
    SpiritualSource(
      id: 'spiritualite_contemporaine',
      name: 'Contemporary / Secular Spirituality',
      iconPath: 'assets/univers_visuel/contemporaine_et_laique.png',
      description: 'Collection of modern non-dogmatic practices inspired by psychology, meditation, personal development, symbolism or various traditions.',
      modeOfThought: 'Experimental, introspective approach, often emotional; priority given to well-being, sensitivity and self-awareness.',
      worldView: 'The world is a space of experience and personal evolution; what matters is authenticity and presence.',
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
                    ? 'No spiritual source selected'
                    : '${_selectedSources.length} spiritual source(s) saved',
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
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Spiritual Sources',
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

          // Icône centrale spiritualités - GRANDE
          Image.asset(
            'assets/univers_visuel/spiritualites.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              // Essayer avec l'accent si sans accent échoue
              return Image.asset(
                'assets/univers_visuel/spiritualites.png',
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
            'Spiritual Sources',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the traditions that inspire you',
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
                      'Way of Thinking',
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
                      'Worldview',
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

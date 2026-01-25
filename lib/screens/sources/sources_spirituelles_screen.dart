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

  // Données des sources spirituelles - VERSION JUDAÏSME ÉTENDUE
  final List<SpiritualSource> _sources = [
    // ═══════════════════════════════════════════════════════════════
    // PÉRIODES HISTORIQUES
    // ═══════════════════════════════════════════════════════════════
    SpiritualSource(
      id: 'talmudiques',
      name: 'Rabbins talmudiques classiques',
      iconPath: 'assets/univers_visuel/talmud.png',
      description: 'Les Tannaïm et Amoraïm (Ier-VIe siècle) : Hillel, Shammaï, Rabbi Akiva, Rav, Shmuel. Fondateurs de la Mishna et du Talmud.',
      modeOfThought: 'Dialectique et débat (mahloket), recherche de la vérité par la confrontation des opinions. "Élu vélu divrei Elohim haïm" - les deux positions sont paroles du Dieu vivant.',
      worldView: 'La Torah orale complète la Torah écrite ; l\'interprétation humaine est partie intégrante de la révélation divine.',
      distinctiveContribution: 'Fondement de tout le judaïsme rabbinique. Apporte la méthode d\'étude par questions-réponses et la légitimité du désaccord constructif.',
    ),
    SpiritualSource(
      id: 'midrash',
      name: 'Midrash',
      iconPath: 'assets/univers_visuel/midrash.png',
      description: 'Littérature d\'interprétation créative de la Torah : Midrash Rabba, Tanhuma, Yalkout Shimoni. Récits, paraboles et enseignements homilétiques.',
      modeOfThought: 'Lecture imaginative et poétique du texte biblique. Chaque mot, lettre, silence recèle un sens caché. Le "blanc" entre les lignes parle autant que le texte.',
      worldView: 'La Torah a 70 visages ; elle parle à chaque génération différemment. L\'interprétation créative est un acte de révélation continue.',
      distinctiveContribution: 'Libère l\'imaginaire spirituel. Apporte des récits, des paraboles et une lecture psychologique des personnages bibliques qui enrichit la compréhension au-delà de la loi.',
    ),
    SpiritualSource(
      id: 'gueonim',
      name: 'Guéonim',
      iconPath: 'assets/univers_visuel/gueonim.png',
      description: 'Chefs des académies de Babylone (VIIe-XIe siècle) : Saadia Gaon, Haï Gaon. Période de codification et de responsa.',
      modeOfThought: 'Systématisation du savoir talmudique, réponses halakhiques aux communautés de la diaspora, philosophie rationnelle.',
      worldView: 'Le judaïsme comme civilisation structurée autour des académies ; transmission ordonnée de la tradition.',
      distinctiveContribution: 'Pont entre l\'époque talmudique et le Moyen Âge. Apporte la méthode des responsa (questions-réponses) et la première philosophie juive systématique.',
    ),
    SpiritualSource(
      id: 'rishonim',
      name: 'Rishonim (Moyen Âge)',
      iconPath: 'assets/univers_visuel/rishonim.png',
      description: 'Grands décisionnaires médiévaux (XIe-XVe siècle) : Rachi, Tossafot, Rambam (Maïmonide), Ramban (Nahmanide), Rif, Rosh.',
      modeOfThought: 'Commentaire systématique, codification de la loi, synthèse entre philosophie grecque et tradition juive (Maïmonide), ou mystique et halakha (Nahmanide).',
      worldView: 'Recherche de l\'harmonie entre raison et foi ; la Torah contient toute sagesse, accessible par l\'étude rigoureuse.',
      distinctiveContribution: 'Âge d\'or de la pensée juive. Apporte les grands commentaires (Rachi), la philosophie rationnelle (Maïmonide) et les codes de loi qui structurent encore la pratique.',
    ),
    SpiritualSource(
      id: 'aharonim',
      name: 'A\'haronim (époque moderne)',
      iconPath: 'assets/univers_visuel/aharonim.png',
      description: 'Décisionnaires depuis le Choul\'han Aroukh (XVIe siècle à nos jours) : Caro, Isserles, Hatam Sofer, Hafetz Haïm, Rav Moshe Feinstein.',
      modeOfThought: 'Responsa adaptés aux réalités modernes, tension entre préservation et adaptation, codification définitive de la halakha.',
      worldView: 'Fidélité à la tradition face aux défis de la modernité ; "Hadash assour min haTorah" vs innovation mesurée.',
      distinctiveContribution: 'Application de la halakha aux questions contemporaines (technologie, médecine, éthique). Apporte des réponses pratiques aux défis de chaque époque.',
    ),

    // ═══════════════════════════════════════════════════════════════
    // COURANTS SPIRITUELS
    // ═══════════════════════════════════════════════════════════════
    SpiritualSource(
      id: 'hassidisme',
      name: 'Hassidisme',
      iconPath: 'assets/univers_visuel/hassidisme.png',
      description: 'Mouvement mystique populaire fondé par le Baal Shem Tov (XVIIIe siècle). Joie dans le service divin, importance du Tsaddik, accessibilité de la spiritualité.',
      modeOfThought: 'Dvekoute (attachement à Dieu), hitbonenoute (méditation), importance de l\'intention (kavana) sur l\'acte. Chaque geste quotidien peut être sacré.',
      worldView: 'Dieu est partout (panenthéisme), même dans le mal apparent ; l\'étincelle divine attend d\'être élevée. La joie est un service divin.',
      distinctiveContribution: 'Démocratise la spiritualité. Apporte la joie comme valeur religieuse, l\'importance de l\'émotion dans la prière, et l\'idée que chacun peut atteindre des niveaux spirituels élevés.',
    ),
    SpiritualSource(
      id: 'chabad_loubavitch',
      name: 'Chabad-Loubavitch',
      iconPath: 'assets/univers_visuel/chabad.png',
      description: 'Mouvement hassidique fondé par Rabbi Schneur Zalman de Liadi (le Tanya). Le 7e Rabbi, Menachem Mendel Schneerson, a transformé le mouvement en force mondiale d\'outreach.',
      modeOfThought: 'ChaBaD = Hokhma, Bina, Da\'at (Sagesse, Compréhension, Connaissance). Approche intellectuelle de la mystique, étude du Tanya et des Maamarim. "Comprendre pour ressentir".',
      worldView: 'Chaque Juif compte, où qu\'il soit. Mission de préparer le monde pour Machia\'h. "Le monde est une demeure pour Dieu" - transformer le matériel en spirituel.',
      distinctiveContribution: 'Outreach mondial (Shlikhout). Apporte une mystique accessible intellectuellement, un réseau mondial d\'émissaires, et l\'idée que chaque mitsva compte pour la rédemption.',
    ),
    SpiritualSource(
      id: 'breslev',
      name: 'Breslev',
      iconPath: 'assets/univers_visuel/breslev.png',
      description: 'Mouvement fondé par Rabbi Na\'hman de Breslev (arrière-petit-fils du Baal Shem Tov). Connu pour ses contes mystiques, ses enseignements sur la joie et le hitbodedout.',
      modeOfThought: 'Hitbodedout : parler à Dieu seul, dans ses propres mots, comme à un ami. "Il est interdit de désespérer !" La simplicité et l\'authenticité priment sur l\'érudition.',
      worldView: 'Le monde est un pont étroit, l\'essentiel est de ne pas avoir peur. Même la chute fait partie du chemin. La joie est une mitsva, la tristesse un obstacle.',
      distinctiveContribution: 'Liberté spirituelle et résilience. Apporte le hitbodedout (prière personnelle spontanée), une spiritualité accessible sans Rebbe vivant, et l\'idée que chaque épreuve cache une élévation.',
    ),
    SpiritualSource(
      id: 'mitnagdisme',
      name: 'Mitnagdisme (Lituanien)',
      iconPath: 'assets/univers_visuel/mitnagdisme.png',
      description: 'Opposition au hassidisme menée par le Gaon de Vilna. Primat de l\'étude talmudique rigoureuse, méfiance envers l\'émotionnel.',
      modeOfThought: 'Étude approfondie (iyoun), analyse logique, précision intellectuelle. "Torah lishmah" - l\'étude pour elle-même est la plus haute valeur.',
      worldView: 'La perfection spirituelle passe par la connaissance ; l\'intellect est le chemin vers Dieu. Les yeshivot lituaniennes comme modèle.',
      distinctiveContribution: 'Excellence intellectuelle et rigueur analytique. Apporte la méthode d\'étude approfondie du Talmud et l\'idéal de l\'érudit comme modèle de vie.',
    ),
    SpiritualSource(
      id: 'kabbale',
      name: 'Kabbale (mystique juive)',
      iconPath: 'assets/univers_visuel/kabale.png',
      description: 'Tradition mystique : Zohar, Isaac Louria (Ari), école de Safed. Explore les Sephirot, les mondes spirituels, et le Tikkoun.',
      modeOfThought: 'Vision symbolique, lecture des niveaux cachés (Sod), correspondances entre le haut et le bas. Les mots et lettres ont un pouvoir créateur.',
      worldView: 'Le monde est une émanation du divin (Tsimtsoum) ; l\'être humain participe à la réparation cosmique (Tikkoun Olam).',
      distinctiveContribution: 'Dimension cosmique et mystique. Apporte une carte de l\'âme et de l\'univers spirituel, des outils de méditation, et le concept de Tikkoun Olam (réparation du monde).',
    ),
    SpiritualSource(
      id: 'moussar',
      name: 'Moussar (éthique juive)',
      iconPath: 'assets/univers_visuel/moussar.png',
      description: 'Mouvement éthique fondé par Rabbi Israël Salanter (XIXe siècle). Travail sur les middot (traits de caractère), introspection, transformation morale.',
      modeOfThought: 'Heshbon hanefesh (examen de conscience), pratique délibérée des vertus, étude des textes éthiques avec émotion (hitpa\'alout).',
      worldView: 'Le perfectionnement moral est le but de la vie ; chaque situation est une opportunité de croissance spirituelle.',
      distinctiveContribution: 'Psychologie spirituelle avant l\'heure. Apporte des outils concrets de développement personnel, l\'auto-observation, et la transformation progressive des traits de caractère.',
    ),

    // ═══════════════════════════════════════════════════════════════
    // COURANTS MODERNES
    // ═══════════════════════════════════════════════════════════════
    SpiritualSource(
      id: 'sionisme_religieux',
      name: 'Sionisme religieux',
      iconPath: 'assets/univers_visuel/sionisme_religieux.png',
      description: 'Synthèse entre nationalisme juif et tradition religieuse. Rav Kook, Bnei Akiva, Gush Emunim. Le retour à Sion comme processus messianique.',
      modeOfThought: 'La Gueoula (rédemption) se construit concrètement ; sainteté de l\'État d\'Israël ; Torah et travail (Torah im Derekh Eretz).',
      worldView: 'L\'histoire a un sens divin ; le peuple juif a une mission nationale et spirituelle ; Atchalta deGueoula (début de la rédemption).',
      distinctiveContribution: 'Sens de l\'histoire et de la mission collective. Apporte une lecture théologique du sionisme, l\'engagement dans la construction nationale, et la sanctification du quotidien en Terre d\'Israël.',
    ),
    SpiritualSource(
      id: 'orthodoxie_moderne',
      name: 'Orthodoxie moderne',
      iconPath: 'assets/univers_visuel/orthodoxie_moderne.png',
      description: 'Engagement avec le monde moderne tout en maintenant la halakha. Rav Soloveitchik, Yeshiva University. Torah Umadda (Torah et science).',
      modeOfThought: 'Dialogue entre tradition et modernité, ouverture aux études séculières, participation à la société civile tout en préservant l\'identité.',
      worldView: 'La Torah s\'applique à tous les domaines de la vie moderne ; être un "Mentsch" dans le monde tout en restant fidèle à la halakha.',
      distinctiveContribution: 'Pont entre tradition et modernité. Apporte la légitimité des études séculières, l\'engagement professionnel et civique, et une approche nuancée des défis contemporains.',
    ),

    // ═══════════════════════════════════════════════════════════════
    // TRADITIONS COMMUNAUTAIRES
    // ═══════════════════════════════════════════════════════════════
    SpiritualSource(
      id: 'sefarade',
      name: 'Tradition Séfarade',
      iconPath: 'assets/univers_visuel/sefarade.png',
      description: 'Héritage des Juifs d\'Espagne et du Portugal. Rav Ovadia Yossef, Ben Ish Haï. Traditions liturgiques et halakhiques distinctes.',
      modeOfThought: 'Approche halakhique souvent plus souple, importance du Minhag (coutume), harmonie entre rigueur et flexibilité selon Maran (Caro).',
      worldView: 'Fierté de l\'âge d\'or espagnol, synthèse culturelle méditerranéenne, attachement aux piyoutim et à la poésie liturgique.',
      distinctiveContribution: 'Élégance et équilibre. Apporte une approche halakhique pragmatique, une riche tradition poétique et musicale, et l\'héritage de la convivencia (coexistence culturelle).',
    ),
    SpiritualSource(
      id: 'mizrahi',
      name: 'Tradition Mizrahi',
      iconPath: 'assets/univers_visuel/mizrahi.png',
      description: 'Juifs des pays arabes et d\'Orient : Irak, Yémen, Perse, Maroc. Traditions anciennes préservées, liturgie et musique distinctes.',
      modeOfThought: 'Transmission familiale et communautaire forte, intégration naturelle de la mystique dans le quotidien, respect des anciens.',
      worldView: 'Continuité millénaire en terre d\'Islam, richesse des traditions locales (Djerba, Fès, Bagdad, Sanaa), nostalgie et renouveau.',
      distinctiveContribution: 'Authenticité et tradition vivante. Apporte des coutumes préservées depuis des siècles, une spiritualité naturellement intégrée au quotidien, et une richesse musicale unique.',
    ),
    SpiritualSource(
      id: 'ashkenaze',
      name: 'Tradition Ashkénaze',
      iconPath: 'assets/univers_visuel/ashkenaze.png',
      description: 'Héritage des Juifs d\'Europe centrale et orientale. Rachi, Tossafot, yeshivot lituaniennes, hassidisme polonais et ukrainien.',
      modeOfThought: 'Rigueur dans l\'étude talmudique, pilpoul (dialectique), importance des coutumes (minhagim) parfois plus strictes que la loi.',
      worldView: 'Mémoire de la Shoah, culture du shtetl, yiddishkeit, tension entre intégration et préservation de l\'identité.',
      distinctiveContribution: 'Profondeur intellectuelle et mémoire. Apporte la méthode d\'étude talmudique la plus développée, le hassidisme, et une conscience historique marquée par la résilience.',
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
                    const SizedBox(height: 14),

                    // Apport distinctif - titre en violet
                    Text(
                      'Apport distinctif',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1), // Violet/Indigo
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.distinctiveContribution,
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
  final String distinctiveContribution;

  SpiritualSource({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.modeOfThought,
    required this.worldView,
    required this.distinctiveContribution,
  });
}

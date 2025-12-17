import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../services/complete_auth_service.dart';
import '../../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _prenomController = TextEditingController();
  final _valeursLibresController = TextEditingController();
  
  // Date de naissance
  DateTime? _dateNaissance;
  
  // Valeurs sélectionnées
  Set<String> _valeursSelectionnees = {};
  
  String? _currentUser;
  bool _isLoading = false;

  // Liste des catégories avec icône et valeurs
  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Relations et famille',
      'icon': 'assets/univers_visuel/relationetfamille.png',
      'valeurs': [
        {'key': 'famille_loyaute', 'label': 'Famille / Loyauté familiale', 'desc': 'Accorder de l\'importance aux liens familiaux et au soutien mutuel'},
        {'key': 'amour_affection', 'label': 'Amour / Affection', 'desc': 'Chérir et prendre soin des personnes proches'},
        {'key': 'respect_parents', 'label': 'Respect des parents / aînés', 'desc': 'Honorer et respecter ceux qui m\'ont précédé'},
        {'key': 'responsabilite_parentale', 'label': 'Responsabilité parentale', 'desc': 'Guider et accompagner ses enfants avec soin'},
        {'key': 'amitie_solidarite', 'label': 'Amitié / Solidarité', 'desc': 'Soutenir et partager avec ses amis et proches'},
      ],
    },
    {
      'name': 'Développement personnel',
      'icon': 'assets/univers_visuel/developpementpersonnel.png',
      'valeurs': [
        {'key': 'curiosite', 'label': 'Curiosité', 'desc': 'Désir d\'apprendre et de découvrir'},
        {'key': 'creativite', 'label': 'Créativité', 'desc': 'Capacité à imaginer et exprimer des idées nouvelles'},
        {'key': 'sagesse_reflexion', 'label': 'Sagesse / Réflexion', 'desc': 'Chercher à comprendre et à agir avec discernement'},
        {'key': 'courage_resilience', 'label': 'Courage / Résilience', 'desc': 'Persévérer face aux difficultés'},
        {'key': 'discipline_perseverance', 'label': 'Discipline / Persévérance', 'desc': 'Capacité à se structurer pour atteindre ses objectifs'},
        {'key': 'autonomie_independance', 'label': 'Autonomie / Indépendance', 'desc': 'Prendre des décisions et agir par soi-même'},
      ],
    },
    {
      'name': 'Santé et bien-être',
      'icon': 'assets/univers_visuel/santeetbienetre.png',
      'valeurs': [
        {'key': 'sante_vitalite', 'label': 'Santé / Vitalité', 'desc': 'Prendre soin de son corps et de son énergie'},
        {'key': 'equilibre_harmonie', 'label': 'Équilibre / Harmonie', 'desc': 'Maintenir un équilibre entre différents aspects de sa vie'},
        {'key': 'bienetre_emotionnel', 'label': 'Bien-être émotionnel', 'desc': 'Cultiver la sérénité et la paix intérieure'},
      ],
    },
    {
      'name': 'Spiritualité et sens',
      'icon': 'assets/univers_visuel/spiritualiteetsens.png',
      'valeurs': [
        {'key': 'spiritualite_foi', 'label': 'Spiritualité / Foi', 'desc': 'Se relier à quelque chose de plus grand que soi'},
        {'key': 'gratitude_appreciation', 'label': 'Gratitude / Appréciation', 'desc': 'Reconnaître et valoriser ce qui est positif'},
        {'key': 'paix_interieure', 'label': 'Paix intérieure / Sérénité', 'desc': 'Rechercher le calme et la stabilité émotionnelle'},
        {'key': 'contemplation_reflexion', 'label': 'Contemplation / Réflexion', 'desc': 'Prendre le temps d\'observer et de méditer'},
      ],
    },
    {
      'name': 'Liberté et authenticité',
      'icon': 'assets/univers_visuel/liberteetauthenticite.png',
      'valeurs': [
        {'key': 'liberte', 'label': 'Liberté / Indépendance', 'desc': 'Pouvoir choisir sa voie et agir selon ses convictions'},
        {'key': 'authenticite_honnetete', 'label': 'Authenticité / Honnêteté', 'desc': 'Être vrai avec soi-même et les autres'},
        {'key': 'responsabilite_integrite', 'label': 'Responsabilité / Intégrité', 'desc': 'Assumer ses choix et agir selon ses valeurs'},
      ],
    },
    {
      'name': 'Contribution et engagement',
      'icon': 'assets/univers_visuel/contributionetengagement.png',
      'valeurs': [
        {'key': 'generosite_partage', 'label': 'Générosité / Partage', 'desc': 'Donner aux autres sans attendre en retour'},
        {'key': 'engagement_social', 'label': 'Engagement social / Écologie', 'desc': 'Agir pour le bien commun et l\'environnement'},
        {'key': 'justice_equite', 'label': 'Justice / Équité', 'desc': 'Défendre ce qui est juste et équilibré pour tous'},
      ],
    },
    {
      'name': 'Esthétique et expression',
      'icon': 'assets/univers_visuel/esthetiqueetexpression.png',
      'valeurs': [
        {'key': 'beaute_esthetique', 'label': 'Beauté / Esthétique', 'desc': 'Rechercher ou créer l\'harmonie et la beauté'},
        {'key': 'art_expression', 'label': 'Art / Expression', 'desc': 'Exprimer ses émotions ou idées de façon créative'},
        {'key': 'creativite_pratique', 'label': 'Créativité pratique', 'desc': 'Résoudre des problèmes avec imagination'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUser = await CompleteAuthService.instance.getCurrentUser();
      final profileData = await CompleteAuthService.instance.getProfile();
      
      if (profileData != null) {
        final profile = UserProfile.fromJson(profileData);
        
        setState(() {
          _userProfile = profile;
          _prenomController.text = profile.prenom ?? '';
          _dateNaissance = profile.dateNaissance;
          
          // Charger les valeurs sélectionnées
          if (profile.valeursSelectionnees != null) {
            _valeursSelectionnees = Set<String>.from(profile.valeursSelectionnees!);
          }
          
          // Charger les valeurs libres
          _valeursLibresController.text = profile.valeursLibres ?? '';
        });
      }
    } catch (e) {
      print('Erreur chargement profil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mon Profil',
      showMenuButton: true,
      showPositiveButton: true,
      showBackButton: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Champ Prénom
                  _buildPrenomField(),
                  const SizedBox(height: 24),
                  
                  // Champ Date de naissance
                  _buildDateNaissanceField(),
                  const SizedBox(height: 32),
                  
                  // Section Valeurs
                  _buildValeursSection(),
                  
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/univers_visuel/profil.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 40, color: Color(0xFF6366F1)),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _prenomController.text.isNotEmpty 
                ? _prenomController.text 
                : (_userProfile?.email ?? _currentUser ?? 'Mon Profil'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_calculateCompletionPercentage()}% complété',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCompletionPercentage() {
    int completed = 0;
    int total = 3; // prénom, date naissance, valeurs
    
    if (_prenomController.text.isNotEmpty) completed++;
    if (_dateNaissance != null) completed++;
    if (_valeursSelectionnees.isNotEmpty || _valeursLibresController.text.isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }

  Widget _buildPrenomField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/univers_visuel/profil.png',
            width: 68,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 68,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Color(0xFF6366F1), size: 32),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // Champ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment veux-tu que je t\'appelle ?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prenomController,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Ton prénom',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateNaissanceField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/univers_visuel/age.png',
            width: 68,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 68,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cake_outlined, color: Color(0xFF6366F1), size: 32),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // Champ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ta date de naissance nous permet d\'ajuster les perspectives à ton étape de vie.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateNaissance != null
                              ? '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}'
                              : 'Sélectionner ta date de naissance',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _dateNaissance != null 
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        DateTime tempDate = _dateNaissance ?? DateTime(1990, 1, 1);
        
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ),
                  Text(
                    'Date de naissance',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _dateNaissance = tempDate);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Valider',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: DateTime(1920),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValeursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre avec icône
        Row(
          children: [
            Image.asset(
              'assets/univers_visuel/valeurs.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star, color: Color(0xFF6366F1), size: 24),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'Mes valeurs',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Texte explicatif
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Les valeurs sont ce qui compte le plus pour toi dans ta vie, ce qui te guide, te donne du sens ou te fait te sentir aligné·e avec toi-même.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '✨ Par exemple : liberté, honnêteté, curiosité, créativité, bienveillance, courage, spiritualité, famille...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '🎯 Pense à ce que tu défends ou choisis même quand c\'est difficile ; ce qui fait que tu te sens toi-même.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Liste des catégories
        ..._categories.map((category) => _buildCategorySection(category)),
        
        const SizedBox(height: 24),
        
        // Saisie libre
        _buildValeursLibresField(),
      ],
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final String categoryName = category['name'];
    final String iconPath = category['icon'];
    final List<dynamic> valeurs = category['valeurs'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de catégorie avec icône
          Row(
            children: [
              Image.asset(
                iconPath,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.category, color: Color(0xFF6366F1), size: 18),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Liste des valeurs avec checkboxes
          ...valeurs.map((valeur) => _buildValeurCheckbox(valeur as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildValeurCheckbox(Map<String, dynamic> valeur) {
    final String key = valeur['key'];
    final String label = valeur['label'];
    final String desc = valeur['desc'];
    final bool isSelected = _valeursSelectionnees.contains(key);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _valeursSelectionnees.remove(key);
          } else {
            _valeursSelectionnees.add(key);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox personnalisée
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValeursLibresField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autres valeurs importantes pour toi',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _valeursLibresController,
          maxLines: 2,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Ex: Humour, Aventure, Tradition...',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Sauvegarder mon profil',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Calculer l'âge à partir de la date de naissance
      int? age;
      if (_dateNaissance != null) {
        final now = DateTime.now();
        age = now.year - _dateNaissance!.year;
        if (now.month < _dateNaissance!.month ||
            (now.month == _dateNaissance!.month && now.day < _dateNaissance!.day)) {
          age--;
        }
      }
      
      // Construire la chaîne des valeurs pour compatibilité
      final valeursTexte = _buildValeursTexte();
      
      final updatedProfile = (_userProfile ?? UserProfile.empty()).copyWith(
        prenom: _prenomController.text.isEmpty ? null : _prenomController.text,
        dateNaissance: _dateNaissance,
        age: age,
        valeurs: valeursTexte,
        valeursSelectionnees: _valeursSelectionnees.toList(),
        valeursLibres: _valeursLibresController.text.isEmpty ? null : _valeursLibresController.text,
        lastUpdated: DateTime.now(),
      );

      final success = await CompleteAuthService.instance.saveProfile(updatedProfile.toJson());
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Profil sauvegardé avec succès !', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Erreur lors de la sauvegarde', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _buildValeursTexte() {
    final valeurs = <String>[];
    
    // Ajouter les valeurs sélectionnées (avec leurs labels)
    for (final category in _categories) {
      final categoryValeurs = category['valeurs'] as List<dynamic>;
      for (final valeur in categoryValeurs) {
        final valeurMap = valeur as Map<String, dynamic>;
        if (_valeursSelectionnees.contains(valeurMap['key'])) {
          valeurs.add(valeurMap['label']);
        }
      }
    }
    
    // Ajouter les valeurs libres
    if (_valeursLibresController.text.isNotEmpty) {
      valeurs.add(_valeursLibresController.text);
    }
    
    return valeurs.join(', ');
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _valeursLibresController.dispose();
    super.dispose();
  }
}

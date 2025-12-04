import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../models/user_profile.dart';
import '../../services/complete_auth_service.dart';
import '../../widgets/app_scaffold.dart'; // ✅ NOUVEAU

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour tous les champs
  final _ageController = TextEditingController();
  final _situationFamilialeController = TextEditingController();
  final _healthEnergyController = TextEditingController();
  final _contraintesController = TextEditingController();
  final _valeursController = TextEditingController();
  final _ressourcesController = TextEditingController();
  final _contraintesRecurrentesController = TextEditingController();
  final _ouJenSuisController = TextEditingController();
  final _ceQuiPeseController = TextEditingController();
  final _ceQuiTientController = TextEditingController();
  
  String? _currentUser;
  bool _isLoading = false;

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
          _ageController.text = profile.age?.toString() ?? '';
          _situationFamilialeController.text = profile.situationFamiliale ?? '';
          _healthEnergyController.text = profile.healthEnergy ?? '';
          _contraintesController.text = profile.contraintes ?? '';
          _valeursController.text = profile.valeurs ?? '';
          _ressourcesController.text = profile.ressources ?? '';
          _contraintesRecurrentesController.text = profile.contraintesRecurrentes ?? '';
          _ouJenSuisController.text = profile.ouJenSuis ?? '';
          _ceQuiPeseController.text = profile.ceQuiPese ?? '';
          _ceQuiTientController.text = profile.ceQuiTient ?? '';
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
                  
                  // Tous les champs directement sur le fond bleu
                  _buildFieldWithIcon(
                    iconPath: 'assets/univers_visuel/age.png',
                    fallbackIcon: Icons.cake_outlined,
                    explanation: 'Votre âge nous permet d\'ajuster les perspectives à votre étape de vie, vos expériences et vos priorités du moment.',
                    hint: 'Ex: 35',
                    controller: _ageController,
                    isNumber: true,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildFieldWithIcon(
                    iconPath: 'assets/univers_visuel/situation familliale.png',
                    fallbackIcon: Icons.family_restroom,
                    explanation: 'Décrivez votre contexte de vie : relations, enfants, entourage, travail… Tout ce qui façonne votre quotidien.',
                    hint: 'Ex: Marié(e), 2 enfants, cadre en entreprise...',
                    controller: _situationFamilialeController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildFieldWithIcon(
                    iconPath: 'assets/univers_visuel/sante et energie.png',
                    fallbackIcon: Icons.favorite_outline,
                    explanation: 'Comment vous sentez-vous physiquement ces temps-ci ? L\'énergie dont vous disposez influence beaucoup la manière dont vous vivez vos pensées.',
                    hint: 'Ex: Fatigué(e) en ce moment, énergie variable...',
                    controller: _healthEnergyController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildFieldWithIcon(
                    iconPath: 'assets/univers_visuel/contraintes recurrentes.png',
                    fallbackIcon: Icons.block_outlined,
                    explanation: 'Quelles sont aujourd\'hui vos limites concrètes (temps, finances, responsabilités, santé…) ? Cela aide à proposer des pistes réalistes pour vous.',
                    hint: 'Ex: Budget serré, peu de temps libre, santé fragile...',
                    controller: _contraintesController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildFieldWithIcon(
                    iconPath: 'assets/univers_visuel/valeurs.png',
                    fallbackIcon: Icons.star_outline,
                    explanation: 'Quels sont les principes qui comptent vraiment pour vous ? Ils éclairent vos choix et donnent du sens à vos décisions.',
                    hint: 'Ex: Authenticité, famille, liberté, créativité...',
                    controller: _valeursController,
                    maxLines: 3,
                  ),
                      const SizedBox(height: 24),
                      
                      _buildFieldWithIcon(
                        iconPath: 'assets/univers_visuel/ressources.png',
                        fallbackIcon: Icons.lightbulb_outline,
                        explanation: 'Qu\'est-ce qui vous aide d\'habitude lorsque vous traversez quelque chose de difficile ? Personnes, habitudes, pratiques, forces intérieures…',
                        hint: 'Ex: Marche en nature, amis proches, méditation, journal...',
                        controller: _ressourcesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildFieldWithIcon(
                        iconPath: 'assets/univers_visuel/contraintesrecurrentes.png',
                        fallbackIcon: Icons.repeat,
                        explanation: 'Quels blocages, difficultés ou schémas semblent revenir souvent dans votre vie ? Identifier ces motifs permet un recul précieux.',
                        hint: 'Ex: Perfectionnisme, difficulté à dire non, procrastination...',
                        controller: _contraintesRecurrentesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildFieldWithIcon(
                        iconPath: 'assets/univers_visuel/oujensuis.png',
                        fallbackIcon: Icons.explore_outlined,
                        explanation: 'Comment décririez-vous votre état actuel, votre période de vie, votre humeur profonde du moment ?',
                        hint: 'Ex: En transition, en questionnement, plutôt serein(e)...',
                        controller: _ouJenSuisController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildFieldWithIcon(
                        iconPath: 'assets/univers_visuel/cequimepese.png',
                        fallbackIcon: Icons.cloud_outlined,
                        explanation: 'Qu\'est-ce qui vous fatigue, vous alourdit ou vous inquiète le plus en ce moment ?',
                        hint: 'Ex: Conflits au travail, incertitude sur l\'avenir...',
                        controller: _ceQuiPeseController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      _buildFieldWithIcon(
                        iconPath: 'assets/univers_visuel/ressources.png',
                        fallbackIcon: Icons.wb_sunny_outlined,
                        explanation: 'Qu\'est-ce qui vous porte encore aujourd\'hui ? Ce qui vous donne de l\'élan, de la force ou de la stabilité ? Même si c\'est petit.',
                        hint: 'Ex: Mes enfants, un projet qui me passionne, ma foi...',
                        controller: _ceQuiTientController,
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAppBar() {
    return Row(
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
        IconButton(
          onPressed: _showLogoutDialog,
          icon: const Icon(Icons.logout),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
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
            _userProfile?.email ?? _currentUser ?? 'Mon Profil',
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
              '${_userProfile?.completionPercentage ?? 0}% complété',
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

  Widget _buildFieldWithIcon({
    required String iconPath,
    required IconData fallbackIcon,
    required String explanation,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    // Calculer la hauteur de l'icône en fonction du nombre de lignes
    // Zone de saisie: ~52px (1 ligne) + ~20px par ligne supplémentaire
    // Texte explicatif: ~40px (2 lignes environ)
    double iconHeight = 52 + (maxLines - 1) * 24 + 40;
    if (iconHeight < 80) iconHeight = 80;
    if (iconHeight > 120) iconHeight = 120;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône PNG à gauche
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            iconPath,
            width: iconHeight * 0.85,
            height: iconHeight,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: iconHeight * 0.85,
                height: iconHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  fallbackIcon, 
                  color: const Color(0xFF6366F1), 
                  size: iconHeight * 0.4,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // Colonne droite : explication + champ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texte explicatif
              Text(
                explanation,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              
              // Champ de saisie
              TextFormField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: hint,
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

  void _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Déconnecter',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await CompleteAuthService.instance.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      }
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = (_userProfile ?? UserProfile.empty()).copyWith(
        age: int.tryParse(_ageController.text),
        situationFamiliale: _situationFamilialeController.text.isEmpty ? null : _situationFamilialeController.text,
        healthEnergy: _healthEnergyController.text.isEmpty ? null : _healthEnergyController.text,
        contraintes: _contraintesController.text.isEmpty ? null : _contraintesController.text,
        valeurs: _valeursController.text.isEmpty ? null : _valeursController.text,
        ressources: _ressourcesController.text.isEmpty ? null : _ressourcesController.text,
        contraintesRecurrentes: _contraintesRecurrentesController.text.isEmpty ? null : _contraintesRecurrentesController.text,
        ouJenSuis: _ouJenSuisController.text.isEmpty ? null : _ouJenSuisController.text,
        ceQuiPese: _ceQuiPeseController.text.isEmpty ? null : _ceQuiPeseController.text,
        ceQuiTient: _ceQuiTientController.text.isEmpty ? null : _ceQuiTientController.text,
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

  @override
  void dispose() {
    _ageController.dispose();
    _situationFamilialeController.dispose();
    _healthEnergyController.dispose();
    _contraintesController.dispose();
    _valeursController.dispose();
    _ressourcesController.dispose();
    _contraintesRecurrentesController.dispose();
    _ouJenSuisController.dispose();
    _ceQuiPeseController.dispose();
    _ceQuiTientController.dispose();
    super.dispose();
  }
}

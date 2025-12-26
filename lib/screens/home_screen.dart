// lib/screens/home_screen.dart
// REFONTE COMPLÈTE - Concept "Flux guidé + Surface mentale"
// Version corrigée avec :
// - Icône app depuis assets/icon/app_icon.png
// - 4 types d'entrée avec icônes existantes (pensee.png, situation.png, question_existentielle.png, dilemme.png)
// - Bloc symétrique "Partage ce que tu ressens" 
// - Sources spirituelles SÉPARÉES (cliquable vers écran dédié)
// - Quiz et Hasard pour sources HUMANISTES
// - Profil remonté dans les accès rapides
// - Onglets directs déconnexion + pensée positive en haut à droite

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/complete_auth_service.dart';
import '../widgets/wisdom_wheel_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userEmail = '';
  bool _isGuest = false;
  
  // Type d'entrée sélectionné (pensée, situation, question, dilemme)
  int _selectedEntryType = 0;
  
  // Contrôleur pour le champ de saisie
  final TextEditingController _thoughtController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Sources sélectionnées
  // ═══════════════════════════════════════════════════════════════════════════
  List<String> _selectedRandomSources = [];  // Sources de la roue du hasard
  List<String> _profileSources = [];          // Sources du profil
  bool _isUsingDefaultSources = false;        // Flag pour afficher "par défaut"
  
  // Flag STATIQUE pour savoir si les sources invité ont déjà été réinitialisées dans cette session
  static bool _guestSourcesAlreadyCleared = false;
  
  // Getter pour le total des sources (sans doublons)
  int get _totalSourcesCount {
    final combined = <String>{..._profileSources, ..._selectedRandomSources};
    return combined.length;
  }
  
  // Animation de respiration du fond
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  // Types d'entrée avec leurs icônes existantes et labels
  static const List<Map<String, dynamic>> _entryTypes = [
    {'id': 'pensee', 'label': 'Pensée', 'icon': 'pensee.png', 'placeholder': 'Qu\'est-ce qui te traverse l\'esprit ?'},
    {'id': 'situation', 'label': 'Situation', 'icon': 'situation.png', 'placeholder': 'Décris la situation que tu traverses...'},
    {'id': 'question', 'label': 'Question', 'icon': 'question_existentielle.png', 'placeholder': 'Quelle question te préoccupe ?'},
    {'id': 'dilemme', 'label': 'Dilemme', 'icon': 'dilemme.png', 'placeholder': 'Quel choix difficile dois-tu faire ?'},
  ];
  
  // Icônes des spiritualités principales (décoratives)
  static const List<String> _spiritualIcons = [
    'judaisme.png',
    'christianisme.png',
    'islam.png',
    'boudhisme.png',
    'hindouisme.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    
    // Animation de respiration (60-120 secondes de cycle)
    _breathingController = AnimationController(
      duration: const Duration(seconds: 80),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    // Écouter le focus pour l'effet "écoute"
    _focusNode.addListener(() {
      setState(() => _isTyping = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _thoughtController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    await CompleteAuthService.instance.init();
    final email = CompleteAuthService.instance.currentUserEmail ?? '';
    setState(() {
      _userEmail = email;
      _isGuest = email == 'invite@unautreregard.app';
    });
    
    // Charger les sources du profil
    await _loadProfileSources();
  }
  
  /// Charger les sources du profil utilisateur
  Future<void> _loadProfileSources() async {
    try {
      // ═══════════════════════════════════════════════════════════════════════
      // MODE INVITÉ : Réinitialiser les sources UNE SEULE FOIS par session
      // ═══════════════════════════════════════════════════════════════════════
      if (_isGuest && !_guestSourcesAlreadyCleared) {
        print('👤 Mode invité: réinitialisation des sources (première fois)');
        await _clearGuestSources();
        _guestSourcesAlreadyCleared = true;  // Ne plus réinitialiser jusqu'à déconnexion
      }
      
      final profileData = await CompleteAuthService.instance.getProfile();
      if (profileData != null) {
        final List<String> sources = [];
        sources.addAll(List<String>.from(profileData['religionsSelectionnees'] ?? []));
        sources.addAll(List<String>.from(profileData['courantsLitteraires'] ?? []));
        sources.addAll(List<String>.from(profileData['approchesPsychologiques'] ?? []));
        sources.addAll(List<String>.from(profileData['courantsPhilosophiques'] ?? []));
        sources.addAll(List<String>.from(profileData['philosophesSelectionnes'] ?? []));
        
        // ═══════════════════════════════════════════════════════════════════════
        // SOURCES PAR DÉFAUT
        // ═══════════════════════════════════════════════════════════════════════
        const defaultSources = [
          'aristote',           // Philosophe par défaut
          'existentialisme',    // Courant philosophique par défaut
          'realisme',           // Courant littéraire par défaut
          'schemas_young',      // Approche psychologique par défaut
        ];
        
        // DEBUG: Afficher les sources chargées
        print('📋 Sources brutes du profil: $sources');
        
        if (sources.isEmpty) {
          // CORRECTION: Sauvegarder les sources par défaut dans le profil
          // pour que AIService puisse les lire
          await _saveDefaultSourcesToProfile(defaultSources);
          sources.addAll(defaultSources);
          _isUsingDefaultSources = true;
          print('📌 Sources par défaut appliquées ET sauvegardées: ${sources.length}');
        } else {
          // ═══════════════════════════════════════════════════════════════════════
          // CORRECTION BUG : Si le quiz d'orientation est complété, les sources ont
          // été CHOISIES explicitement par l'utilisateur → ne pas nettoyer !
          // ═══════════════════════════════════════════════════════════════════════
          final orientationCompleted = profileData['orientationCompleted'] == true;
          
          if (orientationCompleted) {
            // L'utilisateur a fait le quiz et choisi ses sources → les garder telles quelles
            _isUsingDefaultSources = false;
            print('✅ Quiz complété: ${sources.length} sources choisies par l\'utilisateur');
          } else {
            // Quiz pas fait → vérifier si ce sont les sources par défaut
            final sortedSources = List<String>.from(sources)..sort();
            final sortedDefaults = List<String>.from(defaultSources)..sort();
            final isExactlyDefaults = sortedSources.length == sortedDefaults.length &&
                sortedSources.every((s) => sortedDefaults.contains(s));
            
            if (isExactlyDefaults) {
              _isUsingDefaultSources = true;
              print('📌 Sources par défaut détectées: ${sources.length}');
            } else {
              // Quiz pas fait mais sources différentes des défauts (ajout manuel via profil)
              _isUsingDefaultSources = false;
              print('📋 Sources personnalisées (sans quiz): ${sources.length}');
            }
          }
        }
        
        setState(() {
          _profileSources = sources;
        });
        
        print('🔍 Sources du profil chargées: ${_profileSources.length}');
      } else {
        // Aucun profil → appliquer les sources par défaut
        const defaultSources = [
          'aristote',
          'existentialisme',
          'realisme',
          'schemas_young',
        ];
        
        setState(() {
          _profileSources = defaultSources;
          _isUsingDefaultSources = true;
        });
        
        print('📌 Pas de profil, sources par défaut appliquées');
      }
    } catch (e) {
      print('⚠️ Erreur chargement sources profil: $e');
      setState(() {
        _profileSources = [
          'aristote',
          'existentialisme',
          'realisme',
          'schemas_young',
        ];
        _isUsingDefaultSources = true;
      });
    }
  }
  
  /// Supprimer les sources par défaut du profil
  Future<void> _removeDefaultSourcesFromProfile() async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile() ?? {};
      
      // Retirer aristote des philosophes
      final philosophes = List<String>.from(profileData['philosophesSelectionnes'] ?? []);
      philosophes.remove('aristote');
      profileData['philosophesSelectionnes'] = philosophes;
      
      // Retirer existentialisme des courants philosophiques
      final courantsPhilo = List<String>.from(profileData['courantsPhilosophiques'] ?? []);
      courantsPhilo.remove('existentialisme');
      profileData['courantsPhilosophiques'] = courantsPhilo;
      
      // Retirer realisme des courants littéraires
      final courantsLitt = List<String>.from(profileData['courantsLitteraires'] ?? []);
      courantsLitt.remove('realisme');
      profileData['courantsLitteraires'] = courantsLitt;
      
      // Retirer schemas_young des approches psychologiques
      final approches = List<String>.from(profileData['approchesPsychologiques'] ?? []);
      approches.remove('schemas_young');
      profileData['approchesPsychologiques'] = approches;
      
      await CompleteAuthService.instance.saveProfile(profileData);
      print('✅ Sources par défaut supprimées du profil');
    } catch (e) {
      print('⚠️ Erreur suppression sources par défaut: $e');
    }
  }
  
  /// Initialiser les sources du profil invité avec les sources par défaut
  /// CORRECTION: Au lieu de juste effacer, on initialise directement avec les 4 par défaut
  Future<void> _clearGuestSources() async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile() ?? {};
      
      // Effacer toutes les catégories puis ajouter les sources par défaut
      profileData['religionsSelectionnees'] = <String>[];
      profileData['courantsLitteraires'] = ['realisme'];           // Source par défaut
      profileData['approchesPsychologiques'] = ['schemas_young'];  // Source par défaut
      profileData['courantsPhilosophiques'] = ['existentialisme']; // Source par défaut
      profileData['philosophesSelectionnes'] = ['aristote'];       // Source par défaut
      
      await CompleteAuthService.instance.saveProfile(profileData);
      print('✅ Sources invité initialisées avec les 4 sources par défaut');
    } catch (e) {
      print('⚠️ Erreur initialisation sources invité: $e');
    }
  }
  
  /// Sauvegarde les sources par défaut dans le profil utilisateur
  Future<void> _saveDefaultSourcesToProfile(List<String> defaultSources) async {
    try {
      final profileData = await CompleteAuthService.instance.getProfile() ?? {};
      
      // Ajouter les sources par défaut dans les bonnes catégories
      profileData['philosophesSelectionnes'] = ['aristote'];
      profileData['courantsPhilosophiques'] = ['existentialisme'];
      profileData['courantsLitteraires'] = ['realisme'];
      profileData['approchesPsychologiques'] = ['schemas_young'];
      
      await CompleteAuthService.instance.saveProfile(profileData);
      print('✅ Sources par défaut sauvegardées dans le profil');
    } catch (e) {
      print('⚠️ Erreur sauvegarde sources par défaut: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFFE3F2FD), const Color(0xFFBBDEFB), _breathingAnimation.value)!,
                  Color.lerp(const Color(0xFFB3E5FC), const Color(0xFFE1F5FE), _breathingAnimation.value)!,
                  Color.lerp(const Color(0xFFE1F5FE), const Color(0xFFB3E5FC), _breathingAnimation.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════════════════════════
                    // 1. BANDEAU HAUT - Bienvenue + Actions
                    // ═══════════════════════════════════════════════════════
                    _buildHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // ═══════════════════════════════════════════════════════
                    // 2. BLOC PENSÉES - "Exprime ce qui te traverse"
                    // ═══════════════════════════════════════════════════════
                    _buildThoughtInput(),
                    
                    const SizedBox(height: 18),
                    
                    // ═══════════════════════════════════════════════════════
                    // 3. BLOC ÉMOTIONS - "Partage ce que tu ressens"
                    // ═══════════════════════════════════════════════════════
                    _buildEmotionsBlock(),
                    
                    const SizedBox(height: 18),
                    
                    // ═══════════════════════════════════════════════════════
                    // 4. BLOC SOURCES SPIRITUELLES (séparé)
                    // ═══════════════════════════════════════════════════════
                    _buildSpiritualSourcesBlock(),
                    
                    const SizedBox(height: 18),
                    
                    // ═══════════════════════════════════════════════════════
                    // 5. BLOC SOURCES HUMANISTES - Quiz & Hasard
                    // ═══════════════════════════════════════════════════════
                    _buildHumanistSourcesBlock(),
                    
                    const SizedBox(height: 18),
                    
                    // ═══════════════════════════════════════════════════════
                    // 6. ACCÈS RAPIDES - Historiques + Profil
                    // ═══════════════════════════════════════════════════════
                    _buildQuickAccessSection(),
                    
                    // Indicateur mode invité
                    if (_isGuest) ...[
                      const SizedBox(height: 16),
                      _buildGuestIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Couleur qui "respire" doucement
  Color _getBreathingColor(double baseOpacity) {
    final progress = _breathingAnimation.value;
    // Variation subtile entre turquoise clair et légèrement plus saturé
    final r = (232 + (progress * 8)).clamp(0, 255).toInt();
    final g = (244 - (progress * 4)).clamp(0, 255).toInt();
    final b = (248 - (progress * 6)).clamp(0, 255).toInt();
    return Color.fromRGBO(r, g, b, baseOpacity);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. BANDEAU HAUT
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildHeader() {
    return AnimatedOpacity(
      opacity: _isTyping ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Row(
        children: [
          // Logo de l'app - depuis assets/icon/app_icon.png
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Color(0xFF2E8B7B),
                  size: 26,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Texte de bienvenue
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A3A3A),
                  ),
                ),
                Text(
                  'dans "Un Autre Regard"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF5BA3A8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions en haut à droite
          _buildTopRightActions(),
        ],
      ),
    );
  }

  /// Onglets directs en haut à droite : Pensée positive + Déconnexion
  Widget _buildTopRightActions() {
    return Row(
      children: [
        // Bouton Pensée Positive
        GestureDetector(
          onTap: _showPositiveThought,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DB6AC).withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/univers_visuel/pensee_positive.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF4DB6AC),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Bouton Déconnexion
        GestureDetector(
          onTap: _showLogoutDialog,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/univers_visuel/deconnexion.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.logout,
                  color: Color(0xFFE57373),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. BLOC PENSÉES - "Exprime ce qui te traverse"
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildThoughtInput() {
    final currentType = _entryTypes[_selectedEntryType];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(_isTyping ? 20 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isTyping 
              ? const Color(0xFF2E8B7B).withOpacity(0.4)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isTyping 
                ? const Color(0xFF2E8B7B).withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
            blurRadius: _isTyping ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec icône pensée
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/univers_visuel/pensee.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B7B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note, color: Color(0xFF2E8B7B), size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Exprime ce qui te traverse',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E8B7B),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // Les 4 icônes de type d'entrée (icônes existantes)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) => _buildEntryTypeButton(index)),
          ),
          
          const SizedBox(height: 16),
          
          // Champ de saisie
          TextField(
            controller: _thoughtController,
            focusNode: _focusNode,
            maxLines: 4,
            minLines: 2,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1A3A3A),
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: currentType['placeholder'],
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 14),
          
          // ═══════════════════════════════════════════════════════════════════
          // Indicateur du TOTAL des sources sélectionnées (profil + roue)
          // Tooltip au toucher pour montrer les sources par défaut
          // ═══════════════════════════════════════════════════════════════════
          if (_totalSourcesCount > 0) ...[
            GestureDetector(
              onTap: _isUsingDefaultSources ? _showDefaultSourcesDialog : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E8B7B).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF2E8B7B), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _isUsingDefaultSources 
                          ? '$_totalSourcesCount sagesse(s) par défaut'
                          : '$_totalSourcesCount sagesse(s) sélectionnée(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E8B7B),
                      ),
                    ),
                    // Indicateur tactile pour sources par défaut
                    if (_isUsingDefaultSources) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.info_outline, color: Color(0xFF2E8B7B), size: 14),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          
          // Bouton "Voir autrement" (génération directe)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _thoughtController.text.trim().isEmpty 
                  ? null 
                  : _navigateToReflection,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                'Voir autrement',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                disabledForegroundColor: const Color(0xFF9E9E9E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // ═══════════════════════════════════════════════════════════════════
          // NOUVEAU : Bouton "Émotions liées et autre regard"
          // ═══════════════════════════════════════════════════════════════════
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _thoughtController.text.trim().isEmpty 
                  ? null 
                  : _navigateToReflectionWithEmotions,
              icon: Image.asset(
                'assets/univers_visuel/emotionsdujour.png',
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => const Icon(Icons.favorite_outline, size: 18),
              ),
              label: Text(
                'Enregistre les émotions liées à ta pensée si tu le souhaites , puis regarde autrement',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C4DFF),
                side: BorderSide(
                  color: _thoughtController.text.trim().isEmpty 
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF7C4DFF),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Lien "Retour au menu"
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
              icon: const Icon(Icons.arrow_back, size: 14),
              label: Text(
                'Retour au menu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF5BA3A8),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5BA3A8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton de type d'entrée avec icônes existantes
  Widget _buildEntryTypeButton(int index) {
    final type = _entryTypes[index];
    final isSelected = _selectedEntryType == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedEntryType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF2E8B7B).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2E8B7B).withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Icône depuis assets existants
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/univers_visuel/${type['icon']}',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForType(index),
                    color: const Color(0xFF2E8B7B),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              type['label'],
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFF2E8B7B)
                    : const Color(0xFF5A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(int index) {
    switch (index) {
      case 0: return Icons.psychology_outlined;
      case 1: return Icons.place_outlined;
      case 2: return Icons.help_outline;
      case 3: return Icons.compare_arrows;
      default: return Icons.edit_note;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. BLOC ÉMOTIONS - "Partage ce que tu ressens" (symétrique au bloc pensées)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildEmotionsBlock() {
    return AnimatedOpacity(
      opacity: _isTyping ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/daily-mood'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE57373).withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône émotions existante
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/univers_visuel/emotionsdujour.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_outline, color: Color(0xFFE57373), size: 26),
                  ),
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partage ce que tu ressens',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E8B7B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Comment tu te sens là, maintenant ?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF5BA3A8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFE57373),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. BLOC SOURCES SPIRITUELLES (séparé, cliquable vers écran dédié)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSpiritualSourcesBlock() {
    return AnimatedOpacity(
      opacity: _isTyping ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/sources-spirituelles').then((_) => _loadProfileSources()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et sous-titre
              Row(
                children: [
                  // Icône spiritualités
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/univers_visuel/spiritualites.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0), size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sources spirituelles',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E8B7B),
                          ),
                        ),
                        Text(
                          'Choisis une source selon tes croyances',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF5BA3A8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flèche
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF9C27B0),
                      size: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 14),
              
              // Rangée des 5 icônes décoratives
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _spiritualIcons.map((iconName) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/univers_visuel/$iconName',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF9C27B0),
                          size: 22,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. BLOC SOURCES HUMANISTES - Quiz & Hasard côte à côte
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildHumanistSourcesBlock() {
    return AnimatedOpacity(
      opacity: _isTyping ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E57C2).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec icône sources
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/univers_visuel/orientation.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7E57C2).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_stories, color: Color(0xFF7E57C2), size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Laisse-toi guider dans les sources humanistes',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E8B7B),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Quiz et Hasard côte à côte
            Row(
              children: [
                // Quiz
                Expanded(
                  child: _buildSourceOptionCard(
                    iconPath: 'assets/univers_visuel/quiz.png',
                    title: 'Quiz',
                    subtitle: 'Ce qui te correspond',
                    color: const Color(0xFF7E57C2),
                    onTap: () => Navigator.pushNamed(context, '/orientation').then((_) => _loadProfileSources()),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Hasard (appelle WisdomWheelDialog)
                Expanded(
                  child: _buildSourceOptionCard(
                    iconPath: 'assets/univers_visuel/rouehasard.png',
                    title: 'Hasard',
                    subtitle: 'Fais confiance',
                    color: const Color(0xFFFF7043),
                    onTap: _showWisdomWheel,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Lien vers exploration complète des sources humanistes
            GestureDetector(
              onTap: _showSourcesBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Explore les sources humanistes',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E8B7B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF2E8B7B),
                      size: 18,
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

  /// Carte d'option de source (Quiz ou Hasard) - avec icône depuis assets
  Widget _buildSourceOptionCard({
    required String iconPath,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Icône depuis assets
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                iconPath,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    title == 'Quiz' ? Icons.quiz_outlined : Icons.casino_outlined,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A3A3A),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF5BA3A8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. ACCÈS RAPIDES - Historiques + Profil (réduit, profil remonté)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildQuickAccessSection() {
    return AnimatedOpacity(
      opacity: _isTyping ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Accès rapides',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A3A3A),
              ),
            ),
          ),
          
          // Grille de cartes 3 colonnes (Pensées, Émotions, Profil)
          Row(
            children: [
              // Historique pensées
              Expanded(
                child: _buildCompactAccessCard(
                  icon: 'historique_des_pensees.png',
                  fallbackIcon: Icons.history,
                  title: 'Mes pensées',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Historique émotions
              Expanded(
                child: _buildCompactAccessCard(
                  icon: 'suivi_emotions.png',
                  fallbackIcon: Icons.timeline,
                  title: 'Mes émotions',
                  color: const Color(0xFFFF7043),
                  onTap: () => Navigator.pushNamed(context, '/emotion-timeline'),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Profil (remonté ici)
              Expanded(
                child: _buildCompactAccessCard(
                  icon: 'profil.png',
                  fallbackIcon: Icons.person_outline,
                  title: 'Mon profil',
                  color: const Color(0xFF5C6BC0),
                  onTap: () => Navigator.pushNamed(context, '/profile').then((_) => _loadProfileSources()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Carte d'accès compacte
  Widget _buildCompactAccessCard({
    required String icon,
    required IconData fallbackIcon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/univers_visuel/$icon',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    color: color,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Titre
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E8B7B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog affichant les 4 sources par défaut avec leurs icônes
  void _showDefaultSourcesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF2E8B7B), size: 24),
            const SizedBox(width: 10),
            Text(
              'Sources par défaut',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ces 4 sources d\'inspiration sont utilisées par défaut. Tu peux les personnaliser via le quiz ou les roues.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            _buildDefaultSourceTile('aristote', 'Aristote', 'Philosophe'),
            _buildDefaultSourceTile('existentialisme', 'Existentialisme', 'Courant philosophique'),
            _buildDefaultSourceTile('realisme', 'Réalisme', 'Courant littéraire'),
            _buildDefaultSourceTile('schemas_young', 'Schémas de Young', 'Approche psychologique'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Compris',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E8B7B),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Widget pour afficher une source par défaut avec son icône
  Widget _buildDefaultSourceTile(String id, String name, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/univers_visuel/$id.png',
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF2E8B7B)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Indicateur mode invité
  Widget _buildGuestIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D5A8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFFB8960C),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mode invité - Ton historique ne sera pas sauvegardé',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8B7355),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Navigation vers l'écran de réflexion avec la pensée pré-remplie
  /// MODIFIÉ : Passe les sources de la roue + skipEmotions = true (génération directe)
  /// RÈGLE: Sources du hasard utilisées 1 seule fois puis réinitialisées
  void _navigateToReflection() {
    final thought = _thoughtController.text.trim();
    final type = _entryTypes[_selectedEntryType]['id'];
    if (thought.isNotEmpty) {
      // Copier les sources avant réinitialisation
      final sourcesToUse = _selectedRandomSources.isNotEmpty 
          ? List<String>.from(_selectedRandomSources) 
          : null;
      
      // Réinitialiser immédiatement (usage unique)
      setState(() => _selectedRandomSources = []);
      
      Navigator.pushNamed(
        context, 
        '/main',
        arguments: {
          'initialThought': thought,
          'entryType': type,
          'randomSources': sourcesToUse,
          'skipEmotions': true, // NOUVEAU : Génération directe sans émotions
        },
      );
    }
  }
  
  /// NOUVEAU : Navigation avec émotions
  /// RÈGLE: Sources du hasard utilisées 1 seule fois puis réinitialisées
  void _navigateToReflectionWithEmotions() {
    final thought = _thoughtController.text.trim();
    final type = _entryTypes[_selectedEntryType]['id'];
    if (thought.isNotEmpty) {
      // Copier les sources avant réinitialisation
      final sourcesToUse = _selectedRandomSources.isNotEmpty 
          ? List<String>.from(_selectedRandomSources) 
          : null;
      
      // Réinitialiser immédiatement (usage unique)
      setState(() => _selectedRandomSources = []);
      
      Navigator.pushNamed(
        context, 
        '/main',
        arguments: {
          'initialThought': thought,
          'entryType': type,
          'randomSources': sourcesToUse,
          'skipEmotions': false, // NOUVEAU : Parcours avec émotions
        },
      );
    }
  }

  /// Afficher une pensée positive (bottom sheet 50%)
  void _showPositiveThought() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PositiveThoughtSheet(),
    );
  }

  /// Afficher la roue des sagesses (WisdomWheelDialog)
  /// MODIFIÉ : Sauvegarde les sources dans le profil (remplace les sources par défaut)
  void _showWisdomWheel() async {
    final sources = await WisdomWheelDialog.show(context);
    if (sources != null && sources.isNotEmpty && mounted) {
      // Sauvegarder les sources dans le profil (comme le quiz)
      await _saveWheelSourcesToProfile(sources);
      
      // Recharger les sources du profil
      await _loadProfileSources();
      
      // Afficher confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sources.length} sagesse(s) enregistrée(s)'),
          backgroundColor: const Color(0xFF2E8B7B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// Sauvegarder les sources de la roue dans le profil
  /// Catégorise chaque source et remplace les sources par défaut
  Future<void> _saveWheelSourcesToProfile(List<String> sources) async {
    try {
      // Mapping des IDs vers les catégories (basé sur wisdom_wheel_dialog.dart)
      const litteraires = ['humanisme', 'romantisme', 'realisme', 'existentialisme', 
                          'absurdisme', 'poetique', 'mystique', 'symboliste_moderne'];
      const psychologiques = ['jungienne', 'tcc', 'logotherapie', 'act', 
                              'the_work', 'schemas_young', 'humaniste_rogers'];
      const philosophes = ['socrate', 'platon', 'aristote', 'epictete', 'marc_aurele',
                          'spinoza', 'kant', 'nietzsche', 'camus', 'sartre', 'confucius'];
      const courantsPhilo = ['stoicisme_philo', 'epicurisme', 'existentialisme_philo',
                            'humanisme_philo', 'vitalisme', 'absurdisme_philo', 'rationalisme',
                            'empirisme', 'pragmatisme', 'phenomenologie', 'idealisme',
                            'utilitarisme', 'structuralisme', 'philosophies_orientales'];
      
      // Catégoriser les sources sélectionnées
      final selectedLitteraires = sources.where((s) => litteraires.contains(s)).toList();
      final selectedPsycho = sources.where((s) => psychologiques.contains(s)).toList();
      final selectedPhilosophes = sources.where((s) => philosophes.contains(s)).toList();
      final selectedCourantsPhilo = sources.where((s) => courantsPhilo.contains(s)).toList();
      
      // Récupérer le profil actuel
      final profileData = await CompleteAuthService.instance.getProfile() ?? {};
      
      // Mettre à jour avec les nouvelles sources (REMPLACE, n'ajoute pas)
      profileData['courantsLitteraires'] = selectedLitteraires;
      profileData['approchesPsychologiques'] = selectedPsycho;
      profileData['philosophesSelectionnes'] = selectedPhilosophes;
      profileData['courantsPhilosophiques'] = selectedCourantsPhilo;
      profileData['religionsSelectionnees'] = <String>[]; // Pas de spirituelles dans la roue
      profileData['lastUpdated'] = DateTime.now().toIso8601String();
      
      await CompleteAuthService.instance.saveProfile(profileData);
      print('✅ Sources de la roue sauvegardées: ${sources.length}');
    } catch (e) {
      print('⚠️ Erreur sauvegarde sources roue: $e');
    }
  }

  /// Bottom sheet pour le choix des sources humanistes (90%)
  void _showSourcesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => _SourcesSheet(
          scrollController: scrollController,
          onSourcesChanged: _loadProfileSources,
        ),
      ),
    );
  }

  /// Dialog de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Se déconnecter',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A3A3A),
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF5A8A8A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: const Color(0xFF5BA3A8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Réinitialiser le flag pour la prochaine connexion invité
              _guestSourcesAlreadyCleared = false;
              await CompleteAuthService.instance.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Déconnecter',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// BOTTOM SHEET - PENSÉE POSITIVE (50%)
// ════════════════════════════════════════════════════════════════

class _PositiveThoughtSheet extends StatelessWidget {
  // Pensées positives temporaires (sera remplacé par génération IA)
  static const List<Map<String, String>> _thoughts = [
    {
      'text': 'Ce qui te semble insurmontable aujourd\'hui peut devenir une simple étape demain.',
      'source': 'Sagesse stoïcienne',
    },
    {
      'text': 'Tu n\'as pas à tout comprendre maintenant. Parfois, il suffit d\'être là.',
      'source': 'Pleine conscience',
    },
    {
      'text': 'La confusion est souvent le signe que quelque chose cherche à émerger.',
      'source': 'Psychologie humaniste',
    },
    {
      'text': 'Même les questions sans réponse ont leur place en toi.',
      'source': 'Existentialisme',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    final thought = _thoughts[random.nextInt(_thoughts.length)];
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Titre
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/univers_visuel/pensee_positive.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DB6AC).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lightbulb_outline, color: Color(0xFF4DB6AC), size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pensée du moment',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A3A3A),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Citation
                  Text(
                    '"${thought['text']}"',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A3A3A),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Source
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DB6AC).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      thought['source']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E8B7B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bouton fermer
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B7B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Merci',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// BOTTOM SHEET - CHOIX DES SOURCES HUMANISTES (90%)
// ════════════════════════════════════════════════════════════════

class _SourcesSheet extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback? onSourcesChanged;
  
  const _SourcesSheet({
    required this.scrollController,
    this.onSourcesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Titre
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Explorer par catégorie',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A3A3A),
              ),
            ),
          ),
          
          // Liste des catégories (HUMANISTES uniquement - pas spiritualités)
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Psychologie
                _buildCategoryOption(
                  context,
                  iconPath: 'psychologie.png',
                  fallbackIcon: Icons.psychology_outlined,
                  title: 'Psychologie',
                  subtitle: 'Approches thérapeutiques',
                  color: const Color(0xFF42A5F5),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sources-psychologiques').then((_) => onSourcesChanged?.call());
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Littérature
                _buildCategoryOption(
                  context,
                  iconPath: 'litterature.png',
                  fallbackIcon: Icons.menu_book_outlined,
                  title: 'Littérature',
                  subtitle: 'Courants littéraires',
                  color: const Color(0xFF66BB6A),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sources-litteraires').then((_) => onSourcesChanged?.call());
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Philosophie (Écoles)
                _buildCategoryOption(
                  context,
                  iconPath: 'philosophie.png',
                  fallbackIcon: Icons.account_balance_outlined,
                  title: 'Philosophie',
                  subtitle: 'Écoles de pensée',
                  color: const Color(0xFFFFB74D),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sources-philosophiques').then((_) => onSourcesChanged?.call());
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Philosophes
                _buildCategoryOption(
                  context,
                  iconPath: 'philosophes.png',
                  fallbackIcon: Icons.person_outline,
                  title: 'Philosophes',
                  subtitle: 'Grands penseurs',
                  color: const Color(0xFF5C6BC0),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sources-philosophes').then((_) => onSourcesChanged?.call());
                  },
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOption(
    BuildContext context, {
    required String iconPath,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Icône depuis assets
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/univers_visuel/$iconPath',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: color, size: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A3A3A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF5BA3A8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

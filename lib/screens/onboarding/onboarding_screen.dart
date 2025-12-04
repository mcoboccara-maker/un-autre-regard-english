import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:un_autre_regard/models/user_profile.dart';
import 'package:un_autre_regard/services/storage_service.dart';
import 'package:un_autre_regard/config/approach_config.dart';
import 'package:un_autre_regard/widgets/emotion_widgets/approach_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Controllers pour les champs de saisie
  final Map<String, TextEditingController> _controllers = {
    'personalInfo': TextEditingController(),
    'healthEnergy': TextEditingController(),
    'work': TextEditingController(),
    'financial': TextEditingController(),
    'valeurs': TextEditingController(),
    'ressources': TextEditingController(),
  };

  // Liste des approches sélectionnées
  List<String> _selectedApproaches = [];

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Bienvenue !",
      subtitle: "Créons ensemble ton espace personnel",
      description: "Pour t'offrir des perspectives personnalisées, nous allons créer ton profil contextuel. Ces informations resteront privées et stockées uniquement sur ton appareil.",
      icon: Icons.person_add,
      isIntro: true,
    ),
    OnboardingPageData(
      title: "Profil personnel",
      subtitle: "Qui es-tu ?",
      description: "Partage quelques éléments sur ta situation de vie",
      placeholder: "Ex: 34 ans, en couple, 2 enfants en bas âge, vis en banlieue parisienne, aime la lecture et la randonnée...",
      field: 'personalInfo',
      icon: Icons.person,
    ),
    OnboardingPageData(
      title: "Santé & Énergie",
      subtitle: "Comment vas-tu physiquement ?",
      description: "Ton état de santé, ton sommeil, ton niveau d'énergie",
      placeholder: "Ex: Sommeil parfois agité, mal de dos récurrent, pratique la course à pied 2x/semaine, fatigue en fin de journée...",
      field: 'healthEnergy',
      icon: Icons.favorite,
    ),
    OnboardingPageData(
      title: "Travail",
      subtitle: "Ta vie professionnelle",
      description: "Ton poste, tes charges, ce qui t'use ou te nourrit",
      placeholder: "Ex: Manager dans une startup, équipe de 8 personnes, beaucoup de pression mais projets stimulants, télétravail 3j/semaine...",
      field: 'work',
      icon: Icons.work,
    ),
    OnboardingPageData(
      title: "Finances",
      subtitle: "Ta situation financière",
      description: "Tes contraintes du moment, tes principales préoccupations",
      placeholder: "Ex: Crédit immobilier, économies pour les vacances, préoccupation pour l'avenir des enfants...",
      field: 'contraintes',
      icon: Icons.account_balance_wallet,
    ),
    OnboardingPageData(
      title: "Valeurs & Repères",
      subtitle: "Qu'est-ce qui compte pour toi ?",
      description: "Tes valeurs spirituelles, éthiques, philosophiques",
      placeholder: "Ex: Attaché aux valeurs familiales, spiritualité bouddhiste, importance de l'écologie, croyance en la bienveillance...",
      field: 'valuesBeliefs',
      icon: Icons.auto_awesome,
    ),
    OnboardingPageData(
      title: "Ressources aidantes",
      subtitle: "Ce qui t'a déjà aidé",
      description: "Personnes, pratiques, lectures qui te font du bien",
      placeholder: "Ex: Discussions avec ma sœur, méditation le matin, lectures de Marc-Aurèle, promenades en nature...",
      field: 'ressources',
      icon: Icons.healing,
    ),
    OnboardingPageData(
      title: "Tes approches préférées",
      subtitle: "Comment veux-tu être accompagné ?",
      description: "Choisis les perspectives qui résonnent le plus avec toi. Tu pourras les modifier plus tard.",
      icon: Icons.psychology,
      isApproachSelection: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final pageData = _pages[index];
                  return pageData.isApproachSelection == true 
                      ? _buildApproachSelectionPage(pageData)
                      : _buildPage(pageData);
                },
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Étape ${_currentPage + 1} sur ${_pages.length}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Text(
                '${((_currentPage + 1) / _pages.length * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / _pages.length,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              // Bouton Retour
              if (_currentPage > 0)
                OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: Text(
                    'Retour',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              
              if (_currentPage > 0) const SizedBox(width: 16),
              
              // Bouton Principal
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  child: Text(
                    _currentPage == 0 
                        ? 'Commencer'
                        : _currentPage == _pages.length - 1 
                            ? 'Terminer'
                            : 'Suivant',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Bouton Passer
          if (_currentPage > 0 && _currentPage < _pages.length - 1) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skipToMain,
              child: Text(
                'Terminer plus tard',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pageData.icon,
                size: 48,
                color: const Color(0xFF6366F1),
              ),
            ),
          ).animate().scale(delay: 200.ms),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            pageData.title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3, end: 0),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            pageData.subtitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6366F1),
            ),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.3, end: 0),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            pageData.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 32),
          
          // Champ de saisie (si pas page d'intro)
          if (!pageData.isIntro) ...[
            Container(
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
              child: TextField(
                controller: _controllers[pageData.field!],
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: pageData.placeholder,
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                  height: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 12),
            
            // Compteur de caractères
            Row(
              children: [
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controllers[pageData.field!]!,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length} caractères',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApproachSelectionPage(OnboardingPageData pageData) {
    return Column(
      children: [
        // Header de la page d'approches
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pageData.icon,
                  size: 48,
                  color: const Color(0xFF6366F1),
                ),
              ).animate().scale(delay: 200.ms),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                pageData.title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                pageData.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6366F1),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                pageData.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
        
        // Sélecteur d'approches
        Expanded(
          child: ApproachSelector(
            selectedApproaches: _selectedApproaches,
            onApproachesChanged: (approaches) {
              setState(() {
                _selectedApproaches = approaches;
              });
            },
          ),
        ),
      ],
    );
  }

  void _handleNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfileAndProceed();
    }
  }

  void _skipToMain() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  Future<void> _saveProfileAndProceed() async {
    try {
      // Sauvegarder le profil utilisateur
      final profile = UserProfile(
        situationFamiliale: _controllers['personalInfo']?.text.trim(),
        healthEnergy: _controllers['healthEnergy']?.text.trim(),
        contraintes: _controllers['financial']?.text.trim(),
        valeurs: _controllers['valeurs']?.text.trim(),
        ressources: _controllers['ressources']?.text.trim(),
        lastUpdated: DateTime.now(),
        isCompleted: true,
      );

      await StorageService.instance.saveUserProfile(profile);
      
      // Sauvegarder les approches sélectionnées
      await StorageService.instance.saveDefaultApproaches(_selectedApproaches);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      // En cas d'erreur, on continue quand même
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final String? placeholder;
  final String? field;
  final IconData icon;
  final bool isIntro;
  final bool isApproachSelection;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    this.placeholder,
    this.field,
    required this.icon,
    this.isIntro = false,
    this.isApproachSelection = false,
  });
}

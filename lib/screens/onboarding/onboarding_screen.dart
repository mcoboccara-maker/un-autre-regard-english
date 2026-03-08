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
      title: "Welcome!",
      subtitle: "Let's create your personal space together",
      description: "To offer you personalized perspectives, we'll create your contextual profile. This information will remain private and stored only on your device.",
      icon: Icons.person_add,
      isIntro: true,
    ),
    OnboardingPageData(
      title: "Personal Profile",
      subtitle: "Who are you?",
      description: "Share a few details about your life situation",
      placeholder: "E.g.: 34 years old, in a relationship, 2 young children, lives in the suburbs, enjoys reading and hiking...",
      field: 'personalInfo',
      icon: Icons.person,
    ),
    OnboardingPageData(
      title: "Health & Energy",
      subtitle: "How are you physically?",
      description: "Your health, sleep, energy level",
      placeholder: "E.g.: Sometimes restless sleep, recurring back pain, running twice a week, tired by end of day...",
      field: 'healthEnergy',
      icon: Icons.favorite,
    ),
    OnboardingPageData(
      title: "Work",
      subtitle: "Your professional life",
      description: "Your role, responsibilities, what drains or fulfills you",
      placeholder: "E.g.: Manager at a startup, team of 8, high pressure but stimulating projects, remote work 3 days/week...",
      field: 'work',
      icon: Icons.work,
    ),
    OnboardingPageData(
      title: "Finances",
      subtitle: "Your financial situation",
      description: "Your current constraints, main concerns",
      placeholder: "E.g.: Mortgage, saving for vacation, concern about the children's future...",
      field: 'contraintes',
      icon: Icons.account_balance_wallet,
    ),
    OnboardingPageData(
      title: "Values & Beliefs",
      subtitle: "What matters to you?",
      description: "Your spiritual, ethical, philosophical values",
      placeholder: "E.g.: Attached to family values, Buddhist spirituality, importance of ecology, belief in kindness...",
      field: 'valuesBeliefs',
      icon: Icons.auto_awesome,
    ),
    OnboardingPageData(
      title: "Helpful Resources",
      subtitle: "What has already helped you",
      description: "People, practices, readings that do you good",
      placeholder: "E.g.: Talks with my sister, morning meditation, reading Marcus Aurelius, nature walks...",
      field: 'ressources',
      icon: Icons.healing,
    ),
    OnboardingPageData(
      title: "Your Preferred Approaches",
      subtitle: "How do you want to be guided?",
      description: "Choose the perspectives that resonate most with you. You can change them later.",
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
                'Step ${_currentPage + 1} of ${_pages.length}',
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
                    'Back',
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
                        ? 'Get Started'
                        : _currentPage == _pages.length - 1
                            ? 'Finish'
                            : 'Next',
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
                'Finish Later',
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
                      '${value.text.length} characters',
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

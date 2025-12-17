import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isPaused = false;

  final List<WelcomePage> _pages = [
    WelcomePage(
      title: 'Bienvenue dans\nUn Autre Regard',
      subtitle: 'Parce qu\'une autre vie est possible',
      content: 'Bienvenue dans votre espace de réflexion personnelle. Découvrez de nouvelles perspectives sur vos pensées et émotions.',
      icon: Icons.visibility, // Fallback
      iconPath: 'assets/univers_visuel/icone.png',
      gradient: [Color(0xFF8B7FC7), Color(0xFFA89ED8)],  // Violet pastel
    ),
    WelcomePage(
      title: 'Explorez vos émotions',
      subtitle: 'Avec bienveillance et profondeur',
      content: 'Apprenez à identifier et comprendre vos émotions grâce à notre interface intuitive et nos outils de réflexion personnelle.',
      icon: Icons.favorite_outline,
      gradient: [Color(0xFF6BB89D), Color(0xFF8ECFB8)],  // Vert pastel
    ),
    WelcomePage(
      title: 'Perspectives multiples',
      subtitle: 'Sagesses anciennes et approches modernes',
      content: 'Découvrez différentes approches : méditation, philosophie antique, psychologie moderne et bien d\'autres.',
      icon: Icons.psychology_outlined,
      gradient: [Color(0xFFE8B86D), Color(0xFFF0CFA0)],  // Jaune-orange pastel
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isPaused) {
        if (_currentPage < _pages.length - 1) {
          _nextPage();
        }
        // Ne redirige plus automatiquement vers login
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pauseAutoSlide() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeAutoSlide() {
    setState(() {
      _isPaused = false;
    });
    _startAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _pauseAutoSlide,
        onDoubleTap: _resumeAutoSlide,
        child: Stack(
          children: [
            // Pages
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                if (!_isPaused) {
                  _startAutoSlide();
                }
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
            
            // Header avec icône connexion
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isPaused)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pausé',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  // Bouton connexion
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      icon: const Icon(
                        Icons.login,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Se connecter',
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicateurs de page et contrôles
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Indicateurs de points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons de contrôle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton Passer
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.8),
                          ),
                          child: Text(
                            'Passer',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        // Bouton Suivant/Commencer
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pauseAutoSlide();
                              _nextPage();
                            } else {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _pages[_currentPage].gradient[0],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage < _pages.length - 1 
                                  ? Icons.arrow_forward 
                                  : Icons.login,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Instructions d'interaction (première page seulement)
            if (_currentPage == 0)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.72,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tapez pour pauser • Double-tapez pour reprendre',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ).animate().fadeIn(delay: 2000.ms),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(WelcomePage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Icon ou Image de l'application
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: page.iconPath != null
                    ? Image.asset(
                        page.iconPath!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          page.icon,
                          size: 64,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        page.icon,
                        size: 64,
                        color: Colors.white,
                      ),
              ).animate().scale(delay: 300.ms),
              
              const SizedBox(height: 32),
              
              // Titre
              Text(
                page.title,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 16),
              
              // Sous-titre
              Text(
                page.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms),
              
              const SizedBox(height: 24),
              
              // Contenu
              Text(
                page.content,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 900.ms),
              
              const Spacer(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class WelcomePage {
  final String title;
  final String subtitle;
  final String content;
  final IconData icon;
  final String? iconPath;
  final List<Color> gradient;

  const WelcomePage({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    this.iconPath,
    required this.gradient,
  });
}

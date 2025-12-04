// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/complete_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final email = CompleteAuthService.instance.currentUserEmail;
    setState(() {
      _userEmail = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFF0F9FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildMenuPyramid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.visibility, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un Autre Regard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _userEmail ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Menu en pyramide avec icones PNG pleine taille (SANS legende)
  Widget _buildMenuPyramid() {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Niveau 1 : Profil (1 icone centree)
        _buildMenuRow([
          _MenuItem(
            iconPath: 'assets/univers_visuel/profil.png',
            route: '/profile',
          ),
        ]),
        
        const SizedBox(height: 12),
        
        // Niveau 2 : Emotions du jour + Pensee (2 icones)
        _buildMenuRow([
          _MenuItem(
            iconPath: 'assets/univers_visuel/emotionsdujour.png',
            route: '/daily-mood',
          ),
          _MenuItem(
            iconPath: 'assets/univers_visuel/penseejour.png',
            route: '/main',
          ),
        ]),
        
        const SizedBox(height: 12),
        
        // Niveau 3 : Spiritualite (1 icone centree)
        _buildMenuRow([
          _MenuItem(
            iconPath: 'assets/univers_visuel/spiritualites.png',
            route: '/sources-spirituelles',
          ),
        ]),
        
        const SizedBox(height: 12),
        
        // Niveau 4 : Orientation (1 icone centree)
        _buildMenuRow([
          _MenuItem(
            iconPath: 'assets/univers_visuel/orientation.png',
            route: '/orientation',
          ),
        ]),
        
        const SizedBox(height: 12),
        
        // Niveau 5 : Psychologie, Litterature, Philo, Philosophes (4 icones)
        _buildMenuRow([
          _MenuItem(
            iconPath: 'assets/univers_visuel/psychologie.png',
            route: '/sources-psychologiques',
          ),
          _MenuItem(
            iconPath: 'assets/univers_visuel/litterature.png',
            route: '/sources-litteraires',
          ),
          _MenuItem(
            iconPath: 'assets/univers_visuel/philosophie.png',
            route: '/sources-philosophiques',
          ),
          _MenuItem(
            iconPath: 'assets/univers_visuel/philosophes.png',
            route: '/sources-philosophes',
          ),
        ]),
        
        const SizedBox(height: 12),
        
        // Niveau 6 : Historique pensees + Suivi emotions (2 icones)
        _buildMenuRow([
          _MenuItem(
            iconPath: 'assets/univers_visuel/historique des pensees.png',
            route: '/history',
          ),
          _MenuItem(
            iconPath: 'assets/univers_visuel/suivi_emotions.png',
            route: '/emotion-timeline',
          ),
        ]),
        
        const SizedBox(height: 12),
        
        // Niveau 7 : Deconnexion avec image PNG verte
        _buildLogoutButton(),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMenuRow(List<_MenuItem> items) {
    // Calculer la taille des icones selon le nombre d'items et la largeur ecran
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        double iconSize;
        double spacing = 8;
        
        if (items.length == 1) {
          iconSize = 100;
        } else if (items.length == 2) {
          iconSize = 90;
        } else {
          // 4 items - calculer pour que ca rentre
          iconSize = (screenWidth - (spacing * (items.length + 1))) / items.length;
          iconSize = iconSize.clamp(60, 80); // Min 60, max 80
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: _buildMenuIcon(item, iconSize),
            );
          }).toList(),
        ).animate().fadeIn(delay: 100.milliseconds);
      },
    );
  }

  // Icone PNG qui remplit tout le carre, SANS legende
  Widget _buildMenuIcon(_MenuItem item, double size) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, item.route);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            item.iconPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Image non trouvee: ${item.iconPath}');
              return Container(
                color: Colors.grey[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: size * 0.3,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.iconPath.split('/').last,
                        style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // CORRIGE : Bouton deconnexion avec image PNG verte au lieu d'icone Material rouge
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => _showLogoutConfirmation(),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/univers_visuel/deconnexion.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Image deconnexion non trouvee');
              // Fallback si l'image n'existe pas
              return Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: const Color(0xFF2E7D6B),
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deconnexion',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E7D6B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.milliseconds);
  }

  // Dialog de confirmation avant deconnexion
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Deconnexion',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D6B),
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous deconnecter ?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await CompleteAuthService.instance.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Se deconnecter',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String iconPath;
  final String route;

  const _MenuItem({
    required this.iconPath,
    required this.route,
  });
}

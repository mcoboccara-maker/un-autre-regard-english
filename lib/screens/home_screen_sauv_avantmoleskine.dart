// lib/screens/home_screen.dart
// Style CARTES - Icône à gauche + texte à droite
// + Bouton Éclairage Surprise (Machine à Sous OU Carrefour)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/complete_auth_service.dart';
import '../widgets/slot_machine_dialog.dart';
import '../widgets/crossroads_dialog.dart';

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

  /// Ouvre le sélecteur d'inspiration (choix entre Machine à Sous et Carrefour)
  Future<void> _openInspirationSelector() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Fond bleu clair marbré
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F7FA),  // Cyan très clair
                Color(0xFFB2EBF2),  // Cyan clair
                Color(0xFF80DEEA),  // Cyan
                Color(0xFFB2DFDB),  // Teal très clair
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✨ Choisissez votre mode',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comment voulez-vous découvrir vos sources ?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.blueGrey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Option 1 - Machine à Sous
              _buildChoiceCard(
                icon: Icons.casino,
                emoji: '🎰',
                title: 'Machine à Sous',
                subtitle: 'Faites tourner les rouleaux !',
                color: Colors.amber,
                onTap: () => Navigator.pop(context, 'slot'),
              ),
              
              const SizedBox(height: 12),
              
              // Option 2 - Carrefour
              _buildChoiceCard(
                icon: Icons.explore,
                emoji: '🚏',
                title: 'Carrefour des Inspirations',
                subtitle: 'Laissez le destin guider vos pas',
                color: const Color(0xFFe94560),
                onTap: () => Navigator.pop(context, 'crossroads'),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.inter(color: Colors.blueGrey[500]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (choice == null || !mounted) return;
    
    List<String>? selectedSources;
    
    if (choice == 'slot') {
      selectedSources = await SlotMachineDialog.show(context);
    } else if (choice == 'crossroads') {
      selectedSources = await CrossroadsDialog.show(context);
    }
    
    if (selectedSources != null && selectedSources.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Sources: ${selectedSources.join(", ")}'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
      
      Navigator.pushNamed(
        context, 
        '/main',
        arguments: {'randomSources': selectedSources},
      );
    }
  }
  
  Widget _buildChoiceCard({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
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
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFB2EBF2),
              Color(0xFFE0F2F1),
              Color(0xFFB2DFDB),
              Color(0xFFE0F7FA),
              Color(0xFFE8F5E9),
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSlotMachineButton(),
                  const SizedBox(height: 20),
                  _buildMenuList(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/univers_visuel/icone.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Color(0xFF1565C0),
                  size: 45,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                "Bienvenue dans 'Un Autre Regard' :\npour éclairer vos pensées\net comprendre vos émotions",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1565C0),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (_userEmail != null) ...[
                const SizedBox(height: 8),
                Text(
                  _userEmail!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildSlotMachineButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openInspirationSelector,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a237e), Color(0xFF3949ab)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.casino,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Éclairage Surprise',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Machine à sous ou Carrefour des inspirations',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.amber.withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 300.ms)
      .shimmer(delay: 1000.ms, duration: 1500.ms, color: Colors.amber.withOpacity(0.3));
  }

  Widget _buildMenuList() {
    final menuItems = [
      _MenuItem(
        iconPath: 'assets/univers_visuel/emotionsdujour.png',
        title: 'Mes émotions du jour',
        description: 'Exprimez vos émotions : À tout moment, enregistrez et partagez vos émotions et observez leur évolution dans le temps',
        route: '/daily-mood',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/penseejour.png',
        title: 'Mes pensées du jour',
        description: "Déposez vos pensées : L'application vous aide à y voir clair grâce à des éclairages personnalisés",
        route: '/main',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/suivi_emotions.png',
        title: 'Historique des émotions',
        description: 'Retrouvez l\'évolution de vos émotions dans le temps (mode connecté)',
        route: '/emotion-timeline',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/historique des pensees.png',
        title: 'Historique des pensées',
        description: 'Retrouvez l\'historique de vos pensées et des éclairages que vous avez reçus (mode connecté)',
        route: '/history',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/profil.png',
        title: 'Je suis',
        description: 'Pour des éclairages qui vous ressemblent, vous définissez votre profil une première fois — et vous pouvez le mettre à jour quand vous le souhaitez.',
        route: '/profile',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/spiritualites.png',
        title: 'Spiritualités',
        description: "Choisissez les sources spirituelles qui vous inspirent : si vous le souhaitez sélectionnez les éclairages d'une croyance",
        route: '/sources-spirituelles',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/orientation.png',
        title: 'Orientation',
        description: 'Un court quiz vous propose une source qui vous corresponde par catégorie',
        route: '/orientation',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/psychologie.png',
        title: 'Psychologie',
        description: 'Choisissez par vous-même pour un éclairage de sources psychologiques',
        route: '/sources-psychologiques',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/litterature.png',
        title: 'Littérature',
        description: 'Choisissez par vous-même pour un éclairage de sources littéraires',
        route: '/sources-litteraires',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/philosophie.png',
        title: 'Philosophie',
        description: 'Choisissez par vous-même pour un éclairage de sources philosophiques',
        route: '/sources-philosophiques',
      ),
      _MenuItem(
        iconPath: 'assets/univers_visuel/philosophes.png',
        title: 'Philosophes',
        description: "Choisissez par vous-même pour l'éclairage d'un philosophe",
        route: '/sources-philosophes',
      ),
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildMenuCard(item, index);
      }).toList(),
    );
  }

  Widget _buildMenuCard(_MenuItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, item.route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.iconPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        print('❌ Image non trouvée: ${item.iconPath}');
                        return Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              Text(
                                item.iconPath.split('/').last,
                                style: TextStyle(fontSize: 6, color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 14),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1976D2),
                          height: 1.4,
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
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 400 + (index * 60)))
      .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 400 + (index * 60)));
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
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
            errorBuilder: (_, __, ___) => Container(
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
                    'Déconnexion',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E7D6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1200.ms);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D6B),
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: Colors.grey[600]),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Se déconnecter',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String iconPath;
  final String title;
  final String description;
  final String route;

  const _MenuItem({
    required this.iconPath,
    required this.title,
    required this.description,
    required this.route,
  });
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/persistent_storage_service.dart';
import '../services/ai_service.dart';
import '../services/complete_auth_service.dart';
import '../models/user_profile.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;
  final bool showBackButton;
  final List<Widget>? additionalActions;
  final String? headerIconPath;  // NOUVEAU: chemin vers l'icône à afficher au lieu du titre

  const GlobalAppBar({
    super.key,
    this.title = '',
    this.showTitle = true,
    this.showBackButton = true,
    this.additionalActions,
    this.headerIconPath,  // NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // MODIFIÉ: Si headerIconPath est fourni, afficher l'icône au lieu du titre texte
      title: headerIconPath != null
          ? Image.asset(
              headerIconPath!,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback: afficher le titre texte si l'icône n'existe pas
                return showTitle && title.isNotEmpty
                    ? Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            )
          : (showTitle && title.isNotEmpty
              ? Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                )
              : null),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,  // MODIFIÉ: désactiver le leading automatique
      centerTitle: true,  // NOUVEAU: centrer l'icône/titre
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : null,
      actions: [
        // Actions supplémentaires
        if (additionalActions != null) ...additionalActions!,
        
        // Bouton Pensée positive avec icône PNG
        GestureDetector(
          onTap: () => _showPositiveThought(context),
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/univers_visuel/pensee_positive.png',  // CORRIGÉ: pensee_positive.png
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFF59E0B),
                  size: 24,
                );
              },
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Bouton Menu principal avec icône PNG
        GestureDetector(
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/univers_visuel/menu_principal.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.home,
                  color: Color(0xFF6366F1),
                  size: 24,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Afficher une pensée positive générée par IA
  void _showPositiveThought(BuildContext context) async {
    // Afficher le chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône PNG pour le chargement
              Image.asset(
                'assets/univers_visuel/pensee_positive.png',  // CORRIGÉ: pensee_positive.png
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return const CircularProgressIndicator(
                    color: Color(0xFFF59E0B),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Generation de ta pensee positive...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Récupérer le profil via CompleteAuthService
      final profileData = await CompleteAuthService.instance.getProfile();
      
      // Convertir en UserProfile
      UserProfile? profile;
      if (profileData != null) {
        profile = UserProfile.fromJson(profileData);
      }

      // Générer la pensée positive
      final thought = await AIService.instance.generatePositiveThought(
        userProfile: profile,
      );

      // Fermer le chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher la pensée positive
      if (context.mounted) {
        _showThoughtDialog(context, thought);
      }
    } catch (e) {
      // Fermer le chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher l'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showThoughtDialog(BuildContext context, String thought) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône PNG en haut
              Image.asset(
                'assets/univers_visuel/pensee_positive.png',  // CORRIGÉ: pensee_positive.png
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 32,
                      color: Color(0xFFF59E0B),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                thought,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showPositiveThought(context);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Autre pensee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Composant réutilisable pour tous les écrans de l'application
/// Applique automatiquement :
/// - Fond bleu dégradé
/// - Bouton Menu Principal en haut à droite
/// - Bouton Pensée Positive en haut à droite (à côté du menu)
/// - Bouton Retour en bas de page OU action personnalisée (bottomAction)
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showMenuButton;      // Icône menu_principal.png en haut à droite
  final bool showPositiveButton;  // Icône pensee_positive.png en haut à droite
  final bool showBackButton;      // Icône retour.png en bas
  final VoidCallback? onBack;     // Action personnalisée pour retour (sinon Navigator.pop)
  final List<Widget>? additionalActions; // Actions supplémentaires dans l'AppBar
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomAction;     // Widget personnalisé en bas (remplace le bouton retour)
  final String? headerIconPath;   // Icône à afficher dans le header (logo de la page)
  final bool showTitle;           // Afficher le titre texte ou non
  final bool transparentBackground; // Fond transparent (pour effets visuels custom)

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showMenuButton = true,
    this.showPositiveButton = true,
    this.showBackButton = true,
    this.onBack,
    this.additionalActions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomAction,
    this.headerIconPath,          // Nouveau paramètre
    this.showTitle = true,        // Par défaut on affiche le titre
    this.transparentBackground = false, // Par défaut on affiche le gradient
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: transparentBackground,
      backgroundColor: transparentBackground ? Colors.transparent : null,
      appBar: _buildAppBar(context),
      body: Container(
        // Fond transparent ou dégradé bleu selon le paramètre
        decoration: transparentBackground
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8FBFE),  // Blanc avec infime touche de bleu
                    Color(0xFFF5F9FD),  // Très légèrement plus bleuté
                    Color(0xFFF8FBFE),  // Retour quasi blanc
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
        child: Column(
          children: [
            // Corps principal
            Expanded(child: body),

            // Zone du bas: soit bottomAction personnalisé, soit bouton retour
            if (bottomAction != null)
              _buildBottomActionContainer(bottomAction!)
            else if (showBackButton)
              _buildBottomBackButton(context),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: transparentBackground ? Colors.transparent : Colors.white,
      elevation: 0,
      leading: null,
      automaticallyImplyLeading: false,
      // Titre: soit icône seule, soit texte, soit les deux
      title: headerIconPath != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  headerIconPath!,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(width: 40, height: 40);
                  },
                ),
                if (showTitle) ...[
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ],
            )
          : (showTitle
              ? Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                )
              : null),
      actions: [
        // Actions supplémentaires personnalisées
        if (additionalActions != null) ...additionalActions!,
        
        // Bouton Pensée Positive (pensee_positive.png) - CORRIGÉ
        if (showPositiveButton)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () => _showPositiveThought(context),
              tooltip: 'Pensée positive',
              icon: Image.asset(
                'assets/univers_visuel/pensee_positive.png',  // CORRIGÉ: pensee_positive au lieu de pensee
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFFBBF24),
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
        
        // Bouton Menu Principal (menu_principal.png)
        if (showMenuButton)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _goToHome(context),
              tooltip: 'Menu principal',
              icon: Image.asset(
                'assets/univers_visuel/menu_principal.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Container pour le bottomAction personnalisé
  Widget _buildBottomActionContainer(Widget action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: action,
      ),
    );
  }

  Widget _buildBottomBackButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/univers_visuel/retour.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF64748B),
                      size: 24,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Retour',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/menu',
      (route) => false,
    );
  }

  void _showPositiveThought(BuildContext context) {
    // Liste de pensées positives
    final thoughts = [
      "Chaque jour est une nouvelle opportunite de grandir. 🌱",
      "Tu as deja surmonte tant d'obstacles. Tu es plus fort(e) que tu ne le penses. 💪",
      "Prends le temps de respirer. Ce moment difficile passera. 🌬️",
      "Tu merites d'etre heureux(se) et en paix. 🕊️",
      "Tes emotions sont valides. Accueille-les avec bienveillance. 💚",
      "Un petit pas aujourd'hui peut mener a un grand changement demain. 👣",
      "Tu n'as pas besoin d'etre parfait(e), juste authentique. ✨",
      "La tempete finit toujours par se calmer. Tiens bon. 🌈",
      "Tu es exactement la ou tu dois etre en ce moment. 🎯",
      "Chaque emotion est un message. Ecoute ce qu'elle a a te dire. 💭",
    ];
    
    // Sélectionner une pensée aléatoire
    final random = DateTime.now().millisecondsSinceEpoch % thoughts.length;
    final thought = thoughts[random];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFEF3C7),  // Jaune pâle
                Color(0xFFFDE68A),  // Jaune doux
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône - CORRIGÉ: pensee_positive
              Image.asset(
                'assets/univers_visuel/pensee_positive.png',
                width: 64,
                height: 64,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFFBBF24),
                      size: 36,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Titre
              Text(
                '💫 Pensee du moment',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pensée
              Text(
                thought,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF78350F),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Bouton fermer
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF78350F),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Merci ! 🙏',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

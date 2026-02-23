// lib/widgets/nav_cartouche.dart
// Widget réutilisable pour les icônes de navigation dans des cartouches uniformes
// Couleur cyan/bleu atténué — taille identique partout

import 'package:flutter/material.dart';

/// Cartouche de navigation : container avec fond cyan atténué,
/// contenant une icône PNG de taille uniforme.
/// Utilisé en haut à droite de chaque écran et en bas (retour).
class NavCartouche extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  /// Taille par défaut du container (carré)
  static const double defaultSize = 40.0;

  /// Taille par défaut du PNG à l'intérieur
  static const double defaultIconSize = 22.0;

  /// Couleur de fond du cartouche
  static const Color cartoucheColor = Color(0xFF00E5FF);

  /// Opacité du fond
  static const double bgOpacity = 0.12;

  /// Rayon des coins
  static const double borderRadius = 12.0;

  const NavCartouche({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    required this.tooltip,
    required this.onTap,
    this.size = defaultSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cartoucheColor.withValues(alpha: bgOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: cartoucheColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Image.asset(
              assetPath,
              width: defaultIconSize,
              height: defaultIconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                fallbackIcon,
                color: cartoucheColor.withValues(alpha: 0.7),
                size: defaultIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartouche de retour (bas d'écran) — même style que les cartouches du haut
class NavCartoucheRetour extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const NavCartoucheRetour({
    super.key,
    required this.onTap,
    this.label = 'Retour',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: NavCartouche.cartoucheColor.withValues(alpha: NavCartouche.bgOpacity),
          borderRadius: BorderRadius.circular(NavCartouche.borderRadius),
          border: Border.all(
            color: NavCartouche.cartoucheColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/univers_visuel/retour.png',
              width: NavCartouche.defaultIconSize,
              height: NavCartouche.defaultIconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.arrow_back_rounded,
                color: NavCartouche.cartoucheColor.withValues(alpha: 0.7),
                size: NavCartouche.defaultIconSize,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: NavCartouche.cartoucheColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

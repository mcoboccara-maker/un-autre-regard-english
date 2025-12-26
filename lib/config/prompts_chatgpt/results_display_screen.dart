import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/approach_config.dart';
import '../../widgets/app_scaffold.dart'; // ✅ AJOUT IMPORT APPSCAFFOLD

/// ECRAN D'AFFICHAGE DES RESULTATS - VERSION APPSCAFFOLD
/// 
/// Modifications:
/// 1. Utilise AppScaffold pour en-tête standard
/// 2. Bouton retour en bas via AppScaffold
/// 3. Fond bleu marbre conservé dans le body
/// 4. Numéros colorés et stylisés pour chaque perspective
class ResultsDisplayScreen extends StatelessWidget {
  final Map<String, String> aiResponses;
  final List<String> selectedApproaches;
  final VoidCallback onNewReflection;
  final VoidCallback? onBack;

  const ResultsDisplayScreen({
    super.key,
    required this.aiResponses,
    required this.selectedApproaches,
    required this.onNewReflection,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    print('AFFICHAGE DES RESULTATS');
    print('   Nombre de reponses: ${aiResponses.length}');
    print('   Approches selectionnees: ${selectedApproaches.length}');
    
    // ✅ UTILISATION DE APPSCAFFOLD
    return AppScaffold(
      title: 'Tes perspectives',
      headerIconPath: 'assets/univers_visuel/perspectives.png',
      showTitle: false,
      showBackButton: false, // On utilise bottomAction à la place
      bottomAction: _buildNavigationButtons(context),
      body: Container(
        // FOND BLEU MARBRE
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4F8),  // Bleu tres clair
              Color(0xFFD0E8F0),  // Bleu clair
              Color(0xFFB8DCE8),  // Bleu moyen clair
              Color(0xFFD8EEF5),  // Retour bleu clair
              Color(0xFFE0F0F5),  // Bleu pale
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Afficher les cartes de resultats avec numeros
              ...selectedApproaches.asMap().entries.map((entry) {
                final index = entry.key;
                final approachKey = entry.value;
                return _buildResultCard(approachKey, index + 1);
              }).toList(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge avec nombre de perspectives
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E8B7B), Color(0xFF3A9D8C)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E8B7B).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '${selectedApproaches.length} perspectives generees',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 16),
        
        // Titre
        Text(
          'Voici differents regards sur ta pensee',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            height: 1.3,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildResultCard(String approachNameOrKey, int numero) {
    // Chercher l'approche par son NOM ou KEY
    ApproachConfig? approach;
    try {
      approach = ApproachCategories.allApproaches
          .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
    } catch (e) {
      print('Approche introuvable: $approachNameOrKey');
      return const SizedBox();
    }
    
    final response = aiResponses[approachNameOrKey];
    
    if (response == null || response.isEmpty) {
      print('Pas de reponse pour: $approachNameOrKey');
      print('   Cles disponibles: ${aiResponses.keys.toList()}');
      return const SizedBox();
    }
    
    print('Affichage carte #$numero pour: ${approach.name}');
    
    // Couleurs pour les numeros (palette harmonieuse)
    final numeroColors = [
      const Color(0xFF2E8B7B),  // Vert-bleu
      const Color(0xFFD4AF37),  // Or
      const Color(0xFF6B5B95),  // Violet
      const Color(0xFFE67E22),  // Orange
      const Color(0xFF3498DB),  // Bleu
      const Color(0xFFE74C3C),  // Rouge
      const Color(0xFF1ABC9C),  // Turquoise
      const Color(0xFF9B59B6),  // Mauve
      const Color(0xFF27AE60),  // Vert
      const Color(0xFFF39C12),  // Jaune-orange
    ];
    final numeroColor = numeroColors[(numero - 1) % numeroColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: approach.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TETE DE LA CARTE avec numero stylise
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: approach.color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // NUMERO STYLISE
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        numeroColor,
                        numeroColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: numeroColor.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Icone de l'approche
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: approach.color.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    approach.icon,
                    size: 20,
                    color: approach.color,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approach.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: approach.color,
                        ),
                      ),
                      Text(
                        'Eclairage IA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge OpenAI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: approach.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 12, color: approach.color),
                      const SizedBox(width: 4),
                      Text(
                        'OpenAI',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: approach.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // CONTENU DE LA REPONSE
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              response,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1E293B),
                height: 1.7,
              ),
            ),
          ),
          
          // BARRE D'ACTIONS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bouton feedback negatif
                IconButton(
                  icon: Icon(Icons.thumb_down_outlined, 
                    color: const Color(0xFF64748B).withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Implementer feedback
                  },
                  tooltip: 'Pas utile',
                ),
                // Bouton feedback positif
                IconButton(
                  icon: Icon(Icons.thumb_up_outlined, 
                    color: const Color(0xFF64748B).withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Implementer feedback
                  },
                  tooltip: 'Utile',
                ),
                const SizedBox(width: 8),
                // Bouton partager
                IconButton(
                  icon: Icon(Icons.share_outlined, 
                    color: approach.color.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Implementer partage
                  },
                  tooltip: 'Partager',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 + numero * 100).ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton nouvelle reflexion
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onNewReflection,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(
              'Nouvelle reflexion',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B7B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
              shadowColor: const Color(0xFF2E8B7B).withOpacity(0.4),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton retour accueil
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            icon: Image.asset(
              'assets/univers_visuel/menu_principal.png',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(Icons.home, size: 18),
            ),
            label: Text(
              'Retour au menu',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E8B7B),
              side: const BorderSide(color: Color(0xFF2E8B7B), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

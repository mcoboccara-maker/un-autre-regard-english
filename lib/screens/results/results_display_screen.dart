import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/approach_config.dart';

/// 🎯 RESPONSABILITÉ : AFFICHAGE DES RÉSULTATS UNIQUEMENT
/// Ce widget affiche les réponses IA déjà générées.
/// Il NE GÉNÈRE PAS les réponses (c'est le rôle de results_generation_step.dart)
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
    print('🎨 AFFICHAGE DES RÉSULTATS');
    print('   Nombre de réponses: ${aiResponses.length}');
    print('   Approches sélectionnées: ${selectedApproaches.length}');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: onBack,
              )
            : null,
        title: Text(
          'Vos perspectives',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Icône menu pour accéder à l'historique, profil, etc.
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0F172A)),
            onSelected: (value) {
              switch (value) {
                case 'history':
                  Navigator.of(context).pushNamed('/history');
                  break;
                case 'profile':
                  Navigator.of(context).pushNamed('/profile');
                  break;
                case 'home':
                  Navigator.of(context).pushNamed('/home');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Historique',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Profil',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'home',
                child: Row(
                  children: [
                    const Icon(Icons.home, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Accueil',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              // Afficher les cartes de résultats
              ...selectedApproaches.map((approachKey) {
                return _buildResultCard(approachKey);
              }).toList(),
              
              const SizedBox(height: 32),
              
              _buildNavigationButtons(context),
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
        Text(
          '✨ Tes perspectives IA',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          '${aiResponses.length} perspective${aiResponses.length > 1 ? 's' : ''} générée${aiResponses.length > 1 ? 's' : ''} par intelligence artificielle',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildResultCard(String approachNameOrKey) {
    // Chercher l'approche par son NOM ou KEY
    ApproachConfig? approach;
    try {
      approach = ApproachCategories.allApproaches
          .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
    } catch (e) {
      print('❌ Approche introuvable: $approachNameOrKey');
      return const SizedBox();
    }
    
    final response = aiResponses[approachNameOrKey];
    
    // Ne pas afficher si pas de réponse
    if (response == null || response.isEmpty) {
      print('⚠️ Pas de réponse pour: $approachNameOrKey');
      print('   Clés disponibles: ${aiResponses.keys.toList()}');
      return const SizedBox();
    }
    
    print('✅ Affichage carte pour: ${approach.name}');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: approach.color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: approach.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et nom
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: approach.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  approach.icon,
                  size: 20,
                  color: approach.color,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Text(
                  approach.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: approach.color,
                  ),
                ),
              ),
              
              // Badge IA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: approach.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'OpenAI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: approach.color,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contenu de la réponse IA
          Text(
            response,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF0F172A),
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      children: [
        // Bouton retour (optionnel)
        if (onBack != null) ...[
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(
              'Retour',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        // Bouton nouvelle réflexion
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNewReflection,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Nouvelle réflexion',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

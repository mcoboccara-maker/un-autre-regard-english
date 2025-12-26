import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/reflection.dart';
import '../../models/emotional_state.dart';
import '../../models/user_profile.dart';
import '../../config/approach_config.dart';
import '../../services/ai_service.dart';
import '../../services/persistent_storage_service.dart';

/// RESPONSABILITE : GENERATION IA UNIQUEMENT
/// Ce widget orchestre la generation des reponses IA et affiche la progression.
/// Il N'AFFICHE PAS les resultats finaux (c'est le role de results_display_screen.dart)
/// 
/// CORRECTION: Charge maintenant le userProfile pour transmettre les sources du profil
class ResultsGenerationStep extends StatefulWidget {
  final String reflectionText;
  final String? declencheur;
  final String? souhait;
  final String? petitPas;
  final ReflectionType reflectionType;
  final EmotionalState emotionalState;
  final List<String> selectedApproaches;
  final VoidCallback onBack;
  final Function(Map<String, String>) onGenerationComplete;
  final VoidCallback onGenerationError;

  const ResultsGenerationStep({
    super.key,
    required this.reflectionText,
    this.declencheur,
    this.souhait,
    this.petitPas,
    required this.reflectionType,
    required this.emotionalState,
    required this.selectedApproaches,
    required this.onBack,
    required this.onGenerationComplete,
    required this.onGenerationError,
  });

  @override
  State<ResultsGenerationStep> createState() => _ResultsGenerationStepState();
}

class _ResultsGenerationStepState extends State<ResultsGenerationStep>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  final Map<String, String> _approachStatus = {};
  String? _errorMessage;
  bool _isGenerating = false;
  
  // =========================================================================
  // CORRECTION: Variable pour stocker le profil utilisateur
  // =========================================================================
  UserProfile? _userProfile;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialiser les statuts
    for (final approach in widget.selectedApproaches) {
      _approachStatus[approach] = 'pending';
    }
    
    // Demarrer la generation automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    
    _controller.repeat();
    
    print('🚀 DEBUT GENERATION IA');
    
    try {
      // =========================================================================
      // CORRECTION: Charger le profil utilisateur AVANT la generation
      // =========================================================================
      try {
        _userProfile = await PersistentStorageService.instance.getUserProfile();
        print('✅ Profil utilisateur charge:');
        print('   - Religions: ${_userProfile?.religionsSelectionnees}');
        print('   - Litteratures: ${_userProfile?.courantsLitteraires}');
        print('   - Psychologies: ${_userProfile?.approchesPsychologiques}');
        print('   - Philosophies: ${_userProfile?.courantsPhilosophiques}');
        print('   - Philosophes: ${_userProfile?.philosophesSelectionnes}');
      } catch (e) {
        print('⚠️ Impossible de charger le profil utilisateur: $e');
        _userProfile = null;
      }
      
      final responses = <String, String>{};
      final intensiteEmotionnelle = _calculateEmotionalIntensity();
      
      print('😊 Intensite emotionnelle: $intensiteEmotionnelle');
      print('📋 Approches selectionnees: ${widget.selectedApproaches}');
      
      for (final approachNameOrKey in widget.selectedApproaches) {
        // Convertir le nom en key
        ApproachConfig? approach;
        try {
          approach = ApproachCategories.allApproaches
              .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
        } catch (e) {
          print('⚠️ Approche non trouvee: $approachNameOrKey - utilisation par defaut');
          continue;
        }
        
        final approachKey = approach.key;
        
        setState(() {
          _approachStatus[approachNameOrKey] = 'generating';
        });
        
        try {
          print('🔄 Generation pour: ${approach.name}');
          
          // =========================================================================
          // CORRECTION: Passer le userProfile a generateApproachSpecificResponse
          // =========================================================================
          final response = await AIService.instance.generateApproachSpecificResponse(
            approach: approachKey,
            reflectionText: widget.reflectionText,
            reflectionType: widget.reflectionType,
            emotionalState: widget.emotionalState,
            userProfile: _userProfile,  // ← CORRECTION: Ajout du profil
            declencheur: widget.declencheur,
            souhait: widget.souhait,
            petitPas: widget.petitPas,
            intensiteEmotionnelle: intensiteEmotionnelle,
          );
          
          responses[approachKey] = response;
          
          setState(() {
            _approachStatus[approachNameOrKey] = 'completed';
          });
          
          print('✅ Generation terminee pour: ${approach.name}');
          
        } catch (e) {
          print('❌ Erreur generation pour ${approach.name}: $e');
          setState(() {
            _approachStatus[approachNameOrKey] = 'error';
          });
        }
      }
      
      _controller.stop();
      
      if (responses.isNotEmpty) {
        print('🎉 Generation complete: ${responses.length} perspectives');
        widget.onGenerationComplete(responses);
      } else {
        print('❌ Aucune perspective generee');
        setState(() {
          _errorMessage = 'Aucune perspective generee';
          _isGenerating = false;
        });
        widget.onGenerationError();
      }
      
    } catch (e) {
      print('❌ Erreur de generation');
      _controller.stop();
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
      widget.onGenerationError();
    }
  }

  int _calculateEmotionalIntensity() {
    final activeEmotions = widget.emotionalState.emotions.values
        .where((emotion) => emotion.level > 0)
        .toList();
    
    if (activeEmotions.isEmpty) return 1;
    
    final total = activeEmotions.fold<int>(0, (sum, emotion) => sum + emotion.level);
    return (total / activeEmotions.length).round().clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              if (_errorMessage != null) ...[
                _buildError(),
                const SizedBox(height: 24),
              ],
              
              _buildProgressList(),
              
              const SizedBox(height: 32),
              
              // Bouton retour (seulement si erreur)
              if (_errorMessage != null)
                OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // IMAGE GENERATION IA - TAILLE UNIFORME 180x180
        Center(
          child: Image.asset(
            'assets/univers_visuel/generationiaencours.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback si l'image n'est pas trouvee
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      size: 64,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Generation IA en cours...',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              );
            },
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        
        const SizedBox(height: 16),
        
        Text(
          'Intelligence artificielle OpenAI en train d\'analyser votre reflexion',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erreur de generation',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Erreur inconnue',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _startGeneration,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressList() {
    return Column(
      children: [
        // IMAGE "PERSPECTIVES" - TAILLE UNIFORME 180x180
        Center(
          child: Image.asset(
            'assets/univers_visuel/perspectives.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback si l'image n'est pas trouvee
              return RotationTransition(
                turns: _controller,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Color(0xFF6366F1),
                ),
              );
            },
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).shimmer(duration: 2000.ms),
        
        const SizedBox(height: 24),
        
        // TEXTE SIMPLE
        Text(
          'Generation des perspectives...',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF10B981),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Liste des approches avec leur statut
        ...widget.selectedApproaches.map((approachKey) {
          return _buildApproachCard(approachKey);
        }).toList(),
      ],
    );
  }

  Widget _buildApproachCard(String approachNameOrKey) {
    // Chercher par nom OU par key
    ApproachConfig? approach;
    try {
      approach = ApproachCategories.allApproaches
          .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
    } catch (e) {
      // Si l'approche n'est pas trouvee, creer une carte par defaut
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.help_outline, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                approachNameOrKey,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.warning, size: 18, color: Colors.orange),
          ],
        ),
      );
    }
    
    final status = _approachStatus[approachNameOrKey] ?? 'pending';
    
    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'generating':
        statusIcon = Icons.hourglass_empty;
        statusColor = const Color(0xFF6366F1);
        statusText = 'En cours...';
        break;
      case 'completed':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Termine';
        break;
      case 'error':
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = 'Erreur';
        break;
      default:
        statusIcon = Icons.pending;
        statusColor = Colors.grey;
        statusText = 'En attente';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icone de l'approche
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
          
          // Nom de l'approche
          Expanded(
            child: Text(
              approach.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          
          // Statut
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

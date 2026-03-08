import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/approach_config.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';
import '../../models/source_evaluation.dart';

/// ECRAN D'AFFICHAGE DES RESULTATS - VERSION COMPLETE
/// 
/// Fonctionnalités:
/// 1. Affichage des perspectives générées
/// 2. Approfondissement de chaque perspective
/// 3. Évaluation avec note et commentaire
/// 4. TTS (lecture vocale)
/// 5. Partage
class ResultsDisplayScreen extends StatefulWidget {
  final Map<String, String> aiResponses;
  final List<String> selectedApproaches;
  final String reflectionText; // La pensée originale
  final VoidCallback onNewReflection;
  final VoidCallback? onBack;

  const ResultsDisplayScreen({
    super.key,
    required this.aiResponses,
    required this.selectedApproaches,
    required this.reflectionText,
    required this.onNewReflection,
    this.onBack,
  });

  @override
  State<ResultsDisplayScreen> createState() => _ResultsDisplayScreenState();
}

class _ResultsDisplayScreenState extends State<ResultsDisplayScreen> {
  // État pour l'approfondissement
  final Map<String, bool> _isDeepening = {};
  final Map<String, String> _deepenedResponses = {};
  
  // État pour l'évaluation
  final Map<String, SourceEvaluation> _evaluations = {};
  final Map<String, bool> _showEvaluation = {};
  
  // État pour le TTS
  String? _speakingKey;
  
  @override
  void initState() {
    super.initState();
    _initTts();
  }
  
  Future<void> _initTts() async {
    await TtsService.instance.init();
    
    // Configurer le callback pour mettre à jour l'UI quand la lecture se termine
    TtsService.instance.onStateChanged = (approachKey, isSpeaking) {
      if (mounted && !isSpeaking) {
        setState(() {
          _speakingKey = null;
        });
      }
    };
  }
  
  @override
  void dispose() {
    // Ne pas disposer le singleton, juste arrêter la lecture
    TtsService.instance.stop();
    TtsService.instance.onStateChanged = null;  // Nettoyer le callback
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('📊 AFFICHAGE DES RESULTATS (mode invité)');
    print('   Nombre de réponses: ${widget.aiResponses.length}');
    print('   Approches sélectionnées: ${widget.selectedApproaches.length}');
    
    return AppScaffold(
      title: 'Your perspectives',
      headerIconPath: 'assets/univers_visuel/perspectives.png',
      showTitle: false,
      showBackButton: false,
      bottomAction: _buildNavigationButtons(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4F8),
              Color(0xFFD0E8F0),
              Color(0xFFB8DCE8),
              Color(0xFFD8EEF5),
              Color(0xFFE0F0F5),
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
              
              ...widget.selectedApproaches.asMap().entries.map((entry) {
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
                '${widget.selectedApproaches.length} perspectives generated',
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
        
        Text(
          'Here are different perspectives on your thought',
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
    ApproachConfig? approach;
    try {
      approach = ApproachCategories.allApproaches
          .firstWhere((a) => a.name == approachNameOrKey || a.key == approachNameOrKey);
    } catch (e) {
      print('❌ Approche introuvable: $approachNameOrKey');
      return const SizedBox();
    }
    
    final response = widget.aiResponses[approachNameOrKey];
    
    if (response == null || response.isEmpty) {
      return const SizedBox();
    }
    
    final hasDeepened = _deepenedResponses.containsKey(approach.key);
    final isDeepening = _isDeepening[approach.key] == true;
    final showEval = _showEvaluation[approach.key] == true;
    final evaluation = _evaluations[approach.key];
    final isSpeaking = _speakingKey == approach.key;
    
    final numeroColors = [
      const Color(0xFF2E8B7B),
      const Color(0xFFD4AF37),
      const Color(0xFF6B5B95),
      const Color(0xFFE67E22),
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
      const Color(0xFF1ABC9C),
      const Color(0xFF9B59B6),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
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
          // EN-TÊTE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: approach.color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Numéro stylisé
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [numeroColor, numeroColor.withOpacity(0.7)],
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
                
                // Icône
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(approach.icon, size: 20, color: approach.color),
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
                        'AI Insight',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge Claude
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
                        'Claude',
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
          
          // CONTENU avec Markdown
          Padding(
            padding: const EdgeInsets.all(20),
            child: MarkdownBody(
              data: _cleanMarkdown(response),
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                  height: 1.7,
                ),
                strong: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 1.7,
                ),
                em: GoogleFonts.inter(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1E293B),
                  height: 1.7,
                ),
              ),
              selectable: true,
            ),
          ),
          
          // APPROFONDISSEMENT (si existe)
          if (hasDeepened) ...[
            const Divider(height: 1),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: approach.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: approach.color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: approach.color),
                      const SizedBox(width: 8),
                      Text(
                        'Deepening',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: approach.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: _cleanMarkdown(_deepenedResponses[approach.key]!),
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: const Color(0xFF1E293B),
                      ),
                      strong: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // SECTION ÉVALUATION (si ouverte)
          if (showEval) _buildEvaluationSection(approach, evaluation),
          
          // BARRE D'ACTIONS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Bouton Approfondir
                if (!hasDeepened)
                  _buildActionButton(
                    icon: isDeepening ? Icons.hourglass_top : Icons.auto_awesome,
                    label: isDeepening ? 'In progress...' : 'Deepen',
                    color: approach.color,
                    onPressed: isDeepening ? null : () => _deepen(approach!),
                  ),
                
                // Bouton TTS
                _buildActionButton(
                  icon: isSpeaking ? Icons.stop : Icons.volume_up,
                  label: isSpeaking ? 'Stop' : 'Listen',
                  color: const Color(0xFF64748B),
                  onPressed: () => _toggleTts(approach!, response),
                ),
                
                const Spacer(),
                
                // Bouton Évaluer
                _buildActionButton(
                  icon: evaluation != null ? Icons.star : Icons.star_border,
                  label: 'Rate',
                  color: evaluation != null ? const Color(0xFFD4AF37) : const Color(0xFF64748B),
                  onPressed: () {
                    setState(() {
                      _showEvaluation[approach!.key] = !showEval;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 + numero * 100).ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: onPressed == null ? color.withOpacity(0.5) : color),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onPressed == null ? color.withOpacity(0.5) : color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildEvaluationSection(ApproachConfig approach, SourceEvaluation? evaluation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border(
          top: BorderSide(color: approach.color.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your opinion on this perspective',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 12),
          
          // Slider de note
          Row(
            children: [
              Text(
                'Rating:',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF78350F)),
              ),
              Expanded(
                child: Slider(
                  value: (evaluation?.rating ?? 5).toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '${(evaluation?.rating ?? 5)}/10',
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) {
                    setState(() {
                      _evaluations[approach.key] = SourceEvaluation(
                        sourceKey: approach.key,
                        rating: value.toInt(),
                        comment: evaluation?.comment,
                        createdAt: DateTime.now(),
                      );
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(evaluation?.rating ?? 5)}/10',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Champ commentaire
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'A comment? (optional)',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              setState(() {
                _evaluations[approach.key] = SourceEvaluation(
                  sourceKey: approach.key,
                  rating: evaluation?.rating ?? 5,
                  comment: value,
                  createdAt: DateTime.now(),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPROFONDISSEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _deepen(ApproachConfig approach) async {
    setState(() {
      _isDeepening[approach.key] = true;
    });
    
    try {
      final shortResponse = widget.aiResponses[approach.key] ?? widget.aiResponses[approach.name] ?? '';
      
      // Extraire le nom de la figure depuis FIGURE_META si possible
      String figureNom = 'Figure';
      final metaMatch = RegExp(r'\[FIGURE_META\][\s\S]*?nom:\s*([^\n]+)[\s\S]*?\[/FIGURE_META\]')
          .firstMatch(shortResponse);
      if (metaMatch != null) {
        figureNom = metaMatch.group(1)?.trim() ?? 'Figure';
      }
      
      final deepenedResponse = await AiService.instance.generateDeepening(
        penseeOriginale: widget.reflectionText,
        reponseCourte: shortResponse,
        sourceNom: approach.name,
        figureNom: figureNom,
      );
      
      if (mounted) {
        setState(() {
          _deepenedResponses[approach.key] = deepenedResponse;
          _isDeepening[approach.key] = false;
        });
      }
    } catch (e) {
      print('❌ Erreur approfondissement: $e');
      if (mounted) {
        setState(() {
          _isDeepening[approach.key] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _toggleTts(ApproachConfig approach, String text) async {
    if (_speakingKey == approach.key) {
      // Arrêter la lecture
      await TtsService.instance.stop();
      setState(() {
        _speakingKey = null;
      });
    } else {
      // Arrêter toute lecture en cours
      if (_speakingKey != null) {
        await TtsService.instance.stop();
      }
      
      setState(() {
        _speakingKey = approach.key;
      });
      
      // Nettoyer le texte et lancer la lecture
      // La détection de langue est AUTOMATIQUE dans speak()
      final cleanText = _cleanMarkdown(text);
      
      print('🔊 TTS: Lecture de ${cleanText.length} caractères');
      print('🌐 TTS: Détection automatique de la langue...');
      
      await TtsService.instance.speak(
        cleanText,
        approachKey: approach.key,  // Paramètre correct !
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════
  
  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'_{3,}'), '')
        .replaceAll(RegExp(r'##\s*\d+\.\s*[A-ZÉÈÊËÀÂÄÙÛÜÔÖÎÏ\s]+\n'), '')
        .replaceAll(RegExp(r'\[FIGURE_META\][\s\S]*?\[/FIGURE_META\]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onNewReflection,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(
              'New reflection',
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
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false),
            icon: Image.asset(
              'assets/univers_visuel/menu_principal.png',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(Icons.home, size: 18),
            ),
            label: Text(
              'Back to menu',
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

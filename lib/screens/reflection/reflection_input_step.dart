// lib/screens/reflection/reflection_input_step.dart
// MODIFIÉ : Suppression approfondissement + 2 boutons (direct / émotions)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/reflection.dart';

class ReflectionInputStep extends StatefulWidget {
  final String initialText;
  final ReflectionType initialType;
  final Function(String) onTextChanged;
  final Function(ReflectionType) onTypeChanged;
  final VoidCallback onNext;              // Parcours avec émotions
  final VoidCallback? onDirectGeneration; // NOUVEAU: Parcours direct (skip émotions)
  final VoidCallback? onMenuTap;

  const ReflectionInputStep({
    super.key,
    required this.initialText,
    required this.initialType,
    required this.onTextChanged,
    required this.onTypeChanged,
    required this.onNext,
    this.onDirectGeneration,  // NOUVEAU
    this.onMenuTap,
  });

  @override
  State<ReflectionInputStep> createState() => _ReflectionInputStepState();
}

class _ReflectionInputStepState extends State<ReflectionInputStep>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  ReflectionType _selectedType = ReflectionType.thought;
  bool _showSuggestions = false;

  final List<String> _thoughtSuggestions = [
    "Je ne suis pas à la hauteur...",
    "Je me sens bloqué(e)",
    "Cette personne me met en colère",
    "J'ai peur de l'échec",
  ];

  final List<String> _situationSuggestions = [
    "Conflit avec un proche",
    "Stress au travail",
    "Problème de communication",
  ];

  final List<String> _existentialSuggestions = [
    "Quel est le sens de ma vie ?",
    "Suis-je sur la bonne voie ?",
  ];

  final List<String> _dilemmaSuggestions = [
    "Changer de travail ou rester ?",
    "Dire la vérité ou me taire ?",
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _selectedType = widget.initialType;

    _textController.addListener(() {
      widget.onTextChanged(_textController.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _getPlaceholderText() {
    switch (_selectedType) {
      case ReflectionType.thought:
        return 'Je pense que...\nJe me sens...\nJ\'ai l\'impression que...';
      case ReflectionType.situation:
        return 'Décris la situation qui te préoccupe...';
      case ReflectionType.existential:
        return 'Quelle question existentielle te traverse ?';
      case ReflectionType.dilemma:
        return 'Quel choix difficile dois-tu faire ?';
    }
  }

  List<String> _getSuggestionsForType() {
    switch (_selectedType) {
      case ReflectionType.thought:
        return _thoughtSuggestions;
      case ReflectionType.situation:
        return _situationSuggestions;
      case ReflectionType.existential:
        return _existentialSuggestions;
      case ReflectionType.dilemma:
        return _dilemmaSuggestions;
    }
  }

  String _getTypeIconPath(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'assets/univers_visuel/pensee.png';
      case ReflectionType.situation:
        return 'assets/univers_visuel/situation.png';
      case ReflectionType.existential:
        return 'assets/univers_visuel/question_existentielle.png';
      case ReflectionType.dilemma:
        return 'assets/univers_visuel/dilemme.png';
    }
  }

  IconData _getFallbackIcon(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return Icons.psychology;
      case ReflectionType.situation:
        return Icons.place;
      case ReflectionType.existential:
        return Icons.help_outline;
      case ReflectionType.dilemma:
        return Icons.compare_arrows;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFF0F9FF),
          ],
        ),
      ),
      child: Column(
        children: [
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur de type (icônes 80x80)
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
                  
                  // Zone de saisie principale
                  _buildMainInput(),
                  const SizedBox(height: 8),
                  
                  // Suggestions (si activées)
                  if (_showSuggestions) _buildSuggestions(),
                  
                  // ═══════════════════════════════════════════════════════════
                  // SUPPRIMÉ : Section approfondissement (Déclencheur/Souhait/Petit pas)
                  // ═══════════════════════════════════════════════════════════
                ],
              ),
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // NOUVEAU : 2 boutons (Voir autrement / Émotions + regard)
          // ═══════════════════════════════════════════════════════════════════
          _buildTwoButtons(),
        ],
      ),
    );
  }

  // TYPES EN LIGNE - ICÔNES GRANDES (80x80), PAS DE TEXTE
  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ReflectionType.values.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
              widget.onTypeChanged(type);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    _getTypeIconPath(type),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getFallbackIcon(type),
                          size: 36,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 100.milliseconds);
  }

  Widget _buildMainInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/univers_visuel/exprimetoilibrement.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.edit_note,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exprime ce qui te traverse',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
                // Toggle suggestions
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSuggestions = !_showSuggestions;
                    });
                  },
                  icon: Icon(
                    _showSuggestions ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: _showSuggestions 
                        ? const Color(0xFFFBBF24) 
                        : Colors.grey[400],
                    size: 22,
                  ),
                  tooltip: 'Voir des exemples',
                ),
              ],
            ),
          ),
          
          // Zone de texte
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textController,
              maxLines: 6,
              minLines: 4,
              decoration: InputDecoration(
                hintText: _getPlaceholderText(),
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF0F172A),
                height: 1.6,
              ),
            ),
          ),
          
          // Compteur de caractères
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_textController.text.length} caractères',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.milliseconds);
  }

  Widget _buildSuggestions() {
    List<String> suggestions = _getSuggestionsForType();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemples',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () {
                    _textController.text = suggestion;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      suggestion,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU : BARRE 2 BOUTONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTwoButtons() {
    final canContinue = _textController.text.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // BOUTON 1 : Voir autrement (génération directe, sans émotions)
            // ═══════════════════════════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canContinue && widget.onDirectGeneration != null
                    ? widget.onDirectGeneration
                    : null,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(
                  'Voir autrement',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: canContinue ? 2 : 0,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // ═══════════════════════════════════════════════════════════════
            // BOUTON 2 : Émotions liées et autre regard (via émotions)
            // ═══════════════════════════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canContinue ? widget.onNext : null,
                icon: Image.asset(
                  'assets/univers_visuel/emotionsdujour.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.mood, size: 20),
                ),
                label: Text(
                  'Émotions liées et autre regard',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: canContinue 
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF94A3B8),
                  side: BorderSide(
                    color: canContinue 
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Bouton retour menu (petit, discret)
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Image.asset(
                'assets/univers_visuel/retour.png',
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => const Icon(Icons.arrow_back, size: 16),
              ),
              label: Text(
                'Retour au menu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/reflection/reflection_input_step.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/reflection.dart';

class ReflectionInputStep extends StatefulWidget {
  final String initialText;
  final ReflectionType initialType;
  final Function(String) onTextChanged;
  final Function(ReflectionType) onTypeChanged;
  final VoidCallback onNext;
  final Function(String)? onDeclencheurChanged;
  final Function(String)? onSouhaitChanged;
  final Function(String)? onPetitPasChanged;
  final VoidCallback? onMenuTap;

  const ReflectionInputStep({
    super.key,
    required this.initialText,
    required this.initialType,
    required this.onTextChanged,
    required this.onTypeChanged,
    required this.onNext,
    this.onDeclencheurChanged,
    this.onSouhaitChanged,
    this.onPetitPasChanged,
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

  late TextEditingController _declencheurController;
  late TextEditingController _souhaitController;
  late TextEditingController _petitPasController;

  final List<String> _thoughtSuggestions = [
    "Je ne suis pas a la hauteur...",
    "Je me sens bloque(e)",
    "Cette personne me met en colere",
    "J'ai peur de l'echec",
  ];

  final List<String> _situationSuggestions = [
    "Conflit avec un proche",
    "Stress au travail",
    "Probleme de communication",
  ];

  final List<String> _existentialSuggestions = [
    "Quel est le sens de ma vie ?",
    "Suis-je sur la bonne voie ?",
  ];

  final List<String> _dilemmaSuggestions = [
    "Changer de travail ou rester ?",
    "Dire la verite ou me taire ?",
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _selectedType = widget.initialType;
    
    _declencheurController = TextEditingController();
    _souhaitController = TextEditingController();
    _petitPasController = TextEditingController();

    _textController.addListener(() {
      widget.onTextChanged(_textController.text);
      setState(() {});
    });

    _declencheurController.addListener(() {
      widget.onDeclencheurChanged?.call(_declencheurController.text);
    });
    
    _souhaitController.addListener(() {
      widget.onSouhaitChanged?.call(_souhaitController.text);
    });
    
    _petitPasController.addListener(() {
      widget.onPetitPasChanged?.call(_petitPasController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _declencheurController.dispose();
    _souhaitController.dispose();
    _petitPasController.dispose();
    super.dispose();
  }

  String _getPlaceholderText() {
    switch (_selectedType) {
      case ReflectionType.thought:
        return 'Je pense que...\nJe me sens...\nJ\'ai l\'impression que...';
      case ReflectionType.situation:
        return 'Decris la situation qui te preoccupe...';
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

  // Chemins des icônes PNG pour les types
  String _getTypeIconPath(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'assets/univers_visuel/pensee.png';
      case ReflectionType.situation:
        return 'assets/univers_visuel/situation.png';  // CORRIGÉ: situation au lieu de situation1
      case ReflectionType.existential:
        return 'assets/univers_visuel/question_existentielle.png';  // CORRIGÉ: question_existentielle
      case ReflectionType.dilemma:
        return 'assets/univers_visuel/dilemme.png';  // CORRIGÉ: dilemme au lieu de dilemme1
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
                  // Sélecteur de type EN PREMIER (icônes GRANDES 80x80)
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
                  
                  // Zone de saisie principale
                  _buildMainInput(),
                  const SizedBox(height: 16),
                  
                  // Questions enrichies avec icônes PNG
                  _buildEnhancedQuestions(),
                  const SizedBox(height: 8),
                  
                  if (_showSuggestions) _buildSuggestions(),
                ],
              ),
            ),
          ),
          
          // Boutons en bas
          _buildBottomButtons(),
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
              width: 80,   // AGRANDI de 70 à 80
              height: 80,  // AGRANDI de 70 à 80
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
                // ICÔNE PNG GRANDE (72x72), PAS DE TEXTE
                child: Image.asset(
                  _getTypeIconPath(type),
                  width: 72,   // AGRANDI de 56 à 72
                  height: 72,  // AGRANDI de 56 à 72
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getFallbackIcon(type),
                      size: 56,  // AGRANDI de 48 à 56
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF64748B),
                    );
                  },
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Afficher l'icône du type sélectionné
                Image.asset(
                  _getTypeIconPath(_selectedType),
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.edit_note, color: const Color(0xFF6366F1), size: 24);
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Exprime-toi librement',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _getPlaceholderText(),
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // SUPPRIMÉ: Le bouton "Idées ?" - Garder uniquement le compteur de caractères
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_textController.text.length} car.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.milliseconds);
  }

  // Questions enrichies avec ICÔNES PNG - CORRIGÉ: utiliser approfondissement.png
  Widget _buildEnhancedQuestions() {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // CORRIGÉ: Utiliser approfondissement.png au lieu de l'emoji
                Image.asset(
                  'assets/univers_visuel/approfondissement.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.auto_awesome, color: const Color(0xFF7C3AED), size: 20);
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Approfondissement (optionnel)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Déclencheur avec icône PNG
            _buildEnhancedFieldWithPng(
              controller: _declencheurController,
              label: 'Declencheur',
              hint: 'Qu\'est-ce qui a declenche cette pensee ?',
              iconPath: 'assets/univers_visuel/declencheur.png',
              fallbackIcon: Icons.flash_on,
              color: Colors.orange,
            ),
            const SizedBox(height: 14),
            
            // Souhait profond avec icône PNG
            _buildEnhancedFieldWithPng(
              controller: _souhaitController,
              label: 'Souhait profond',
              hint: 'Qu\'aimeriez-vous ressentir a la place ?',
              iconPath: 'assets/univers_visuel/souhaitprofond.png',
              fallbackIcon: Icons.favorite,
              color: Colors.pink,
            ),
            const SizedBox(height: 14),
            
            // Action concrète avec icône PNG
            _buildEnhancedFieldWithPng(
              controller: _petitPasController,
              label: 'Action concrete',
              hint: 'Quel petit geste pourriez-vous faire ?',
              iconPath: 'assets/univers_visuel/actionconcrete.png',
              fallbackIcon: Icons.directions_walk,
              color: Colors.green,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.milliseconds);
  }

  // Champ avec icône PNG à gauche
  Widget _buildEnhancedFieldWithPng({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String iconPath,
    required IconData fallbackIcon,
    required MaterialColor color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône PNG à gauche
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(top: 4),
          child: Image.asset(
            iconPath,
            width: 44,
            height: 44,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(fallbackIcon, size: 24, color: color[600]),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // Champ de texte
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.inter(fontSize: 12, color: color[600]),
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color[400]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(10),
              isDense: true,
            ),
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[800]),
          ),
        ),
      ],
    );
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
              'Suggestions',
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

  Widget _buildBottomButtons() {
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
        child: Row(
          children: [
            // Bouton Retour
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Image.asset(
                  'assets/univers_visuel/retour.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.arrow_back, size: 18);
                  },
                ),
                label: Text(
                  'Retour',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Bouton Continuer
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canContinue ? widget.onNext : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  'Continuer',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: canContinue ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

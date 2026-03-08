// lib/widgets/emotion_widgets/emotion_detail_modal.dart
// MODIFIÉ : Curseur 0-100% remplacé par 10 boutons cliquables (1-10)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/emotion_config.dart';

class EmotionDetailModal extends StatefulWidget {
  final EmotionConfig emotion;
  final int initialLevel;
  final List<String> initialNuances;
  final Function(int level, List<String> nuances) onSave;

  const EmotionDetailModal({
    super.key,
    required this.emotion,
    required this.initialLevel,
    required this.initialNuances,
    required this.onSave,
  });

  @override
  State<EmotionDetailModal> createState() => _EmotionDetailModalState();
}

class _EmotionDetailModalState extends State<EmotionDetailModal>
    with TickerProviderStateMixin {
  late int _level;
  late Set<String> _selectedNuances;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _selectedNuances = Set.from(widget.initialNuances);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _closeModal(),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {}, // Empêcher la fermeture en tapant sur le modal
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildLevelSelector(),
                    Expanded(child: _buildNuancesSelector()),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.emotion.color.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle pour glisser
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Icône PNG et titre
          Row(
            children: [
              // Icône PNG de l'émotion (au lieu de IconData)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.emotion.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  widget.emotion.iconPath,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      widget.emotion.icon,
                      size: 40,
                      color: widget.emotion.color,
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.emotion.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.emotion.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      widget.emotion.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bouton fermer
              IconButton(
                onPressed: _closeModal,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU : 10 BOUTONS AU LIEU DU CURSEUR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLevelSelector() {
    // Convertir le level (0-100) en index bouton (0-10)
    // 0 = pas sélectionné, 1-10 = intensité
    final int selectedButton = (_level / 10).round().clamp(0, 10);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intensity',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selectedButton > 0 
                      ? widget.emotion.color 
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selectedButton > 0 ? '$selectedButton/10' : '—',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // ═══════════════════════════════════════════════════════════════════
          // 10 BOUTONS CLIQUABLES
          // ═══════════════════════════════════════════════════════════════════
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final buttonValue = index + 1; // 1 à 10
              final isSelected = selectedButton == buttonValue;
              final isLowerOrEqual = buttonValue <= selectedButton;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Si on clique sur le même bouton, on désélectionne (level = 0)
                    if (_level == buttonValue * 10) {
                      _level = 0;
                    } else {
                      _level = buttonValue * 10; // 10, 20, 30... 100
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 30,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLowerOrEqual && selectedButton > 0
                        ? widget.emotion.color.withOpacity(
                            0.3 + (buttonValue / 10) * 0.7)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? widget.emotion.color
                          : isLowerOrEqual && selectedButton > 0
                              ? widget.emotion.color.withOpacity(0.5)
                              : Colors.grey[300]!,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: widget.emotion.color.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$buttonValue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected 
                            ? FontWeight.w700 
                            : FontWeight.w500,
                        color: isLowerOrEqual && selectedButton > 0
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Strong',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNuancesSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nuances (${_selectedNuances.length} selected)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Refine your feeling by selecting the nuances that match you',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Grille des nuances
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.emotion.nuances.map((nuance) {
                  final isSelected = _selectedNuances.contains(nuance);
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedNuances.remove(nuance);
                        } else {
                          _selectedNuances.add(nuance);
                        }
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? widget.emotion.color
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? widget.emotion.color
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: widget.emotion.color.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        nuance,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                          color: isSelected 
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton annuler
          Expanded(
            child: OutlinedButton(
              onPressed: _closeModal,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Bouton valider
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _saveAndClose,
              icon: const Icon(Icons.check),
              label: Text(
                'Confirm',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.emotion.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _saveAndClose() {
    widget.onSave(_level, _selectedNuances.toList());
    _closeModal();
  }

  void _closeModal() {
    _slideController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}

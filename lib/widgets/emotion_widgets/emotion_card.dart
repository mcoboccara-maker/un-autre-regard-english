import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/emotion_config.dart';

class EmotionCard extends StatefulWidget {
  final EmotionConfig emotion;
  final int level;
  final int nuancesCount;
  final VoidCallback onTap;
  final Function(int) onLevelChanged;

  const EmotionCard({
    super.key,
    required this.emotion,
    required this.level,
    required this.nuancesCount,
    required this.onTap,
    required this.onLevelChanged,
  });

  @override
  State<EmotionCard> createState() => _EmotionCardState();
}

class _EmotionCardState extends State<EmotionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.level > 0;
    
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive 
                      ? widget.emotion.color
                      : const Color(0xFFE2E8F0),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive 
                        ? widget.emotion.color.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isActive ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône PNG GRANDE (comme menu principal)
                    _buildEmotionIcon(),
                    
                    const SizedBox(height: 8),
                    
                    // Nom de l'émotion
                    _buildEmotionName(),
                    
                    const SizedBox(height: 8),
                    
                    // MODIFIÉ: Boutons 1-10 au lieu du slider
                    _buildLevelButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Icône PNG grande comme menu principal
  Widget _buildEmotionIcon() {
    final isActive = widget.level > 0;
    
    return Stack(
      children: [
        // Icône PNG grande (64x64 comme menu principal)
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.emotion.color.withOpacity(isActive ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
            widget.emotion.iconPath,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback vers l'icône Material si le PNG n'existe pas
              return Icon(
                widget.emotion.icon,
                size: 56,
                color: widget.emotion.color,
              );
            },
          ),
        ),
        
        // Badge nuances (si applicable)
        if (widget.nuancesCount > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.emotion.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.nuancesCount}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmotionName() {
    // Convertir le niveau (0-100) en valeur 1-10
    final displayLevel = (widget.level / 10).round().clamp(0, 10);
    
    return Column(
      children: [
        Text(
          widget.emotion.name.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.level > 0 
                ? widget.emotion.color
                : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.level > 0) ...[
          const SizedBox(height: 2),
          Text(
            '$displayLevel/10',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: widget.emotion.color,
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODIFIÉ: Boutons 1-10 au lieu du slider
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLevelButtons() {
    // Convertir le niveau (0-100) en bouton sélectionné (0-10)
    final selectedButton = (widget.level / 10).round().clamp(0, 10);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(10, (index) {
        final buttonValue = index + 1; // 1 à 10
        final isSelected = selectedButton == buttonValue;
        final isLowerOrEqual = buttonValue <= selectedButton && selectedButton > 0;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            
            // Si on clique sur le bouton déjà sélectionné, on désélectionne (niveau 0)
            if (isSelected) {
              widget.onLevelChanged(0);
            } else {
              // Sinon on sélectionne ce niveau (converti en 0-100)
              widget.onLevelChanged(buttonValue * 10);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isLowerOrEqual
                  ? widget.emotion.color.withOpacity(0.3 + (buttonValue / 10) * 0.7)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? widget.emotion.color : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
            child: Center(
              child: Text(
                '$buttonValue',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isLowerOrEqual ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
}

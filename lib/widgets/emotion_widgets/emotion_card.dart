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
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.level.toDouble();
    
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
  void didUpdateWidget(EmotionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      setState(() {
        _sliderValue = widget.level.toDouble();
      });
    }
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
                    // ✅ Icône PNG GRANDE (comme menu principal)
                    _buildEmotionIcon(),
                    
                    const SizedBox(height: 8),
                    
                    // Nom de l'émotion
                    _buildEmotionName(),
                    
                    const SizedBox(height: 8),
                    
                    // Slider pour ajuster le niveau
                    _buildSlider(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ✅ NOUVELLE MÉTHODE : Icône PNG grande comme menu principal
  Widget _buildEmotionIcon() {
    final isActive = widget.level > 0;
    
    return Stack(
      children: [
        // ✅ Icône PNG grande (64x64 comme menu principal)
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
            '${widget.level}%',
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

  Widget _buildSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: widget.emotion.color,
        inactiveTrackColor: widget.emotion.color.withOpacity(0.2),
        thumbColor: widget.emotion.color,
        overlayColor: widget.emotion.color.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 12,
        ),
        trackHeight: 3,
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: _sliderValue,
        min: 0,
        max: 100,
        divisions: 20,
        onChanged: (value) {
          setState(() {
            _sliderValue = value;
          });
          
          // Haptic feedback
          if (value > 0 && widget.level == 0) {
            HapticFeedback.lightImpact();
          } else if (value == 0 && widget.level > 0) {
            HapticFeedback.lightImpact();
          }
          
          widget.onLevelChanged(value.round());
        },
        onChangeEnd: (value) {
          // Haptic feedback à la fin
          HapticFeedback.selectionClick();
        },
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
}

// lib/screens/emotion_wheel_screen.dart
// Écran roue des émotions Plutchik + panel nuances/intensité

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../widgets/interactive_plutchik_wheel.dart';
import 'thought_input_screen.dart';

class EmotionWheelScreen extends StatefulWidget {
  final ApproachConfig? preselectedSource;

  const EmotionWheelScreen({super.key, this.preselectedSource});

  @override
  State<EmotionWheelScreen> createState() => _EmotionWheelScreenState();
}

class _EmotionWheelScreenState extends State<EmotionWheelScreen>
    with SingleTickerProviderStateMixin {
  static final List<EmotionConfig> _allEmotions = [
    ...EmotionCategories.negativeEmotions,
    ...EmotionCategories.positiveEmotions,
  ];

  int? _selectedIndex;
  int _intensity = 5;
  final Set<String> _selectedNuances = {};

  // Animation du panel du bas
  late AnimationController _panelController;
  late Animation<double> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _onEmotionTapped(int index) {
    setState(() {
      if (_selectedIndex == index) return; // déjà sélectionné
      _selectedIndex = index;
      _intensity = 5;
      _selectedNuances.clear();
    });
    _panelController.forward(from: 0);
  }

  EmotionConfig? get _selectedEmotion =>
      _selectedIndex != null ? _allEmotions[_selectedIndex!] : null;

  void _navigateToThought() {
    if (_selectedEmotion == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThoughtInputScreen(
          preselectedSource: widget.preselectedSource,
          preselectedEmotion: _selectedEmotion,
          emotionComment: null,
          selectedNuances: _selectedNuances.toList(),
          emotionIntensity: _intensity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FD),
              Color(0xFFFFF8E7),
              Color(0xFFE8F8E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Barre du haut ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Color(0xFF1A2E5A)),
                    ),
                    Expanded(
                      child: Text(
                        'Que ressens-tu ?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A2E5A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/menu', (route) => false,
                      ),
                      icon: const Icon(Icons.home_rounded,
                          color: Color(0xFF1A2E5A)),
                      tooltip: 'Menu',
                    ),
                  ],
                ),
              ),

              // ── Contenu scrollable ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // ── Roue Plutchik ──────────────────────────────────
                      SizedBox(
                        height: MediaQuery.of(context).size.width - 32,
                        child: InteractivePlutchikWheel(
                          selectedIndex: _selectedIndex,
                          onEmotionTapped: _onEmotionTapped,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Panel détails (slide up) ───────────────────────
                      if (_selectedEmotion != null)
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_panelSlide),
                          child: FadeTransition(
                            opacity: _panelSlide,
                            child: _buildDetailsPanel(),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PANEL DÉTAILS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDetailsPanel() {
    final emotion = _selectedEmotion!;
    final isNeg = _selectedIndex! < EmotionCategories.negativeEmotions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: emotion.color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête émotion ────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    emotion.iconPath,
                    width: 30,
                    height: 30,
                    errorBuilder: (_, __, ___) =>
                        Icon(emotion.icon, color: emotion.color, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emotion.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: emotion.color,
                      ),
                    ),
                    Text(
                      isNeg ? 'Émotion difficile' : 'Émotion ressource',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Intensité cinématique ──────────────────────────────────────
          Text(
            'Intensité',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // Cercle animé + boutons
          Center(
            child: Column(
              children: [
                _buildIntensityCircle(emotion),
                const SizedBox(height: 14),
                _buildIntensityButtons(emotion),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Nuances ───────────────────────────────────────────────────
          Text(
            'Nuances (${_selectedNuances.length}/${emotion.nuances.length})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          _buildNuancesWrap(emotion),

          const SizedBox(height: 24),

          // ── Bouton Continuer ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToThought,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                'Continuer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: emotion.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cercle animé d'intensité ────────────────────────────────────────────
  Widget _buildIntensityCircle(EmotionConfig emotion) {
    // Taille 60 → 120 selon intensité
    final size = 60.0 + (_intensity / 10.0) * 60.0;
    // Saturation : pastel (bas) → vibrant (haut)
    final hsl = HSLColor.fromColor(emotion.color);
    final saturation = 0.2 + (_intensity / 10.0) * 0.6;
    final displayColor =
        hsl.withSaturation(saturation.clamp(0.0, 1.0)).toColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: displayColor.withValues(alpha: 0.3),
        border: Border.all(color: displayColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: displayColor.withValues(alpha: 0.25),
            blurRadius: 12 + _intensity * 1.5,
            spreadRadius: _intensity * 0.5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$_intensity',
          style: GoogleFonts.inter(
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
      ),
    );
  }

  // ── Boutons intensité 0-10 ──────────────────────────────────────────────
  Widget _buildIntensityButtons(EmotionConfig emotion) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(11, (i) {
          final isSelected = i == _intensity;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => setState(() => _intensity = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? emotion.color
                      : emotion.color.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isSelected
                        ? emotion.color
                        : emotion.color.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$i',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : emotion.color,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Nuances multi-sélection ─────────────────────────────────────────────
  Widget _buildNuancesWrap(EmotionConfig emotion) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: emotion.nuances.map((nuance) {
        final isSelected = _selectedNuances.contains(nuance);
        return FilterChip(
          label: Text(
            nuance,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedNuances.add(nuance);
              } else {
                _selectedNuances.remove(nuance);
              }
            });
          },
          selectedColor: emotion.color,
          backgroundColor: emotion.color.withValues(alpha: 0.08),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? emotion.color
                  : emotion.color.withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

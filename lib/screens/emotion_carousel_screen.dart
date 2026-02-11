// lib/screens/emotion_carousel_screen.dart
// CDC §3.4 - Emotions en mode SPINE (18 cartes)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../widgets/carousel_3d/card_carousel_3d.dart';
import 'thought_input_screen.dart';

class EmotionCarouselScreen extends StatefulWidget {
  final ApproachConfig? preselectedSource;

  const EmotionCarouselScreen({super.key, this.preselectedSource});

  @override
  State<EmotionCarouselScreen> createState() => _EmotionCarouselScreenState();
}

class _EmotionCarouselScreenState extends State<EmotionCarouselScreen> {
  late List<EmotionConfig> _emotions;
  late List<CarouselCardData> _cards;

  @override
  void initState() {
    super.initState();
    _emotions = [
      ...EmotionCategories.negativeEmotions,
      ...EmotionCategories.positiveEmotions,
    ];
    _cards = _buildCards();
  }

  // Pastel version of emotion color
  Color _pastelOf(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(0.82).withSaturation(0.35).toColor();
  }

  List<CarouselCardData> _buildCards() {
    final negCount = EmotionCategories.negativeEmotions.length;
    return _emotions.asMap().entries.map((entry) {
      final i = entry.key;
      final emotion = entry.value;
      final isPositive = i >= negCount;
      final pastel = _pastelOf(emotion.color);

      return CarouselCardData(
        id: emotion.key,
        backgroundColor: pastel,
        label: emotion.name,
        child: _buildEmotionCard(emotion, isPositive, pastel),
      );
    }).toList();
  }

  Widget _buildEmotionCard(EmotionConfig emotion, bool isPositive, Color pastel) {
    final textDark = HSLColor.fromColor(emotion.color)
        .withLightness(0.25)
        .withSaturation(0.5)
        .toColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            pastel.withValues(alpha: 0.5),
            pastel.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: pastel.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPositive ? 'Positive' : 'Negative',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textDark,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: pastel.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  emotion.iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    emotion.icon,
                    color: textDark,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            emotion.name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            emotion.description,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textDark.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Sample nuances
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: emotion.nuances.take(3).map((n) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pastel.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  n,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: textDark.withValues(alpha: 0.8),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onEmotionTap(int index, CarouselCardData card) {
    final emotion = _emotions[index];
    _showCommentSheet(emotion);
  }

  void _showCommentSheet(EmotionConfig emotion) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF102A43),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(emotion.icon, color: emotion.color, size: 36),
              const SizedBox(height: 12),
              Text(
                emotion.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Optional comment
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Un commentaire ? (optionnel)',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ThoughtInputScreen(
                          preselectedSource: widget.preselectedSource,
                          preselectedEmotion: emotion,
                          emotionComment: commentController.text.isNotEmpty
                              ? commentController.text
                              : null,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emotion.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continuer',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CardCarousel3D(
            cards: _cards,
            mode: CarouselMode.spine,
            angleSpacing: 18,
            cardHeight: 300,
            cardWidth: 200,
            onCardTap: _onEmotionTap,
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),

          // Home button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/menu', (route) => false,
              ),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'Menu',
            ),
          ),

          // Title
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 56,
            right: 56,
            child: Text(
              'Que ressens-tu ?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/screens/orientation/orientation_welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'orientation_quiz_screen.dart';

class OrientationWelcomeScreen extends StatelessWidget {
  const OrientationWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond bleu pastel comme le reste de l'application
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBFE),
              Color(0xFFF5F9FD),
              Color(0xFFF8FBFE),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bouton fermer
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Contenu principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Icône animée
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '✨',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
                      .then()
                      .shimmer(duration: 2000.ms, delay: 500.ms),

                    const SizedBox(height: 40),

                    // Titre
                    Text(
                      'Découvre ton\nunivers intérieur',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 16),

                    // Sous-titre
                    Text(
                      '14 images • 45 secondes\nSwipe instinctivement',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms),

                    const SizedBox(height: 48),

                    // Instructions visuelles
                    _buildInstructions(),
                  ],
                ),
              ),

              const Spacer(),

              // Bouton commencer
              Padding(
                padding: const EdgeInsets.all(32),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const OrientationQuizScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 60),
                    elevation: 8,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Commencer',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(delay: 800.ms, duration: 500.ms)
                .slideY(begin: 0.5, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInstructionItem(
            icon: Icons.swipe,
            label: 'Swipe',
            subLabel: 'pour explorer',
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF6366F1).withOpacity(0.1),
          ),
          _buildInstructionItem(
            icon: Icons.touch_app,
            label: 'Tap',
            subLabel: 'pour choisir',
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 700.ms, duration: 500.ms);
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String label,
    required String subLabel,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subLabel,
          style: GoogleFonts.poppins(
            color: const Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

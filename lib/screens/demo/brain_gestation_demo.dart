// lib/screens/demo/brain_gestation_demo.dart
// Page de démonstration pour tester le widget BrainGestationWidget

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/brain_gestation_widget.dart';

class BrainGestationDemo extends StatefulWidget {
  const BrainGestationDemo({super.key});

  @override
  State<BrainGestationDemo> createState() => _BrainGestationDemoState();
}

class _BrainGestationDemoState extends State<BrainGestationDemo> {
  bool _isComplete = false;
  bool _transitionDone = false;

  void _simulateGeneration() {
    setState(() {
      _isComplete = false;
      _transitionDone = false;
    });
    
    // Simuler une génération de 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isComplete = true;
        });
      }
    });
  }

  void _toggleComplete() {
    setState(() {
      _isComplete = !_isComplete;
      if (!_isComplete) {
        _transitionDone = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Brain Gestation Demo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Titre
              Text(
                '🧠 Gestation Widget',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Energy flow symbolizing the ongoing reflection',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Widget principal
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: BrainGestationWidget(
                  isComplete: _isComplete,
                  size: 300,
                  // Utilise les placeholders si les images n'existent pas
                  loadingImagePath: 'assets/univers_visuel/brain_loading.png',
                  completeImagePath: 'assets/univers_visuel/brain_complete.webp',
                  onTransitionComplete: () {
                    setState(() {
                      _transitionDone = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✨ Generation complete!',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Indicateur d'état
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _transitionDone 
                      ? Colors.green.withOpacity(0.2)
                      : _isComplete 
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _transitionDone 
                        ? Colors.green
                        : _isComplete 
                            ? Colors.orange
                            : Colors.blue,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _transitionDone 
                          ? Icons.check_circle
                          : _isComplete 
                              ? Icons.hourglass_top
                              : Icons.sync,
                      color: _transitionDone 
                          ? Colors.green
                          : _isComplete 
                              ? Colors.orange
                              : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _transitionDone
                          ? 'Transition complete'
                          : _isComplete
                              ? 'Transition in progress...'
                              : 'Generation in progress...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Boutons de contrôle
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _simulateGeneration,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      'Simulate (5s)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  OutlinedButton.icon(
                    onPressed: _toggleComplete,
                    icon: Icon(_isComplete ? Icons.refresh : Icons.check),
                    label: Text(
                      _isComplete ? 'Reset' : 'Complete',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyan,
                      side: const BorderSide(color: Colors.cyan),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Instructions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('1', 'Add your images to assets/univers_visuel/'),
                    _buildInstruction('2', 'brain_loading.png → Image with rings'),
                    _buildInstruction('3', 'brain_complete.webp → Brain blue sky'),
                    _buildInstruction('4', 'Declare the assets in pubspec.yaml'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

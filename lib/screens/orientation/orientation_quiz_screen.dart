// lib/screens/orientation/orientation_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/orientation_config.dart';
import '../../widgets/app_scaffold.dart'; // ✅ AJOUT IMPORT APPSCAFFOLD
import 'orientation_result_screen.dart';

class OrientationQuizScreen extends StatefulWidget {
  const OrientationQuizScreen({super.key});

  @override
  State<OrientationQuizScreen> createState() => _OrientationQuizScreenState();
}

class _OrientationQuizScreenState extends State<OrientationQuizScreen> 
    with SingleTickerProviderStateMixin {
  
  int _currentQuestionIndex = 0;
  int _currentOptionIndex = 0; // Option affichée (0, 1, 2)
  
  final Map<String, int> _scores = {}; // source_id → score cumulé
  final List<String> _selectedOptions = []; // Pour historique
  
  late AnimationController _swipeController;
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  OrientationQuestion get _currentQuestion => 
      OrientationConfig.questions[_currentQuestionIndex];

  OrientationOption get _currentOption => 
      _currentQuestion.options[_currentOptionIndex];

  double get _progress => 
      (_currentQuestionIndex + 1) / OrientationConfig.questions.length;

  void _onOptionSelected(OrientationOption option) {
    // Feedback haptique
    HapticFeedback.lightImpact();
    
    // Ajouter les scores
    option.sourceScores.forEach((sourceId, points) {
      _scores[sourceId] = (_scores[sourceId] ?? 0) + points;
    });
    
    // Sauvegarder le choix
    _selectedOptions.add(option.id);
    
    // Passer à la question suivante
    if (_currentQuestionIndex < OrientationConfig.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentOptionIndex = 0;
        _dragOffset = 0;
      });
    } else {
      // Quiz terminé → afficher les résultats
      _showResults();
    }
  }

  void _showResults() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrientationResultScreen(scores: _scores),
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (_dragOffset.abs() > screenWidth * 0.25 || velocity.abs() > 500) {
      if (_dragOffset > 0) {
        // Swipe droite → option précédente
        _showPreviousOption();
      } else {
        // Swipe gauche → option suivante
        _showNextOption();
      }
    }
    
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }

  void _showNextOption() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentOptionIndex < _currentQuestion.options.length - 1) {
        _currentOptionIndex++;
      } else {
        _currentOptionIndex = 0; // Boucler
      }
    });
  }

  void _showPreviousOption() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentOptionIndex > 0) {
        _currentOptionIndex--;
      } else {
        _currentOptionIndex = _currentQuestion.options.length - 1; // Boucler
      }
    });
  }

  void _selectCurrentOption() {
    _onOptionSelected(_currentOption);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UTILISATION DE APPSCAFFOLD
    return AppScaffold(
      title: 'Quiz d\'orientation',
      headerIconPath: 'assets/univers_visuel/orientation.png',
      showTitle: false,
      showBackButton: false, // Pas de bouton retour standard, on a un bouton fermer custom
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
        child: Column(
          children: [
            // Barre de progression
            _buildProgressBar(),
            
            // Thème de la question
            _buildQuestionTheme(),
            
            // Image principale (swipeable)
            Expanded(
              child: _buildSwipeableImage(),
            ),
            
            // Indicateurs d'options
            _buildOptionIndicators(),
            
            // Instructions
            _buildInstructions(),
            
            // Bouton de sélection
            _buildSelectButton(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bouton retour menu
              GestureDetector(
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
              
              // Numéro de question
              Text(
                '${_currentQuestionIndex + 1}/${OrientationConfig.questions.length}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTheme() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _currentQuestion.theme,
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E293B),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate(key: ValueKey(_currentQuestionIndex))
      .fadeIn(duration: 300.ms)
      .slideY(begin: -0.2, end: 0);
  }

  Widget _buildSwipeableImage() {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTap: _selectCurrentOption,
      child: Container(
        margin: const EdgeInsets.all(24),
        child: Transform.translate(
          offset: Offset(_dragOffset * 0.3, 0),
          child: Transform.rotate(
            angle: _dragOffset * 0.0005,
            child: Stack(
              children: [
                // Image principale
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      _currentOption.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _currentOption.label,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ).animate(key: ValueKey('${_currentQuestionIndex}_$_currentOptionIndex'))
                  .fadeIn(duration: 200.ms)
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                
                // ❌ SUPPRIMÉ : Overlay avec label (causait la duplication de texte)
                
                // Indicateur de swipe gauche
                if (_dragOffset < -20)
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                
                // Indicateur de swipe droite
                if (_dragOffset > 20)
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _currentQuestion.options.length,
        (index) => GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _currentOptionIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: index == _currentOptionIndex ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == _currentOptionIndex
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          Text(
            'Swipe pour explorer • Tap pour choisir',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: ElevatedButton(
        onPressed: _selectCurrentOption,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: Text(
          'Choisir "${_currentOption.label}"',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 300.ms)
      .slideY(begin: 0.3, end: 0);
  }
}

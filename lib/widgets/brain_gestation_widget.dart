// lib/widgets/brain_gestation_widget.dart
// Widget d'animation pour la phase de génération IA
// Symbolise la gestation d'une pensée avec des flux d'énergie

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget qui affiche un cerveau avec des flux d'énergie circulant
/// sur des anneaux orbitaux pendant la génération IA
class BrainGestationWidget extends StatefulWidget {
  /// Indique si la génération est terminée
  final bool isComplete;
  
  /// Callback appelé quand la transition de fin est terminée
  final VoidCallback? onTransitionComplete;
  
  /// Chemin vers l'image de chargement (cerveau avec anneaux)
  final String loadingImagePath;
  
  /// Chemin vers l'image finale (cerveau sur ciel bleu)
  final String completeImagePath;
  
  /// Taille du widget (carré)
  final double size;

  const BrainGestationWidget({
    super.key,
    required this.isComplete,
    this.onTransitionComplete,
    this.loadingImagePath = 'assets/univers_visuel/brain_loading.png',
    this.completeImagePath = 'assets/univers_visuel/brain_complete.png',
    this.size = 280,
  });

  @override
  State<BrainGestationWidget> createState() => _BrainGestationWidgetState();
}

class _BrainGestationWidgetState extends State<BrainGestationWidget>
    with TickerProviderStateMixin {
  
  // Contrôleur principal pour les particules
  late AnimationController _particleController;
  
  // Contrôleur pour la transition finale
  late AnimationController _transitionController;
  
  // Animation de fondu entre les images
  late Animation<double> _fadeAnimation;
  
  // Animation d'accélération des particules
  late Animation<double> _accelerationAnimation;
  
  // Animation de disparition des particules
  late Animation<double> _particleFadeAnimation;
  
  // État interne
  bool _isTransitioning = false;
  bool _showCompleteImage = false;

  @override
  void initState() {
    super.initState();
    
    // Animation des particules (boucle infinie)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    // Animation de transition (2 secondes)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Courbes d'animation pour la transition
    _accelerationAnimation = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _particleFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showCompleteImage = true;
        });
        widget.onTransitionComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(BrainGestationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Démarrer la transition quand isComplete passe à true
    if (widget.isComplete && !oldWidget.isComplete && !_isTransitioning) {
      _startTransition();
    }
  }

  void _startTransition() {
    setState(() {
      _isTransitioning = true;
    });
    _transitionController.forward();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Couche 1: Image de chargement (cerveau avec anneaux)
            if (!_showCompleteImage)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1.0 - _fadeAnimation.value,
                    child: child,
                  );
                },
                child: Image.asset(
                  widget.loadingImagePath,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderBackground();
                  },
                ),
              ),
            
            // Couche 2: Particules d'énergie
            if (!_showCompleteImage)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _particleController,
                  _transitionController,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: EnergyFlowPainter(
                      progress: _particleController.value,
                      speedMultiplier: _isTransitioning 
                          ? _accelerationAnimation.value 
                          : 1.0,
                      opacity: _isTransitioning 
                          ? _particleFadeAnimation.value 
                          : 1.0,
                    ),
                  );
                },
              ),
            
            // Couche 3: Flash lumineux pendant transition
            if (_isTransitioning && !_showCompleteImage)
              AnimatedBuilder(
                animation: _transitionController,
                builder: (context, _) {
                  final flashValue = _calculateFlashIntensity();
                  return Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(flashValue * 0.6),
                          Colors.cyan.withOpacity(flashValue * 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  );
                },
              ),
            
            // Couche 4: Image finale (cerveau sur ciel bleu)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                widget.completeImagePath,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildCompletePlaceholder();
                },
              ),
            ),
            
            // Couche 5: Glow final subtil
            if (_showCompleteImage)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, _) {
                  return Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.2 * value),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  double _calculateFlashIntensity() {
    // Flash qui monte puis redescend entre 40% et 60% de la transition
    final t = _transitionController.value;
    if (t < 0.4) return 0.0;
    if (t > 0.6) return 0.0;
    final normalized = (t - 0.4) / 0.2;
    return math.sin(normalized * math.pi);
  }

  Widget _buildPlaceholderBackground() {
    // Placeholder si l'image de chargement n'est pas trouvée
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8F4FC),
            const Color(0xFFB8D4E8),
            const Color(0xFF8FB8D4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.psychology,
          size: widget.size * 0.4,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildCompletePlaceholder() {
    // Placeholder si l'image finale n'est pas trouvée
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF87CEEB),
            const Color(0xFF4DB8E8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.psychology,
          size: widget.size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

// =============================================================================
// PAINTER POUR LES FLUX D'ÉNERGIE
// =============================================================================

class EnergyFlowPainter extends CustomPainter {
  final double progress;
  final double speedMultiplier;
  final double opacity;

  EnergyFlowPainter({
    required this.progress,
    this.speedMultiplier = 1.0,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Définir les 3 anneaux orbitaux avec différentes orientations
    final orbits = [
      _OrbitConfig(
        radiusX: size.width * 0.42,
        radiusY: size.height * 0.18,
        rotation: -0.3,
        particleCount: 4,
        baseSpeed: 1.0,
        direction: 1,
        color: const Color(0xFF00E5FF),
      ),
      _OrbitConfig(
        radiusX: size.width * 0.38,
        radiusY: size.height * 0.20,
        rotation: 0.8,
        particleCount: 3,
        baseSpeed: 0.7,
        direction: -1,
        color: const Color(0xFF64FFDA),
      ),
      _OrbitConfig(
        radiusX: size.width * 0.35,
        radiusY: size.height * 0.22,
        rotation: 2.2,
        particleCount: 5,
        baseSpeed: 1.3,
        direction: 1,
        color: const Color(0xFFB388FF),
      ),
    ];

    for (final orbit in orbits) {
      _drawOrbitParticles(canvas, center, orbit);
    }
  }

  void _drawOrbitParticles(Canvas canvas, Offset center, _OrbitConfig orbit) {
    final particleSpacing = (2 * math.pi) / orbit.particleCount;
    
    for (int i = 0; i < orbit.particleCount; i++) {
      // Position de la particule sur l'orbite
      final baseAngle = i * particleSpacing;
      final currentAngle = baseAngle + 
          (progress * 2 * math.pi * orbit.baseSpeed * speedMultiplier * orbit.direction);
      
      // Calculer la position sur l'ellipse avec rotation
      final rotatedAngle = currentAngle;
      final x = orbit.radiusX * math.cos(rotatedAngle);
      final y = orbit.radiusY * math.sin(rotatedAngle);
      
      // Appliquer la rotation de l'orbite
      final cosR = math.cos(orbit.rotation);
      final sinR = math.sin(orbit.rotation);
      final rotatedX = x * cosR - y * sinR;
      final rotatedY = x * sinR + y * cosR;
      
      final particlePos = Offset(
        center.dx + rotatedX,
        center.dy + rotatedY,
      );
      
      // Dessiner la traînée
      _drawTrail(canvas, center, orbit, currentAngle, particlePos);
      
      // Dessiner la particule principale
      _drawParticle(canvas, particlePos, orbit.color);
    }
  }

  void _drawTrail(
    Canvas canvas,
    Offset center,
    _OrbitConfig orbit,
    double currentAngle,
    Offset particlePos,
  ) {
    final trailLength = 15; // Nombre de segments de traînée
    final trailPath = Path();
    
    List<Offset> trailPoints = [particlePos];
    
    for (int j = 1; j <= trailLength; j++) {
      final trailAngle = currentAngle - 
          (j * 0.08 * orbit.direction * speedMultiplier);
      
      final tx = orbit.radiusX * math.cos(trailAngle);
      final ty = orbit.radiusY * math.sin(trailAngle);
      
      final cosR = math.cos(orbit.rotation);
      final sinR = math.sin(orbit.rotation);
      final rotatedTx = tx * cosR - ty * sinR;
      final rotatedTy = tx * sinR + ty * cosR;
      
      trailPoints.add(Offset(
        center.dx + rotatedTx,
        center.dy + rotatedTy,
      ));
    }
    
    // Dessiner la traînée avec dégradé d'opacité
    for (int j = 0; j < trailPoints.length - 1; j++) {
      final segmentOpacity = (1.0 - (j / trailLength)) * opacity * 0.6;
      final segmentWidth = (1.0 - (j / trailLength)) * 3.0 + 1.0;
      
      final trailPaint = Paint()
        ..color = orbit.color.withOpacity(segmentOpacity)
        ..strokeWidth = segmentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(trailPoints[j], trailPoints[j + 1], trailPaint);
    }
  }

  void _drawParticle(Canvas canvas, Offset position, Color color) {
    // Glow externe
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(position, 8, glowPaint);
    
    // Glow moyen
    final midGlowPaint = Paint()
      ..color = color.withOpacity(0.5 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(position, 5, midGlowPaint);
    
    // Cœur lumineux
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity);
    canvas.drawCircle(position, 2.5, corePaint);
    
    // Centre brillant
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(opacity);
    canvas.drawCircle(position, 1.5, centerPaint);
  }

  @override
  bool shouldRepaint(EnergyFlowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.speedMultiplier != speedMultiplier ||
           oldDelegate.opacity != opacity;
  }
}

// Configuration d'une orbite
class _OrbitConfig {
  final double radiusX;
  final double radiusY;
  final double rotation;
  final int particleCount;
  final double baseSpeed;
  final int direction; // 1 ou -1
  final Color color;

  _OrbitConfig({
    required this.radiusX,
    required this.radiusY,
    required this.rotation,
    required this.particleCount,
    required this.baseSpeed,
    required this.direction,
    required this.color,
  });
}

// =============================================================================
// WIDGET SIMPLIFIÉ POUR INTÉGRATION RAPIDE
// =============================================================================

/// Version simplifiée qui gère son propre état
class BrainGestationLoader extends StatefulWidget {
  final Stream<bool>? completionStream;
  final bool isComplete;
  final double size;
  final String? loadingImagePath;
  final String? completeImagePath;

  const BrainGestationLoader({
    super.key,
    this.completionStream,
    this.isComplete = false,
    this.size = 200,
    this.loadingImagePath,
    this.completeImagePath,
  });

  @override
  State<BrainGestationLoader> createState() => _BrainGestationLoaderState();
}

class _BrainGestationLoaderState extends State<BrainGestationLoader> {
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _isComplete = widget.isComplete;
    widget.completionStream?.listen((complete) {
      if (complete && !_isComplete) {
        setState(() {
          _isComplete = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(BrainGestationLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isComplete && !_isComplete) {
      setState(() {
        _isComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrainGestationWidget(
      isComplete: _isComplete,
      size: widget.size,
      loadingImagePath: widget.loadingImagePath ?? 
          'assets/univers_visuel/brain_loading.png',
      completeImagePath: widget.completeImagePath ?? 
          'assets/univers_visuel/brain_complete.png',
    );
  }
}

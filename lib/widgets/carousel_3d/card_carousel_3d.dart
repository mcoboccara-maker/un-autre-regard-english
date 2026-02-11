import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Mode d'affichage du manège
enum CarouselMode {
  /// Cartes vues de face (menu, éclairages)
  face,
  /// Cartes vues par la tranche (accueil, émotions)
  spine,
}

/// Direction du swipe décisionnel (Tinder-like)
enum SwipeDirection {
  left,
  right,
  none,
}

/// Données pour une carte du carousel
class CarouselCardData {
  final String id;
  final Widget child;
  final Color? backgroundColor;
  final String? label;

  const CarouselCardData({
    required this.id,
    required this.child,
    this.backgroundColor,
    this.label,
  });
}

/// Callback pour les événements du carousel
typedef OnCardTap = void Function(int index, CarouselCardData card);
typedef OnCardSwipe = void Function(int index, CarouselCardData card, SwipeDirection direction);
typedef OnCardChanged = void Function(int index);

/// Manège 3D de cartes - Composant central réutilisable
///
/// Deux modes d'affichage :
/// - [CarouselMode.face] : carte centrale face à l'utilisateur
/// - [CarouselMode.spine] : cartes vues par la tranche (75-85°)
class CardCarousel3D extends StatefulWidget {
  /// Liste des cartes à afficher
  final List<CarouselCardData> cards;

  /// Mode d'affichage (face ou spine)
  final CarouselMode mode;

  /// Index initial de la carte active
  final int initialIndex;

  /// Callback quand on tap sur une carte
  final OnCardTap? onCardTap;

  /// Callback quand on swipe une carte (gauche/droite)
  final OnCardSwipe? onCardSwipe;

  /// Callback quand la carte active change
  final OnCardChanged? onCardChanged;

  /// Active les swipes décisionnels (Tinder-like)
  final bool enableSwipeActions;

  /// Hauteur des cartes (défaut: 400)
  final double cardHeight;

  /// Largeur des cartes (défaut: 280)
  final double cardWidth;

  /// Espacement angulaire entre les cartes (en degrés)
  final double angleSpacing;

  /// Contrôleur externe optionnel
  final Carousel3DController? controller;

  /// Décalage vertical du centre (négatif = vers le haut)
  final double verticalOffset;

  const CardCarousel3D({
    super.key,
    required this.cards,
    this.mode = CarouselMode.face,
    this.initialIndex = 0,
    this.onCardTap,
    this.onCardSwipe,
    this.onCardChanged,
    this.enableSwipeActions = false,
    this.cardHeight = 400,
    this.cardWidth = 280,
    this.angleSpacing = 30,
    this.controller,
    this.verticalOffset = 0,
  });

  @override
  State<CardCarousel3D> createState() => _CardCarousel3DState();
}

class _CardCarousel3DState extends State<CardCarousel3D>
    with TickerProviderStateMixin {

  late double _currentAngle;
  late AnimationController _rotationController;
  late AnimationController _swipeController;

  double _dragStartX = 0;
  double _dragDeltaX = 0;
  double _swipeOffsetX = 0;
  int _activeCardIndex = 0;
  bool _isDragging = false;
  bool _isSwipingCard = false;

  // Centre du layout (calculé dans LayoutBuilder)
  double _centerX = 0;
  double _centerY = 0;

  // Constantes visuelles CDC - Bleu nuit
  static const Color _fondPrincipal = Color(0xFF0D1B3E);
  static const Color _fondVariante = Color(0xFF1A2E5A);

  // Angles pour mode spine (CDC: 75-85°)
  static const double _spineAngle = 80.0;

  @override
  void initState() {
    super.initState();
    _activeCardIndex = widget.initialIndex.clamp(0, widget.cards.length - 1);
    _currentAngle = -_activeCardIndex * widget.angleSpacing;

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _rotationController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  /// Calcule l'index actif basé sur l'angle courant
  int _calculateActiveIndex() {
    final rawIndex = (-_currentAngle / widget.angleSpacing).round();
    return rawIndex.clamp(0, widget.cards.length - 1);
  }

  /// Anime vers un index spécifique
  void animateToIndex(int index) {
    if (index < 0 || index >= widget.cards.length) return;

    final targetAngle = -index * widget.angleSpacing;
    final startAngle = _currentAngle;

    _rotationController.reset();
    _rotationController.duration = const Duration(milliseconds: 400);
    _rotationController.addListener(() {
      setState(() {
        _currentAngle = startAngle +
            (_rotationController.value * (targetAngle - startAngle));
      });
    });

    _rotationController.forward().then((_) {
      _updateActiveIndex();
    });
  }

  /// Spin roulette : fait tourner le carousel de [extraCards] cartes
  /// supplémentaires avant d'atterrir sur [index] avec décélération
  void spinToIndex(int index, {int extraCards = 48}) {
    if (index < 0 || index >= widget.cards.length) return;

    // L'angle cible inclut les tours supplémentaires
    final totalCards = extraCards + index;
    final targetAngle = -totalCards * widget.angleSpacing;
    final startAngle = _currentAngle;

    _rotationController.reset();
    // Durée proportionnelle au nombre de cartes traversées
    final duration = 2000 + (extraCards * 20);
    _rotationController.duration = Duration(milliseconds: duration.clamp(2000, 5000));

    _rotationController.addListener(() {
      // Courbe de décélération : rapide au début, lent à la fin
      final t = Curves.easeOutCubic.transform(_rotationController.value);
      setState(() {
        _currentAngle = startAngle + (t * (targetAngle - startAngle));
      });
    });

    _rotationController.forward().then((_) {
      // Normaliser l'angle pour correspondre à l'index réel
      _currentAngle = -index * widget.angleSpacing;
      _updateActiveIndex();
    });
  }

  void _updateActiveIndex() {
    final newIndex = _calculateActiveIndex();
    if (newIndex != _activeCardIndex) {
      _activeCardIndex = newIndex;
      widget.onCardChanged?.call(_activeCardIndex);
    }
  }

  /// Snap vers la carte la plus proche
  void _snapToNearest() {
    final nearestIndex = _calculateActiveIndex();
    animateToIndex(nearestIndex);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [_fondVariante, _fondPrincipal],
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _centerX = constraints.maxWidth / 2;
              _centerY = constraints.maxHeight / 2 + widget.verticalOffset;
              return Stack(
                clipBehavior: Clip.none,
                children: _buildCards(),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards() {
    final List<_CardTransformData> cardsData = [];

    for (int i = 0; i < widget.cards.length; i++) {
      final cardAngle = _currentAngle + (i * widget.angleSpacing);
      final transformData = _calculateCardTransform(i, cardAngle);
      cardsData.add(transformData);
    }

    // Trier par profondeur (z) pour afficher les plus éloignées en premier
    cardsData.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return cardsData.map((data) => _buildCard(data)).toList();
  }

  _CardTransformData _calculateCardTransform(int index, double angle) {
    // Normaliser l'angle entre -180 et 180
    double normalizedAngle = angle % 360;
    if (normalizedAngle > 180) normalizedAngle -= 360;
    if (normalizedAngle < -180) normalizedAngle += 360;

    final bool isActive = index == _activeCardIndex;
    final double absAngle = normalizedAngle.abs();

    // Position X basée sur l'angle
    final double xOffset = math.sin(normalizedAngle * math.pi / 180) * 200;

    // Profondeur Z : carte active (angle ~0) devant, cartes éloignées derrière
    final double zOffset = math.cos(normalizedAngle * math.pi / 180) * 50;

    // Rotation Y
    double rotationY;
    if (widget.mode == CarouselMode.spine) {
      // Mode tranche : rotation forte (75-85°)
      rotationY = normalizedAngle > 0 ? _spineAngle : -_spineAngle;
      if (isActive && absAngle < 15) {
        // Carte active : pivote vers la face
        rotationY = normalizedAngle * 0.5;
      }
    } else {
      // Mode face : rotation progressive
      rotationY = normalizedAngle * 0.3;
    }

    // Opacité décroissante avec la distance
    double opacity = 1.0 - (absAngle / 180) * 0.7;
    opacity = opacity.clamp(0.3, 1.0);

    // Scale décroissant avec la distance
    double scale = 1.0 - (absAngle / 180) * 0.3;
    scale = scale.clamp(0.7, 1.0);

    // Blur pour les cartes éloignées (effet de profondeur)
    double blur = absAngle > 60 ? (absAngle - 60) / 30 : 0;
    blur = blur.clamp(0.0, 3.0);

    return _CardTransformData(
      index: index,
      card: widget.cards[index],
      xOffset: xOffset,
      zIndex: zOffset,
      rotationY: rotationY,
      opacity: opacity,
      scale: scale,
      blur: blur,
      isActive: isActive,
    );
  }

  Widget _buildCard(_CardTransformData data) {
    // Swipe offset pour la carte active seulement
    final swipeOffset = data.isActive ? _swipeOffsetX : 0.0;
    final swipeRotation = data.isActive ? _swipeOffsetX / 500 : 0.0;

    // Position centrée dans le layout
    final left = _centerX - widget.cardWidth / 2;
    final top = _centerY - widget.cardHeight / 2;

    return Positioned(
      left: left,
      top: top,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..translate(data.xOffset + swipeOffset, 0.0, data.zIndex)
          ..rotateY(data.rotationY * math.pi / 180)
          ..rotateZ(swipeRotation)
          ..scale(data.scale),
        child: Opacity(
          opacity: data.opacity,
          child: GestureDetector(
            onTap: () => _onCardTap(data.index, data.card),
            onHorizontalDragStart: widget.enableSwipeActions && data.isActive
                ? _onSwipeStart
                : null,
            onHorizontalDragUpdate: widget.enableSwipeActions && data.isActive
                ? _onSwipeUpdate
                : null,
            onHorizontalDragEnd: widget.enableSwipeActions && data.isActive
                ? _onSwipeEnd
                : null,
            child: Container(
              width: widget.cardWidth,
              height: widget.cardHeight,
              decoration: BoxDecoration(
                color: data.card.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (data.card.backgroundColor ?? Colors.blue)
                        .withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: data.blur > 0
                    ? ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: data.blur,
                          sigmaY: data.blur,
                        ),
                        child: data.card.child,
                      )
                    : data.card.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === Gestion des gestes - Rotation du manège ===

  void _onDragStart(DragStartDetails details) {
    if (_isSwipingCard) return;
    _isDragging = true;
    _dragStartX = details.globalPosition.dx;
    _rotationController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isSwipingCard) return;

    _dragDeltaX = details.globalPosition.dx - _dragStartX;

    setState(() {
      // Convertir le drag en rotation
      // Plus de sensibilité pour plus de cartes
      final sensitivity = widget.cards.length > 10 ? 0.3 : 0.2;
      _currentAngle += details.delta.dx * sensitivity;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    // Inertie basée sur la vélocité
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 500) {
      // Swipe rapide : avancer/reculer d'une ou plusieurs cartes
      final cardsToMove = (velocity.abs() / 1000).ceil();
      final direction = velocity > 0 ? -1 : 1;
      final targetIndex = (_activeCardIndex + direction * cardsToMove)
          .clamp(0, widget.cards.length - 1);
      animateToIndex(targetIndex);
    } else {
      _snapToNearest();
    }
  }

  // === Gestion des gestes - Swipe décisionnel (Tinder) ===

  void _onSwipeStart(DragStartDetails details) {
    _isSwipingCard = true;
    _swipeController.stop();
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    if (!_isSwipingCard) return;
    setState(() {
      _swipeOffsetX += details.delta.dx;
    });
  }

  void _onSwipeEnd(DragEndDetails details) {
    if (!_isSwipingCard) return;
    _isSwipingCard = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_swipeOffsetX.abs() > threshold) {
      // Swipe validé
      final direction = _swipeOffsetX > 0
          ? SwipeDirection.right
          : SwipeDirection.left;

      // Animer la sortie
      final targetX = _swipeOffsetX > 0 ? screenWidth : -screenWidth;
      _animateSwipeOut(targetX, () {
        widget.onCardSwipe?.call(
          _activeCardIndex,
          widget.cards[_activeCardIndex],
          direction,
        );
        setState(() {
          _swipeOffsetX = 0;
        });
      });
    } else {
      // Retour à la position initiale
      _animateSwipeBack();
    }
  }

  void _animateSwipeOut(double targetX, VoidCallback onComplete) {
    final startX = _swipeOffsetX;
    _swipeController.reset();
    _swipeController.addListener(() {
      setState(() {
        _swipeOffsetX = startX +
            (_swipeController.value * (targetX - startX));
      });
    });
    _swipeController.forward().then((_) => onComplete());
  }

  void _animateSwipeBack() {
    final startX = _swipeOffsetX;
    _swipeController.reset();
    _swipeController.addListener(() {
      setState(() {
        _swipeOffsetX = startX * (1 - _swipeController.value);
      });
    });
    _swipeController.forward();
  }

  void _onCardTap(int index, CarouselCardData card) {
    if (index == _activeCardIndex) {
      widget.onCardTap?.call(index, card);
    } else {
      // Naviguer vers cette carte
      animateToIndex(index);
    }
  }
}

/// Données de transformation pour une carte
class _CardTransformData {
  final int index;
  final CarouselCardData card;
  final double xOffset;
  final double zIndex;
  final double rotationY;
  final double opacity;
  final double scale;
  final double blur;
  final bool isActive;

  _CardTransformData({
    required this.index,
    required this.card,
    required this.xOffset,
    required this.zIndex,
    required this.rotationY,
    required this.opacity,
    required this.scale,
    required this.blur,
    required this.isActive,
  });
}

/// Contrôleur pour manipuler le carousel depuis l'extérieur
class Carousel3DController {
  _CardCarousel3DState? _state;

  void _attach(_CardCarousel3DState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Navigue vers un index spécifique
  void animateToIndex(int index) {
    _state?.animateToIndex(index);
  }

  /// Spin roulette vers un index avec tours supplémentaires
  void spinToIndex(int index, {int extraCards = 48}) {
    _state?.spinToIndex(index, extraCards: extraCards);
  }

  /// Retourne l'index actif actuel
  int? get activeIndex => _state?._activeCardIndex;

  /// Navigue vers la carte suivante
  void next() {
    if (_state != null) {
      final nextIndex = (_state!._activeCardIndex + 1)
          .clamp(0, _state!.widget.cards.length - 1);
      animateToIndex(nextIndex);
    }
  }

  /// Navigue vers la carte précédente
  void previous() {
    if (_state != null) {
      final prevIndex = (_state!._activeCardIndex - 1)
          .clamp(0, _state!.widget.cards.length - 1);
      animateToIndex(prevIndex);
    }
  }
}

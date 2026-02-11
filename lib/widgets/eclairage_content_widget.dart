import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math' as math;

/// WIDGET DE MISE EN SCENE DU CONTENU D'UN ECLAIRAGE
///
/// STYLES DISPONIBLES:
/// - 'classic'    : affichage simple (comme avant)
/// - 'carousel'   : cartes horizontales swipeable
/// - 'story'      : style Instagram stories avec progression
/// - 'flip'       : carte qui se retourne au tap
/// - 'typewriter' : texte qui s'écrit lettre par lettre
/// - 'stack'      : cartes empilées qui se dépilent
/// - 'manege'     : carrousel 3D rotatif style manège
class EclairageContentWidget extends StatefulWidget {
  final String response;
  final Color accentColor;
  final String Function(String) cleanMarkdown;
  final String style;

  /// Callbacks pour les actions (utilisés par le style manège)
  final VoidCallback? onListen;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onNewReflection;

  const EclairageContentWidget({
    super.key,
    required this.response,
    required this.accentColor,
    required this.cleanMarkdown,
    this.style = 'classic',
    this.onListen,
    this.onShare,
    this.onSave,
    this.onNewReflection,
  });

  @override
  State<EclairageContentWidget> createState() => _EclairageContentWidgetState();
}

class _EclairageContentWidgetState extends State<EclairageContentWidget>
    with TickerProviderStateMixin {

  // Carousel / Manège
  late PageController _pageController;
  int _currentPage = 0;
  double _rotationAngle = 0;

  // Flip card
  bool _isFlipped = false;

  // Typewriter
  String _displayedText = '';
  int _charIndex = 0;

  // Stack
  int _currentStackIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    if (widget.style == 'typewriter') {
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startTypewriter() async {
    final text = widget.cleanMarkdown(widget.response);
    for (int i = 0; i < text.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 15));
      setState(() {
        _charIndex = i + 1;
        _displayedText = text.substring(0, _charIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case 'carousel':
        return _buildCarouselStyle();
      case 'story':
        return _buildStoryStyle();
      case 'flip':
        return _buildFlipStyle();
      case 'typewriter':
        return _buildTypewriterStyle();
      case 'stack':
        return _buildStackStyle();
      case 'manege':
        return _buildManegeStyle();
      default:
        return _buildClassicStyle();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STYLE CLASSIQUE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildClassicStyle() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: MarkdownBody(
        data: widget.cleanMarkdown(widget.response),
        styleSheet: _getMarkdownStyleSheet(),
        selectable: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANEGE - Carrousel 3D rotatif
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildManegeStyle() {
    final paragraphs = _getParagraphs();

    // Créer les items du manège: paragraphes + carte actions
    final List<_ManegeItem> items = [
      ...paragraphs.asMap().entries.map((e) => _ManegeItem(
        type: 'content',
        title: e.key == 0 ? 'Accroche' : 'Partie ${e.key + 1}',
        content: e.value,
        icon: e.key == 0 ? Icons.auto_awesome : Icons.article,
      )),
      _ManegeItem(
        type: 'actions',
        title: 'Actions',
        content: '',
        icon: Icons.touch_app,
      ),
    ];

    final itemCount = items.length;
    final anglePerItem = 2 * math.pi / itemCount;

    return Column(
      children: [
        // Indicateur de position
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(itemCount, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () => _goToManegeItem(index, itemCount),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? widget.accentColor
                        : widget.accentColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: isActive ? Center(
                    child: Icon(
                      items[index].icon,
                      size: 8,
                      color: Colors.white,
                    ),
                  ) : null,
                ),
              );
            }),
          ),
        ),

        // Le manège 3D
        SizedBox(
          height: 380,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _rotationAngle += details.delta.dx * 0.01;
              });
            },
            onHorizontalDragEnd: (details) {
              // Snap to nearest item
              final nearestIndex = ((-_rotationAngle / anglePerItem) % itemCount).round() % itemCount;
              _goToManegeItem(nearestIndex, itemCount);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fond avec dégradé
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Les cartes du manège
                ...List.generate(itemCount, (index) {
                  final angle = anglePerItem * index + _rotationAngle;
                  final x = math.sin(angle) * 120;
                  final z = math.cos(angle);
                  final scale = 0.6 + (z + 1) * 0.25; // 0.6 to 1.1
                  final opacity = 0.4 + (z + 1) * 0.3; // 0.4 to 1.0

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..translate(x, 0.0, -z * 50),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: _buildManegeCard(items[index], index, z > 0.5),
                      ),
                    ),
                  );
                })..sort((a, b) {
                  // Trier par profondeur pour que la carte devant soit au-dessus
                  final aZ = math.cos(anglePerItem * items.indexOf(items[0]) + _rotationAngle);
                  final bZ = math.cos(anglePerItem * items.indexOf(items[0]) + _rotationAngle);
                  return aZ.compareTo(bZ);
                }),
              ],
            ),
          ),
        ),

        // Contrôles de navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildManegeNavButton(Icons.arrow_back_ios, () {
                _goToManegeItem((_currentPage - 1 + itemCount) % itemCount, itemCount);
              }),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  items[_currentPage].title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _buildManegeNavButton(Icons.arrow_forward_ios, () {
                _goToManegeItem((_currentPage + 1) % itemCount, itemCount);
              }),
            ],
          ),
        ),

        // Instruction
        Text(
          'Glissez ou utilisez les flèches',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: widget.accentColor.withOpacity(0.5),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 1000.ms)
            .then()
            .fadeOut(duration: 1000.ms),

        const SizedBox(height: 8),
      ],
    );
  }

  void _goToManegeItem(int index, int itemCount) {
    final anglePerItem = 2 * math.pi / itemCount;
    final targetAngle = -anglePerItem * index;

    // Animation fluide vers la cible
    setState(() {
      _rotationAngle = targetAngle;
      _currentPage = index;
    });
  }

  Widget _buildManegeNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.accentColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms);
  }

  Widget _buildManegeCard(_ManegeItem item, int index, bool isFront) {
    if (item.type == 'actions') {
      return _buildManegeActionsCard(isFront);
    }
    return _buildManegeContentCard(item, index, isFront);
  }

  Widget _buildManegeContentCard(_ManegeItem item, int index, bool isFront) {
    return Container(
      width: 280,
      height: 350,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            widget.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFront
              ? widget.accentColor.withOpacity(0.3)
              : widget.accentColor.withOpacity(0.1),
          width: isFront ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(isFront ? 0.2 : 0.1),
            blurRadius: isFront ? 30 : 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: widget.accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  item.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManegeActionsCard(bool isFront) {
    return Container(
      width: 280,
      height: 350,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.accentColor.withOpacity(0.1),
            widget.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFront
              ? widget.accentColor.withOpacity(0.4)
              : widget.accentColor.withOpacity(0.2),
          width: isFront ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(isFront ? 0.25 : 0.1),
            blurRadius: isFront ? 30 : 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 48,
              color: widget.accentColor,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),

            const SizedBox(height: 16),

            Text(
              'Actions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            _buildManegeActionButton(
              Icons.volume_up,
              'Écouter',
              widget.onListen,
            ),
            const SizedBox(height: 12),
            _buildManegeActionButton(
              Icons.share,
              'Partager',
              widget.onShare,
            ),
            const SizedBox(height: 12),
            _buildManegeActionButton(
              Icons.bookmark_outline,
              'Sauvegarder',
              widget.onSave,
            ),
            const SizedBox(height: 12),
            _buildManegeActionButton(
              Icons.refresh,
              'Nouvelle réflexion',
              widget.onNewReflection,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManegeActionButton(IconData icon, String label, VoidCallback? onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary ? widget.accentColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.accentColor.withOpacity(isPrimary ? 1 : 0.3),
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: widget.accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : widget.accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : widget.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAROUSEL - Cartes horizontales swipeable
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCarouselStyle() {
    final paragraphs = _getParagraphs();

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: paragraphs.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: Curves.easeOut.transform(value),
                      child: _buildCarouselCard(paragraphs[index], index),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(paragraphs.length, (index) {
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? widget.accentColor
                      : widget.accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe, size: 16, color: widget.accentColor.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'Glissez pour explorer',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.accentColor.withOpacity(0.5),
                ),
              ),
            ],
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideX(begin: -0.05, end: 0.05, duration: 1500.ms),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(String text, int index) {
    final icons = [Icons.auto_awesome, Icons.psychology, Icons.lightbulb, Icons.favorite];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withOpacity(0.1),
            widget.accentColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icons[index % icons.length],
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${index + 1}/${_getParagraphs().length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY - Style Instagram stories
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStoryStyle() {
    final paragraphs = _getParagraphs();

    return GestureDetector(
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth / 2) {
          if (_currentPage > 0) setState(() => _currentPage--);
        } else {
          if (_currentPage < paragraphs.length - 1) setState(() => _currentPage++);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.accentColor.withOpacity(0.08),
              widget.accentColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: List.generate(paragraphs.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage
                            ? widget.accentColor
                            : widget.accentColor.withOpacity(0.2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  key: ValueKey(_currentPage),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${paragraphs.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        paragraphs[_currentPage],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          color: const Color(0xFF1E293B),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 16, color: widget.accentColor.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Text(
                    'Tapez à gauche/droite',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: widget.accentColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLIP - Carte qui se retourne
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFlipStyle() {
    final paragraphs = _getParagraphs();
    final front = paragraphs.isNotEmpty ? paragraphs[0] : '';
    final back = paragraphs.length > 1 ? paragraphs.skip(1).join('\n\n') : '';

    return GestureDetector(
      onTap: () => setState(() => _isFlipped = !_isFlipped),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            final rotate = Tween(begin: math.pi, end: 0.0).animate(animation);
            return AnimatedBuilder(
              animation: rotate,
              child: child,
              builder: (context, child) {
                final isUnder = (ValueKey(_isFlipped) != child?.key);
                final value = isUnder ? math.min(rotate.value, math.pi / 2) : rotate.value;
                return Transform(
                  transform: Matrix4.rotationY(value),
                  alignment: Alignment.center,
                  child: child,
                );
              },
            );
          },
          child: _isFlipped
              ? _buildFlipCard(back, 'DÉVELOPPEMENT', Icons.psychology, key: const ValueKey(true))
              : _buildFlipCard(front, 'ACCROCHE', Icons.auto_awesome, key: const ValueKey(false)),
        ),
      ),
    );
  }

  Widget _buildFlipCard(String text, String label, IconData icon, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withOpacity(0.12),
            widget.accentColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.flip, color: widget.accentColor.withOpacity(0.5))
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 2000.ms),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1E293B),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tapez pour retourner',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: widget.accentColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPEWRITER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTypewriterStyle() {
    final fullText = widget.cleanMarkdown(widget.response);
    final isComplete = _charIndex >= fullText.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isComplete)
            LinearProgressIndicator(
              value: _charIndex / fullText.length,
              backgroundColor: widget.accentColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(widget.accentColor),
            ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _displayedText,
                  style: GoogleFonts.courierPrime(
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                    height: 1.8,
                  ),
                ),
                if (!isComplete)
                  WidgetSpan(
                    child: Container(width: 2, height: 18, color: widget.accentColor)
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(duration: 500.ms)
                        .then()
                        .fadeOut(duration: 500.ms),
                  ),
              ],
            ),
          ),
          if (!isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _displayedText = fullText;
                    _charIndex = fullText.length;
                  });
                },
                icon: const Icon(Icons.fast_forward, size: 18),
                label: const Text('Afficher tout'),
                style: TextButton.styleFrom(foregroundColor: widget.accentColor),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STACK
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStackStyle() {
    final paragraphs = _getParagraphs();
    final remaining = paragraphs.length - _currentStackIndex;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = math.min(_currentStackIndex + 2, paragraphs.length - 1);
                     i > _currentStackIndex; i--)
                  Transform.translate(
                    offset: Offset(0, (i - _currentStackIndex) * -8.0),
                    child: Transform.scale(
                      scale: 1 - (i - _currentStackIndex) * 0.05,
                      child: _buildStackCard(paragraphs[i], i, isBackground: true),
                    ),
                  ),
                if (_currentStackIndex < paragraphs.length)
                  Dismissible(
                    key: ValueKey(_currentStackIndex),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) => setState(() => _currentStackIndex++),
                    child: _buildStackCard(paragraphs[_currentStackIndex], _currentStackIndex, isBackground: false),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (remaining > 0)
                Text(
                  '$remaining carte${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(fontSize: 14, color: widget.accentColor, fontWeight: FontWeight.w500),
                )
              else
                TextButton.icon(
                  onPressed: () => setState(() => _currentStackIndex = 0),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Recommencer'),
                  style: TextButton.styleFrom(foregroundColor: widget.accentColor),
                ),
            ],
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe, size: 16, color: widget.accentColor.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Text('Glissez pour passer', style: GoogleFonts.inter(fontSize: 12, color: widget.accentColor.withOpacity(0.5))),
                ],
              ).animate(onPlay: (c) => c.repeat(reverse: true)).slideX(begin: -0.03, end: 0.03, duration: 1000.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildStackCard(String text, int index, {required bool isBackground}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: isBackground ? Colors.white : null,
        gradient: isBackground ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, widget.accentColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor.withOpacity(isBackground ? 0.1 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(isBackground ? 0.05 : 0.15),
            blurRadius: isBackground ? 10 : 25,
            offset: Offset(0, isBackground ? 5 : 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${index + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: widget.accentColor)),
            ),
            const SizedBox(height: 12),
            Text(text, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B), height: 1.6)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  List<String> _getParagraphs() {
    final cleaned = widget.cleanMarkdown(widget.response);
    return cleaned.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
  }

  MarkdownStyleSheet _getMarkdownStyleSheet() {
    // CDC: Texte crème doux pour fond sombre bleu-vert (pas trop blanc)
    const textColor = Color(0xFFE8E0D0); // Crème doux, moins blanc
    const boldColor = Color(0xFFF0EBE0); // Légèrement plus clair pour le gras
    return MarkdownStyleSheet(
      p: GoogleFonts.inter(fontSize: 15, color: textColor, height: 1.7),
      strong: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: boldColor, height: 1.7),
      em: GoogleFonts.inter(fontSize: 15, fontStyle: FontStyle.italic, color: textColor, height: 1.7),
    );
  }
}

// Classe helper pour les items du manège
class _ManegeItem {
  final String type;
  final String title;
  final String content;
  final IconData icon;

  _ManegeItem({
    required this.type,
    required this.title,
    required this.content,
    required this.icon,
  });
}

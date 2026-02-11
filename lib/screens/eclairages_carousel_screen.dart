// lib/screens/eclairages_carousel_screen.dart
// CDC §3.6 - Eclairages en mode FACE avec swipe save/reject

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../widgets/carousel_3d/card_carousel_3d.dart';
import 'perspective_room_screen.dart';

class EclairagesCarouselScreen extends StatefulWidget {
  final String thoughtText;
  final List<PerspectiveData> perspectives;

  const EclairagesCarouselScreen({
    super.key,
    required this.thoughtText,
    required this.perspectives,
  });

  @override
  State<EclairagesCarouselScreen> createState() =>
      _EclairagesCarouselScreenState();
}

class _EclairagesCarouselScreenState extends State<EclairagesCarouselScreen> {
  late List<PerspectiveData> _perspectives;
  final Map<int, bool> _savedMap = {}; // true=saved, false=rejected
  bool _showFinalPage = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _perspectives = List.from(widget.perspectives);
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  ApproachConfig? _getApproachConfig(String key) {
    return ApproachCategories.findByKey(key);
  }

  List<CarouselCardData> _buildCards() {
    return _perspectives.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      final config = _getApproachConfig(p.approachKey);
      final color = config?.color ?? const Color(0xFF4A90A4);
      final isSaved = _savedMap[i];

      return CarouselCardData(
        id: p.approachKey,
        backgroundColor: color,
        label: p.approachName,
        child: _buildEclairageCard(p, config, color, isSaved),
      );
    }).toList();
  }

  Widget _buildEclairageCard(
    PerspectiveData perspective,
    ApproachConfig? config,
    Color color,
    bool? savedState,
  ) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.15),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source header
              Row(
                children: [
                  Icon(config?.icon ?? Icons.auto_awesome,
                      color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      perspective.approachName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (config != null)
                Text(
                  config.credo,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Divider(height: 16),
              // Response text (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    perspective.responseText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                      height: 1.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Swipe hints
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_back,
                          size: 14, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text('Passer',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: Colors.red[300])),
                    ],
                  ),
                  Text('Tap pour approfondir',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic)),
                  Row(
                    children: [
                      Text('Garder',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: Colors.green[400])),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 14, color: Colors.green[400]),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Save/reject overlay
        if (savedState != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: savedState
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  savedState ? Icons.bookmark : Icons.close,
                  color: savedState ? Colors.green : Colors.red,
                  size: 64,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onCardSwipe(int index, CarouselCardData card, SwipeDirection direction) {
    setState(() {
      _savedMap[index] = direction == SwipeDirection.right;
    });

    // Check if all cards processed
    if (_savedMap.length == _perspectives.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showFinalPage = true;
          });
        }
      });
    }
  }

  void _onCardTap(int index, CarouselCardData card) {
    final perspective = _perspectives[index];
    _showDeepeningSheet(perspective, index);
  }

  void _onCardChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showDeepeningSheet(PerspectiveData perspective, int index) {
    final config = _getApproachConfig(perspective.approachKey);
    final color = config?.color ?? const Color(0xFF4A90A4);

    // Get questions for this source
    final group = config?.type.name ?? 'philosophical';
    final questions = _getQuestionsForApproach(perspective.approachKey, group);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF102A43),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(config?.icon ?? Icons.auto_awesome,
                      color: color, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Approfondissement',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full text
              Text(
                perspective.responseText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 24),

              // CDC §5 questions
              if (questions.isNotEmpty) ...[
                Text(
                  'Questions pour aller plus loin',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                ...questions.map((q) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          q,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _savedMap[index] = false;
                        });
                        _checkAllProcessed();
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Passer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _savedMap[index] = true;
                        });
                        _checkAllProcessed();
                      },
                      icon: const Icon(Icons.bookmark, size: 18),
                      label: const Text('Garder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getQuestionsForApproach(String approachKey, String group) {
    // Reuse kSourceQuestions from perspective_room_screen.dart
    if (group == 'spiritual') return kSourceQuestions['spiritualite'] ?? [];
    if (group == 'psychological') return kSourceQuestions['psychologie'] ?? [];
    if (group == 'literary') return kSourceQuestions['litterature'] ?? [];
    if (group == 'philosophical') return kSourceQuestions['philosophie'] ?? [];
    if (group == 'philosopher') return kSourceQuestions['philosophie'] ?? [];

    const stoicKeys = [
      'stoicisme', 'stoicisme_philo', 'epicurisme', 'epicure',
      'seneque', 'epictete', 'marc_aurele'
    ];
    if (stoicKeys.contains(approachKey)) {
      return kSourceQuestions['stoicisme'] ?? [];
    }

    const existKeys = [
      'existentialisme', 'existentialisme_philo', 'sartre', 'camus',
      'kierkegaard'
    ];
    if (existKeys.contains(approachKey)) {
      return kSourceQuestions['existentialisme'] ?? [];
    }

    return kSourceQuestions['hasard'] ?? [];
  }

  void _checkAllProcessed() {
    if (_savedMap.length == _perspectives.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showFinalPage = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFinalPage) {
      return _buildFinalPage();
    }

    final cards = _buildCards();

    return Scaffold(
      body: Stack(
        children: [
          CardCarousel3D(
            cards: cards,
            mode: CarouselMode.face,
            angleSpacing: 35,
            cardHeight: 480,
            cardWidth: 300,
            enableSwipeActions: true,
            onCardSwipe: _onCardSwipe,
            onCardTap: _onCardTap,
            onCardChanged: _onCardChanged,
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

          // Title & progress
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 56,
            right: 56,
            child: Column(
              children: [
                Text(
                  'Eclairages',
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
                const SizedBox(height: 4),
                Text(
                  '${_savedMap.length}/${_perspectives.length} traites',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    final savedCount = _savedMap.values.where((v) => v).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF102A43), Color(0xFF0B1C2D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 32),
                Text(
                  'Ton regard a-t-il bouge ?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '$savedCount eclairage${savedCount > 1 ? 's' : ''} garde${savedCount > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // 3 options
                _buildFinalOption(
                  icon: Icons.refresh,
                  label: 'Nouvelle reflexion',
                  subtitle: 'Recommencer avec une autre pensee',
                  onTap: () {
                    // Go back to home
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 12),
                _buildFinalOption(
                  icon: Icons.auto_awesome,
                  label: 'Autres eclairages',
                  subtitle: 'Explorer d\'autres perspectives',
                  onTap: () {
                    setState(() {
                      _savedMap.clear();
                      _showFinalPage = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildFinalOption(
                  icon: Icons.home,
                  label: 'Retour a l\'accueil',
                  subtitle: 'Revenir au manege des sources',
                  onTap: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}

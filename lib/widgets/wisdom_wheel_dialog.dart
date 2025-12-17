// lib/widgets/wisdom_wheel_dialog.dart
// 4 ROUES DES SAGESSES en carre 2x2 - Style astrolabe bleu/or
// VERSION CORRIGEE : 
// - Possibilite de decocher une sagesse selectionnee
// - Validation de 1 a 3 sagesses (pas obligatoire d'en avoir 4)
// - Retour au menu principal apres fermeture

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class WheelSource {
  final String id;
  final String name;
  final String iconPath;
  
  const WheelSource({required this.id, required this.name, required this.iconPath});
}

class WisdomWheelDialog extends StatefulWidget {
  const WisdomWheelDialog({super.key});

  static Future<List<String>?> show(BuildContext context) {
    return showGeneralDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const WisdomWheelDialog(),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<WisdomWheelDialog> createState() => _WisdomWheelDialogState();
}

class _WisdomWheelDialogState extends State<WisdomWheelDialog> with TickerProviderStateMixin {
  late List<AnimationController> _spinControllers;
  late AnimationController _pulseController;
  
  final List<double> _currentAngles = [0, 0, 0, 0];
  final List<bool> _isSpinning = [false, false, false, false];
  final List<WheelSource?> _selectedSources = [null, null, null, null];
  
  // NOUVEAU: Limite de sagesses (1 a 4)
  static const int _maxSagesses = 4;
  
  static const _categoryNames = ['Litterature', 'Psychologie', 'Philosophes', 'Ecoles Philo.'];
  static const _categoryEmojis = ['📚', '🧠', '👤', '🏛️'];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCES - IDs correspondent aux keys de approach_config.dart
  // ═══════════════════════════════════════════════════════════════════════════
  
  final List<List<WheelSource>> _allSources = [
    // ROUE 0 - COURANTS LITTERAIRES
    [
      WheelSource(id: 'humanisme', name: 'Humanisme', iconPath: 'assets/univers_visuel/humanisme.png'),
      WheelSource(id: 'romantisme', name: 'Romantisme', iconPath: 'assets/univers_visuel/romantisme.png'),
      WheelSource(id: 'realisme', name: 'Realisme', iconPath: 'assets/univers_visuel/realisme.png'),
      WheelSource(id: 'existentialisme', name: 'Existentialisme', iconPath: 'assets/univers_visuel/existentialisme.png'),
      WheelSource(id: 'absurdisme', name: 'Absurdisme', iconPath: 'assets/univers_visuel/absurdisme.png'),
      WheelSource(id: 'poetique', name: 'Poetique', iconPath: 'assets/univers_visuel/poesie.png'),
      WheelSource(id: 'mystique', name: 'Mystique', iconPath: 'assets/univers_visuel/mystique.png'),
      WheelSource(id: 'symboliste_moderne', name: 'Symbolisme', iconPath: 'assets/univers_visuel/symbolisme.png'),
    ],
    
    // ROUE 1 - APPROCHES PSYCHOLOGIQUES
    [
      WheelSource(id: 'jungienne', name: 'Jungienne', iconPath: 'assets/univers_visuel/jungienne.png'),
      WheelSource(id: 'tcc', name: 'TCC', iconPath: 'assets/univers_visuel/TCC.png'),
      WheelSource(id: 'logotherapie', name: 'Logotherapie', iconPath: 'assets/univers_visuel/logotherapie_frankl.png'),
      WheelSource(id: 'act', name: 'ACT', iconPath: 'assets/univers_visuel/pleine_conscience.png'),
      WheelSource(id: 'the_work', name: 'The Work', iconPath: 'assets/univers_visuel/theworkkb.png'),
      WheelSource(id: 'schemas_young', name: 'Schemas', iconPath: 'assets/univers_visuel/schemas_young.png'),
      WheelSource(id: 'humaniste_rogers', name: 'Humaniste', iconPath: 'assets/univers_visuel/humanisme_philo.png'),
    ],
    
    // ROUE 2 - PHILOSOPHES
    [
      WheelSource(id: 'socrate', name: 'Socrate', iconPath: 'assets/univers_visuel/socrate.png'),
      WheelSource(id: 'platon', name: 'Platon', iconPath: 'assets/univers_visuel/platon.png'),
      WheelSource(id: 'aristote', name: 'Aristote', iconPath: 'assets/univers_visuel/aristote.png'),
      WheelSource(id: 'epictete', name: 'Epictete', iconPath: 'assets/univers_visuel/epictete.png'),
      WheelSource(id: 'marc_aurele', name: 'Marc Aurele', iconPath: 'assets/univers_visuel/marc_aurele.png'),
      WheelSource(id: 'spinoza', name: 'Spinoza', iconPath: 'assets/univers_visuel/spinoza.png'),
      WheelSource(id: 'kant', name: 'Kant', iconPath: 'assets/univers_visuel/kant.png'),
      WheelSource(id: 'nietzsche', name: 'Nietzsche', iconPath: 'assets/univers_visuel/nietzsche.png'),
      WheelSource(id: 'camus', name: 'Camus', iconPath: 'assets/univers_visuel/camus.png'),
      WheelSource(id: 'sartre', name: 'Sartre', iconPath: 'assets/univers_visuel/sartre.png'),
      WheelSource(id: 'confucius', name: 'Confucius', iconPath: 'assets/univers_visuel/confucius.png'),
    ],
    
    // ROUE 3 - ECOLES PHILOSOPHIQUES
    [
      WheelSource(id: 'stoicisme_philo', name: 'Stoicisme', iconPath: 'assets/univers_visuel/stoicisme.png'),
      WheelSource(id: 'epicurisme', name: 'Epicurisme', iconPath: 'assets/univers_visuel/epicurisme.png'),
      WheelSource(id: 'existentialisme_philo', name: 'Existentialisme', iconPath: 'assets/univers_visuel/existentialisme.png'),
      WheelSource(id: 'humanisme_philo', name: 'Humanisme', iconPath: 'assets/univers_visuel/humanisme.png'),
      WheelSource(id: 'vitalisme', name: 'Vitalisme', iconPath: 'assets/univers_visuel/vitalisme.png'),
      WheelSource(id: 'absurdisme_philo', name: 'Absurdisme', iconPath: 'assets/univers_visuel/absurdisme.png'),
      WheelSource(id: 'rationalisme', name: 'Rationalisme', iconPath: 'assets/univers_visuel/rationalisme.png'),
      WheelSource(id: 'empirisme', name: 'Empirisme', iconPath: 'assets/univers_visuel/empirisme.png'),
      WheelSource(id: 'pragmatisme', name: 'Pragmatisme', iconPath: 'assets/univers_visuel/pragmatisme.png'),
      WheelSource(id: 'phenomenologie', name: 'Phenomenologie', iconPath: 'assets/univers_visuel/phenomenologie.png'),
      WheelSource(id: 'idealisme', name: 'Idealisme', iconPath: 'assets/univers_visuel/idealisme.png'),
      WheelSource(id: 'utilitarisme', name: 'Utilitarisme', iconPath: 'assets/univers_visuel/utilitarisme.png'),
      WheelSource(id: 'structuralisme', name: 'Structuralisme', iconPath: 'assets/univers_visuel/structuralisme.png'),
      WheelSource(id: 'philosophies_orientales', name: 'Orient', iconPath: 'assets/univers_visuel/zen.png'),
    ],
  ];

  @override
  void initState() {
    super.initState();
    
    _spinControllers = List.generate(4, (i) => AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    ));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    for (final c in _spinControllers) c.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Compte le nombre de sagesses selectionnees
  int get _selectionCount => _selectedSources.where((s) => s != null).length;

  /// Verifie si on peut encore selectionner
  bool get _canSelectMore => _selectionCount < _maxSagesses;

  void _spinWheel(int index) {
    if (_isSpinning[index]) return;
    
    // NOUVEAU: Verifier si on peut encore selectionner (sauf si on va decocher)
    if (_selectedSources[index] == null && !_canSelectMore) {
      _showMaxSelectionMessage();
      return;
    }
    
    final sources = _allSources[index];
    final random = math.Random();
    
    final spins = 3 + random.nextInt(3);
    final targetIndex = random.nextInt(sources.length);
    final anglePerSegment = (2 * math.pi) / sources.length;
    final targetAngle = spins * 2 * math.pi + targetIndex * anglePerSegment;
    
    setState(() {
      _isSpinning[index] = true;
      _selectedSources[index] = null;
    });
    
    _spinControllers[index].reset();
    
    final animation = Tween<double>(
      begin: _currentAngles[index],
      end: _currentAngles[index] + targetAngle,
    ).animate(CurvedAnimation(
      parent: _spinControllers[index],
      curve: Curves.easeOutCubic,
    ));
    
    animation.addListener(() {
      setState(() => _currentAngles[index] = animation.value);
    });
    
    _spinControllers[index].forward().then((_) {
      setState(() {
        _isSpinning[index] = false;
        _selectedSources[index] = sources[targetIndex];
      });
    });
  }

  /// NOUVEAU: Decocher une sagesse selectionnee
  void _deselectSource(int index) {
    if (_selectedSources[index] != null) {
      setState(() {
        _selectedSources[index] = null;
      });
    }
  }

  /// NOUVEAU: Message quand max atteint
  void _showMaxSelectionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Maximum $_maxSagesses sagesses. Decochez-en une pour en choisir une autre.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF2E8B7B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width * 0.94,
          height: size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F4F8), Color(0xFFD8EEF5), Color(0xFFD0E8F0)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E8B7B).withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E8B7B).withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildWheelsGrid()),
                _buildSelectedSummary(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF2E8B7B).withOpacity(0.2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF2E8B7B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roues des Sagesses',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E8B7B),
                  ),
                ),
                // NOUVEAU: Indicateur de selection
                Text(
                  'Selectionnez 1 a $_maxSagesses sagesses',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF5A8A8A),
                  ),
                ),
              ],
            ),
          ),
          // Badge de comptage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _selectionCount > 0 
                  ? const Color(0xFF2E8B7B) 
                  : const Color(0xFF5A8A8A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_selectionCount/$_maxSagesses',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A3A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Color(0xFF5A8A8A), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelsGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildWheelCard(0)),
                const SizedBox(width: 6),
                Expanded(child: _buildWheelCard(1)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildWheelCard(2)),
                const SizedBox(width: 6),
                Expanded(child: _buildWheelCard(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelCard(int index) {
    final sources = _allSources[index];
    final selected = _selectedSources[index];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null 
              ? const Color(0xFF2E8B7B).withOpacity(0.6) 
              : const Color(0xFF5BA3A8).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFF2E8B7B).withOpacity(0.15))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_categoryEmojis[index], style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  _categoryNames[index],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E8B7B),
                  ),
                ),
                Text(
                  ' (${sources.length})',
                  style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF5A8A8A)),
                ),
              ],
            ),
          ),
          
          // Roue avec indicateur
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableSize = math.min(constraints.maxWidth, constraints.maxHeight);
                final wheelSize = availableSize - 16;
                
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _currentAngles[index],
                      child: CustomPaint(
                        size: Size(wheelSize, wheelSize),
                        painter: MiniWheelPainter(sources: sources),
                        child: _buildMiniWheelContent(sources, wheelSize),
                      ),
                    ),
                    Positioned(
                      top: (constraints.maxHeight - wheelSize) / 2 - 8,
                      child: CustomPaint(
                        size: const Size(12, 7),
                        painter: SmallIndicatorPainter(),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _spinWheel(index),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final scale = _isSpinning[index] ? 1.0 : 1.0 + _pulseController.value * 0.05;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: wheelSize * 0.24,
                              height: wheelSize * 0.24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Color(0xFF2A4A7A), Color(0xFF1E3A5F)],
                                ),
                                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isSpinning[index]
                                    ? SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: const Color(0xFFD4AF37).withOpacity(0.7),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.touch_app,
                                        color: Color(0xFFD4AF37),
                                        size: 12,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // RESULTAT AVEC BOUTON DECOCHER
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected != null 
                  ? const Color(0xFF2E8B7B).withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: selected != null
                ? Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E8B7B).withOpacity(0.2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            selected.iconPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF2E8B7B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          selected.name,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E8B7B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // NOUVEAU: Bouton pour decocher
                      GestureDetector(
                        onTap: () => _deselectSource(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      _canSelectMore ? 'Tourne la roue' : 'Max atteint',
                      style: GoogleFonts.inter(
                        fontSize: 8, 
                        color: _canSelectMore 
                            ? const Color(0xFF5A8A8A) 
                            : Colors.orange,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// NOUVEAU: Resume des selections
  Widget _buildSelectedSummary() {
    final selectedIds = _selectedSources.whereType<WheelSource>().toList();
    
    if (selectedIds.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B7B).withOpacity(0.05),
        border: Border(
          top: BorderSide(color: const Color(0xFF2E8B7B).withOpacity(0.15)),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: selectedIds.map((source) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B7B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  source.name,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2E8B7B),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    final index = _selectedSources.indexOf(source);
                    if (index != -1) _deselectSource(index);
                  },
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Color(0xFF5A8A8A),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniWheelContent(List<WheelSource> sources, double size) {
    final count = sources.length;
    final anglePerSegment = (2 * math.pi) / count;
    final radius = size * (count > 10 ? 0.35 : 0.32);
    final iconSize = count > 10 ? 18.0 : 20.0;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(count, (i) {
          final angle = i * anglePerSegment + anglePerSegment / 2 - math.pi / 2;
          final x = radius * math.cos(angle);
          final y = radius * math.sin(angle);
          
          return Transform.translate(
            offset: Offset(x, y),
            child: Transform.rotate(
              angle: angle + math.pi / 2,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    sources[i].iconPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome, size: iconSize * 0.6, color: Colors.amber[700]),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter() {
    final hasSelection = _selectedSources.any((s) => s != null);
    final selectedIds = _selectedSources.whereType<WheelSource>().map((s) => s.id).toList();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFF2E8B7B).withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              icon: Image.asset(
                'assets/univers_visuel/menu_principal.png',
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => const Icon(Icons.home, size: 14),
              ),
              label: Text('Menu', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5A8A8A))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF5A8A8A).withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedIds),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B7B),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Utiliser ${selectedIds.length} sagesse${selectedIds.length > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MiniWheelPainter extends CustomPainter {
  final List<WheelSource> sources;
  MiniWheelPainter({required this.sources});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFD4AF37),
          const Color(0xFFF4D47C),
          const Color(0xFFD4AF37),
          const Color(0xFFB8962E),
          const Color(0xFFD4AF37),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    
    canvas.drawCircle(center, radius - 2.5, borderPaint);
    
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF2A4A7A), const Color(0xFF1E3A5F), const Color(0xFF152A45)],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 5));
    
    canvas.drawCircle(center, radius - 5, bgPaint);
    
    final concentricPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    
    canvas.drawCircle(center, radius * 0.7, concentricPaint);
    canvas.drawCircle(center, radius * 0.5, concentricPaint);
    
    final count = sources.length;
    final anglePerSegment = (2 * math.pi) / count;
    
    final rayPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    for (int i = 0; i < count; i++) {
      final angle = i * anglePerSegment - math.pi / 2;
      final outerPoint = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + radius * 0.2 * math.cos(angle),
        center.dy + radius * 0.2 * math.sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, rayPaint);
    }
    
    final dotPaint = Paint()..color = const Color(0xFFD4AF37);
    for (int i = 0; i < 12; i++) {
      final angle = i * (2 * math.pi / 12);
      final dotCenter = Offset(
        center.dx + (radius - 2.5) * math.cos(angle),
        center.dy + (radius - 2.5) * math.sin(angle),
      );
      canvas.drawCircle(dotCenter, 1.2, dotPaint);
    }
    
    _drawStars(canvas, center, radius);
  }

  void _drawStars(Canvas canvas, Offset center, double radius) {
    final starPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    final rand = math.Random(42);
    for (int i = 0; i < 6; i++) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final dist = radius * 0.55 + rand.nextDouble() * radius * 0.15;
      final starCenter = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );
      _drawStar(canvas, starCenter, 2 + rand.nextDouble(), starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerX = center.dx + size * math.cos(angle);
      final outerY = center.dy + size * math.sin(angle);
      if (i == 0) path.moveTo(outerX, outerY);
      else path.lineTo(outerX, outerY);
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + size * 0.3 * math.cos(innerAngle);
      final innerY = center.dy + size * 0.3 * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SmallIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF4D47C), Color(0xFFD4AF37), Color(0xFFB8962E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

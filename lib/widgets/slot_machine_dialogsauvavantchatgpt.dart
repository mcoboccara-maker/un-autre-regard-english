// lib/widgets/slot_machine_dialog.dart
// Machine à sous pour sélection aléatoire des sources
// Version corrigée - bug de rotation fixé
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class SlotMachineDialog extends StatefulWidget {
  const SlotMachineDialog({super.key});

  static Future<List<String>?> show(BuildContext context) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SlotMachineDialog(),
    );
  }

  @override
  State<SlotMachineDialog> createState() => _SlotMachineDialogState();
}

class _SlotMachineDialogState extends State<SlotMachineDialog>
    with TickerProviderStateMixin {
  
  // Roue 1 - Philosophie/Philosophes
  static const List<SlotItem> wheel1Items = [
    SlotItem('Stoïcisme', 'stoicisme.png'),
    SlotItem('Épicurisme', 'epicurisme.png'),
    SlotItem('Existentialisme', 'existentialisme.png'),
    SlotItem('Cynisme', 'cynisme.png'),
    SlotItem('Marc Aurèle', 'marc_aurele.png'),
    SlotItem('Épictète', 'epictete.png'),
    SlotItem('Sénèque', 'seneque.png'),
    SlotItem('Nietzsche', 'nietzsche.png'),
    SlotItem('Camus', 'camus.png'),
    SlotItem('Sartre', 'sartre.png'),
    SlotItem('Platon', 'platon.png'),
    SlotItem('Aristote', 'aristote.png'),
  ];

  // Roue 2 - Psychologie
  static const List<SlotItem> wheel2Items = [
    SlotItem('TCC', 'TCC.png'),
    SlotItem('Logothérapie', 'logotherapie_frankl.png'),
    SlotItem('Schémas Young', 'schemas_young.png'),
    SlotItem('Jungienne', 'jungienne.png'),
    SlotItem('Pleine Conscience', 'pleine_conscience.png'),
    SlotItem('The Work', 'theworkkb.png'),
  ];

  // Roue 3 - Littérature (avec les bons noms de fichiers)
  static const List<SlotItem> wheel3Items = [
    SlotItem('Poésie', 'poesie.png'),
    SlotItem('Romantisme', 'romantisme.png'),
    SlotItem('Réalisme', 'realisme.png'),
    SlotItem('Symbolisme', 'symbolisme.png'),
    SlotItem('Modernisme', 'modernisme.png'),
    SlotItem('Tragédie', 'tragedie_classique.png'),
  ];

  // Animation glow
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool _isSpinning = false;
  bool _hasSpun = false;
  
  // Clé pour forcer reconstruction des roues
  int _rebuildKey = 0;
  
  int _target1 = 0;
  int _target2 = 0;
  int _target3 = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    // Générer nouvelles cibles
    _target1 = _random.nextInt(wheel1Items.length);
    _target2 = _random.nextInt(wheel2Items.length);
    _target3 = _random.nextInt(wheel3Items.length);

    // Incrémenter la clé pour forcer reconstruction des roues
    setState(() {
      _rebuildKey++;
      _isSpinning = true;
      _hasSpun = false;
    });

    // Attendre fin des animations
    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      setState(() {
        _isSpinning = false;
        _hasSpun = true;
      });
    }
  }

  List<String> _getSelectedSources() {
    return [
      wheel1Items[_target1].name,
      wheel2Items[_target2].name,
      wheel3Items[_target3].name,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 380,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Fond bleu clair marbré
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA),  // Cyan très clair
                  Color(0xFFB2EBF2),  // Cyan clair
                  Color(0xFF80DEEA),  // Cyan
                  Color(0xFFB2DFDB),  // Teal très clair
                  Color(0xFFE0F2F1),  // Teal clair
                  Color(0xFFE8F5E9),  // Vert très clair
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.amber.withOpacity(_glowAnimation.value),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildWheels(),
                const SizedBox(height: 20),
                _buildButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.blueGrey[700], size: 20),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber[700], size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Laissez le hasard vous inspirer !',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome, color: Colors.amber[700], size: 24),
          ],
        ),
      ],
    );
  }

  Widget _buildWheels() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 2),
      ),
      child: Stack(
        children: [
          // Les 3 roues - clé unique pour forcer reconstruction
          Row(
            key: ValueKey('wheels_$_rebuildKey'),
            children: [
              Expanded(
                child: _SpinningWheel(
                  items: wheel1Items,
                  label: 'Philosophie',
                  color: const Color(0xFF7C4DFF),
                  targetIndex: _target1,
                  isSpinning: _isSpinning,
                  delayMs: 0,
                  durationMs: 2000,
                ),
              ),
              _buildSeparator(),
              Expanded(
                child: _SpinningWheel(
                  items: wheel2Items,
                  label: 'Psychologie',
                  color: const Color(0xFF00BCD4),
                  targetIndex: _target2,
                  isSpinning: _isSpinning,
                  delayMs: 150,
                  durationMs: 2400,
                ),
              ),
              _buildSeparator(),
              Expanded(
                child: _SpinningWheel(
                  items: wheel3Items,
                  label: 'Littérature',
                  color: const Color(0xFF4CAF50),
                  targetIndex: _target3,
                  isSpinning: _isSpinning,
                  delayMs: 300,
                  durationMs: 2800,
                ),
              ),
            ],
          ),
          // Ligne de sélection centrale
          Positioned(
            top: 95,
            left: 8,
            right: 8,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.amber.withOpacity(0.9), width: 2),
                  bottom: BorderSide(color: Colors.amber.withOpacity(0.9), width: 2),
                ),
                color: Colors.amber.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 30),
      color: Colors.amber.withOpacity(0.5),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSpinning ? null : _spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF1a237e),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSpinning)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1a237e)),
                  )
                else
                  const Icon(Icons.casino, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isSpinning ? 'Les roues tournent...' : '🎰 LANCER !',
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        
        if (_hasSpun) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  '✨ Sources sélectionnées :',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey[700]),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildChip(wheel1Items[_target1].name, const Color(0xFF7C4DFF)),
                    _buildChip(wheel2Items[_target2].name, const Color(0xFF00838F)),
                    _buildChip(wheel3Items[_target3].name, const Color(0xFF2E7D32)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _getSelectedSources()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Utiliser ces sources',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Widget séparé pour chaque roue - gère son propre controller
class _SpinningWheel extends StatefulWidget {
  final List<SlotItem> items;
  final String label;
  final Color color;
  final int targetIndex;
  final bool isSpinning;
  final int delayMs;
  final int durationMs;

  const _SpinningWheel({
    required this.items,
    required this.label,
    required this.color,
    required this.targetIndex,
    required this.isSpinning,
    required this.delayMs,
    required this.durationMs,
  });

  @override
  State<_SpinningWheel> createState() => _SpinningWheelState();
}

class _SpinningWheelState extends State<_SpinningWheel> {
  late FixedExtentScrollController _controller;
  bool _hasStartedSpin = false;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: 0);
    
    // Si on doit spinner, lancer l'animation après le délai
    if (widget.isSpinning) {
      _startSpin();
    }
  }

  Future<void> _startSpin() async {
    if (_hasStartedSpin) return;
    _hasStartedSpin = true;
    
    await Future.delayed(Duration(milliseconds: widget.delayMs));
    
    if (mounted) {
      final spins = widget.items.length * 4 + widget.targetIndex;
      _controller.animateToItem(
        spins,
        duration: Duration(milliseconds: widget.durationMs),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Roue
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 40,
            perspective: 0.004,
            diameterRatio: 1.4,
            physics: widget.isSpinning
                ? const NeverScrollableScrollPhysics()
                : const FixedExtentScrollPhysics(),
            childDelegate: ListWheelChildLoopingListDelegate(
              children: widget.items.map((item) => _buildItem(item)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(SlotItem item) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/univers_visuel/${item.icon}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.amber.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        item.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class SlotItem {
  final String name;
  final String icon;

  const SlotItem(this.name, this.icon);
}

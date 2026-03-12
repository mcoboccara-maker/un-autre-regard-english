// lib/widgets/slot_machine_dialog.dart
// Machine à inspirations - Mécanisme analogique doux

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlotItem {
  final String label;
  final String asset;
  const SlotItem(this.label, this.asset);
}

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
  late final FixedExtentScrollController _ctrl1;
  late final FixedExtentScrollController _ctrl2;
  late final FixedExtentScrollController _ctrl3;

  late final AnimationController _pressController;
  late final Animation<double> _pressAnim;

  bool _isSpinning = false;
  final Random _random = Random();

  static const List<SlotItem> wheel1Items = [
    SlotItem('Judaism', 'judaisme.png'),
    SlotItem('Mussar', 'moussar.png'),
    SlotItem('Theravāda', 'theravada.png'),
    SlotItem('Zen', 'zen.png'),
    SlotItem('Advaita Vedānta', 'advaita_vedanta.png'),
    SlotItem('Bhakti', 'bhakti.png'),
    SlotItem('Sufism', 'soufisme.png'),
  ];

  static const List<SlotItem> wheel2Items = [
    SlotItem('Ancient Phil.', 'philo_antique.png'),
    SlotItem('Modern Phil.', 'philo_moderne.png'),
    SlotItem('Psychology', 'psychologie.png'),
    SlotItem('Jungian', 'jungienne.png'),
    SlotItem('Mindfulness', 'pleine_conscience.png'),
    SlotItem('The Work', 'theworkkb.png'),
  ];

  static const List<SlotItem> wheel3Items = [
    SlotItem('Poetry', 'poesie.png'),
    SlotItem('Romanticism', 'romantisme.png'),
    SlotItem('Realism', 'realisme.png'),
    SlotItem('Symbolism', 'symbolisme.png'),
    SlotItem('Sacred Texts', 'textes_sacres.png'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl1 = FixedExtentScrollController();
    _ctrl2 = FixedExtentScrollController();
    _ctrl3 = FixedExtentScrollController();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pressAnim =
        CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;
    setState(() => _isSpinning = true);

    await _pressController.forward();
    await _pressController.reverse();

    final target1 = _random.nextInt(wheel1Items.length) + 30;
    final target2 = _random.nextInt(wheel2Items.length) + 40;
    final target3 = _random.nextInt(wheel3Items.length) + 50;

    Future<void> animateWheel(
      FixedExtentScrollController ctrl,
      int target,
      Duration duration,
    ) {
      return ctrl.animateToItem(
        target,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }

    await Future.wait([
      animateWheel(_ctrl1, target1, const Duration(milliseconds: 900)),
      Future.delayed(const Duration(milliseconds: 140), () {
        return animateWheel(
            _ctrl2, target2, const Duration(milliseconds: 1100));
      }),
      Future.delayed(const Duration(milliseconds: 280), () {
        return animateWheel(
            _ctrl3, target3, const Duration(milliseconds: 1250));
      }),
    ]);

    final pick1 = wheel1Items[target1 % wheel1Items.length].label;
    final pick2 = wheel2Items[target2 % wheel2Items.length].label;
    final pick3 = wheel3Items[target3 % wheel3Items.length].label;

    if (!mounted) return;

    setState(() => _isSpinning = false);

    Navigator.of(context).pop(<String>[pick1, pick2, pick3]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isSpinning) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.65),
        body: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.97).animate(_pressAnim),
            child: _buildMachine(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMachine(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(18, 22, 22, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF272935),
              Color(0xFF171823),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF444857),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inspiration Machine',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Let a combination come to you.',
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            _buildReels(),
            const SizedBox(height: 14),
            _buildHandleAndActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildReels() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3C3F4E),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bande lumineuse sur la ligne centrale
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.white.withOpacity(0.09),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildWheel(wheel1Items, _ctrl1)),
              const SizedBox(width: 8),
              Expanded(child: _buildWheel(wheel2Items, _ctrl2)),
              const SizedBox(width: 8),
              Expanded(child: _buildWheel(wheel3Items, _ctrl3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(List<SlotItem> items, FixedExtentScrollController ctrl) {
    final extended = List.generate(80, (index) => items[index % items.length]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.25, 0.75, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListWheelScrollView.useDelegate(
          controller: ctrl,
          physics: const NeverScrollableScrollPhysics(),
          itemExtent: 32,
          perspective: 0.003,
          overAndUnderCenterOpacity: 0.25,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= extended.length) return null;
              final item = extended[index];
              return _WheelCell(item: item);
            },
            childCount: extended.length,
          ),
        ),
      ),
    );
  }

  Widget _buildHandleAndActions() {
    return Row(
      children: [
        // Bouton principal
        Expanded(
          child: ElevatedButton(
            onPressed: _isSpinning ? null : _spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE4C184),
              foregroundColor: const Color(0xFF3D301F),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              _isSpinning ? 'Spinning…' : 'Pull the lever',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Petit levier décoratif
        SizedBox(
          width: 42,
          height: 60,
          child: CustomPaint(
            painter: _LeverPainter(isSpinning: _isSpinning),
          ),
        ),
      ],
    );
  }
}

class _WheelCell extends StatelessWidget {
  final SlotItem item;
  const _WheelCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Si tu as des icônes, tu peux les afficher ici avec Image.asset(item.asset)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.10),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeverPainter extends CustomPainter {
  final bool isSpinning;
  const _LeverPainter({required this.isSpinning});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final bottomY = size.height * 0.95;

    // Tige
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF616574),
          Color(0xFF2D303D),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, bottomY),
      Offset(centerX, size.height * 0.18),
      stemPaint,
    );

    // Boule
    final ballCenter = Offset(centerX, size.height * 0.12);
    final ballPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF2D7A4),
          Color(0xFFC69355),
        ],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: 11));

    canvas.drawCircle(ballCenter, 11, ballPaint);

    // Indicateur "en cours"
    if (isSpinning) {
      final glowPaint = Paint()
        ..color = const Color(0xFFF8E2B8).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(ballCenter, 14, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeverPainter oldDelegate) {
    return oldDelegate.isSpinning != isSpinning;
  }
}

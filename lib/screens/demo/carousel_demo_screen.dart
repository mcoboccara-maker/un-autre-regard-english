import 'package:flutter/material.dart';
import '../../widgets/carousel_3d/carousel_3d.dart';

/// Écran de démonstration du composant CardCarousel3D
class CarouselDemoScreen extends StatefulWidget {
  const CarouselDemoScreen({super.key});

  @override
  State<CarouselDemoScreen> createState() => _CarouselDemoScreenState();
}

class _CarouselDemoScreenState extends State<CarouselDemoScreen> {
  CarouselMode _currentMode = CarouselMode.face;
  final Carousel3DController _controller = Carousel3DController();

  // Couleurs de test pour les cartes
  static const List<Color> _cardColors = [
    Color(0xFF4A90A4),  // Bleu-vert
    Color(0xFF6B8E7B),  // Vert sauge
    Color(0xFF9B7B6B),  // Terre
    Color(0xFF8B6B8B),  // Mauve
    Color(0xFF7B8B6B),  // Olive
  ];

  List<CarouselCardData> _buildMenuCards() {
    final menuItems = [
      ('Pensée', Icons.edit_note_rounded),
      ('Émotion', Icons.favorite_rounded),
      ('Sources', Icons.auto_stories_rounded),
      ('Profil', Icons.person_rounded),
      ('Historique', Icons.history_rounded),
    ];

    return List.generate(menuItems.length, (index) {
      final item = menuItems[index];
      return CarouselCardData(
        id: 'menu_$index',
        backgroundColor: _cardColors[index],
        label: item.$1,
        child: _buildMenuCardContent(item.$1, item.$2, _cardColors[index]),
      );
    });
  }

  Widget _buildMenuCardContent(String title, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap pour explorer',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<CarouselCardData> _buildEmotionCards() {
    // 18 émotions du CDC
    final emotions = [
      ('Joie', Color(0xFFFFD700)),
      ('Tristesse', Color(0xFF4169E1)),
      ('Colère', Color(0xFFDC143C)),
      ('Peur', Color(0xFF2F4F4F)),
      ('Surprise', Color(0xFFFF69B4)),
      ('Dégoût', Color(0xFF556B2F)),
      ('Confiance', Color(0xFF20B2AA)),
      ('Anticipation', Color(0xFFFF8C00)),
      ('Sérénité', Color(0xFF87CEEB)),
      ('Acceptation', Color(0xFF98FB98)),
      ('Appréhension', Color(0xFF708090)),
      ('Distraction', Color(0xFFDDA0DD)),
      ('Ennui', Color(0xFFD2B48C)),
      ('Contrariété', Color(0xFFCD5C5C)),
      ('Intérêt', Color(0xFF9370DB)),
      ('Admiration', Color(0xFFFFB6C1)),
      ('Terreur', Color(0xFF191970)),
      ('Extase', Color(0xFFFFD700)),
    ];

    return List.generate(emotions.length, (index) {
      final emotion = emotions[index];
      return CarouselCardData(
        id: 'emotion_$index',
        backgroundColor: emotion.$2,
        label: emotion.$1,
        child: Center(
          child: Text(
            emotion.$1,
            style: TextStyle(
              color: _getContrastColor(emotion.$2),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final cards = _currentMode == CarouselMode.face
        ? _buildMenuCards()
        : _buildEmotionCards();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Démo Manège 3D - Mode ${_currentMode.name.toUpperCase()}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _currentMode == CarouselMode.face
                  ? Icons.view_carousel
                  : Icons.view_agenda,
            ),
            onPressed: () {
              setState(() {
                _currentMode = _currentMode == CarouselMode.face
                    ? CarouselMode.spine
                    : CarouselMode.face;
              });
            },
            tooltip: 'Changer de mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeChip('Face', CarouselMode.face),
                const SizedBox(width: 16),
                _buildModeChip('Spine', CarouselMode.spine),
              ],
            ),
          ),

          // Carousel
          Expanded(
            child: CardCarousel3D(
              key: ValueKey(_currentMode),
              cards: cards,
              mode: _currentMode,
              controller: _controller,
              enableSwipeActions: _currentMode == CarouselMode.face,
              cardHeight: _currentMode == CarouselMode.face ? 400 : 300,
              cardWidth: _currentMode == CarouselMode.face ? 280 : 200,
              angleSpacing: _currentMode == CarouselMode.face ? 35 : 20,
              onCardTap: (index, card) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tap sur: ${card.label ?? card.id}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              onCardSwipe: (index, card, direction) {
                final action = direction == SwipeDirection.right
                    ? 'Sauvegardé'
                    : 'Rejeté';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$action: ${card.label ?? card.id}'),
                    backgroundColor: direction == SwipeDirection.right
                        ? Colors.green
                        : Colors.red,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              onCardChanged: (index) {
                debugPrint('Carte active: $index');
              },
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _controller.previous(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Précédent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _controller.next(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Suivant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, CarouselMode mode) {
    final isActive = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A90A4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF4A90A4) : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

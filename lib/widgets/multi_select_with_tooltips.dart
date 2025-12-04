import 'package:flutter/material.dart';

// Classe pour les choix enrichis avec tooltips
class ProfileChoicesWithTooltips {
  static const List<Map<String, String>> religions = [
    {
      "label": "Judaïsme rabbinique",
      "tooltip": "Tradition fondée sur la Torah et le Talmud : une voie de responsabilité, de foi et d'éthique dans la vie quotidienne."
    },
    {
      "label": "Moussar (éthique juive)",
      "tooltip": "Démarche introspective du judaïsme axée sur la maîtrise de soi et le perfectionnement moral à travers l'observation des émotions et comportements."
    },
    {
      "label": "Kabbale",
      "tooltip": "Mystique juive qui explore les lois spirituelles cachées du monde et la réparation intérieure (tikkoun) comme chemin de lumière."
    },
    {
      "label": "Christianisme",
      "tooltip": "Voie centrée sur l'amour du prochain, la grâce et la transformation du cœur à l'image du Christ."
    },
    {
      "label": "Islam",
      "tooltip": "Foi dans l'unicité de Dieu et soumission consciente à Sa volonté, prônant équilibre, gratitude et patience."
    },
    {
      "label": "Soufisme",
      "tooltip": "Mystique de l'islam axée sur l'amour divin, la purification du cœur et l'union avec le Réel à travers la beauté et la compassion."
    },
    {
      "label": "Bouddhisme",
      "tooltip": "Voie de la libération de la souffrance par la pleine conscience, la sagesse et la compassion envers tous les êtres."
    },
    {
      "label": "Hindouisme",
      "tooltip": "Tradition spirituelle plurielle visant l'union avec le divin intérieur (ātman) par la connaissance, la dévotion ou l'action désintéressée."
    },
    {
      "label": "Stoïcisme",
      "tooltip": "Philosophie antique de la maîtrise de soi, de la lucidité et de l'acceptation sereine de ce qui ne dépend pas de nous."
    },
    {
      "label": "Spiritualité contemporaine / laïque",
      "tooltip": "Recherche de sens et de présence au-delà des dogmes, intégrant psychologie, art et conscience du vivant."
    }
  ];

  static const List<Map<String, String>> courantsLitteraires = [
    {
      "label": "Humaniste",
      "tooltip": "Courant valorisant la dignité humaine, la raison, la liberté et la quête de sens à travers l'expérience."
    },
    {
      "label": "Poétique",
      "tooltip": "Sensibilité à la beauté du langage et aux émotions profondes, révélant le monde intérieur et le sacré du quotidien."
    },
    {
      "label": "Réaliste",
      "tooltip": "Observation lucide de la vie telle qu'elle est, sans idéalisation, pour comprendre la vérité humaine."
    },
    {
      "label": "Mystique",
      "tooltip": "Littérature de la fusion avec le divin ou l'invisible, cherchant la communion entre l'âme et l'absolu."
    },
    {
      "label": "Existentialiste",
      "tooltip": "Exploration du sens de la vie, de la liberté et de la responsabilité de l'individu face à l'absurde."
    },
    {
      "label": "Romantique",
      "tooltip": "Exaltation de la passion, de la nature et de la subjectivité comme expression de l'âme."
    },
    {
      "label": "Symboliste / Moderne",
      "tooltip": "Recherche du sens caché derrière les apparences, langage suggestif et spirituel de l'invisible."
    }
  ];

  static const List<Map<String, String>> approchesPsychologiques = [
    {
      "label": "Logothérapie (Frankl)",
      "tooltip": "Approche centrée sur la quête de sens : chaque épreuve devient l'occasion d'une réponse libre et signifiante."
    },
    {
      "label": "Thérapie des Schémas (Young)",
      "tooltip": "Démarche pour identifier et transformer les schémas émotionnels précoces qui conditionnent nos réactions."
    },
    {
      "label": "Humaniste (Rogers)",
      "tooltip": "Vision bienveillante de l'être humain axée sur l'acceptation inconditionnelle et le développement du potentiel intérieur."
    },
    {
      "label": "The Work (Byron Katie)",
      "tooltip": "Méthode de questionnement des pensées stressantes pour revenir à la réalité et retrouver la paix intérieure."
    },
    {
      "label": "TCC (Cognitivo-Comportementale)",
      "tooltip": "Thérapie pratique fondée sur la modification des pensées et comportements limitants à travers des exercices concrets."
    },
    {
      "label": "Jungienne (symbolique, archétypes)",
      "tooltip": "Approche basée sur l'inconscient et les symboles universels (archétypes) comme chemins d'intégration et de transformation."
    }
  ];

  static const List<String> tonalites = [
    'Apaisant et sécurisant',
    'Réflexif et équilibré',
    'Orienté action douce',
    'Introspectif et inspirant',
    'Bienveillant et profond',
  ];
}

// Widget multi-sélecteur avec infobulles
class MultiSelectWithTooltips extends StatelessWidget {
  final String title;
  final List<Map<String, String>> allItems;
  final List<String> selectedItems;
  final Function(List<String>) onChanged;

  const MultiSelectWithTooltips({
    super.key,
    required this.title,
    required this.allItems,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allItems.map((item) {
            final label = item['label']!;
            final tooltip = item['tooltip']!;
            final isSelected = selectedItems.contains(label);
            
            return Tooltip(
              message: tooltip,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              showDuration: const Duration(seconds: 3),
              waitDuration: const Duration(milliseconds: 500),
              child: GestureDetector(
                onTap: () {
                  final newSelection = List<String>.from(selectedItems);
                  if (isSelected) {
                    newSelection.remove(label);
                  } else {
                    newSelection.add(label);
                  }
                  onChanged(newSelection);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purple[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.purple[400]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.purple[700] : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: isSelected ? Colors.purple[700] : Colors.grey[500],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

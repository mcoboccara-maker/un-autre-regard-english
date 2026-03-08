import 'package:flutter/material.dart';

// Classe pour les choix enrichis avec tooltips
class ProfileChoicesWithTooltips {
  static const List<Map<String, String>> religions = [
    {
      "label": "Rabbinic Judaism",
      "tooltip": "Tradition founded on the Torah and Talmud: a path of responsibility, faith, and ethics in daily life."
    },
    {
      "label": "Mussar (Jewish ethics)",
      "tooltip": "An introspective Jewish approach focused on self-mastery and moral refinement through observing emotions and behaviors."
    },
    {
      "label": "Kabbalah",
      "tooltip": "Jewish mysticism exploring the hidden spiritual laws of the world and inner repair (tikkun) as a path of light."
    },
    {
      "label": "Christianity",
      "tooltip": "A path centered on love of neighbor, grace, and the transformation of the heart in the image of Christ."
    },
    {
      "label": "Islam",
      "tooltip": "Faith in the oneness of God and conscious submission to His will, promoting balance, gratitude, and patience."
    },
    {
      "label": "Sufism",
      "tooltip": "Islamic mysticism focused on divine love, purification of the heart, and union with the Real through beauty and compassion."
    },
    {
      "label": "Buddhism",
      "tooltip": "A path of liberation from suffering through mindfulness, wisdom, and compassion toward all beings."
    },
    {
      "label": "Hinduism",
      "tooltip": "A pluralistic spiritual tradition aiming for union with the inner divine (atman) through knowledge, devotion, or selfless action."
    },
    {
      "label": "Stoicism",
      "tooltip": "Ancient philosophy of self-mastery, lucidity, and serene acceptance of what is beyond our control."
    },
    {
      "label": "Contemporary / secular spirituality",
      "tooltip": "Search for meaning and presence beyond dogma, integrating psychology, art, and awareness of the living."
    }
  ];

  static const List<Map<String, String>> courantsLitteraires = [
    {
      "label": "Humanist",
      "tooltip": "A movement valuing human dignity, reason, freedom, and the search for meaning through experience."
    },
    {
      "label": "Poetic",
      "tooltip": "Sensitivity to the beauty of language and deep emotions, revealing the inner world and the sacred in everyday life."
    },
    {
      "label": "Realist",
      "tooltip": "Clear-eyed observation of life as it is, without idealization, to understand human truth."
    },
    {
      "label": "Mystical",
      "tooltip": "Literature of fusion with the divine or invisible, seeking communion between the soul and the absolute."
    },
    {
      "label": "Existentialist",
      "tooltip": "Exploration of the meaning of life, freedom, and individual responsibility in the face of the absurd."
    },
    {
      "label": "Romantic",
      "tooltip": "Exaltation of passion, nature, and subjectivity as an expression of the soul."
    },
    {
      "label": "Symbolist / Modern",
      "tooltip": "Search for hidden meaning behind appearances, suggestive and spiritual language of the invisible."
    }
  ];

  static const List<Map<String, String>> approchesPsychologiques = [
    {
      "label": "Logotherapy (Frankl)",
      "tooltip": "An approach centered on the search for meaning: every challenge becomes an opportunity for a free and meaningful response."
    },
    {
      "label": "Schema Therapy (Young)",
      "tooltip": "A process to identify and transform early emotional schemas that condition our reactions."
    },
    {
      "label": "Humanistic (Rogers)",
      "tooltip": "A compassionate view of the human being focused on unconditional acceptance and the development of inner potential."
    },
    {
      "label": "The Work (Byron Katie)",
      "tooltip": "A method of questioning stressful thoughts to return to reality and find inner peace."
    },
    {
      "label": "CBT (Cognitive-Behavioral)",
      "tooltip": "A practical therapy based on modifying limiting thoughts and behaviors through concrete exercises."
    },
    {
      "label": "Jungian (symbolism, archetypes)",
      "tooltip": "An approach based on the unconscious and universal symbols (archetypes) as paths of integration and transformation."
    }
  ];

  static const List<String> tonalites = [
    'Soothing and reassuring',
    'Reflective and balanced',
    'Gently action-oriented',
    'Introspective and inspiring',
    'Compassionate and deep',
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

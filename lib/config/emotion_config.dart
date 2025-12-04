import 'package:flutter/material.dart';

class EmotionConfig {
  final String key;
  final String name;
  final String description;
  final List<String> nuances;
  final IconData icon;
  final Color color;
  final String iconPath; // ✅ Chemin vers l'icône PNG

  const EmotionConfig({
    required this.key,
    required this.name,
    required this.description,
    required this.nuances,
    required this.icon,
    required this.color,
    required this.iconPath,
  });
}

class EmotionCategories {
  // ========================================
  // 😔 ÉMOTIONS NÉGATIVES - QUESTION 3
  // "Comment réagissez-vous quand vous croyez cette pensée ?"
  // ========================================
  
  static const List<EmotionConfig> negativeEmotions = [
    // ❌ BLESSE
    EmotionConfig(
      key: 'BLESSE',
      name: 'Blessé',
      description: 'Douleur émotionnelle, souffrance',
      nuances: [
        'abusé',
        'affaibli',
        'affligé',
        'blessé',
        'démuni',
        'écrasé',
        'endolori',
        'horrifié',
        'humilié',
        'insulté',
        'le cœur brisé',
        'mis en défaut',
        'offensé',
        'rejeté',
        'souffrant',
        'torturé',
        'tourmenté',
      ],
      icon: Icons.healing,
      color: Color(0xFFBE185D),
      iconPath: 'assets/univers_visuel/blesse.png',
    ),

    // ❌ CONFUS
    EmotionConfig(
      key: 'CONFUS',
      name: 'Confus',
      description: 'Incertitude, doute, perplexité',
      nuances: [
        'dans la comparaison',
        'dans le doute',
        'déconcerté',
        'dédaigneux',
        'désorienté',
        'détraqué',
        'distrait',
        'embarrassé',
        'ergoteur',
        'exigeant',
        'hésitant',
        'incertain',
        'inconfortable',
        'indécis',
        'inquiet',
        'malhonnête',
        'maladroit',
        'manipulateur',
        'perdu',
        'perplexe',
        'peu sûr',
        'plein de préjugés',
        'rougissant',
        'stressé',
        'supérieur',
      ],
      icon: Icons.help_outline,
      color: Color(0xFFF59E0B),
      iconPath: 'assets/univers_visuel/confus.png',
    ),

    // ❌ CRITIQUE
    EmotionConfig(
      key: 'CRITIQUE',
      name: 'Critique',
      description: 'Jugement négatif, condamnation',
      nuances: [
        'attaquant',
        'autoritaire',
        'blessant',
        'borné',
        'combatif',
        'direct',
        'dur',
        'faux',
        'glacial',
        'grave',
        'grondeur',
        'guindé',
        'imposteur',
        'indélicat',
        'injuste',
        'langue de bois',
        'le regard furieux',
        'maniaque',
        'négligeant',
        'en recul',
        'renfrogné',
        'sermonneur',
        'sévère',
        'superficiel',
      ],
      icon: Icons.gavel,
      color: Color(0xFF374151),
      iconPath: 'assets/univers_visuel/critique.png',
    ),

    // ❌ DEPRIME
    EmotionConfig(
      key: 'DEPRIME',
      name: 'Déprimé',
      description: 'Tristesse, découragement, abattement',
      nuances: [
        'autocritique',
        'autodénigrement',
        'bon à rien',
        'boudeur',
        'chicanier',
        'coincé',
        'coupable',
        'crispé',
        'découragé',
        'déçu',
        'démobilisé',
        'démoralisé',
        'démotivé',
        'dénigrant de soi',
        'de mauvais poil',
        'déprimé',
        'désespéré',
        'diminué',
        'en enfer',
        'exclu',
        'exténué',
        'fermé',
        'haine de soi',
        'honteux',
        'impuissant',
        'instable',
        'mal',
        'masochiste',
        'mauvais',
        'mélancolique',
        'méprisable',
        'misérable',
        'morose',
        'négatif',
        'nul',
        'pessimiste',
        'punissant',
        'râleur',
        'réfractaire',
        'sans énergie',
        'sans entrain',
        'susceptible',
        'versatile',
      ],
      icon: Icons.sentiment_very_dissatisfied,
      color: Color(0xFF1E40AF),
      iconPath: 'assets/univers_visuel/triste.png',
    ),

    // ❌ EFFRAYE
    EmotionConfig(
      key: 'EFFRAYE',
      name: 'Effrayé',
      description: 'Peur, anxiété, terreur',
      nuances: [
        'agoraphobe',
        'anxieux',
        'apeuré',
        'bouleversé',
        'captif',
        'craintif',
        'égocentrique',
        'emprunté',
        'effrayé',
        'épouvanté',
        'évitant',
        'affolé',
        'importuné',
        'inhibé',
        'immobile',
        'intolérant',
        'intimidé',
        'lâche',
        'menacé',
        'méfiant',
        'nerveux',
        'offensif',
        'paniqué',
        'paranoïaque',
        'perturbé',
        'pétrifié',
        'phobique',
        'prudent',
        'rigide',
        'sans assurance',
        'soucieux',
        'sur la défensive',
        'tendu',
        'terrifié',
        'timide',
        'tremblant',
      ],
      icon: Icons.warning,
      color: Color(0xFF7C2D12),
      iconPath: 'assets/univers_visuel/effraye.png',
    ),

    // ❌ EN_COLERE
    EmotionConfig(
      key: 'EN_COLERE',
      name: 'En colère',
      description: 'Irritation, rage, frustration',
      nuances: [
        'abrupt',
        'accusateur',
        'agacé',
        'agressif',
        'amer',
        'antagoniste',
        'contrarié',
        'contraignant',
        'critique',
        'dégoûté',
        'désagréable',
        'directif',
        'dominateur',
        'effervescent',
        'enragé',
        'envieux',
        'exaspéré',
        'exubérant',
        'fâché',
        'fou',
        'frustré',
        'furieux',
        'grossier',
        'haineux',
        'hostile',
        'hurlant',
        'impatient',
        'impétueux',
        'injurieux',
        'insultant',
        'irrespectueux',
        'irritable',
        'irrité',
        'jaloux',
        'malicieux',
        'malveillant',
        'méchant',
        'méprisant',
        'obstiné',
        'outré',
        'pernicieux',
        'plein de ressentiment',
        'provocant',
        'querelleur',
        'rancunier',
        'réactif',
        'rebelle',
        'reprochant',
        'ripostant',
        'sadique',
        'sarcastique',
        'venimeux',
        'vengeur',
        'vif',
        'vindicatif',
        'violent',
      ],
      icon: Icons.local_fire_department,
      color: Color(0xFFDC2626),
      iconPath: 'assets/univers_visuel/encolere.png',
    ),

    // ❌ IMPUISSANT
    EmotionConfig(
      key: 'IMPUISSANT',
      name: 'Impuissant',
      description: 'Sentiment d\'être bloqué, sans pouvoir',
      nuances: [
        'affamé',
        'agité',
        'amputé',
        'anéanti',
        'assoiffé',
        'compulsif',
        'condamné',
        'décomposé',
        'écartelé',
        'épuisé',
        'étourdi',
        'faible',
        'handicapé',
        'incapable',
        'incompétent',
        'inepte',
        'inférieur',
        'inutile',
        'lamentable',
        'malade',
        'nauséeux',
        'paralysé',
        'piégé',
        'submergé',
        'vide',
        'vulnérable',
      ],
      icon: Icons.block,
      color: Color(0xFF6B7280),
      iconPath: 'assets/univers_visuel/impuissant.png',
    ),

    // ❌ INDIFFERENT
    EmotionConfig(
      key: 'INDIFFERENT',
      name: 'Indifférent',
      description: 'Détachement négatif, apathie',
      nuances: [
        'ennuyé',
        'fatigué',
        'froid',
        'indifférent',
        'insensible',
        'las',
        'lent',
        'léthargique',
        'maussade',
        'passif',
        'préoccupé',
        'réservé',
        'sans intérêt',
        'sans vie',
        'tel un robot',
      ],
      icon: Icons.sentiment_neutral,
      color: Color(0xFF9CA3AF),
      iconPath: 'assets/univers_visuel/indifferent.png',
    ),

    // ❌ TRISTE
    EmotionConfig(
      key: 'TRISTE',
      name: 'Triste',
      description: 'Chagrin, mélancolie',
      nuances: [
        'aigri',
        'angoissé',
        'auto flagellation',
        'aveuglé',
        'dans le partage',
        'déconnecté',
        'désolé',
        'dévasté',
        'distant',
        'dévalorisé',
        'en larmes',
        'envahi',
        'estomaqué',
        'étouffé',
        'fragile',
        'grognon',
        'hypersensible',
        'indigne',
        'indigné',
        'insatisfait',
        'malheureux',
        'mécontent',
        'peiné',
        'plaintif',
        'plein de remords',
        'pleurant',
        'sale',
        'secret',
        'seul',
        'souffrant',
        'tyrannisé',
      ],
      icon: Icons.sentiment_very_dissatisfied,
      color: Color(0xFF1E3A8A),
      iconPath: 'assets/univers_visuel/triste.png',
    ),
  ];

  // ========================================
  // 😊 ÉMOTIONS POSITIVES - QUESTION 4
  // "Qui seriez-vous sans cette pensée ?"
  // ========================================
  
  static const List<EmotionConfig> positiveEmotions = [
    // ✅ AIMANT
    EmotionConfig(
      key: 'AIMANT',
      name: 'Aimant',
      description: 'Affection, tendresse, bienveillance',
      nuances: [
        'admiratif',
        'affectueux',
        'aimable',
        'aimé',
        'attentionné',
        'avec bienveillance',
        'avec gratitude',
        'bienveillant',
        'chaleureux',
        'compatissant',
        'dans le non jugement',
        'dévoué',
        'doux',
        'ému',
        'expansif',
        'humble',
        'intime',
        'patient',
        'reconnaissant',
        'respectueux',
        'sensible',
        'tendre',
      ],
      icon: Icons.favorite,
      color: Color(0xFFEC4899),
      iconPath: 'assets/univers_visuel/aimant.png',
    ),

    // ✅ DETENDU
    EmotionConfig(
      key: 'DETENDU',
      name: 'Détendu',
      description: 'Relaxation, sérénité, tranquillité',
      nuances: [
        'ancré',
        'centré',
        'charmant',
        'conscient',
        'efficace',
        'en bonne santé',
        'épanoui',
        'l\'esprit ouvert',
        'fluide',
        'léger',
        'modeste',
        'naturel',
        'patientant',
        'placide',
        'posé',
        'rayonnant',
        'recueilli',
        'réfléchi',
        'reposé',
        'rieur',
        'sans contrôle',
        'souriant',
        'spontané',
        'soutenu',
      ],
      icon: Icons.spa,
      color: Color(0xFF06B6D4),
      iconPath: 'assets/univers_visuel/detendu.png',
    ),

    // ✅ FORT
    EmotionConfig(
      key: 'FORT',
      name: 'Fort',
      description: 'Puissance, solidité, résilience',
      nuances: [
        'accompli',
        'authentique',
        'dans l\'affirmation de soi',
        'de soutien',
        'dynamisé',
        'dynamique',
        'excellent',
        'exceptionnel',
        'fiable',
        'honnête',
        'mûr',
        'persévérant',
        'responsable',
        'résistant',
        'sécurisé',
        'sensé',
        'solide',
        'stable',
        'sûr',
        'tenace',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFEF4444),
      iconPath: 'assets/univers_visuel/fort.png',
    ),

    // ✅ HEUREUX
    EmotionConfig(
      key: 'HEUREUX',
      name: 'Heureux',
      description: 'Joie, contentement, satisfaction',
      nuances: [
        'au paradis au septième ciel',
        'bienheureux',
        'content',
        'de bonne humeur',
        'enthousiaste',
        'euphorique',
        'extasié',
        'fou de joie',
        'gai',
        'heureux',
        'innocent',
        'insouciant',
        'jovial',
        'joyeux',
        'jubilant',
        'radieux',
        'ravi',
        'satisfait',
        'tel un enfant',
      ],
      icon: Icons.sentiment_very_satisfied,
      color: Color(0xFFFBBF24),
      iconPath: 'assets/univers_visuel/heureux.png',
    ),

    // ✅ INTERESSE
    EmotionConfig(
      key: 'INTERESSE',
      name: 'Intéressé',
      description: 'Curiosité, attention, engagement',
      nuances: [
        'absorbé',
        'attentif',
        'captivé',
        'concentré',
        'courtois',
        'curieux',
        'engagé',
        'fasciné',
        'intéressé',
        'observateur',
        'partie prenante',
        'pensif',
        'prévenant',
        'stupéfait',
      ],
      icon: Icons.visibility,
      color: Color(0xFF8B5CF6),
      iconPath: 'assets/univers_visuel/interesse.png',
    ),

    // ✅ OUVERT
    EmotionConfig(
      key: 'OUVERT',
      name: 'Ouvert',
      description: 'Réceptivité, tolérance, acceptation',
      nuances: [
        'à l\'écoute',
        'abordable',
        'accommodant',
        'acceptant',
        'accueillant',
        'aimable',
        'amical',
        'compréhensif',
        'confiant',
        'décontracté',
        'empathique',
        'en harmonie',
        'en lien',
        'libre',
        'présent',
        'réceptif',
        'sociable',
        'souple',
        'tolérant',
      ],
      icon: Icons.psychology,
      color: Color(0xFF3B82F6),
      iconPath: 'assets/univers_visuel/ouvert.png',
    ),

    // ✅ PAISIBLE
    EmotionConfig(
      key: 'PAISIBLE',
      name: 'Paisible',
      description: 'Calme, paix intérieure, tranquillité',
      nuances: [
        'à l\'aise',
        'approprié',
        'autosuffisant',
        'beau',
        'bien',
        'calme',
        'clair',
        'comblé',
        'confortable',
        'convaincu',
        'détendu',
        'encouragé',
        'équilibré',
        'étonné',
        'indulgent',
        'sans un doute',
        'serein',
        'soulagé',
        'très bien',
        'vrai',
      ],
      icon: Icons.self_improvement,
      color: Color(0xFF10B981),
      iconPath: 'assets/univers_visuel/paisible.png',
    ),

    // ✅ POSITIF
    EmotionConfig(
      key: 'POSITIF',
      name: 'Positif',
      description: 'Optimisme, espoir, construction',
      nuances: [
        'aidant',
        'approbateur',
        'consciencieux',
        'constructif',
        'coopératif',
        'créatif',
        'estimé',
        'exubérant',
        'impliqué',
        'inspiré',
        'intrépide',
        'motivé',
        'optimiste',
        'passionné',
        'plein de ressources',
        'plein d\'espoir',
        'privilégié',
        'productif',
        'sincère',
        'superbe',
      ],
      icon: Icons.trending_up,
      color: Color(0xFF059669),
      iconPath: 'assets/univers_visuel/positif.png',
    ),

    // ✅ VIVANT
    EmotionConfig(
      key: 'VIVANT',
      name: 'Vivant',
      description: 'Énergie, dynamisme, vitalité',
      nuances: [
        'actif',
        'aimant s\'amuser',
        'animé',
        'appréciant',
        'audacieux',
        'bienfait',
        'bouillonnant',
        'communicatif',
        'courageux',
        'dans le partage',
        'drôle',
        'égal',
        'émotionné',
        'amusé',
        'enchanté',
        'énergie de jeunesse',
        'énergique',
        'enjoué',
        'enthousiasme',
        'formidable',
        'intelligent',
        'libéré',
        'merveilleux',
        'optimiste',
        'vif',
        'vigoureux',
      ],
      icon: Icons.flash_on,
      color: Color(0xFFF59E0B),
      iconPath: 'assets/univers_visuel/vivant.png',
    ),
  ];

  // ========================================
  // 🔍 MÉTHODES UTILITAIRES
  // ========================================

  /// Trouver une émotion par sa clé (négative OU positive)
  static EmotionConfig? findByKey(String key) {
    try {
      // Chercher d'abord dans les négatives
      try {
        return negativeEmotions.firstWhere((emotion) => emotion.key == key);
      } catch (e) {
        // Si pas trouvé, chercher dans les positives
        return positiveEmotions.firstWhere((emotion) => emotion.key == key);
      }
    } catch (e) {
      print('❌ Émotion introuvable: $key');
      return null;
    }
  }

  /// Obtenir TOUTES les émotions (négatives + positives)
  static List<EmotionConfig> get allEmotions => [
    ...negativeEmotions,
    ...positiveEmotions,
  ];

  /// Obtenir uniquement les émotions négatives
  static List<EmotionConfig> get negatives => negativeEmotions;

  /// Obtenir uniquement les émotions positives
  static List<EmotionConfig> get positives => positiveEmotions;

  /// Debug: Afficher toutes les clés disponibles
  static void printAllKeys() {
    print('\n📋 LISTE COMPLÈTE DES ÉMOTIONS DISPONIBLES:');
    
    print('\n😔 ÉMOTIONS NÉGATIVES (Question 3):');
    for (var emotion in negativeEmotions) {
      print('   "${emotion.key}" → ${emotion.name} (${emotion.nuances.length} nuances)');
    }
    
    print('\n😊 ÉMOTIONS POSITIVES (Question 4):');
    for (var emotion in positiveEmotions) {
      print('   "${emotion.key}" → ${emotion.name} (${emotion.nuances.length} nuances)');
    }
    
    print('\n📊 TOTAL: ${allEmotions.length} catégories d\'émotions');
  }

  /// Vérifier si une clé existe
  static bool isValidKey(String key) {
    return findByKey(key) != null;
  }
}

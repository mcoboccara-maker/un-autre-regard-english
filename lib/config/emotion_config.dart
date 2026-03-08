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
      name: 'Hurt',
      description: 'Emotional pain, suffering',
      nuances: [
        'abused',
        'weakened',
        'afflicted',
        'hurt',
        'destitute',
        'crushed',
        'sore',
        'horrified',
        'humiliated',
        'insulted',
        'heartbroken',
        'found lacking',
        'offended',
        'rejected',
        'suffering',
        'tortured',
        'tormented',
      ],
      icon: Icons.healing,
      color: Color(0xFFBE185D),
      iconPath: 'assets/univers_visuel/blesse.png',
    ),

    // ❌ CONFUS
    EmotionConfig(
      key: 'CONFUS',
      name: 'Confused',
      description: 'Uncertainty, doubt, perplexity',
      nuances: [
        'comparing',
        'doubtful',
        'disconcerted',
        'disdainful',
        'disoriented',
        'unhinged',
        'distracted',
        'embarrassed',
        'nitpicking',
        'demanding',
        'hesitant',
        'uncertain',
        'uncomfortable',
        'indecisive',
        'worried',
        'dishonest',
        'clumsy',
        'manipulative',
        'lost',
        'perplexed',
        'unsure',
        'full of prejudice',
        'blushing',
        'stressed',
        'superior',
      ],
      icon: Icons.help_outline,
      color: Color(0xFFF59E0B),
      iconPath: 'assets/univers_visuel/confus.png',
    ),

    // ❌ CRITIQUE
    EmotionConfig(
      key: 'CRITIQUE',
      name: 'Critical',
      description: 'Negative judgment, condemnation',
      nuances: [
        'attacking',
        'authoritarian',
        'hurtful',
        'narrow-minded',
        'combative',
        'blunt',
        'harsh',
        'fake',
        'icy',
        'grave',
        'scolding',
        'stiff',
        'impostor',
        'indelicate',
        'unfair',
        'evasive',
        'glaring',
        'obsessive',
        'neglectful',
        'withdrawn',
        'scowling',
        'preachy',
        'severe',
        'superficial',
      ],
      icon: Icons.gavel,
      color: Color(0xFF374151),
      iconPath: 'assets/univers_visuel/critique.png',
    ),

    // ❌ DEPRIME
    EmotionConfig(
      key: 'DEPRIME',
      name: 'Depressed',
      description: 'Sadness, discouragement, dejection',
      nuances: [
        'self-critical',
        'self-deprecating',
        'good for nothing',
        'sulky',
        'quarrelsome',
        'stuck',
        'guilty',
        'tense',
        'discouraged',
        'disappointed',
        'disengaged',
        'demoralized',
        'unmotivated',
        'self-belittling',
        'grumpy',
        'depressed',
        'desperate',
        'diminished',
        'in hell',
        'excluded',
        'exhausted',
        'closed off',
        'self-loathing',
        'ashamed',
        'powerless',
        'unstable',
        'unwell',
        'masochistic',
        'bad',
        'melancholic',
        'contemptible',
        'miserable',
        'gloomy',
        'negative',
        'worthless',
        'pessimistic',
        'punishing',
        'grumbling',
        'resistant',
        'without energy',
        'listless',
        'touchy',
        'fickle',
      ],
      icon: Icons.sentiment_very_dissatisfied,
      color: Color(0xFF1E40AF),
      iconPath: 'assets/univers_visuel/deprime.png',
    ),

    // ❌ EFFRAYE
    EmotionConfig(
      key: 'EFFRAYE',
      name: 'Frightened',
      description: 'Fear, anxiety, terror',
      nuances: [
        'agoraphobic',
        'anxious',
        'scared',
        'overwhelmed',
        'captive',
        'fearful',
        'self-centered',
        'awkward',
        'frightened',
        'terrified',
        'avoidant',
        'panicked',
        'bothered',
        'inhibited',
        'frozen',
        'intolerant',
        'intimidated',
        'cowardly',
        'threatened',
        'distrustful',
        'nervous',
        'offensive',
        'panic-stricken',
        'paranoid',
        'disturbed',
        'petrified',
        'phobic',
        'cautious',
        'rigid',
        'insecure',
        'worried',
        'defensive',
        'tense',
        'terror-stricken',
        'shy',
        'trembling',
      ],
      icon: Icons.warning,
      color: Color(0xFF7C2D12),
      iconPath: 'assets/univers_visuel/effraye.png',
    ),

    // ❌ EN_COLERE
    EmotionConfig(
      key: 'EN_COLERE',
      name: 'Angry',
      description: 'Irritation, rage, frustration',
      nuances: [
        'abrupt',
        'accusatory',
        'annoyed',
        'aggressive',
        'bitter',
        'antagonistic',
        'upset',
        'constraining',
        'critical',
        'disgusted',
        'unpleasant',
        'bossy',
        'domineering',
        'effervescent',
        'enraged',
        'envious',
        'exasperated',
        'exuberant',
        'angry',
        'crazy',
        'frustrated',
        'furious',
        'rude',
        'hateful',
        'hostile',
        'screaming',
        'impatient',
        'impetuous',
        'abusive',
        'insulting',
        'disrespectful',
        'irritable',
        'irritated',
        'jealous',
        'malicious',
        'malevolent',
        'mean',
        'contemptuous',
        'stubborn',
        'outraged',
        'pernicious',
        'full of resentment',
        'provocative',
        'quarrelsome',
        'resentful',
        'reactive',
        'rebellious',
        'reproachful',
        'retaliating',
        'sadistic',
        'sarcastic',
        'venomous',
        'vengeful',
        'fierce',
        'vindictive',
        'violent',
      ],
      icon: Icons.local_fire_department,
      color: Color(0xFFDC2626),
      iconPath: 'assets/univers_visuel/encolere.png',
    ),

    // ❌ IMPUISSANT
    EmotionConfig(
      key: 'IMPUISSANT',
      name: 'Powerless',
      description: 'Feeling stuck, without power',
      nuances: [
        'starving',
        'agitated',
        'amputated',
        'annihilated',
        'parched',
        'compulsive',
        'condemned',
        'falling apart',
        'torn apart',
        'drained',
        'dizzy',
        'weak',
        'handicapped',
        'incapable',
        'incompetent',
        'inept',
        'inferior',
        'useless',
        'pathetic',
        'sick',
        'nauseous',
        'paralyzed',
        'trapped',
        'overwhelmed',
        'empty',
        'vulnerable',
      ],
      icon: Icons.block,
      color: Color(0xFF6B7280),
      iconPath: 'assets/univers_visuel/impuissant.png',
    ),

    // ❌ INDIFFERENT
    EmotionConfig(
      key: 'INDIFFERENT',
      name: 'Indifferent',
      description: 'Negative detachment, apathy',
      nuances: [
        'bored',
        'tired',
        'cold',
        'indifferent',
        'insensitive',
        'weary',
        'slow',
        'lethargic',
        'dreary',
        'passive',
        'preoccupied',
        'reserved',
        'uninterested',
        'lifeless',
        'robotic',
      ],
      icon: Icons.sentiment_neutral,
      color: Color(0xFF9CA3AF),
      iconPath: 'assets/univers_visuel/indifferent.png',
    ),

    // ❌ TRISTE
    EmotionConfig(
      key: 'TRISTE',
      name: 'Sad',
      description: 'Grief, melancholy',
      nuances: [
        'embittered',
        'anguished',
        'self-flagellating',
        'blinded',
        'sharing grief',
        'disconnected',
        'sorry',
        'devastated',
        'distant',
        'devalued',
        'in tears',
        'overwhelmed',
        'stunned',
        'suffocated',
        'fragile',
        'grouchy',
        'hypersensitive',
        'unworthy',
        'indignant',
        'dissatisfied',
        'unhappy',
        'discontented',
        'pained',
        'plaintive',
        'full of remorse',
        'crying',
        'dirty',
        'secretive',
        'lonely',
        'suffering',
        'bullied',
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
      name: 'Loving',
      description: 'Affection, tenderness, kindness',
      nuances: [
        'admiring',
        'affectionate',
        'amiable',
        'loved',
        'caring',
        'with kindness',
        'with gratitude',
        'benevolent',
        'warm',
        'compassionate',
        'non-judgmental',
        'devoted',
        'gentle',
        'moved',
        'expansive',
        'humble',
        'intimate',
        'patient',
        'grateful',
        'respectful',
        'sensitive',
        'tender',
      ],
      icon: Icons.favorite,
      color: Color(0xFFEC4899),
      iconPath: 'assets/univers_visuel/aimant.png',
    ),

    // ✅ DETENDU
    EmotionConfig(
      key: 'DETENDU',
      name: 'Relaxed',
      description: 'Relaxation, serenity, tranquility',
      nuances: [
        'grounded',
        'centered',
        'charming',
        'aware',
        'efficient',
        'healthy',
        'fulfilled',
        'open-minded',
        'fluid',
        'light',
        'modest',
        'natural',
        'patient',
        'placid',
        'composed',
        'radiant',
        'contemplative',
        'thoughtful',
        'rested',
        'cheerful',
        'letting go',
        'smiling',
        'spontaneous',
        'supported',
      ],
      icon: Icons.spa,
      color: Color(0xFF06B6D4),
      iconPath: 'assets/univers_visuel/detendu.png',
    ),

    // ✅ FORT
    EmotionConfig(
      key: 'FORT',
      name: 'Strong',
      description: 'Power, solidity, resilience',
      nuances: [
        'accomplished',
        'authentic',
        'self-assertive',
        'supportive',
        'energized',
        'dynamic',
        'excellent',
        'exceptional',
        'reliable',
        'honest',
        'mature',
        'persevering',
        'responsible',
        'resilient',
        'secure',
        'sensible',
        'solid',
        'stable',
        'confident',
        'tenacious',
      ],
      icon: Icons.fitness_center,
      color: Color(0xFFEF4444),
      iconPath: 'assets/univers_visuel/fort.png',
    ),

    // ✅ HEUREUX
    EmotionConfig(
      key: 'HEUREUX',
      name: 'Happy',
      description: 'Joy, contentment, satisfaction',
      nuances: [
        'on cloud nine',
        'blissful',
        'content',
        'in a good mood',
        'enthusiastic',
        'euphoric',
        'ecstatic',
        'overjoyed',
        'cheerful',
        'happy',
        'innocent',
        'carefree',
        'jovial',
        'joyful',
        'jubilant',
        'radiant',
        'delighted',
        'satisfied',
        'childlike',
      ],
      icon: Icons.sentiment_very_satisfied,
      color: Color(0xFFFBBF24),
      iconPath: 'assets/univers_visuel/heureux.png',
    ),

    // ✅ INTERESSE
    EmotionConfig(
      key: 'INTERESSE',
      name: 'Interested',
      description: 'Curiosity, attention, engagement',
      nuances: [
        'absorbed',
        'attentive',
        'captivated',
        'focused',
        'courteous',
        'curious',
        'engaged',
        'fascinated',
        'interested',
        'observant',
        'involved',
        'pensive',
        'considerate',
        'amazed',
      ],
      icon: Icons.visibility,
      color: Color(0xFF8B5CF6),
      iconPath: 'assets/univers_visuel/interesse.png',
    ),

    // ✅ OUVERT
    EmotionConfig(
      key: 'OUVERT',
      name: 'Open',
      description: 'Receptivity, tolerance, acceptance',
      nuances: [
        'listening',
        'approachable',
        'accommodating',
        'accepting',
        'welcoming',
        'likable',
        'friendly',
        'understanding',
        'trusting',
        'laid-back',
        'empathetic',
        'in harmony',
        'connected',
        'free',
        'present',
        'receptive',
        'sociable',
        'flexible',
        'tolerant',
      ],
      icon: Icons.psychology,
      color: Color(0xFF3B82F6),
      iconPath: 'assets/univers_visuel/ouvert.png',
    ),

    // ✅ PAISIBLE
    EmotionConfig(
      key: 'PAISIBLE',
      name: 'Peaceful',
      description: 'Calm, inner peace, tranquility',
      nuances: [
        'at ease',
        'appropriate',
        'self-sufficient',
        'beautiful',
        'well',
        'calm',
        'clear',
        'fulfilled',
        'comfortable',
        'convinced',
        'relaxed',
        'encouraged',
        'balanced',
        'astonished',
        'forgiving',
        'without a doubt',
        'serene',
        'relieved',
        'very well',
        'true',
      ],
      icon: Icons.self_improvement,
      color: Color(0xFF10B981),
      iconPath: 'assets/univers_visuel/paisible.png',
    ),

    // ✅ POSITIF
    EmotionConfig(
      key: 'POSITIF',
      name: 'Positive',
      description: 'Optimism, hope, building',
      nuances: [
        'helpful',
        'approving',
        'conscientious',
        'constructive',
        'cooperative',
        'creative',
        'esteemed',
        'exuberant',
        'involved',
        'inspired',
        'fearless',
        'motivated',
        'optimistic',
        'passionate',
        'resourceful',
        'hopeful',
        'privileged',
        'productive',
        'sincere',
        'superb',
      ],
      icon: Icons.trending_up,
      color: Color(0xFF059669),
      iconPath: 'assets/univers_visuel/positif.png',
    ),

    // ✅ VIVANT
    EmotionConfig(
      key: 'VIVANT',
      name: 'Alive',
      description: 'Energy, dynamism, vitality',
      nuances: [
        'active',
        'fun-loving',
        'animated',
        'appreciative',
        'bold',
        'blessed',
        'bubbling',
        'communicative',
        'courageous',
        'sharing',
        'funny',
        'equal',
        'emotional',
        'amused',
        'enchanted',
        'youthful energy',
        'energetic',
        'playful',
        'enthusiastic',
        'tremendous',
        'intelligent',
        'liberated',
        'wonderful',
        'optimistic',
        'lively',
        'vigorous',
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

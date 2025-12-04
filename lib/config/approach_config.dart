import 'package:flutter/material.dart';

enum ApproachType {
  spiritual,
  psychological,
  literary,
  philosophical,  // Courants philosophiques
  philosopher,    // Philosophes individuels
}

class ApproachConfig {
  final String key;
  final String name;
  final String description;
  final String credo;
  final String tonEmotionnel;
  final List<String> exemples;
  final IconData icon;
  final Color color;
  final ApproachType type;

  const ApproachConfig({
    required this.key,
    required this.name,
    required this.description,
    required this.credo,
    required this.tonEmotionnel,
    required this.exemples,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class ApproachCategories {
  // ========================================
  // 🕊️ APPROCHES SPIRITUELLES/RELIGIEUSES
  // ========================================
  // ⚠️ Les clés (key) correspondent aux IDs de sources_spirituelles_screen.dart
  static const List<ApproachConfig> spiritual = [
    ApproachConfig(
      key: 'judaisme_rabbinique',
      name: 'Judaïsme rabbinique',
      description: 'Tradition fondée sur la Torah et le Talmud',
      credo: 'Chaque pensée est une occasion de tikkoun (réparation)',
      tonEmotionnel: 'Réfléchi, structuré',
      exemples: ['Torah', 'Talmud', 'Éthique des Pères'],
      icon: Icons.menu_book,
      color: Color(0xFF1E40AF),
      type: ApproachType.spiritual,
    ),
    
    ApproachConfig(
      key: 'moussar',
      name: 'Moussar (éthique juive)',
      description: 'Introspection éthique et perfectionnement moral',
      credo: 'Observer ses émotions pour perfectionner son caractère',
      tonEmotionnel: 'Introspectif, exigeant',
      exemples: ['Ramban', 'Rav Israel Salanter'],
      icon: Icons.self_improvement,
      color: Color(0xFF3B82F6),
      type: ApproachType.spiritual,
    ),
    
    ApproachConfig(
      key: 'kabbale',
      name: 'Kabbale (mystique juive)',
      description: 'Mystique juive de la réparation intérieure',
      credo: 'Cette épreuve révèle un aspect de ta mission d\'âme',
      tonEmotionnel: 'Mystique, élevé',
      exemples: ['Zohar', 'Ari Hakadosh', 'Baal Shem Tov'],
      icon: Icons.auto_awesome,
      color: Color(0xFF7C3AED),
      type: ApproachType.spiritual,
    ),
    
    ApproachConfig(
      key: 'christianisme',
      name: 'Christianisme',
      description: 'Transformer la souffrance par l\'amour et l\'abandon',
      credo: 'Comment le Christ agirait-il face à cette situation ?',
      tonEmotionnel: 'Compatissant, confiant',
      exemples: ['Saint Jean de la Croix', 'Thérèse d\'Avila'],
      icon: Icons.favorite,
      color: Color(0xFFDC2626),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'islam',
      name: 'Islam',
      description: 'Soumission à Allah et patience dans l\'épreuve',
      credo: 'Allah ne t\'impose que ce que tu peux supporter',
      tonEmotionnel: 'Confiant, patient',
      exemples: ['Coran', 'Hadith', 'Al-Ghazali'],
      icon: Icons.mosque,
      color: Color(0xFF059669),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'soufisme',
      name: 'Soufisme (mystique musulmane)',
      description: 'Purification du cœur et abandon mystique',
      credo: 'Cette épreuve est un polissage de ton cœur vers la pureté',
      tonEmotionnel: 'Mystique, abandonné',
      exemples: ['Rumi', 'Ibn Arabi', 'Al-Hallaj'],
      icon: Icons.auto_awesome,
      color: Color(0xFF8B5CF6),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'bouddhisme',
      name: 'Bouddhisme',
      description: 'Libération par la compréhension de l\'impermanence',
      credo: 'Cette souffrance naît de l\'attachement - comment la relâcher ?',
      tonEmotionnel: 'Sage, apaisant',
      exemples: ['Bouddha', 'Dalaï Lama', 'Thich Nhat Hanh'],
      icon: Icons.self_improvement,
      color: Color(0xFF10B981),
      type: ApproachType.spiritual,
    ),
    
    ApproachConfig(
      key: 'hindouisme',
      name: 'Hindouisme',
      description: 'Comprendre le karma et dépasser l\'illusion (maya)',
      credo: 'Cette situation t\'enseigne à voir au-delà des apparences',
      tonEmotionnel: 'Philosophique, détaché',
      exemples: ['Bhagavad Gita', 'Patanjali', 'Ramana Maharshi'],
      icon: Icons.temple_hindu,
      color: Color(0xFFF59E0B),
      type: ApproachType.spiritual,
    ),
    
    ApproachConfig(
      key: 'stoicisme',
      name: 'Stoïcisme',
      description: 'Maîtrise de soi et acceptation sereine',
      credo: 'Tu ne peux pas contrôler les événements, seulement ta réponse',
      tonEmotionnel: 'Stoïque, rationnel',
      exemples: ['Marc Aurèle', 'Épictète', 'Sénèque'],
      icon: Icons.shield,
      color: Color(0xFF6B7280),
      type: ApproachType.spiritual,
    ),
    
    ApproachConfig(
      key: 'spiritualite_contemporaine',
      name: 'Spiritualité contemporaine / laïque',
      description: 'Recherche de sens au-delà des dogmes',
      credo: 'Tu peux créer ton propre chemin spirituel',
      tonEmotionnel: 'Ouvert, inclusif',
      exemples: ['Mindfulness', 'Développement personnel'],
      icon: Icons.explore,
      color: Color(0xFF06B6D4),
      type: ApproachType.spiritual,
    ),
  ];

  // ========================================
  // 📚 APPROCHES LITTÉRAIRES
  // ========================================
  // ⚠️ Les clés correspondent aux IDs de sources_litteraires_screen.dart
  static const List<ApproachConfig> literary = [
    ApproachConfig(
      key: 'humanisme',
      name: 'Humanisme',
      description: 'La dignité humaine et la quête de sens',
      credo: 'L\'homme est capable de grandeur par sa raison et son cœur',
      tonEmotionnel: 'Élevé, confiant',
      exemples: ['Montaigne', 'Érasme', 'Rabelais'],
      icon: Icons.auto_stories,
      color: Color(0xFF059669),
      type: ApproachType.literary,
    ),
    
    ApproachConfig(
      key: 'romantisme',
      name: 'Romantisme',
      description: 'Exaltation de la passion et de la subjectivité',
      credo: 'J\'ai quelquefois pleuré, voilà ma gloire',
      tonEmotionnel: 'Exalté, émotionnel',
      exemples: ['Hugo', 'Musset', 'Lamartine'],
      icon: Icons.favorite_border,
      color: Color(0xFFEC4899),
      type: ApproachType.literary,
    ),
    
    ApproachConfig(
      key: 'realisme',
      name: 'Réalisme',
      description: 'Observation lucide de la vie sans idéalisation',
      credo: 'Le monde n\'est pas juste, mais il est réel',
      tonEmotionnel: 'Lucide, factuel',
      exemples: ['Flaubert', 'Zola', 'Maupassant'],
      icon: Icons.visibility,
      color: Color(0xFF92400E),
      type: ApproachType.literary,
    ),
    
    ApproachConfig(
      key: 'existentialisme',
      name: 'Existentialisme',
      description: 'La liberté et la responsabilité face à l\'absurde',
      credo: 'L\'homme est condamné à être libre',
      tonEmotionnel: 'Conscient, dépouillé',
      exemples: ['Camus', 'Sartre', 'de Beauvoir'],
      icon: Icons.psychology_outlined,
      color: Color(0xFF374151),
      type: ApproachType.literary,
    ),
    
    ApproachConfig(
      key: 'absurdisme',
      name: 'Absurdisme',
      description: 'Le monde est dénué de sens objectif mais l\'humain peut réagir avec liberté',
      credo: 'Il faut imaginer Sisyphe heureux',
      tonEmotionnel: 'Lucide, libre',
      exemples: ['Camus', 'Ionesco', 'Beckett'],
      icon: Icons.help_outline,
      color: Color(0xFF4B5563),
      type: ApproachType.literary,
    ),
    
    // Approches supplémentaires pour compatibilité avec approach_config original
    ApproachConfig(
      key: 'poetique',
      name: 'Poétique',
      description: 'La beauté du langage révèle le monde intérieur',
      credo: 'Les mots peuvent transformer la souffrance en beauté',
      tonEmotionnel: 'Sensible, artistique',
      exemples: ['Baudelaire', 'Rilke', 'Rimbaud'],
      icon: Icons.auto_fix_high,
      color: Color(0xFFEC4899),
      type: ApproachType.literary,
    ),
    
    ApproachConfig(
      key: 'mystique',
      name: 'Mystique',
      description: 'Communion entre l\'âme et l\'absolu',
      credo: 'Il y a un sens caché derrière chaque épreuve',
      tonEmotionnel: 'Contemplatif, profond',
      exemples: ['Maître Eckhart', 'Angelus Silesius'],
      icon: Icons.wb_twilight,
      color: Color(0xFF7C3AED),
      type: ApproachType.literary,
    ),
    
    ApproachConfig(
      key: 'symboliste_moderne',
      name: 'Symboliste / Moderne',
      description: 'Recherche du sens caché et langage suggestif',
      credo: 'Patience, tout ce qui veut fleurir mûrit dans la douleur',
      tonEmotionnel: 'Poétique, suggestif',
      exemples: ['Mallarmé', 'Valéry', 'Claudel'],
      icon: Icons.auto_awesome,
      color: Color(0xFF6366F1),
      type: ApproachType.literary,
    ),
  ];

  // ========================================
  // 🧠 APPROCHES PSYCHOLOGIQUES
  // ========================================
  // ⚠️ Les clés correspondent aux IDs de sources_psychologiques_screen.dart
  static const List<ApproachConfig> psychological = [
    ApproachConfig(
      key: 'act',
      name: 'ACT (Acceptance & Commitment)',
      description: 'Thérapie basée sur l\'acceptation et l\'action alignée avec les valeurs',
      credo: 'Accepter ce qui est, agir selon tes valeurs',
      tonEmotionnel: 'Pragmatique, bienveillant',
      exemples: ['Steven Hayes', 'Défusion cognitive'],
      icon: Icons.check_circle_outline,
      color: Color(0xFF10B981),
      type: ApproachType.psychological,
    ),
    
    ApproachConfig(
      key: 'tcc',
      name: 'TCC (Cognitivo-Comportementale)',
      description: 'Modification des pensées et comportements limitants',
      credo: 'Quelle pensée automatique t\'empêche d\'avancer ?',
      tonEmotionnel: 'Pragmatique, structuré',
      exemples: ['Aaron Beck', 'Pensées automatiques'],
      icon: Icons.psychology_outlined,
      color: Color(0xFF3B82F6),
      type: ApproachType.psychological,
    ),
    
    ApproachConfig(
      key: 'jungienne',
      name: 'Psychologie Jungienne',
      description: 'Exploration de l\'inconscient et des symboles universels',
      credo: 'Quel archétype ou symbole parle à travers cette situation ?',
      tonEmotionnel: 'Profond, symbolique',
      exemples: ['Carl Jung', 'Archétypes', 'Inconscient collectif'],
      icon: Icons.psychology,
      color: Color(0xFF7C3AED),
      type: ApproachType.psychological,
    ),
    
    ApproachConfig(
      key: 'logotherapie',
      name: 'Logothérapie (Frankl)',
      description: 'La quête de sens dans chaque épreuve',
      credo: 'Quel sens peux-tu donner à cette situation ?',
      tonEmotionnel: 'Existentiel, résilient',
      exemples: ['Viktor Frankl', 'Sens de la vie'],
      icon: Icons.lightbulb_outline,
      color: Color(0xFF059669),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'schemas_young',
      name: 'Thérapie des Schémas (Young)',
      description: 'Identifier et transformer les schémas émotionnels précoces',
      credo: 'Quel schéma de ton enfance se répète ici ?',
      tonEmotionnel: 'Analytique, structuré',
      exemples: ['Jeffrey Young', 'Schémas précoces'],
      icon: Icons.account_tree,
      color: Color(0xFF6366F1),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'the_work',
      name: 'The Work (Byron Katie)',
      description: 'Questionnement des pensées stressantes',
      credo: 'Est-ce que c\'est vrai ? Qui serais-tu sans cette pensée ?',
      tonEmotionnel: 'Neutre, investigateur',
      exemples: ['Byron Katie', '4 questions + retournement'],
      icon: Icons.help_center,
      color: Color(0xFF8B5CF6),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'humaniste_rogers',
      name: 'Approche Humaniste (Rogers)',
      description: 'Acceptation inconditionnelle et potentiel intérieur',
      credo: 'Tu as en toi les ressources pour grandir',
      tonEmotionnel: 'Bienveillant, encourageant',
      exemples: ['Carl Rogers', 'Approche centrée sur la personne'],
      icon: Icons.favorite,
      color: Color(0xFFEC4899),
      type: ApproachType.psychological,
    ),
  ];

  // ========================================
  // 🏛️ COURANTS PHILOSOPHIQUES
  // ========================================
  static const List<ApproachConfig> philosophical = [
    ApproachConfig(
      key: 'stoicisme_philo',
      name: 'Stoïcisme',
      description: 'Maîtrise de soi et acceptation du destin',
      credo: 'Distingue ce qui dépend de toi de ce qui n\'en dépend pas',
      tonEmotionnel: 'Serein, rationnel',
      exemples: ['Marc Aurèle', 'Épictète', 'Sénèque'],
      icon: Icons.shield,
      color: Color(0xFF6B7280),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'epicurisme',
      name: 'Épicurisme',
      description: 'Recherche du bonheur par la modération des désirs',
      credo: 'Le plaisir est le bien suprême, mais le sage sait le modérer',
      tonEmotionnel: 'Paisible, mesuré',
      exemples: ['Épicure', 'Lucrèce'],
      icon: Icons.spa,
      color: Color(0xFF10B981),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'existentialisme_philo',
      name: 'Existentialisme',
      description: 'L\'existence précède l\'essence',
      credo: 'Tu es condamné à être libre, assume ta responsabilité',
      tonEmotionnel: 'Lucide, engagé',
      exemples: ['Sartre', 'Heidegger', 'Kierkegaard'],
      icon: Icons.person_outline,
      color: Color(0xFF374151),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'phenomenologie',
      name: 'Phénoménologie',
      description: 'Retour aux choses mêmes, à l\'expérience vécue',
      credo: 'Comment vis-tu vraiment cette expérience ?',
      tonEmotionnel: 'Attentif, descriptif',
      exemples: ['Husserl', 'Merleau-Ponty'],
      icon: Icons.visibility,
      color: Color(0xFF8B5CF6),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'absurdisme_philo',
      name: 'Absurdisme',
      description: 'Face à l\'absurde, la révolte et la création',
      credo: 'Il faut imaginer Sisyphe heureux',
      tonEmotionnel: 'Lucide, révolté',
      exemples: ['Camus', 'Le Mythe de Sisyphe'],
      icon: Icons.terrain,
      color: Color(0xFF4B5563),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'rationalisme',
      name: 'Rationalisme',
      description: 'La raison comme source de connaissance',
      credo: 'Pense clairement, distingue le vrai du faux',
      tonEmotionnel: 'Méthodique, clair',
      exemples: ['Descartes', 'Spinoza', 'Leibniz'],
      icon: Icons.lightbulb,
      color: Color(0xFF3B82F6),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'empirisme',
      name: 'Empirisme',
      description: 'L\'expérience comme source de connaissance',
      credo: 'Que t\'enseigne concrètement cette expérience ?',
      tonEmotionnel: 'Pragmatique, observateur',
      exemples: ['Hume', 'Locke', 'Berkeley'],
      icon: Icons.science,
      color: Color(0xFF059669),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'idealisme',
      name: 'Idéalisme',
      description: 'La réalité est fondamentalement spirituelle',
      credo: 'Le monde est une manifestation de l\'esprit',
      tonEmotionnel: 'Élevé, contemplatif',
      exemples: ['Platon', 'Hegel', 'Kant'],
      icon: Icons.cloud,
      color: Color(0xFF6366F1),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'pragmatisme',
      name: 'Pragmatisme',
      description: 'La vérité se mesure à ses effets pratiques',
      credo: 'Qu\'est-ce qui fonctionne concrètement ?',
      tonEmotionnel: 'Pratique, orienté action',
      exemples: ['William James', 'John Dewey'],
      icon: Icons.build,
      color: Color(0xFFF59E0B),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'vitalisme',
      name: 'Vitalisme',
      description: 'La vie comme force créatrice fondamentale',
      credo: 'Affirme ta puissance vitale',
      tonEmotionnel: 'Énergique, créatif',
      exemples: ['Bergson', 'Nietzsche'],
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'humanisme_philo',
      name: 'Humanisme philosophique',
      description: 'L\'homme comme valeur suprême',
      credo: 'Chaque être humain a une dignité inviolable',
      tonEmotionnel: 'Bienveillant, universel',
      exemples: ['Montaigne', 'Érasme', 'Renaissance'],
      icon: Icons.people,
      color: Color(0xFFEC4899),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'utilitarisme',
      name: 'Utilitarisme',
      description: 'Maximiser le bonheur pour le plus grand nombre',
      credo: 'Quelle action produit le plus de bien ?',
      tonEmotionnel: 'Calculateur, bienveillant',
      exemples: ['Bentham', 'Mill'],
      icon: Icons.calculate,
      color: Color(0xFF06B6D4),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'structuralisme',
      name: 'Structuralisme',
      description: 'Les structures sous-jacentes déterminent le sens',
      credo: 'Quelles structures invisibles façonnent ta situation ?',
      tonEmotionnel: 'Analytique, systémique',
      exemples: ['Lévi-Strauss', 'Foucault'],
      icon: Icons.account_tree,
      color: Color(0xFF7C3AED),
      type: ApproachType.philosophical,
    ),
    
    ApproachConfig(
      key: 'philosophies_orientales',
      name: 'Philosophies orientales',
      description: 'Sagesse de l\'harmonie et de l\'équilibre',
      credo: 'Trouve l\'équilibre entre les opposés',
      tonEmotionnel: 'Équilibré, harmonieux',
      exemples: ['Taoïsme', 'Confucianisme', 'Zen'],
      icon: Icons.brightness_6,
      color: Color(0xFF10B981),
      type: ApproachType.philosophical,
    ),
  ];

  // ========================================
  // 👤 PHILOSOPHES INDIVIDUELS
  // ========================================
  static const List<ApproachConfig> philosophers = [
    ApproachConfig(
      key: 'socrate',
      name: 'Socrate',
      description: 'La maïeutique et la connaissance de soi',
      credo: 'Connais-toi toi-même',
      tonEmotionnel: 'Interrogatif, humble',
      exemples: ['Dialogues platoniciens', 'Ironie socratique'],
      icon: Icons.help_outline,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'platon',
      name: 'Platon',
      description: 'Le monde des Idées et la quête de la vérité',
      credo: 'Au-delà des apparences, cherche l\'essence',
      tonEmotionnel: 'Élevé, contemplatif',
      exemples: ['La République', 'Allégorie de la caverne'],
      icon: Icons.lightbulb,
      color: Color(0xFF3B82F6),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'aristote',
      name: 'Aristote',
      description: 'L\'éthique de la vertu et le juste milieu',
      credo: 'La vertu est un équilibre entre les extrêmes',
      tonEmotionnel: 'Mesuré, pratique',
      exemples: ['Éthique à Nicomaque', 'Vertus cardinales'],
      icon: Icons.balance,
      color: Color(0xFF059669),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'epicure',
      name: 'Épicure',
      description: 'Le plaisir sage et l\'ataraxie',
      credo: 'Le bonheur est dans la simplicité',
      tonEmotionnel: 'Paisible, serein',
      exemples: ['Lettre à Ménécée', 'Jardin d\'Épicure'],
      icon: Icons.spa,
      color: Color(0xFF10B981),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'seneque',
      name: 'Sénèque',
      description: 'La sagesse stoïcienne appliquée',
      credo: 'Vis chaque jour comme s\'il était le dernier',
      tonEmotionnel: 'Sage, pragmatique',
      exemples: ['Lettres à Lucilius', 'De la brièveté de la vie'],
      icon: Icons.edit_note,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'epictete',
      name: 'Épictète',
      description: 'La liberté intérieure malgré les contraintes',
      credo: 'Ce qui dépend de nous, ce qui n\'en dépend pas',
      tonEmotionnel: 'Stoïque, ferme',
      exemples: ['Manuel', 'Entretiens'],
      icon: Icons.link_off,
      color: Color(0xFF4B5563),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'marc_aurele',
      name: 'Marc Aurèle',
      description: 'La méditation stoïcienne au quotidien',
      credo: 'Que ta pensée soit ton refuge',
      tonEmotionnel: 'Méditatif, discipliné',
      exemples: ['Pensées pour moi-même'],
      icon: Icons.self_improvement,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'spinoza',
      name: 'Spinoza',
      description: 'Dieu-Nature et la joie de comprendre',
      credo: 'Comprendre, c\'est se libérer',
      tonEmotionnel: 'Serein, lumineux',
      exemples: ['Éthique', 'Substance unique'],
      icon: Icons.all_inclusive,
      color: Color(0xFF8B5CF6),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'kant',
      name: 'Kant',
      description: 'Le devoir moral et l\'impératif catégorique',
      credo: 'Agis comme si ta maxime devait devenir loi universelle',
      tonEmotionnel: 'Rigoureux, moral',
      exemples: ['Critique de la raison pure', 'Fondements de la métaphysique des mœurs'],
      icon: Icons.gavel,
      color: Color(0xFF1E40AF),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'nietzsche',
      name: 'Nietzsche',
      description: 'La volonté de puissance et le dépassement de soi',
      credo: 'Deviens ce que tu es',
      tonEmotionnel: 'Intense, provocateur',
      exemples: ['Ainsi parlait Zarathoustra', 'Surhomme'],
      icon: Icons.bolt,
      color: Color(0xFFDC2626),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'kierkegaard',
      name: 'Kierkegaard',
      description: 'L\'angoisse et le saut de la foi',
      credo: 'L\'existence précède l\'essence',
      tonEmotionnel: 'Angoissé, authentique',
      exemples: ['Le concept d\'angoisse', 'Stades de l\'existence'],
      icon: Icons.trending_up,
      color: Color(0xFF7C3AED),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'sartre',
      name: 'Sartre',
      description: 'La liberté radicale et la responsabilité',
      credo: 'L\'homme est condamné à être libre',
      tonEmotionnel: 'Lucide, engagé',
      exemples: ['L\'être et le néant', 'L\'existentialisme est un humanisme'],
      icon: Icons.person_outline,
      color: Color(0xFF374151),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'camus',
      name: 'Camus',
      description: 'L\'absurde et la révolte',
      credo: 'Il faut imaginer Sisyphe heureux',
      tonEmotionnel: 'Lucide, révolté',
      exemples: ['Le mythe de Sisyphe', 'L\'homme révolté'],
      icon: Icons.terrain,
      color: Color(0xFF4B5563),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'simone_de_beauvoir',
      name: 'Simone de Beauvoir',
      description: 'La liberté et la situation',
      credo: 'On ne naît pas femme, on le devient',
      tonEmotionnel: 'Engagé, féministe',
      exemples: ['Le deuxième sexe', 'Pour une morale de l\'ambiguïté'],
      icon: Icons.woman,
      color: Color(0xFFEC4899),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'hannah_arendt',
      name: 'Hannah Arendt',
      description: 'La pensée et l\'action politique',
      credo: 'Penser ce que nous faisons',
      tonEmotionnel: 'Réflexif, politique',
      exemples: ['La condition de l\'homme moderne', 'Banalité du mal'],
      icon: Icons.public,
      color: Color(0xFF6366F1),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'schopenhauer',
      name: 'Schopenhauer',
      description: 'Le vouloir-vivre et la souffrance',
      credo: 'La vie oscille entre souffrance et ennui',
      tonEmotionnel: 'Pessimiste, lucide',
      exemples: ['Le monde comme volonté et représentation'],
      icon: Icons.nights_stay,
      color: Color(0xFF1F2937),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'montaigne',
      name: 'Montaigne',
      description: 'L\'essai de soi et la sagesse modeste',
      credo: 'Que sais-je ?',
      tonEmotionnel: 'Humble, curieux',
      exemples: ['Essais', 'Introspection'],
      icon: Icons.menu_book,
      color: Color(0xFF92400E),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'diogene',
      name: 'Diogène',
      description: 'Le cynisme et le retour à la nature',
      credo: 'Vis selon la nature, méprise les conventions',
      tonEmotionnel: 'Provocateur, libre',
      exemples: ['Tonneau de Diogène', 'Cynisme'],
      icon: Icons.mood,
      color: Color(0xFFF59E0B),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'confucius',
      name: 'Confucius',
      description: 'L\'harmonie sociale et la vertu',
      credo: 'Cultive-toi pour cultiver les autres',
      tonEmotionnel: 'Sage, harmonieux',
      exemples: ['Entretiens', 'Ren (humanité)'],
      icon: Icons.people,
      color: Color(0xFFDC2626),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'rousseau',
      name: 'Rousseau',
      description: 'Le bon sauvage et le contrat social',
      credo: 'L\'homme naît bon, la société le corrompt',
      tonEmotionnel: 'Sensible, naturel',
      exemples: ['Du contrat social', 'Émile'],
      icon: Icons.nature_people,
      color: Color(0xFF059669),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'hume',
      name: 'Hume',
      description: 'Le scepticisme et l\'empirisme',
      credo: 'L\'expérience est la seule source de connaissance',
      tonEmotionnel: 'Sceptique, mesuré',
      exemples: ['Traité de la nature humaine', 'Empirisme'],
      icon: Icons.science,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'foucault',
      name: 'Foucault',
      description: 'Le pouvoir et les normes',
      credo: 'Questionne les évidences et les normes',
      tonEmotionnel: 'Critique, subversif',
      exemples: ['Surveiller et punir', 'Histoire de la folie'],
      icon: Icons.visibility_off,
      color: Color(0xFF7C3AED),
      type: ApproachType.philosopher,
    ),
    
    ApproachConfig(
      key: 'descartes',
      name: 'Descartes',
      description: 'Le doute méthodique et le cogito',
      credo: 'Je pense, donc je suis',
      tonEmotionnel: 'Méthodique, rationnel',
      exemples: ['Méditations métaphysiques', 'Discours de la méthode'],
      icon: Icons.psychology,
      color: Color(0xFF3B82F6),
      type: ApproachType.philosopher,
    ),
  ];

  // ========================================
  // 🔍 MÉTHODES UTILITAIRES
  // ========================================
  
  /// Trouver une approche par son key
  static ApproachConfig? findByKey(String key) {
    final allApproaches = [...spiritual, ...psychological, ...literary, ...philosophical, ...philosophers];
    try {
      return allApproaches.firstWhere(
        (approach) => approach.key == key,
        orElse: () {
          print('⚠️ Approche non trouvée: $key');
          print('📋 Clés disponibles:');
          for (var approach in allApproaches) {
            print('   - ${approach.key}');
          }
          throw Exception('Approche introuvable: $key');
        },
      );
    } catch (e) {
      print('❌ Exception lors de la recherche de l\'approche: $e');
      return null;
    }
  }

  /// Obtenir toutes les approches d'un type spécifique
  static List<ApproachConfig> getByType(ApproachType type) {
    switch (type) {
      case ApproachType.spiritual:
        return spiritual;
      case ApproachType.psychological:
        return psychological;
      case ApproachType.literary:
        return literary;
      case ApproachType.philosophical:
        return philosophical;
      case ApproachType.philosopher:
        return philosophers;
    }
  }

  /// Obtenir toutes les approches disponibles
  static List<ApproachConfig> get allApproaches => [
    ...spiritual,
    ...psychological,
    ...literary,
    ...philosophical,
    ...philosophers,
  ];
  
  /// Debug: afficher toutes les clés disponibles
  static void printAllKeys() {
    print('\n📋 LISTE COMPLÈTE DES APPROCHES DISPONIBLES:');
    print('\n🕊️ SPIRITUELLES:');
    for (var approach in spiritual) {
      print('   "${approach.key}"');
    }
    print('\n📚 LITTÉRAIRES:');
    for (var approach in literary) {
      print('   "${approach.key}"');
    }
    print('\n🧠 PSYCHOLOGIQUES:');
    for (var approach in psychological) {
      print('   "${approach.key}"');
    }
    print('\n🏛️ COURANTS PHILOSOPHIQUES:');
    for (var approach in philosophical) {
      print('   "${approach.key}"');
    }
    print('\n👤 PHILOSOPHES:');
    for (var approach in philosophers) {
      print('   "${approach.key}"');
    }
  }
}

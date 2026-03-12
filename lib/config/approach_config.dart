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
      name: 'Rabbinic Judaism',
      description: 'Tradition rooted in the Torah and the Talmud',
      credo: 'Every thought is an opportunity for tikkun (repair)',
      tonEmotionnel: 'Reflective, structured',
      exemples: ['Torah', 'Talmud', 'Ethics of the Fathers'],
      icon: Icons.menu_book,
      color: Color(0xFF1E40AF),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'moussar',
      name: 'Mussar (Jewish Ethics)',
      description: 'Ethical introspection and moral self-improvement',
      credo: 'Observe your emotions to refine your character',
      tonEmotionnel: 'Introspective, demanding',
      exemples: ['Ramban', 'Rav Israel Salanter'],
      icon: Icons.self_improvement,
      color: Color(0xFF3B82F6),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'kabbale',
      name: 'Kabbalah (Jewish Mysticism)',
      description: 'Jewish mysticism of inner repair',
      credo: 'This trial reveals an aspect of your soul\'s mission',
      tonEmotionnel: 'Mystical, elevated',
      exemples: ['Zohar', 'Ari Hakadosh', 'Baal Shem Tov'],
      icon: Icons.auto_awesome,
      color: Color(0xFF7C3AED),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'christianisme',
      name: 'Christianity',
      description: 'Transforming suffering through love and surrender',
      credo: 'How would Christ act in this situation?',
      tonEmotionnel: 'Compassionate, trusting',
      exemples: ['Saint John of the Cross', 'Teresa of Avila'],
      icon: Icons.favorite,
      color: Color(0xFFDC2626),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'islam',
      name: 'Islam',
      description: 'Submission to Allah and patience through trials',
      credo: 'Allah does not burden you beyond what you can bear',
      tonEmotionnel: 'Trusting, patient',
      exemples: ['Quran', 'Hadith', 'Al-Ghazali'],
      icon: Icons.mosque,
      color: Color(0xFF059669),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'soufisme',
      name: 'Sufism (Islamic Mysticism)',
      description: 'Purification of the heart and mystical surrender',
      credo: 'This trial is a polishing of your heart toward purity',
      tonEmotionnel: 'Mystical, surrendered',
      exemples: ['Rumi', 'Ibn Arabi', 'Al-Hallaj'],
      icon: Icons.auto_awesome,
      color: Color(0xFF8B5CF6),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'theravada',
      name: 'Theravāda Buddhism',
      description: 'Way of the Elders — liberation through personal discipline and Vipassana meditation',
      credo: 'Observe your suffering with clarity — it dissolves in mindful awareness',
      tonEmotionnel: 'Methodical, soothing, progressive',
      exemples: ['Buddha', 'Ajahn Chah', 'Mahasi Sayadaw'],
      icon: Icons.self_improvement,
      color: Color(0xFF10B981),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'zen',
      name: 'Zen Buddhism',
      description: 'Direct awakening through immediate experience, beyond words and concepts',
      credo: 'Let go of all thought — the answer is already here, before the mind',
      tonEmotionnel: 'Stripped, radical, lightning',
      exemples: ['Dōgen', 'Shunryu Suzuki', 'Thich Nhat Hanh'],
      icon: Icons.spa,
      color: Color(0xFF065F46),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'advaita_vedanta',
      name: 'Advaita Vedānta',
      description: 'Radical non-duality — you ARE the Absolute, the world is illusion (māyā)',
      credo: 'You are not this situation — discover who you truly are, beyond appearances',
      tonEmotionnel: 'Philosophical, liberating, contemplative',
      exemples: ['Śaṅkara', 'Ramana Maharshi', 'Nisargadatta Maharaj'],
      icon: Icons.all_inclusive,
      color: Color(0xFFF59E0B),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'bhakti',
      name: 'Bhakti (Hindu devotion)',
      description: 'Devotional love as a path to liberation — the heart before knowledge',
      credo: 'Offer this trial to the divine — love transforms all suffering',
      tonEmotionnel: 'Ardent, trusting, ecstatic',
      exemples: ['Rāmānuja', 'Caitanya', 'Mirabai', 'Tulsidas'],
      icon: Icons.temple_hindu,
      color: Color(0xFFEA580C),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'stoicisme',
      name: 'Stoicism',
      description: 'Self-mastery and serene acceptance',
      credo: 'You cannot control events, only your response to them',
      tonEmotionnel: 'Stoic, rational',
      exemples: ['Marcus Aurelius', 'Epictetus', 'Seneca'],
      icon: Icons.shield,
      color: Color(0xFF6B7280),
      type: ApproachType.spiritual,
    ),

    ApproachConfig(
      key: 'spiritualite_contemporaine',
      name: 'Contemporary / Secular Spirituality',
      description: 'Seeking meaning beyond dogma',
      credo: 'You can create your own spiritual path',
      tonEmotionnel: 'Open, inclusive',
      exemples: ['Mindfulness', 'Personal development'],
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
      name: 'Humanism',
      description: 'Human dignity and the quest for meaning',
      credo: 'Humanity is capable of greatness through reason and heart',
      tonEmotionnel: 'Elevated, confident',
      exemples: ['Montaigne', 'Erasmus', 'Rabelais'],
      icon: Icons.auto_stories,
      color: Color(0xFF059669),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'romantisme',
      name: 'Romanticism',
      description: 'Exaltation of passion and subjectivity',
      credo: 'I have sometimes wept — therein lies my glory',
      tonEmotionnel: 'Exalted, emotional',
      exemples: ['Hugo', 'Musset', 'Lamartine'],
      icon: Icons.favorite_border,
      color: Color(0xFFEC4899),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'realisme',
      name: 'Realism',
      description: 'Clear-eyed observation of life without idealization',
      credo: 'The world is not fair, but it is real',
      tonEmotionnel: 'Lucid, factual',
      exemples: ['Flaubert', 'Zola', 'Maupassant'],
      icon: Icons.visibility,
      color: Color(0xFF92400E),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'existentialisme',
      name: 'Existentialism',
      description: 'Freedom and responsibility in the face of the absurd',
      credo: 'Man is condemned to be free',
      tonEmotionnel: 'Aware, stripped down',
      exemples: ['Camus', 'Sartre', 'de Beauvoir'],
      icon: Icons.psychology_outlined,
      color: Color(0xFF374151),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'absurdisme',
      name: 'Absurdism',
      description: 'The world lacks objective meaning, yet humans can respond with freedom',
      credo: 'One must imagine Sisyphus happy',
      tonEmotionnel: 'Lucid, free',
      exemples: ['Camus', 'Ionesco', 'Beckett'],
      icon: Icons.help_outline,
      color: Color(0xFF4B5563),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'poetique',
      name: 'Poetics',
      description: 'The beauty of language reveals the inner world',
      credo: 'Words can transform suffering into beauty',
      tonEmotionnel: 'Sensitive, artistic',
      exemples: ['Baudelaire', 'Rilke', 'Rimbaud'],
      icon: Icons.auto_fix_high,
      color: Color(0xFFEC4899),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'mystique',
      name: 'Mysticism',
      description: 'Communion between the soul and the absolute',
      credo: 'There is a hidden meaning behind every trial',
      tonEmotionnel: 'Contemplative, profound',
      exemples: ['Meister Eckhart', 'Angelus Silesius'],
      icon: Icons.wb_twilight,
      color: Color(0xFF7C3AED),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'symboliste_moderne',
      name: 'Symbolist / Modern',
      description: 'Search for hidden meaning and suggestive language',
      credo: 'Patience — everything that wants to bloom ripens in pain',
      tonEmotionnel: 'Poetic, suggestive',
      exemples: ['Mallarm\u00e9', 'Val\u00e9ry', 'Claudel'],
      icon: Icons.auto_awesome,
      color: Color(0xFF6366F1),
      type: ApproachType.literary,
    ),

    // ========================================
    // 📚 AJOUTS POUR SYNCHRONISATION ÉCRANS
    // ========================================

    ApproachConfig(
      key: 'naturalisme',
      name: 'Naturalism',
      description: 'Humanity determined by environment and heredity',
      credo: 'Understanding the forces that shape us to better overcome them',
      tonEmotionnel: 'Scientific, lucid',
      exemples: ['Zola', 'Les Rougon-Macquart', 'Germinal'],
      icon: Icons.biotech,
      color: Color(0xFF78716C),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'symbolisme',
      name: 'Symbolism',
      description: 'The visible world as a reflection of a spiritual reality',
      credo: 'Every thing is a sign pointing to the invisible',
      tonEmotionnel: 'Mysterious, suggestive',
      exemples: ['Baudelaire', 'Mallarm\u00e9', 'Verlaine'],
      icon: Icons.blur_on,
      color: Color(0xFF6366F1),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'surrealisme',
      name: 'Surrealism',
      description: 'Liberation of the unconscious and psychic automatism',
      credo: 'The imaginary is what tends to become real',
      tonEmotionnel: 'Dreamlike, liberated',
      exemples: ['Breton', '\u00c9luard', 'Desnos'],
      icon: Icons.psychology,
      color: Color(0xFFD946EF),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'modernisme',
      name: 'Modernism',
      description: 'Breaking with tradition and formal experimentation',
      credo: 'One must be absolutely modern',
      tonEmotionnel: 'Innovative, bold',
      exemples: ['Proust', 'Joyce', 'Woolf'],
      icon: Icons.architecture,
      color: Color(0xFF0EA5E9),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'postmodernisme',
      name: 'Postmodernism',
      description: 'Deconstruction of grand narratives and playing with conventions',
      credo: 'Every truth is a construction',
      tonEmotionnel: 'Ironic, playful',
      exemples: ['Borges', 'Calvino', 'Perec'],
      icon: Icons.layers,
      color: Color(0xFFF43F5E),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'tragedie_classique',
      name: 'Classical Tragedy',
      description: 'Fate, destiny, and greatness in downfall',
      credo: 'True greatness reveals itself in adversity',
      tonEmotionnel: 'Noble, fatalistic',
      exemples: ['Racine', 'Corneille', 'Sophocles'],
      icon: Icons.theater_comedy,
      color: Color(0xFF7C2D12),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'roman_psychologique',
      name: 'Psychological Novel',
      description: 'Exploration of the depths of the human soul',
      credo: 'Understanding others means understanding yourself',
      tonEmotionnel: 'Introspective, nuanced',
      exemples: ['Dostoevsky', 'Proust', 'Henry James'],
      icon: Icons.psychology_alt,
      color: Color(0xFF7C3AED),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'mythologie',
      name: 'Mythology',
      description: 'Founding narratives and universal archetypes',
      credo: 'Myths are eternal truths in the form of stories',
      tonEmotionnel: 'Epic, symbolic',
      exemples: ['Homer', 'Ovid', 'Greek Myths'],
      icon: Icons.auto_awesome_motion,
      color: Color(0xFFF59E0B),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'science_fiction',
      name: 'Science Fiction',
      description: 'Exploring possible futures and questioning what it means to be human',
      credo: 'Imagining tomorrow to better understand today',
      tonEmotionnel: 'Visionary, questioning',
      exemples: ['Asimov', 'Philip K. Dick', 'Ursula Le Guin'],
      icon: Icons.rocket_launch,
      color: Color(0xFF0891B2),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'fantasy',
      name: 'Fantasy',
      description: 'Imaginary worlds and initiatory quests',
      credo: 'The imaginary reveals truths that reality cannot express',
      tonEmotionnel: 'Wondrous, epic',
      exemples: ['Tolkien', 'Ursula Le Guin', 'Robin Hobb'],
      icon: Icons.castle,
      color: Color(0xFF059669),
      type: ApproachType.literary,
    ),

    // ========================================
    // 📖 INDIVIDUAL AUTHORS
    // ========================================
    ApproachConfig(
      key: 'kafka',
      name: 'Franz Kafka',
      description: 'The absurdity of the system — the individual crushed by incomprehensible forces',
      credo: 'This situation escapes your logic? Perhaps it is the one revealing you',
      tonEmotionnel: 'Anguished, lucid, vertiginous',
      exemples: ['Josef K. (The Trial)', 'Gregor Samsa (The Metamorphosis)', 'K. (The Castle)', 'Karl Rossmann (Amerika)'],
      icon: Icons.menu_book,
      color: Color(0xFF1F2937),
      type: ApproachType.literary,
    ),

    ApproachConfig(
      key: 'dostoievski',
      name: 'Fyodor Dostoevsky',
      description: 'The abysses of the human soul — inner torment, redemption through suffering',
      credo: 'Descend into the depths of yourself — that is where the light begins',
      tonEmotionnel: 'Tormented, profound, redemptive',
      exemples: ['Raskolnikov (Crime and Punishment)', 'Myshkin (The Idiot)', 'Ivan Karamazov (The Brothers Karamazov)', 'The Underground Man'],
      icon: Icons.menu_book,
      color: Color(0xFF7C2D12),
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
      description: 'Therapy based on acceptance and values-aligned action',
      credo: 'Accept what is, act according to your values',
      tonEmotionnel: 'Pragmatic, caring',
      exemples: ['Steven Hayes', 'Cognitive Defusion'],
      icon: Icons.check_circle_outline,
      color: Color(0xFF10B981),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'tcc',
      name: 'CBT (Cognitive Behavioral Therapy)',
      description: 'Modifying limiting thoughts and behaviors',
      credo: 'What automatic thought is holding you back?',
      tonEmotionnel: 'Pragmatic, structured',
      exemples: ['Aaron Beck', 'Automatic Thoughts'],
      icon: Icons.psychology_outlined,
      color: Color(0xFF3B82F6),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'jungienne',
      name: 'Jungian Psychology',
      description: 'Exploration of the unconscious and universal symbols',
      credo: 'What archetype or symbol speaks through this situation?',
      tonEmotionnel: 'Deep, symbolic',
      exemples: ['Carl Jung', 'Archetypes', 'Collective Unconscious'],
      icon: Icons.psychology,
      color: Color(0xFF7C3AED),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'logotherapie',
      name: 'Logotherapy (Frankl)',
      description: 'The quest for meaning in every trial',
      credo: 'What meaning can you find in this situation?',
      tonEmotionnel: 'Existential, resilient',
      exemples: ['Viktor Frankl', 'Meaning of Life'],
      icon: Icons.lightbulb_outline,
      color: Color(0xFF059669),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'schemas_young',
      name: 'Schema Therapy (Young)',
      description: 'Identifying and transforming early emotional schemas',
      credo: 'What childhood pattern is repeating here?',
      tonEmotionnel: 'Analytical, structured',
      exemples: ['Jeffrey Young', 'Early Maladaptive Schemas'],
      icon: Icons.account_tree,
      color: Color(0xFF6366F1),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'the_work',
      name: 'The Work (Byron Katie)',
      description: 'Questioning stressful thoughts',
      credo: 'Is it true? Who would you be without that thought?',
      tonEmotionnel: 'Neutral, investigative',
      exemples: ['Byron Katie', '4 Questions + Turnaround'],
      icon: Icons.help_center,
      color: Color(0xFF8B5CF6),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'humaniste_rogers',
      name: 'Humanistic Approach (Rogers)',
      description: 'Unconditional acceptance and inner potential',
      credo: 'You have the resources within you to grow',
      tonEmotionnel: 'Caring, encouraging',
      exemples: ['Carl Rogers', 'Person-Centered Approach'],
      icon: Icons.favorite,
      color: Color(0xFFEC4899),
      type: ApproachType.psychological,
    ),

    // ========================================
    // 🧠 AJOUTS POUR SYNCHRONISATION ÉCRANS
    // ========================================

    ApproachConfig(
      key: 'psychanalyse',
      name: 'Psychoanalysis',
      description: 'Exploration of the unconscious and repressed conflicts',
      credo: 'What is repressed always resurfaces',
      tonEmotionnel: 'Deep, analytical',
      exemples: ['Freud', 'Lacan', 'Interpretation of Dreams'],
      icon: Icons.psychology,
      color: Color(0xFF1E40AF),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'analyse_transactionnelle',
      name: 'Transactional Analysis',
      description: 'Understanding ego states and relational dynamics',
      credo: 'Which ego state (Parent, Adult, Child) is speaking in you?',
      tonEmotionnel: 'Structured, relational',
      exemples: ['Eric Berne', 'Ego States', 'Psychological Games'],
      icon: Icons.people_outline,
      color: Color(0xFFF59E0B),
      type: ApproachType.psychological,
    ),

    ApproachConfig(
      key: 'systemique',
      name: 'Systemic Approach',
      description: 'The individual within their system of relationships',
      credo: 'Changing one part means changing the whole',
      tonEmotionnel: 'Contextual, holistic',
      exemples: ['Palo Alto', 'Family Therapy', 'Bateson'],
      icon: Icons.hub,
      color: Color(0xFF06B6D4),
      type: ApproachType.psychological,
    ),
  ];

  // ========================================
  // 🏛️ COURANTS PHILOSOPHIQUES
  // ========================================
  static const List<ApproachConfig> philosophical = [
    // AJOUT: stoicisme (sans _philo) pour matcher l'écran
    ApproachConfig(
      key: 'stoicisme',
      name: 'Stoicism',
      description: 'Self-mastery and acceptance of fate',
      credo: 'Distinguish what depends on you from what does not',
      tonEmotionnel: 'Serene, rational',
      exemples: ['Marcus Aurelius', 'Epictetus', 'Seneca'],
      icon: Icons.shield,
      color: Color(0xFF6B7280),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'stoicisme_philo',
      name: 'Stoicism',
      description: 'Self-mastery and acceptance of fate',
      credo: 'Distinguish what depends on you from what does not',
      tonEmotionnel: 'Serene, rational',
      exemples: ['Marcus Aurelius', 'Epictetus', 'Seneca'],
      icon: Icons.shield,
      color: Color(0xFF6B7280),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'epicurisme',
      name: 'Epicureanism',
      description: 'Seeking happiness through the moderation of desires',
      credo: 'Pleasure is the highest good, but the wise know how to moderate it',
      tonEmotionnel: 'Peaceful, measured',
      exemples: ['Epicurus', 'Lucretius'],
      icon: Icons.spa,
      color: Color(0xFF10B981),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'existentialisme_philo',
      name: 'Existentialism',
      description: 'Existence precedes essence',
      credo: 'You are condemned to be free — embrace your responsibility',
      tonEmotionnel: 'Lucid, committed',
      exemples: ['Sartre', 'Heidegger', 'Kierkegaard'],
      icon: Icons.person_outline,
      color: Color(0xFF374151),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'phenomenologie',
      name: 'Phenomenology',
      description: 'Returning to the things themselves, to lived experience',
      credo: 'How are you truly experiencing this?',
      tonEmotionnel: 'Attentive, descriptive',
      exemples: ['Husserl', 'Merleau-Ponty'],
      icon: Icons.visibility,
      color: Color(0xFF8B5CF6),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'absurdisme_philo',
      name: 'Absurdism',
      description: 'Facing the absurd with revolt and creation',
      credo: 'One must imagine Sisyphus happy',
      tonEmotionnel: 'Lucid, rebellious',
      exemples: ['Camus', 'The Myth of Sisyphus'],
      icon: Icons.terrain,
      color: Color(0xFF4B5563),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'rationalisme',
      name: 'Rationalism',
      description: 'Reason as the source of knowledge',
      credo: 'Think clearly, distinguish truth from falsehood',
      tonEmotionnel: 'Methodical, clear',
      exemples: ['Descartes', 'Spinoza', 'Leibniz'],
      icon: Icons.lightbulb,
      color: Color(0xFF3B82F6),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'empirisme',
      name: 'Empiricism',
      description: 'Experience as the source of knowledge',
      credo: 'What does this experience concretely teach you?',
      tonEmotionnel: 'Pragmatic, observant',
      exemples: ['Hume', 'Locke', 'Berkeley'],
      icon: Icons.science,
      color: Color(0xFF059669),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'idealisme',
      name: 'Idealism',
      description: 'Reality is fundamentally spiritual',
      credo: 'The world is a manifestation of the mind',
      tonEmotionnel: 'Elevated, contemplative',
      exemples: ['Plato', 'Hegel', 'Kant'],
      icon: Icons.cloud,
      color: Color(0xFF6366F1),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'pragmatisme',
      name: 'Pragmatism',
      description: 'Truth is measured by its practical effects',
      credo: 'What concretely works?',
      tonEmotionnel: 'Practical, action-oriented',
      exemples: ['William James', 'John Dewey'],
      icon: Icons.build,
      color: Color(0xFFF59E0B),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'vitalisme',
      name: 'Vitalism',
      description: 'Life as a fundamental creative force',
      credo: 'Affirm your vital power',
      tonEmotionnel: 'Energetic, creative',
      exemples: ['Bergson', 'Nietzsche'],
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'humanisme_philo',
      name: 'Philosophical Humanism',
      description: 'Humanity as the supreme value',
      credo: 'Every human being has inviolable dignity',
      tonEmotionnel: 'Caring, universal',
      exemples: ['Montaigne', 'Erasmus', 'Renaissance'],
      icon: Icons.people,
      color: Color(0xFFEC4899),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'utilitarisme',
      name: 'Utilitarianism',
      description: 'Maximizing happiness for the greatest number',
      credo: 'Which action produces the most good?',
      tonEmotionnel: 'Calculative, benevolent',
      exemples: ['Bentham', 'Mill'],
      icon: Icons.calculate,
      color: Color(0xFF06B6D4),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'structuralisme',
      name: 'Structuralism',
      description: 'Underlying structures determine meaning',
      credo: 'What invisible structures are shaping your situation?',
      tonEmotionnel: 'Analytical, systemic',
      exemples: ['L\u00e9vi-Strauss', 'Foucault'],
      icon: Icons.account_tree,
      color: Color(0xFF7C3AED),
      type: ApproachType.philosophical,
    ),

    ApproachConfig(
      key: 'philosophies_orientales',
      name: 'Eastern Philosophies',
      description: 'Wisdom of harmony and balance',
      credo: 'Find the balance between opposites',
      tonEmotionnel: 'Balanced, harmonious',
      exemples: ['Taoism', 'Confucianism', 'Zen'],
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
      name: 'Socrates',
      description: 'Maieutics and self-knowledge',
      credo: 'Know thyself',
      tonEmotionnel: 'Questioning, humble',
      exemples: ['Platonic Dialogues', 'Socratic Irony'],
      icon: Icons.help_outline,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'platon',
      name: 'Plato',
      description: 'The world of Ideas and the quest for truth',
      credo: 'Beyond appearances, seek the essence',
      tonEmotionnel: 'Elevated, contemplative',
      exemples: ['The Republic', 'Allegory of the Cave'],
      icon: Icons.lightbulb,
      color: Color(0xFF3B82F6),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'aristote',
      name: 'Aristotle',
      description: 'Virtue ethics and the golden mean',
      credo: 'Virtue is a balance between extremes',
      tonEmotionnel: 'Measured, practical',
      exemples: ['Nicomachean Ethics', 'Cardinal Virtues'],
      icon: Icons.balance,
      color: Color(0xFF059669),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'epicure',
      name: 'Epicurus',
      description: 'Wise pleasure and ataraxia',
      credo: 'Happiness lies in simplicity',
      tonEmotionnel: 'Peaceful, serene',
      exemples: ['Letter to Menoeceus', 'Garden of Epicurus'],
      icon: Icons.spa,
      color: Color(0xFF10B981),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'seneque',
      name: 'Seneca',
      description: 'Applied Stoic wisdom',
      credo: 'Live each day as if it were your last',
      tonEmotionnel: 'Wise, pragmatic',
      exemples: ['Letters to Lucilius', 'On the Shortness of Life'],
      icon: Icons.edit_note,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'epictete',
      name: 'Epictetus',
      description: 'Inner freedom despite constraints',
      credo: 'What depends on us, and what does not',
      tonEmotionnel: 'Stoic, firm',
      exemples: ['Enchiridion', 'Discourses'],
      icon: Icons.link_off,
      color: Color(0xFF4B5563),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'marc_aurele',
      name: 'Marcus Aurelius',
      description: 'Daily Stoic meditation',
      credo: 'Let your thoughts be your refuge',
      tonEmotionnel: 'Meditative, disciplined',
      exemples: ['Meditations'],
      icon: Icons.self_improvement,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'spinoza',
      name: 'Spinoza',
      description: 'God-Nature and the joy of understanding',
      credo: 'To understand is to be free',
      tonEmotionnel: 'Serene, luminous',
      exemples: ['Ethics', 'Single Substance'],
      icon: Icons.all_inclusive,
      color: Color(0xFF8B5CF6),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'kant',
      name: 'Kant',
      description: 'Moral duty and the categorical imperative',
      credo: 'Act as if your maxim should become a universal law',
      tonEmotionnel: 'Rigorous, moral',
      exemples: ['Critique of Pure Reason', 'Groundwork of the Metaphysics of Morals'],
      icon: Icons.gavel,
      color: Color(0xFF1E40AF),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'nietzsche',
      name: 'Nietzsche',
      description: 'The will to power and self-overcoming',
      credo: 'Become who you are',
      tonEmotionnel: 'Intense, provocative',
      exemples: ['Thus Spoke Zarathustra', '\u00dcbermensch'],
      icon: Icons.bolt,
      color: Color(0xFFDC2626),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'kierkegaard',
      name: 'Kierkegaard',
      description: 'Anxiety and the leap of faith',
      credo: 'Existence precedes essence',
      tonEmotionnel: 'Anxious, authentic',
      exemples: ['The Concept of Anxiety', 'Stages of Existence'],
      icon: Icons.trending_up,
      color: Color(0xFF7C3AED),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'sartre',
      name: 'Sartre',
      description: 'Radical freedom and responsibility',
      credo: 'Man is condemned to be free',
      tonEmotionnel: 'Lucid, committed',
      exemples: ['Being and Nothingness', 'Existentialism Is a Humanism'],
      icon: Icons.person_outline,
      color: Color(0xFF374151),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'camus',
      name: 'Camus',
      description: 'The absurd and revolt',
      credo: 'One must imagine Sisyphus happy',
      tonEmotionnel: 'Lucid, rebellious',
      exemples: ['The Myth of Sisyphus', 'The Rebel'],
      icon: Icons.terrain,
      color: Color(0xFF4B5563),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'simone_de_beauvoir',
      name: 'Simone de Beauvoir',
      description: 'Freedom and situation',
      credo: 'One is not born, but rather becomes, a woman',
      tonEmotionnel: 'Committed, feminist',
      exemples: ['The Second Sex', 'The Ethics of Ambiguity'],
      icon: Icons.woman,
      color: Color(0xFFEC4899),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'hannah_arendt',
      name: 'Hannah Arendt',
      description: 'Thought and political action',
      credo: 'Think what we are doing',
      tonEmotionnel: 'Reflective, political',
      exemples: ['The Human Condition', 'Banality of Evil'],
      icon: Icons.public,
      color: Color(0xFF6366F1),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'schopenhauer',
      name: 'Schopenhauer',
      description: 'The will-to-live and suffering',
      credo: 'Life oscillates between suffering and boredom',
      tonEmotionnel: 'Pessimistic, lucid',
      exemples: ['The World as Will and Representation'],
      icon: Icons.nights_stay,
      color: Color(0xFF1F2937),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'montaigne',
      name: 'Montaigne',
      description: 'The essay of the self and modest wisdom',
      credo: 'What do I know?',
      tonEmotionnel: 'Humble, curious',
      exemples: ['Essays', 'Introspection'],
      icon: Icons.menu_book,
      color: Color(0xFF92400E),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'diogene',
      name: 'Diogenes',
      description: 'Cynicism and the return to nature',
      credo: 'Live according to nature, scorn conventions',
      tonEmotionnel: 'Provocative, free',
      exemples: ['Barrel of Diogenes', 'Cynicism'],
      icon: Icons.mood,
      color: Color(0xFFF59E0B),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'confucius',
      name: 'Confucius',
      description: 'Social harmony and virtue',
      credo: 'Cultivate yourself to cultivate others',
      tonEmotionnel: 'Wise, harmonious',
      exemples: ['Analects', 'Ren (humaneness)'],
      icon: Icons.people,
      color: Color(0xFFDC2626),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'rousseau',
      name: 'Rousseau',
      description: 'The noble savage and the social contract',
      credo: 'Man is born good; society corrupts him',
      tonEmotionnel: 'Sensitive, natural',
      exemples: ['The Social Contract', 'Emile'],
      icon: Icons.nature_people,
      color: Color(0xFF059669),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'hume',
      name: 'Hume',
      description: 'Skepticism and empiricism',
      credo: 'Experience is the only source of knowledge',
      tonEmotionnel: 'Skeptical, measured',
      exemples: ['A Treatise of Human Nature', 'Empiricism'],
      icon: Icons.science,
      color: Color(0xFF6B7280),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'foucault',
      name: 'Foucault',
      description: 'Power and norms',
      credo: 'Question the obvious and the norms',
      tonEmotionnel: 'Critical, subversive',
      exemples: ['Discipline and Punish', 'Madness and Civilization'],
      icon: Icons.visibility_off,
      color: Color(0xFF7C3AED),
      type: ApproachType.philosopher,
    ),

    ApproachConfig(
      key: 'descartes',
      name: 'Descartes',
      description: 'Methodical doubt and the cogito',
      credo: 'I think, therefore I am',
      tonEmotionnel: 'Methodical, rational',
      exemples: ['Meditations on First Philosophy', 'Discourse on the Method'],
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

// lib/config/orientation_config.dart
import 'package:flutter/material.dart';

/// Configuration complète du quiz d'orientation
/// 14 questions → 56 sources (hors spirituelles)

class OrientationQuestion {
  final String id;
  final String theme;
  final List<OrientationOption> options;

  const OrientationQuestion({
    required this.id,
    required this.theme,
    required this.options,
  });
}

class OrientationOption {
  final String id;
  final String label;
  final String imagePath;
  final Map<String, int> sourceScores; // source_id → points

  const OrientationOption({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.sourceScores,
  });
}

class OrientationConfig {
  // ========================================
  // 📋 LES 14 QUESTIONS
  // ========================================

  static const List<OrientationQuestion> questions = [
    // ----------------------------------------
    // Q1 - MONDE INTÉRIEUR
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q1',
      theme: 'Your inner world',
      options: [
        OrientationOption(
          id: 'serenite',
          label: 'SERENITY',
          imagePath: 'assets/univers_visuel/orientation/Q1serenite.png',
          sourceScores: {
            // Philosophes
            'marc_aurele': 3,
            'epictete': 3,
            'seneque': 2,
            'epicure': 2,
            // Courants philo
            'stoicisme': 3,
            'epicurisme': 2,
            // Littéraires
            'naturalisme': 1,
            // Psycho
            'act': 2,
            'pleine_conscience': 2,
          },
        ),
        OrientationOption(
          id: 'intensite',
          label: 'INTENSITY',
          imagePath: 'assets/univers_visuel/orientation/Q1intensite.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 3,
            'kierkegaard': 2,
            'schopenhauer': 1,
            // Courants philo
            'vitalisme': 3,
            'existentialisme_philo': 2,
            // Littéraires
            'romantisme': 3,
            'symbolisme': 2,
            // Psycho
            'jungienne': 2,
          },
        ),
        OrientationOption(
          id: 'aspiration',
          label: 'ASPIRATION',
          imagePath: 'assets/univers_visuel/orientation/Q1aspiration.png',
          sourceScores: {
            // Philosophes
            'platon': 3,
            'aristote': 2,
            'spinoza': 2,
            // Courants philo
            'idealisme': 3,
            'humanisme_philo': 2,
            // Littéraires
            'humanisme': 2,
            'modernisme': 1,
            // Psycho
            'logotherapie': 3,
            'humaniste_rogers': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q2 - ÉNERGIE DOMINANTE
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q2',
      theme: 'Your dominant energy',
      options: [
        OrientationOption(
          id: 'fluide',
          label: 'FLUID',
          imagePath: 'assets/univers_visuel/orientation/Q2fluide.png',
          sourceScores: {
            // Philosophes
            'epicure': 2,
            'spinoza': 2,
            'confucius': 2,
            // Courants philo
            'epicurisme': 2,
            'philosophies_orientales': 3,
            // Littéraires
            'symbolisme': 2,
            'naturalisme': 1,
            // Psycho
            'act': 2,
            'systemique': 2,
          },
        ),
        OrientationOption(
          id: 'structuree',
          label: 'STRUCTURED',
          imagePath: 'assets/univers_visuel/orientation/Q2structuree.png',
          sourceScores: {
            // Philosophes
            'kant': 3,
            'aristote': 2,
            'descartes': 2,
            // Courants philo
            'rationalisme': 3,
            'structuralisme': 2,
            // Littéraires
            'realisme': 2,
            'tragedie_classique': 2,
            // Psycho
            'tcc': 3,
            'analyse_transactionnelle': 2,
          },
        ),
        OrientationOption(
          id: 'dispersee',
          label: 'SCATTERED',
          imagePath: 'assets/univers_visuel/orientation/Q2dispersee.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 2,
            'diogene': 2,
            // Courants philo
            'absurdisme_philo': 2,
            // Littéraires
            'surrealisme': 3,
            'postmodernisme': 3,
            'modernisme': 2,
            // Psycho
            'jungienne': 2,
            'psychanalyse': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q3 - QUAND TU DOUTES
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q3',
      theme: 'When you doubt',
      options: [
        OrientationOption(
          id: 'recentre',
          label: 'REFOCUSED',
          imagePath: 'assets/univers_visuel/orientation/Q3recentre.png',
          sourceScores: {
            // Philosophes
            'marc_aurele': 3,
            'epictete': 2,
            'socrate': 2,
            // Courants philo
            'stoicisme': 3,
            // Littéraires
            'realisme': 1,
            // Psycho
            'act': 2,
            'the_work': 2,
            'tcc': 2,
          },
        ),
        OrientationOption(
          id: 'exploration',
          label: 'EXPLORATION',
          imagePath: 'assets/univers_visuel/orientation/Q3exploration.png',
          sourceScores: {
            // Philosophes
            'sartre': 2,
            'camus': 2,
            'kierkegaard': 2,
            // Courants philo
            'existentialisme_philo': 3,
            'phenomenologie': 2,
            // Littéraires
            'existentialisme': 3,
            'roman_psychologique': 2,
            // Psycho
            'jungienne': 2,
            'psychanalyse': 2,
          },
        ),
        OrientationOption(
          id: 'observation',
          label: 'OBSERVATION',
          imagePath: 'assets/univers_visuel/orientation/Q3observation.png',
          sourceScores: {
            // Philosophes
            'aristote': 2,
            'spinoza': 2,
            'hume': 2,
            // Courants philo
            'phenomenologie': 3,
            'empirisme': 3,
            // Littéraires
            'naturalisme': 2,
            'realisme': 2,
            // Psycho
            'tcc': 2,
            'systemique': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q4 - STYLE DE PENSÉE
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q4',
      theme: 'Your thinking style',
      options: [
        OrientationOption(
          id: 'geometrique',
          label: 'GEOMETRIC',
          imagePath: 'assets/univers_visuel/orientation/Q4geometrique.png',
          sourceScores: {
            // Philosophes
            'kant': 3,
            'spinoza': 2,
            'aristote': 2,
            // Courants philo
            'rationalisme': 3,
            'structuralisme': 2,
            // Littéraires
            'realisme': 2,
            // Psycho
            'tcc': 3,
            'analyse_transactionnelle': 2,
          },
        ),
        OrientationOption(
          id: 'naturel',
          label: 'NATURAL',
          imagePath: 'assets/univers_visuel/orientation/Q4naturel.png',
          sourceScores: {
            // Philosophes
            'epicure': 2,
            'rousseau': 2,
            'diogene': 2,
            // Courants philo
            'epicurisme': 2,
            'vitalisme': 2,
            // Littéraires
            'naturalisme': 3,
            'romantisme': 2,
            // Psycho
            'humaniste_rogers': 2,
            'systemique': 1,
          },
        ),
        OrientationOption(
          id: 'deforme',
          label: 'DISTORTED',
          imagePath: 'assets/univers_visuel/orientation/Q4deforme.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 2,
            'foucault': 2,
            // Courants philo
            'absurdisme_philo': 2,
            // Littéraires
            'surrealisme': 3,
            'symbolisme': 2,
            'postmodernisme': 2,
            // Psycho
            'jungienne': 3,
            'psychanalyse': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q5 - RAPPORT AUX AUTRES
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q5',
      theme: 'Your relationship with others',
      options: [
        OrientationOption(
          id: 'humanisme',
          label: 'HUMANISM',
          imagePath: 'assets/univers_visuel/orientation/Q5humanisme.png',
          sourceScores: {
            // Philosophes
            'confucius': 3,
            'aristote': 2,
            'montaigne': 2,
            'hannah_arendt': 2,
            // Courants philo
            'humanisme_philo': 3,
            // Littéraires
            'humanisme': 3,
            // Psycho
            'humaniste_rogers': 3,
            'systemique': 2,
            'analyse_transactionnelle': 2,
          },
        ),
        OrientationOption(
          id: 'seule',
          label: 'ALONE',
          imagePath: 'assets/univers_visuel/orientation/Q5seule.png',
          sourceScores: {
            // Philosophes
            'sartre': 3,
            'kierkegaard': 3,
            'schopenhauer': 2,
            'camus': 2,
            // Courants philo
            'existentialisme_philo': 3,
            // Littéraires
            'existentialisme': 3,
            'roman_psychologique': 2,
            // Psycho
            'psychanalyse': 2,
            'logotherapie': 2,
          },
        ),
        OrientationOption(
          id: 'cynisme',
          label: 'CYNICISM',
          imagePath: 'assets/univers_visuel/orientation/Q5Cynisme.png',
          sourceScores: {
            // Philosophes
            'diogene': 3,
            'nietzsche': 2,
            // Courants philo
            'absurdisme_philo': 2,
            // Littéraires
            'absurdisme': 3,
            'postmodernisme': 2,
            // Psycho
            'the_work': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q6 - RAPPORT AUX ÉMOTIONS
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q6',
      theme: 'Your relationship with emotions',
      options: [
        OrientationOption(
          id: 'pulsation',
          label: 'GENTLE PULSE',
          imagePath: 'assets/univers_visuel/orientation/Q6pulsationdouce.png',
          sourceScores: {
            // Philosophes
            'spinoza': 2,
            'epicure': 2,
            // Courants philo
            'epicurisme': 2,
            'vitalisme': 2,
            // Littéraires
            'romantisme': 3,
            'symbolisme': 2,
            // Psycho
            'humaniste_rogers': 2,
            'jungienne': 2,
          },
        ),
        OrientationOption(
          id: 'mecanique',
          label: 'MECHANICAL',
          imagePath: 'assets/univers_visuel/orientation/Q6mecanique.png',
          sourceScores: {
            // Philosophes
            'kant': 2,
            'aristote': 2,
            // Courants philo
            'rationalisme': 2,
            'structuralisme': 2,
            // Littéraires
            'realisme': 2,
            'naturalisme': 2,
            // Psycho
            'tcc': 3,
            'analyse_transactionnelle': 2,
          },
        ),
        OrientationOption(
          id: 'resistance',
          label: 'RESISTANCE',
          imagePath: 'assets/univers_visuel/orientation/Q6resistance.png',
          sourceScores: {
            // Philosophes
            'epictete': 3,
            'marc_aurele': 2,
            'seneque': 2,
            'camus': 2,
            // Courants philo
            'stoicisme': 3,
            // Littéraires
            'absurdisme': 2,
            // Psycho
            'act': 3,
            'the_work': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q7 - STYLE ARTISTIQUE
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q7',
      theme: 'The style that speaks to you',
      options: [
        OrientationOption(
          id: 'symbolisme',
          label: 'SYMBOLISM',
          imagePath: 'assets/univers_visuel/orientation/Q7symbolisme.png',
          sourceScores: {
            // Philosophes
            'platon': 2,
            // Courants philo
            'idealisme': 2,
            // Littéraires
            'symbolisme': 3,
            'romantisme': 2,
            'mythologie': 2,
            // Psycho
            'jungienne': 3,
          },
        ),
        OrientationOption(
          id: 'surrealisme',
          label: 'SURREALISM',
          imagePath: 'assets/univers_visuel/orientation/Q7surrealisme.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 1,
            // Courants philo
            'absurdisme_philo': 2,
            // Littéraires
            'surrealisme': 3,
            'postmodernisme': 2,
            'fantasy': 2,
            // Psycho
            'psychanalyse': 3,
            'jungienne': 2,
          },
        ),
        OrientationOption(
          id: 'classicisme',
          label: 'CLASSICISM',
          imagePath: 'assets/univers_visuel/orientation/Q7classicisme.png',
          sourceScores: {
            // Philosophes
            'aristote': 2,
            'platon': 2,
            'kant': 2,
            // Courants philo
            'rationalisme': 2,
            // Littéraires
            'tragedie_classique': 3,
            'realisme': 2,
            // Psycho
            'tcc': 1,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q8 - COMPRÉHENSION DU MONDE
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q8',
      theme: 'How you understand the world',
      options: [
        OrientationOption(
          id: 'harmonie',
          label: 'HARMONY',
          imagePath: 'assets/univers_visuel/orientation/Q8harmonie.png',
          sourceScores: {
            // Philosophes
            'confucius': 3,
            'spinoza': 2,
            'aristote': 2,
            // Courants philo
            'philosophies_orientales': 3,
            // Littéraires
            'humanisme': 2,
            // Psycho
            'systemique': 3,
            'humaniste_rogers': 2,
          },
        ),
        OrientationOption(
          id: 'questionnement',
          label: 'QUESTIONING',
          imagePath: 'assets/univers_visuel/orientation/Q8questionnement.png',
          sourceScores: {
            // Philosophes
            'platon': 3,
            'descartes': 2,
            // Courants philo
            'idealisme': 3,
            'rationalisme': 2,
            // Littéraires
            'symbolisme': 2,
            'modernisme': 1,
            // Psycho
            'logotherapie': 2,
          },
        ),
        OrientationOption(
          id: 'pluralite',
          label: 'PLURALITY',
          imagePath: 'assets/univers_visuel/orientation/Q8pluralite.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 2,
            'foucault': 2,
            // Courants philo
            'phenomenologie': 2,
            // Littéraires
            'postmodernisme': 3,
            'modernisme': 2,
            // Psycho
            'jungienne': 2,
            'systemique': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q9 - MODE DE COMPRÉHENSION
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q9',
      theme: 'How you understand things',
      options: [
        OrientationOption(
          id: 'deduction',
          label: 'DEDUCTION',
          imagePath: 'assets/univers_visuel/orientation/Q9deduction.png',
          sourceScores: {
            // Philosophes
            'aristote': 3,
            'kant': 2,
            'spinoza': 2,
            // Courants philo
            'rationalisme': 3,
            'empirisme': 2,
            // Littéraires
            'realisme': 2,
            // Psycho
            'tcc': 3,
          },
        ),
        OrientationOption(
          id: 'ressenti',
          label: 'FEELING',
          imagePath: 'assets/univers_visuel/orientation/Q9ressenti.png',
          sourceScores: {
            // Philosophes
            'rousseau': 2,
            'kierkegaard': 2,
            // Courants philo
            'phenomenologie': 2,
            'vitalisme': 2,
            // Littéraires
            'romantisme': 3,
            'roman_psychologique': 3,
            // Psycho
            'jungienne': 3,
            'humaniste_rogers': 2,
            'psychanalyse': 2,
          },
        ),
        OrientationOption(
          id: 'holistique',
          label: 'HOLISTIC',
          imagePath: 'assets/univers_visuel/orientation/Q9holistique.png',
          sourceScores: {
            // Philosophes
            'spinoza': 2,
            'confucius': 2,
            // Courants philo
            'structuralisme': 2,
            'philosophies_orientales': 2,
            // Littéraires
            'mythologie': 2,
            // Psycho
            'systemique': 3,
            'jungienne': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q10 - RELATION AU TEMPS
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q10',
      theme: 'Your relationship with time',
      options: [
        OrientationOption(
          id: 'analyse',
          label: 'ANALYSIS',
          imagePath: 'assets/univers_visuel/orientation/Q10analyse.png',
          sourceScores: {
            // Philosophes
            'aristote': 2,
            'kant': 2,
            // Courants philo
            'rationalisme': 2,
            'structuralisme': 2,
            // Littéraires
            'realisme': 2,
            'roman_psychologique': 2,
            // Psycho
            'psychanalyse': 3,
            'schemas_young': 3,
          },
        ),
        OrientationOption(
          id: 'connexion',
          label: 'SENSITIVE CONNECTION',
          imagePath: 'assets/univers_visuel/orientation/Q10connexionsensible.png',
          sourceScores: {
            // Philosophes
            'epicure': 2,
            'montaigne': 2,
            // Courants philo
            'epicurisme': 2,
            'phenomenologie': 2,
            // Littéraires
            'romantisme': 2,
            'symbolisme': 2,
            // Psycho
            'act': 2,
            'humaniste_rogers': 2,
          },
        ),
        OrientationOption(
          id: 'verite_brute',
          label: 'RAW TRUTH',
          imagePath: 'assets/univers_visuel/orientation/Q10veritebrute.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 2,
            'camus': 2,
            'schopenhauer': 2,
            // Courants philo
            'existentialisme_philo': 2,
            'absurdisme_philo': 2,
            // Littéraires
            'absurdisme': 2,
            'existentialisme': 2,
            // Psycho
            'the_work': 3,
            'logotherapie': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q11 - FACE À UNE PENSÉE SOUFFRANTE (NOUVELLE)
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q11',
      theme: 'Facing a thought that makes you suffer',
      options: [
        OrientationOption(
          id: 'questionner',
          label: 'QUESTION',
          imagePath: 'assets/univers_visuel/orientation/Q11questionner.png',
          sourceScores: {
            // Philosophes
            'socrate': 3,
            // Courants philo
            'rationalisme': 1,
            // Littéraires
            // (pas de lien direct)
            // Psycho
            'the_work': 3,
            'tcc': 3,
          },
        ),
        OrientationOption(
          id: 'origine',
          label: 'ORIGIN',
          imagePath: 'assets/univers_visuel/orientation/Q11origine.png',
          sourceScores: {
            // Philosophes
            'freud_influence': 1,
            // Courants philo
            'phenomenologie': 1,
            // Littéraires
            'roman_psychologique': 3,
            // Psycho
            'schemas_young': 3,
            'psychanalyse': 3,
          },
        ),
        OrientationOption(
          id: 'qui_parle',
          label: 'WHO SPEAKS',
          imagePath: 'assets/univers_visuel/orientation/Q11quisparle.png',
          sourceScores: {
            // Philosophes
            // (pas de lien direct)
            // Courants philo
            'structuralisme': 1,
            // Littéraires
            'postmodernisme': 1,
            // Psycho
            'analyse_transactionnelle': 3,
            'jungienne': 2,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q12 - HISTOIRES QUI CAPTIVENT (NOUVELLE)
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q12',
      theme: 'The type of stories that captivate you',
      options: [
        OrientationOption(
          id: 'quete',
          label: 'EPIC QUESTS',
          imagePath: 'assets/univers_visuel/orientation/Q12quete.png',
          sourceScores: {
            // Philosophes
            'platon': 1,
            // Courants philo
            'idealisme': 1,
            // Littéraires
            'fantasy': 3,
            'mythologie': 3,
            // Psycho
            'jungienne': 2,
            'logotherapie': 1,
          },
        ),
        OrientationOption(
          id: 'futur',
          label: 'POSSIBLE FUTURES',
          imagePath: 'assets/univers_visuel/orientation/Q12futur.png',
          sourceScores: {
            // Philosophes
            'hannah_arendt': 1,
            // Courants philo
            'pragmatisme': 2,
            'utilitarisme': 1,
            // Littéraires
            'science_fiction': 3,
            'modernisme': 2,
            // Psycho
            'systemique': 1,
          },
        ),
        OrientationOption(
          id: 'miroirs',
          label: 'MIRROR GAMES',
          imagePath: 'assets/univers_visuel/orientation/Q12miroirs.png',
          sourceScores: {
            // Philosophes
            'foucault': 2,
            'nietzsche': 1,
            // Courants philo
            'structuralisme': 2,
            // Littéraires
            'postmodernisme': 3,
            'surrealisme': 2,
            // Psycho
            'psychanalyse': 1,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q13 - DÉFINIR LE BIEN (NOUVELLE)
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q13',
      theme: 'How you decide what is right',
      options: [
        OrientationOption(
          id: 'efficacite',
          label: 'EFFICIENCY',
          imagePath: 'assets/univers_visuel/orientation/Q13efficace.png',
          sourceScores: {
            // Philosophes
            'aristote': 1,
            // Courants philo
            'pragmatisme': 3,
            'utilitarisme': 3,
            // Littéraires
            'realisme': 1,
            // Psycho
            'tcc': 2,
            'act': 1,
          },
        ),
        OrientationOption(
          id: 'systeme',
          label: 'SYSTEM',
          imagePath: 'assets/univers_visuel/orientation/Q13systeme.png',
          sourceScores: {
            // Philosophes
            'foucault': 2,
            'spinoza': 1,
            // Courants philo
            'structuralisme': 3,
            // Littéraires
            'naturalisme': 1,
            // Psycho
            'systemique': 3,
            'analyse_transactionnelle': 1,
          },
        ),
        OrientationOption(
          id: 'harmonie_rel',
          label: 'HARMONY',
          imagePath: 'assets/univers_visuel/orientation/Q13harmonie.png',
          sourceScores: {
            // Philosophes
            'confucius': 3,
            'aristote': 1,
            // Courants philo
            'humanisme_philo': 2,
            'philosophies_orientales': 2,
            // Littéraires
            'humanisme': 2,
            // Psycho
            'humaniste_rogers': 2,
            'systemique': 1,
          },
        ),
      ],
    ),

    // ----------------------------------------
    // Q14 - FACE À L'ANGOISSE (NOUVELLE)
    // ----------------------------------------
    OrientationQuestion(
      id: 'Q14',
      theme: 'Facing existential anguish',
      options: [
        OrientationOption(
          id: 'saut',
          label: 'LEAP',
          imagePath: 'assets/univers_visuel/orientation/Q14saut.png',
          sourceScores: {
            // Philosophes
            'kierkegaard': 3,
            'sartre': 2,
            'simone_de_beauvoir': 2,
            // Courants philo
            'existentialisme_philo': 3,
            // Littéraires
            'existentialisme': 2,
            // Psycho
            'logotherapie': 2,
            'act': 1,
          },
        ),
        OrientationOption(
          id: 'obscurite',
          label: 'DARKNESS',
          imagePath: 'assets/univers_visuel/orientation/Q14obscurite.png',
          sourceScores: {
            // Philosophes
            'schopenhauer': 3,
            'camus': 2,
            // Courants philo
            'absurdisme_philo': 3,
            // Littéraires
            'absurdisme': 3,
            'tragedie_classique': 1,
            // Psycho
            'psychanalyse': 1,
          },
        ),
        OrientationOption(
          id: 'force',
          label: 'STRENGTH',
          imagePath: 'assets/univers_visuel/orientation/Q14force.png',
          sourceScores: {
            // Philosophes
            'nietzsche': 3,
            'marc_aurele': 2,
            'epictete': 1,
            // Courants philo
            'vitalisme': 3,
            'stoicisme': 2,
            // Littéraires
            'romantisme': 1,
            // Psycho
            'logotherapie': 2,
            'act': 2,
          },
        ),
      ],
    ),
  ];

  // ========================================
  // 📊 TOUTES LES SOURCES (pour le calcul)
  // ========================================

  static const Map<String, SourceInfo> allSources = {
    // PHILOSOPHES (17)
    'socrate': SourceInfo(id: 'socrate', name: 'Socrates', category: 'philosophe'),
    'platon': SourceInfo(id: 'platon', name: 'Plato', category: 'philosophe'),
    'aristote': SourceInfo(id: 'aristote', name: 'Aristotle', category: 'philosophe'),
    'epicure': SourceInfo(id: 'epicure', name: 'Epicurus', category: 'philosophe'),
    'seneque': SourceInfo(id: 'seneque', name: 'Seneca', category: 'philosophe'),
    'epictete': SourceInfo(id: 'epictete', name: 'Epictetus', category: 'philosophe'),
    'marc_aurele': SourceInfo(id: 'marc_aurele', name: 'Marcus Aurelius', category: 'philosophe'),
    'spinoza': SourceInfo(id: 'spinoza', name: 'Spinoza', category: 'philosophe'),
    'kant': SourceInfo(id: 'kant', name: 'Kant', category: 'philosophe'),
    'schopenhauer': SourceInfo(id: 'schopenhauer', name: 'Schopenhauer', category: 'philosophe'),
    'nietzsche': SourceInfo(id: 'nietzsche', name: 'Nietzsche', category: 'philosophe'),
    'kierkegaard': SourceInfo(id: 'kierkegaard', name: 'Kierkegaard', category: 'philosophe'),
    'sartre': SourceInfo(id: 'sartre', name: 'Sartre', category: 'philosophe'),
    'simone_de_beauvoir': SourceInfo(id: 'simone_de_beauvoir', name: 'Simone de Beauvoir', category: 'philosophe'),
    'camus': SourceInfo(id: 'camus', name: 'Camus', category: 'philosophe'),
    'hannah_arendt': SourceInfo(id: 'hannah_arendt', name: 'Hannah Arendt', category: 'philosophe'),
    'confucius': SourceInfo(id: 'confucius', name: 'Confucius', category: 'philosophe'),
    'diogene': SourceInfo(id: 'diogene', name: 'Diogenes', category: 'philosophe'),
    'montaigne': SourceInfo(id: 'montaigne', name: 'Montaigne', category: 'philosophe'),
    'rousseau': SourceInfo(id: 'rousseau', name: 'Rousseau', category: 'philosophe'),
    'hume': SourceInfo(id: 'hume', name: 'Hume', category: 'philosophe'),
    'foucault': SourceInfo(id: 'foucault', name: 'Foucault', category: 'philosophe'),
    'descartes': SourceInfo(id: 'descartes', name: 'Descartes', category: 'philosophe'),

    // COURANTS PHILOSOPHIQUES (14)
    'stoicisme': SourceInfo(id: 'stoicisme', name: 'Stoicism', category: 'philosophique'),
    'epicurisme': SourceInfo(id: 'epicurisme', name: 'Epicureanism', category: 'philosophique'),
    'existentialisme_philo': SourceInfo(id: 'existentialisme_philo', name: 'Existentialism', category: 'philosophique'),
    'humanisme_philo': SourceInfo(id: 'humanisme_philo', name: 'Humanism', category: 'philosophique'),
    'vitalisme': SourceInfo(id: 'vitalisme', name: 'Vitalism', category: 'philosophique'),
    'absurdisme_philo': SourceInfo(id: 'absurdisme_philo', name: 'Absurdism', category: 'philosophique'),
    'rationalisme': SourceInfo(id: 'rationalisme', name: 'Rationalism', category: 'philosophique'),
    'empirisme': SourceInfo(id: 'empirisme', name: 'Empiricism', category: 'philosophique'),
    'pragmatisme': SourceInfo(id: 'pragmatisme', name: 'Pragmatism', category: 'philosophique'),
    'phenomenologie': SourceInfo(id: 'phenomenologie', name: 'Phenomenology', category: 'philosophique'),
    'idealisme': SourceInfo(id: 'idealisme', name: 'Idealism', category: 'philosophique'),
    'utilitarisme': SourceInfo(id: 'utilitarisme', name: 'Utilitarianism', category: 'philosophique'),
    'structuralisme': SourceInfo(id: 'structuralisme', name: 'Structuralism', category: 'philosophique'),
    'philosophies_orientales': SourceInfo(id: 'philosophies_orientales', name: 'Eastern Philosophies', category: 'philosophique'),

    // COURANTS LITTÉRAIRES (15)
    'romantisme': SourceInfo(id: 'romantisme', name: 'Romanticism', category: 'litteraire'),
    'realisme': SourceInfo(id: 'realisme', name: 'Realism', category: 'litteraire'),
    'naturalisme': SourceInfo(id: 'naturalisme', name: 'Naturalism', category: 'litteraire'),
    'symbolisme': SourceInfo(id: 'symbolisme', name: 'Symbolism', category: 'litteraire'),
    'surrealisme': SourceInfo(id: 'surrealisme', name: 'Surrealism', category: 'litteraire'),
    'existentialisme': SourceInfo(id: 'existentialisme', name: 'Existentialism', category: 'litteraire'),
    'humanisme': SourceInfo(id: 'humanisme', name: 'Humanism', category: 'litteraire'),
    'absurdisme': SourceInfo(id: 'absurdisme', name: 'Absurdism', category: 'litteraire'),
    'modernisme': SourceInfo(id: 'modernisme', name: 'Modernism', category: 'litteraire'),
    'postmodernisme': SourceInfo(id: 'postmodernisme', name: 'Postmodernism', category: 'litteraire'),
    'tragedie_classique': SourceInfo(id: 'tragedie_classique', name: 'Classical Tragedy', category: 'litteraire'),
    'roman_psychologique': SourceInfo(id: 'roman_psychologique', name: 'Psychological Novel', category: 'litteraire'),
    'mythologie': SourceInfo(id: 'mythologie', name: 'Mythology', category: 'litteraire'),
    'science_fiction': SourceInfo(id: 'science_fiction', name: 'Science Fiction', category: 'litteraire'),
    'fantasy': SourceInfo(id: 'fantasy', name: 'Fantasy', category: 'litteraire'),

    // SOURCES PSYCHOLOGIQUES (10)
    'act': SourceInfo(id: 'act', name: 'ACT', category: 'psychologique'),
    'tcc': SourceInfo(id: 'tcc', name: 'CBT', category: 'psychologique'),
    'jungienne': SourceInfo(id: 'jungienne', name: 'Jungian Psychology', category: 'psychologique'),
    'logotherapie': SourceInfo(id: 'logotherapie', name: 'Logotherapy', category: 'psychologique'),
    'schemas_young': SourceInfo(id: 'schemas_young', name: 'Young Schema Therapy', category: 'psychologique'),
    'the_work': SourceInfo(id: 'the_work', name: 'The Work', category: 'psychologique'),
    'humaniste_rogers': SourceInfo(id: 'humaniste_rogers', name: 'Humanistic Approach', category: 'psychologique'),
    'psychanalyse': SourceInfo(id: 'psychanalyse', name: 'Psychoanalysis', category: 'psychologique'),
    'analyse_transactionnelle': SourceInfo(id: 'analyse_transactionnelle', name: 'Transactional Analysis', category: 'psychologique'),
    'systemique': SourceInfo(id: 'systemique', name: 'Systemic Approach', category: 'psychologique'),
  };
}

class SourceInfo {
  final String id;
  final String name;
  final String category; // 'philosophe', 'philosophique', 'litteraire', 'psychologique'

  const SourceInfo({
    required this.id,
    required this.name,
    required this.category,
  });
}

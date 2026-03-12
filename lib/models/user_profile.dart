import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 4)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String? email;
  
  @HiveField(1)
  final String? password;
  
  // === SECTION A - Identité et contexte ===
  @HiveField(2)
  final int? age;
  
  @HiveField(3)
  final String? situationFamiliale; // Situation familiale et professionnelle
  
  @HiveField(4)
  final String? healthEnergy; // Santé ou niveau d'énergie
  
  @HiveField(5)
  final String? contraintes; // Contraintes matérielles ou logistiques
  
  // === SECTION B - Valeurs et repères ===
  @HiveField(6)
  final String? valeurs; // Valeurs fondamentales
  
  @HiveField(7)
  final String? ressources; // Ressources habituelles pour traverser les difficultés
  
  @HiveField(8)
  final String? contraintesRecurrentes; // Contraintes récurrentes qui limitent
  
  // === SECTION C - Styles d'éclairage préférés ===
  @HiveField(9)
  final List<String> religionsSelectionnees; // Traditions spirituelles
  
  @HiveField(10)
  final List<String> courantsLitteraires; // Courants littéraires préférés
  
  @HiveField(11)
  final List<String> approchesPsychologiques; // Approches psychologiques préférées
  
  @HiveField(12)
  final String? tonalitePrefere; // Tonalité préférée
  
  // === SECTION D - "Ma vie actuellement" ===
  @HiveField(13)
  final String? ouJenSuis; // Où j'en suis aujourd'hui
  
  @HiveField(14)
  final String? ceQuiPese; // Ce qui me pèse ou me fatigue
  
  @HiveField(15)
  final String? ceQuiTient; // Ce qui me tient debout ou me donne envie d'avancer
  
  // === Métadonnées ===
  @HiveField(16)
  final DateTime lastUpdated;
  
  @HiveField(17)
  final bool isCompleted;

  // === NOUVEAU CHAMP POUR LE PROMPT IA ===
  @HiveField(18)
  final String? historique30JoursResume; // Résumé des 30 derniers jours glissants pour contexte IA

  // === CHAMPS ORIENTATION ===
  @HiveField(19)
  final List<String> philosophesSelectionnes; // Philosophes choisis via orientation
  
  @HiveField(20)
  final List<String> courantsPhilosophiques; // Courants philosophiques choisis
  
  @HiveField(21)
  final bool orientationCompleted; // Quiz orientation terminé
  
  @HiveField(22)
  final DateTime? orientationDate; // Date du quiz orientation

  // === ⭐ NOUVEAUX CHAMPS PROFIL SIMPLIFIÉ ===
  @HiveField(23)
  final String? prenom; // Prénom de l'utilisateur
  
  @HiveField(24)
  final DateTime? dateNaissance; // Date de naissance
  
  @HiveField(25)
  final List<String>? valeursSelectionnees; // Liste des clés de valeurs sélectionnées
  
  @HiveField(26)
  final String? valeursLibres; // Valeurs saisies librement

  UserProfile({
    this.email,
    this.password,
    // Section A
    this.age,
    this.situationFamiliale,
    this.healthEnergy,
    this.contraintes,
    // Section B
    this.valeurs,
    this.ressources,
    this.contraintesRecurrentes,
    // Section C
    this.religionsSelectionnees = const [],
    this.courantsLitteraires = const [],
    this.approchesPsychologiques = const [],
    this.tonalitePrefere,
    // Section D
    this.ouJenSuis,
    this.ceQuiPese,
    this.ceQuiTient,
    // Métadonnées
    required this.lastUpdated,
    this.isCompleted = false,
    // Nouveau champ
    this.historique30JoursResume,
    // Champs orientation
    this.philosophesSelectionnes = const [],
    this.courantsPhilosophiques = const [],
    this.orientationCompleted = false,
    this.orientationDate,
    // ⭐ Nouveaux champs profil simplifié
    this.prenom,
    this.dateNaissance,
    this.valeursSelectionnees,
    this.valeursLibres,
  });

  // Factory constructor pour profil vide
  factory UserProfile.empty([String? email]) {
    return UserProfile(
      email: email,
      lastUpdated: DateTime.now(),
      isCompleted: false,
    );
  }

  UserProfile copyWith({
    String? email,
    String? password,
    int? age,
    String? situationFamiliale,
    String? healthEnergy,
    String? contraintes,
    String? valeurs,
    String? ressources,
    String? contraintesRecurrentes,
    List<String>? religionsSelectionnees,
    List<String>? courantsLitteraires,
    List<String>? approchesPsychologiques,
    String? tonalitePrefere,
    String? ouJenSuis,
    String? ceQuiPese,
    String? ceQuiTient,
    DateTime? lastUpdated,
    bool? isCompleted,
    String? historique30JoursResume,
    List<String>? philosophesSelectionnes,
    List<String>? courantsPhilosophiques,
    bool? orientationCompleted,
    DateTime? orientationDate,
    // ⭐ Nouveaux champs profil simplifié
    String? prenom,
    DateTime? dateNaissance,
    List<String>? valeursSelectionnees,
    String? valeursLibres,
  }) {
    return UserProfile(
      email: email ?? this.email,
      password: password ?? this.password,
      age: age ?? this.age,
      situationFamiliale: situationFamiliale ?? this.situationFamiliale,
      healthEnergy: healthEnergy ?? this.healthEnergy,
      contraintes: contraintes ?? this.contraintes,
      valeurs: valeurs ?? this.valeurs,
      ressources: ressources ?? this.ressources,
      contraintesRecurrentes: contraintesRecurrentes ?? this.contraintesRecurrentes,
      religionsSelectionnees: religionsSelectionnees ?? this.religionsSelectionnees,
      courantsLitteraires: courantsLitteraires ?? this.courantsLitteraires,
      approchesPsychologiques: approchesPsychologiques ?? this.approchesPsychologiques,
      tonalitePrefere: tonalitePrefere ?? this.tonalitePrefere,
      ouJenSuis: ouJenSuis ?? this.ouJenSuis,
      ceQuiPese: ceQuiPese ?? this.ceQuiPese,
      ceQuiTient: ceQuiTient ?? this.ceQuiTient,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCompleted: isCompleted ?? this.isCompleted,
      historique30JoursResume: historique30JoursResume ?? this.historique30JoursResume,
      philosophesSelectionnes: philosophesSelectionnes ?? this.philosophesSelectionnes,
      courantsPhilosophiques: courantsPhilosophiques ?? this.courantsPhilosophiques,
      orientationCompleted: orientationCompleted ?? this.orientationCompleted,
      orientationDate: orientationDate ?? this.orientationDate,
      // ⭐ Nouveaux champs profil simplifié
      prenom: prenom ?? this.prenom,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      valeursSelectionnees: valeursSelectionnees ?? this.valeursSelectionnees,
      valeursLibres: valeursLibres ?? this.valeursLibres,
    );
  }

  bool get hasAnyContent {
    return (age != null) ||
           (situationFamiliale?.isNotEmpty == true) ||
           (healthEnergy?.isNotEmpty == true) ||
           (contraintes?.isNotEmpty == true) ||
           (valeurs?.isNotEmpty == true) ||
           (ressources?.isNotEmpty == true) ||
           (contraintesRecurrentes?.isNotEmpty == true) ||
           religionsSelectionnees.isNotEmpty ||
           courantsLitteraires.isNotEmpty ||
           approchesPsychologiques.isNotEmpty ||
           philosophesSelectionnes.isNotEmpty ||
           courantsPhilosophiques.isNotEmpty ||
           (tonalitePrefere?.isNotEmpty == true) ||
           (ouJenSuis?.isNotEmpty == true) ||
           (ceQuiPese?.isNotEmpty == true) ||
           (ceQuiTient?.isNotEmpty == true) ||
           (prenom?.isNotEmpty == true) ||
           (dateNaissance != null) ||
           (valeursSelectionnees?.isNotEmpty == true) ||
           (valeursLibres?.isNotEmpty == true);
  }

  int get completionPercentage {
    int completed = 0;
    int total = 17; // Nombre de champs principaux (ajusté)
    
    if (age != null) completed++;
    if (situationFamiliale?.isNotEmpty == true) completed++;
    if (healthEnergy?.isNotEmpty == true) completed++;
    if (contraintes?.isNotEmpty == true) completed++;
    if (valeurs?.isNotEmpty == true) completed++;
    if (ressources?.isNotEmpty == true) completed++;
    if (contraintesRecurrentes?.isNotEmpty == true) completed++;
    if (religionsSelectionnees.isNotEmpty) completed++;
    if (courantsLitteraires.isNotEmpty) completed++;
    if (approchesPsychologiques.isNotEmpty) completed++;
    if (philosophesSelectionnes.isNotEmpty) completed++;
    if (courantsPhilosophiques.isNotEmpty) completed++;
    if (ouJenSuis?.isNotEmpty == true) completed++;
    if (ceQuiPese?.isNotEmpty == true) completed++;
    if (ceQuiTient?.isNotEmpty == true) completed++;
    if (prenom?.isNotEmpty == true) completed++;
    if (valeursSelectionnees?.isNotEmpty == true) completed++;
    
    return (completed / total * 100).round();
  }

  /// Génère un préfixe de fichier sécurisé basé sur l'email
  String get filePrefix {
    if (email == null || email!.isEmpty) {
      return 'default_user';
    }
    
    // Nettoyer l'email pour le nom de fichier
    return email!
        .toLowerCase()
        .replaceAll('@', '_at_')
        .replaceAll('.', '_')
        .replaceAll('+', '_plus_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }

  /// 💎 MÉTHODE CLÉ : Génère le contexte pour l'IA selon le format du prompt
  String getContextForAI() {
    final buffer = StringBuffer();
    
    buffer.writeln('Contexte personnel :');
    if (prenom?.isNotEmpty == true) buffer.writeln('Prénom : $prenom');
    if (age != null) buffer.writeln('Âge : $age ans');
    if (situationFamiliale?.isNotEmpty == true) buffer.writeln('Situation : $situationFamiliale');
    if (healthEnergy?.isNotEmpty == true) buffer.writeln('Santé/Énergie : $healthEnergy');
    if (contraintes?.isNotEmpty == true) buffer.writeln('Contraintes actuelles : $contraintes');
    if (ressources?.isNotEmpty == true) buffer.writeln('Ressources habituelles : $ressources');
    
    // Valeurs (nouveau système)
    if (valeurs?.isNotEmpty == true) {
      buffer.writeln('Valeurs fondamentales : $valeurs');
    }
    
    if (religionsSelectionnees.isNotEmpty) {
      buffer.writeln('Religions / traditions spirituelles choisies : ${religionsSelectionnees.join(", ")}');
    }
    if (courantsLitteraires.isNotEmpty) {
      buffer.writeln('Courants littéraires préférés : ${courantsLitteraires.join(", ")}');
    }
    if (approchesPsychologiques.isNotEmpty) {
      buffer.writeln('Démarches psychologiques / thérapeutiques préférées : ${approchesPsychologiques.join(", ")}');
    }
    if (philosophesSelectionnes.isNotEmpty) {
      buffer.writeln('Philosophes de référence : ${philosophesSelectionnes.join(", ")}');
    }
    if (courantsPhilosophiques.isNotEmpty) {
      buffer.writeln('Courants philosophiques préférés : ${courantsPhilosophiques.join(", ")}');
    }
    if (tonalitePrefere?.isNotEmpty == true) {
      buffer.writeln('Tonalité préférée : $tonalitePrefere');
    }
    
    buffer.writeln();
    buffer.writeln('Ma vie actuellement :');
    if (ouJenSuis?.isNotEmpty == true) buffer.writeln('Où j\'en suis : $ouJenSuis');
    if (ceQuiPese?.isNotEmpty == true) buffer.writeln('Ce qui me pèse : $ceQuiPese');
    if (ceQuiTient?.isNotEmpty == true) buffer.writeln('Ce qui me tient : $ceQuiTient');
    
    // Historique 30 jours glissants pour contexte
    if (historique30JoursResume?.isNotEmpty == true) {
      buffer.writeln();
      buffer.writeln('Historique récent (30 derniers jours glissants) :');
      buffer.writeln(historique30JoursResume);
    }
    
    return buffer.toString();
  }

  /// Getter pour toutes les sources d'inspiration (pour le prompt IA)
  List<String> get allSourcesInspiration {
    return [
      ...religionsSelectionnees,
      ...courantsLitteraires,
      ...approchesPsychologiques,
      ...philosophesSelectionnes,
      ...courantsPhilosophiques,
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'age': age,
      'situationFamiliale': situationFamiliale,
      'healthEnergy': healthEnergy,
      'contraintes': contraintes,
      'valeurs': valeurs,
      'ressources': ressources,
      'contraintesRecurrentes': contraintesRecurrentes,
      'religionsSelectionnees': religionsSelectionnees,
      'courantsLitteraires': courantsLitteraires,
      'approchesPsychologiques': approchesPsychologiques,
      'tonalitePrefere': tonalitePrefere,
      'ouJenSuis': ouJenSuis,
      'ceQuiPese': ceQuiPese,
      'ceQuiTient': ceQuiTient,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isCompleted': isCompleted,
      'historique30JoursResume': historique30JoursResume,
      'philosophesSelectionnes': philosophesSelectionnes,
      'courantsPhilosophiques': courantsPhilosophiques,
      'orientationCompleted': orientationCompleted,
      'orientationDate': orientationDate?.toIso8601String(),
      // ⭐ Nouveaux champs profil simplifié
      'prenom': prenom,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'valeursSelectionnees': valeursSelectionnees,
      'valeursLibres': valeursLibres,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'],
      password: json['password'],
      age: json['age'],
      situationFamiliale: json['situationFamiliale'],
      healthEnergy: json['healthEnergy'],
      contraintes: json['contraintes'],
      valeurs: json['valeurs'],
      ressources: json['ressources'],
      contraintesRecurrentes: json['contraintesRecurrentes'],
      religionsSelectionnees: _migrateReligions(List<String>.from(json['religionsSelectionnees'] ?? [])),
      courantsLitteraires: List<String>.from(json['courantsLitteraires'] ?? []),
      approchesPsychologiques: List<String>.from(json['approchesPsychologiques'] ?? []),
      tonalitePrefere: json['tonalitePrefere'],
      ouJenSuis: json['ouJenSuis'],
      ceQuiPese: json['ceQuiPese'],
      ceQuiTient: json['ceQuiTient'],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
      historique30JoursResume: json['historique30JoursResume'],
      philosophesSelectionnes: List<String>.from(json['philosophesSelectionnes'] ?? []),
      courantsPhilosophiques: List<String>.from(json['courantsPhilosophiques'] ?? []),
      orientationCompleted: json['orientationCompleted'] ?? false,
      orientationDate: json['orientationDate'] != null 
          ? DateTime.parse(json['orientationDate']) 
          : null,
      // ⭐ Nouveaux champs profil simplifié
      prenom: json['prenom'],
      dateNaissance: json['dateNaissance'] != null 
          ? DateTime.parse(json['dateNaissance']) 
          : null,
      valeursSelectionnees: json['valeursSelectionnees'] != null 
          ? List<String>.from(json['valeursSelectionnees']) 
          : null,
      valeursLibres: json['valeursLibres'],
    );
  }
  
  /// MÉTHODE UTILITAIRE : Générer le résumé des 30 derniers jours glissants
  static String generateHistorique30Jours(List<dynamic> recentReflections) {
    if (recentReflections.isEmpty) {
      return '';
    }
    
    final buffer = StringBuffer();
    final emotionsFrequentes = <String, int>{};
    int totalIntensite = 0;
    
    // Analyser les réflexions récentes
    for (final reflection in recentReflections) {
      // Comptabiliser les émotions
      final emotionPrincipale = reflection is Map 
          ? reflection['emotionPrincipale'] 
          : (reflection as dynamic).emotionPrincipale;
      
      if (emotionPrincipale != null && emotionPrincipale.toString().isNotEmpty) {
        final emotion = emotionPrincipale.toString();
        emotionsFrequentes[emotion] = (emotionsFrequentes[emotion] ?? 0) + 1;
      }
      
      // Cumuler l'intensité
      final intensite = reflection is Map
          ? (reflection['intensiteEmotionnelle'] ?? 5)
          : (reflection as dynamic).intensiteEmotionnelle ?? 5;
      totalIntensite += intensite as int;
    }
    
    // Construire le résumé
    buffer.write('${recentReflections.length} réflexion(s)');
    
    if (emotionsFrequentes.isNotEmpty) {
      final topEmotions = emotionsFrequentes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      buffer.write(' - Émotions récurrentes : ');
      buffer.write(topEmotions.take(3).map((e) => '${e.key} (${e.value}x)').join(', '));
    }
    
    if (recentReflections.isNotEmpty) {
      final moyenneIntensite = (totalIntensite / recentReflections.length).round();
      buffer.write(' - Intensité moyenne : $moyenneIntensite/10');
    }
    
    return buffer.toString();
  }
}

/// Smooth migration: replace old bouddhisme/hindouisme keys with new schools
List<String> _migrateReligions(List<String> religions) {
  final migrated = <String>[];
  for (final r in religions) {
    if (r == 'bouddhisme' || r == 'Buddhism') {
      if (!migrated.contains('theravada')) migrated.add('theravada');
      if (!migrated.contains('zen')) migrated.add('zen');
    } else if (r == 'hindouisme' || r == 'Hinduism') {
      if (!migrated.contains('advaita_vedanta')) migrated.add('advaita_vedanta');
      if (!migrated.contains('bhakti')) migrated.add('bhakti');
    } else {
      migrated.add(r);
    }
  }
  return migrated;
}

// === LISTES DE CHOIX CONFORMES AU PROMPT ===

class ProfileChoices {
  static const List<String> religions = [
    'Judaism',
    'Christianity',
    'Islam / Sufism',
    'Theravāda Buddhism',
    'Zen Buddhism',
    'Advaita Vedānta',
    'Bhakti (Hindu devotion)',
    'Stoicism',
    'Contemporary / Secular Spirituality',
    'Other',
  ];

  static const List<String> courantsLitteraires = [
    'Humaniste',
    'Poétique',
    'Réaliste',
    'Mystique',
    'Existentialiste',
    'Romantique',
    'Symboliste / Moderne',
  ];

  static const List<String> approchesPsychologiques = [
    'Logothérapie (Frankl)',
    'Thérapie des Schémas (Young)',
    'Humaniste (Rogers)',
    'The Work (Byron Katie)',
    'TCC (Cognitivo-Comportementale)',
    'Jungienne (symbolique, archétypes)',
  ];

  static const List<String> tonalites = [
    'Apaisant et sécurisant',
    'Réflexif et équilibré',
    'Orienté action douce',
    'Introspectif et inspirant',
    'Bienveillant et profond',
  ];
  
  // CHOIX ORIENTATION
  static const List<String> philosophes = [
    'Socrate',
    'Platon',
    'Aristote',
    'Épicure',
    'Sénèque',
    'Épictète',
    'Marc Aurèle',
    'Spinoza',
    'Kant',
    'Schopenhauer',
    'Nietzsche',
    'Kierkegaard',
    'Sartre',
    'Simone de Beauvoir',
    'Camus',
    'Hannah Arendt',
    'Confucius',
  ];
  
  static const List<String> courantsPhilosophiques = [
    'Stoïcisme',
    'Épicurisme',
    'Existentialisme',
    'Humanisme',
    'Vitalisme',
    'Absurdisme',
    'Rationalisme',
    'Empirisme',
    'Pragmatisme',
    'Phénoménologie',
    'Idéalisme',
    'Utilitarisme',
    'Structuralisme',
    'Philosophies orientales',
  ];
}

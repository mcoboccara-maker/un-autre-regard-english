import 'package:hive/hive.dart';
import 'emotional_state.dart';

part 'reflection.g.dart'; // ⭐ AJOUTÉ pour Hive

@HiveType(typeId: 2)
class Reflection extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String text; // Objet Ã  analyser (pensÃ©e ou situation)
  
  @HiveField(2)
  final ReflectionType type; // Type : pensÃ©e | dilemme | situation | question
  
  @HiveField(3)
  final EmotionalState emotionalState;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final List<String> selectedApproaches;
  
  @HiveField(6)
  final Map<String, String> aiResponses;
  
  @HiveField(7)
  final bool isFavorite;
  
  // === NOUVEAUX CHAMPS CONFORMES AU PROMPT ===
  @HiveField(8)
  final String? declencheur; // DÃ©clencheur / contexte
  
  @HiveField(9)
  final String? souhait; // Souhait / besoin
  
  @HiveField(10)
  final String? petitPas; // Petit pas envisageable
  
  @HiveField(11)
  final int intensiteEmotionnelle; // 1-10 pour adapter le ton IA
  
  @HiveField(12)
  final String? emotionPrincipale; // Ã‰motion principale dÃ©tectÃ©e

  Reflection({
    required this.id,
    required this.text,
    required this.type,
    required this.emotionalState,
    required this.createdAt,
    required this.selectedApproaches,
    required this.aiResponses,
    this.isFavorite = false,
    // Nouveaux champs
    this.declencheur,
    this.souhait,
    this.petitPas,
    this.intensiteEmotionnelle = 5,
    this.emotionPrincipale,
  });

  Reflection copyWith({
    String? id,
    String? text,
    ReflectionType? type,
    EmotionalState? emotionalState,
    DateTime? createdAt,
    List<String>? selectedApproaches,
    Map<String, String>? aiResponses,
    bool? isFavorite,
    String? declencheur,
    String? souhait,
    String? petitPas,
    int? intensiteEmotionnelle,
    String? emotionPrincipale,
  }) {
    return Reflection(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      emotionalState: emotionalState ?? this.emotionalState,
      createdAt: createdAt ?? this.createdAt,
      selectedApproaches: selectedApproaches ?? this.selectedApproaches,
      aiResponses: aiResponses ?? this.aiResponses,
      isFavorite: isFavorite ?? this.isFavorite,
      declencheur: declencheur ?? this.declencheur,
      souhait: souhait ?? this.souhait,
      petitPas: petitPas ?? this.petitPas,
      intensiteEmotionnelle: intensiteEmotionnelle ?? this.intensiteEmotionnelle,
      emotionPrincipale: emotionPrincipale ?? this.emotionPrincipale,
    );
  }

  /// GÃ©nÃ¨re le prompt utilisateur conforme au format spÃ©cifiÃ©
  String generateUserPrompt(String userProfileContext) {
    final buffer = StringBuffer();
    
    // En-tÃªte du prompt utilisateur
    buffer.writeln('Objet Ã  analyser : "$text"');
    buffer.writeln('Type : ${type.promptValue}');
    
    if (emotionPrincipale?.isNotEmpty == true) {
      buffer.writeln('Ã‰motions principales : $emotionPrincipale ($intensiteEmotionnelle/10)');
    }
    
    if (declencheur?.isNotEmpty == true) {
      buffer.writeln('DÃ©clencheur / contexte : $declencheur');
    }
    
    if (souhait?.isNotEmpty == true) {
      buffer.writeln('Souhait / besoin : $souhait');
    }
    
    if (petitPas?.isNotEmpty == true) {
      buffer.writeln('Petit pas envisageable : $petitPas');
    }
    
    buffer.writeln();
    buffer.writeln(userProfileContext);
    
    return buffer.toString();
  }

  /// DÃ©termine le ton Ã  adopter selon l'intensitÃ© Ã©motionnelle
  String get tonRecommande {
    if (intensiteEmotionnelle >= 7) {
      return 'apaisant et sÃ©curisant';
    } else if (intensiteEmotionnelle >= 4) {
      return 'rÃ©flexif et Ã©quilibrÃ©';
    } else {
      return 'orientÃ© action douce';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'emotionalState': emotionalState.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'selectedApproaches': selectedApproaches,
      'aiResponses': aiResponses,
      'isFavorite': isFavorite,
      'declencheur': declencheur,
      'souhait': souhait,
      'petitPas': petitPas,
      'intensiteEmotionnelle': intensiteEmotionnelle,
      'emotionPrincipale': emotionPrincipale,
    };
  }

  factory Reflection.fromJson(Map<String, dynamic> json) {
    return Reflection(
      id: json['id'],
      text: json['text'],
      type: ReflectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReflectionType.thought,
      ),
      emotionalState: EmotionalState.fromJson(json['emotionalState']),
      createdAt: DateTime.parse(json['createdAt']),
      selectedApproaches: List<String>.from(json['selectedApproaches']),
      aiResponses: Map<String, String>.from(json['aiResponses']),
      isFavorite: json['isFavorite'] ?? false,
      declencheur: json['declencheur'],
      souhait: json['souhait'],
      petitPas: json['petitPas'],
      intensiteEmotionnelle: json['intensiteEmotionnelle'] ?? 5,
      emotionPrincipale: json['emotionPrincipale'],
    );
  }
}

/// Extension pour le mapping des types vers les valeurs du prompt
extension ReflectionTypeExtension on ReflectionType {
  String get promptValue {
    switch (this) {
      case ReflectionType.thought:
        return 'pensÃ©e';
      case ReflectionType.situation:
        return 'situation';
      case ReflectionType.existential:
        return 'question';
      case ReflectionType.dilemma:
        return 'dilemme';
    }
  }
}

// Enum existant (gardÃ© pour compatibilitÃ©)
@HiveType(typeId: 3)
enum ReflectionType {
  @HiveField(0)
  thought('PensÃ©e'),
  
  @HiveField(1)
  situation('Situation Ã©motionnelle'),
  
  @HiveField(2)
  existential('Question existentielle'),
  
  @HiveField(3)
  dilemma('Dilemme');

  const ReflectionType(this.displayName);
  final String displayName;
}

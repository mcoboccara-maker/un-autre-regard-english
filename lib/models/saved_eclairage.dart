/// Modèle de sauvegarde complète d'un éclairage
/// Contient tout le contexte : éclairage + réponses + émotions + pensée + source + figure

class SavedEclairage {
  final String eclairageText;
  final String? deepeningText; // Approfondissement généré par l'IA
  final String? userResponse; // Réflexions/commentaires de l'utilisateur
  final String thoughtText; // Pensée originale de l'utilisateur
  final String sourceKey;
  final String sourceName;
  final String? figureName; // Depuis FIGURE_META
  final String? figureReference; // Référence textuelle depuis FIGURE_META
  final Map<String, dynamic>? emotionalState; // État émotionnel sérialisé
  final int? intensiteEmotionnelle;
  final DateTime savedAt;

  SavedEclairage({
    required this.eclairageText,
    this.deepeningText,
    this.userResponse,
    required this.thoughtText,
    required this.sourceKey,
    required this.sourceName,
    this.figureName,
    this.figureReference,
    this.emotionalState,
    this.intensiteEmotionnelle,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'eclairageText': eclairageText,
      'deepeningText': deepeningText,
      'userResponse': userResponse,
      'thoughtText': thoughtText,
      'sourceKey': sourceKey,
      'sourceName': sourceName,
      'figureName': figureName,
      'figureReference': figureReference,
      'emotionalState': emotionalState,
      'intensiteEmotionnelle': intensiteEmotionnelle,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedEclairage.fromJson(Map<String, dynamic> json) {
    return SavedEclairage(
      eclairageText: json['eclairageText'] as String,
      deepeningText: json['deepeningText'] as String?,
      userResponse: json['userResponse'] as String?,
      thoughtText: json['thoughtText'] as String,
      sourceKey: json['sourceKey'] as String,
      sourceName: json['sourceName'] as String,
      figureName: json['figureName'] as String?,
      figureReference: json['figureReference'] as String?,
      emotionalState: json['emotionalState'] as Map<String, dynamic>?,
      intensiteEmotionnelle: json['intensiteEmotionnelle'] as int?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

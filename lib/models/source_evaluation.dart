import 'dart:convert';

/// MODELE D'EVALUATION D'UNE SOURCE/PERSPECTIVE
/// 
/// Stocke l'évaluation d'un utilisateur pour une perspective générée :
/// - Note de 1 à 10
/// - Commentaire optionnel
/// - Timestamp de l'évaluation
class SourceEvaluation {
  final String sourceKey;      // Clé de la source (ex: 'stoicisme', 'tcc')
  final String sourceName;     // Nom affiché (ex: 'Stoïcisme', 'TCC')
  final int rating;            // Note de 1 à 10
  final String? comment;       // Commentaire optionnel
  final DateTime evaluatedAt;  // Date de l'évaluation
  final String? responseText;  // Texte de la réponse IA (pour export)

  SourceEvaluation({
    required this.sourceKey,
    required this.sourceName,
    required this.rating,
    this.comment,
    DateTime? evaluatedAt,
    this.responseText,
  }) : evaluatedAt = evaluatedAt ?? DateTime.now();

  /// Copie avec modifications
  SourceEvaluation copyWith({
    String? sourceKey,
    String? sourceName,
    int? rating,
    String? comment,
    DateTime? evaluatedAt,
    String? responseText,
  }) {
    return SourceEvaluation(
      sourceKey: sourceKey ?? this.sourceKey,
      sourceName: sourceName ?? this.sourceName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      responseText: responseText ?? this.responseText,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'sourceKey': sourceKey,
      'sourceName': sourceName,
      'rating': rating,
      'comment': comment,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'responseText': responseText,
    };
  }

  /// Création depuis JSON
  factory SourceEvaluation.fromJson(Map<String, dynamic> json) {
    return SourceEvaluation(
      sourceKey: json['sourceKey'] ?? '',
      sourceName: json['sourceName'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      evaluatedAt: json['evaluatedAt'] != null 
          ? DateTime.parse(json['evaluatedAt']) 
          : DateTime.now(),
      responseText: json['responseText'],
    );
  }

  @override
  String toString() {
    return 'SourceEvaluation(sourceKey: $sourceKey, rating: $rating, comment: $comment)';
  }
}

/// CLASSE POUR REGROUPER TOUTES LES EVALUATIONS D'UNE REFLEXION
class ReflectionEvaluations {
  final String reflectionId;           // ID de la réflexion associée
  final String penseeOriginale;        // Texte de la pensée
  final String? typeReflexion;         // Type (pensée, situation, etc.)
  final String? emotions;              // Émotions sélectionnées
  final int? intensite;                // Intensité émotionnelle
  final Map<String, SourceEvaluation> evaluations;  // Évaluations par sourceKey
  final DateTime createdAt;            // Date de création
  final bool isExported;               // Déjà exporté par email ?

  ReflectionEvaluations({
    required this.reflectionId,
    required this.penseeOriginale,
    this.typeReflexion,
    this.emotions,
    this.intensite,
    Map<String, SourceEvaluation>? evaluations,
    DateTime? createdAt,
    this.isExported = false,
  }) : 
    evaluations = evaluations ?? {},
    createdAt = createdAt ?? DateTime.now();

  /// Ajouter ou mettre à jour une évaluation
  ReflectionEvaluations addEvaluation(SourceEvaluation evaluation) {
    final newEvaluations = Map<String, SourceEvaluation>.from(evaluations);
    newEvaluations[evaluation.sourceKey] = evaluation;
    return ReflectionEvaluations(
      reflectionId: reflectionId,
      penseeOriginale: penseeOriginale,
      typeReflexion: typeReflexion,
      emotions: emotions,
      intensite: intensite,
      evaluations: newEvaluations,
      createdAt: createdAt,
      isExported: isExported,
    );
  }

  /// Marquer comme exporté
  ReflectionEvaluations markAsExported() {
    return ReflectionEvaluations(
      reflectionId: reflectionId,
      penseeOriginale: penseeOriginale,
      typeReflexion: typeReflexion,
      emotions: emotions,
      intensite: intensite,
      evaluations: evaluations,
      createdAt: createdAt,
      isExported: true,
    );
  }

  /// Nombre d'évaluations
  int get evaluationCount => evaluations.length;

  /// Moyenne des notes
  double get averageRating {
    if (evaluations.isEmpty) return 0;
    final total = evaluations.values.fold<int>(0, (sum, e) => sum + e.rating);
    return total / evaluations.length;
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'reflectionId': reflectionId,
      'penseeOriginale': penseeOriginale,
      'typeReflexion': typeReflexion,
      'emotions': emotions,
      'intensite': intensite,
      'evaluations': evaluations.map((key, value) => MapEntry(key, value.toJson())),
      'createdAt': createdAt.toIso8601String(),
      'isExported': isExported,
    };
  }

  /// Création depuis JSON
  factory ReflectionEvaluations.fromJson(Map<String, dynamic> json) {
    final evaluationsJson = json['evaluations'] as Map<String, dynamic>? ?? {};
    final evaluations = evaluationsJson.map(
      (key, value) => MapEntry(key, SourceEvaluation.fromJson(value)),
    );

    return ReflectionEvaluations(
      reflectionId: json['reflectionId'] ?? '',
      penseeOriginale: json['penseeOriginale'] ?? '',
      typeReflexion: json['typeReflexion'],
      emotions: json['emotions'],
      intensite: json['intensite'],
      evaluations: evaluations,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isExported: json['isExported'] ?? false,
    );
  }

  /// Génère le texte formaté pour export (email ou fichier)
  String toExportText() {
    final buffer = StringBuffer();
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📝 PENSÉE ORIGINALE');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln(penseeOriginale);
    buffer.writeln();
    
    if (typeReflexion != null) {
      buffer.writeln('Type : $typeReflexion');
    }
    if (emotions != null) {
      buffer.writeln('Émotions : $emotions');
    }
    if (intensite != null) {
      buffer.writeln('Intensité : $intensite/10');
    }
    buffer.writeln();
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('🔮 PERSPECTIVES ET ÉVALUATIONS');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    
    for (final evaluation in evaluations.values) {
      buffer.writeln('───────────────────────────────────────');
      buffer.writeln('📌 ${evaluation.sourceName}');
      buffer.writeln('───────────────────────────────────────');
      
      if (evaluation.responseText != null && evaluation.responseText!.isNotEmpty) {
        buffer.writeln(evaluation.responseText);
        buffer.writeln();
      }
      
      buffer.writeln('⭐ Note : ${evaluation.rating}/10');
      
      if (evaluation.comment != null && evaluation.comment!.isNotEmpty) {
        buffer.writeln('💬 Commentaire : ${evaluation.comment}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('📊 Moyenne globale : ${averageRating.toStringAsFixed(1)}/10');
    buffer.writeln('📅 Date : ${createdAt.day}/${createdAt.month}/${createdAt.year}');
    
    return buffer.toString();
  }
}

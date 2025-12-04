import 'dart:convert';

/// Statut d'une micro-action suggérée à l'utilisateur
enum MicroActionResult { notAttempted, inProgress, success, failed }

/// Difficulté perçue d'une micro-action
enum MicroActionDifficulty { easy, medium, hard }

class MicroActionStatus {
  final String id;                    // ID unique
  final String description;           // Description de l'action
  final DateTime suggested;           // Quand elle a été suggérée
  final DateTime? attempted;          // Quand elle a été tentée
  final bool? success;               // Succès ou échec (null = pas tentée)
  final String? feedback;            // Commentaire utilisateur
  final MicroActionResult result;    // Statut détaillé
  final MicroActionDifficulty difficulty; // Difficulté perçue
  final int? rating;                 // Note de 1-5 si réalisée

  const MicroActionStatus({
    required this.id,
    required this.description,
    required this.suggested,
    this.attempted,
    this.success,
    this.feedback,
    this.result = MicroActionResult.notAttempted,
    this.difficulty = MicroActionDifficulty.medium,
    this.rating,
  });

  /// Micro-action vide pour initialisation
  factory MicroActionStatus.empty() => MicroActionStatus(
    id: '',
    description: '',
    suggested: DateTime.now(),
  );

  /// Créer une nouvelle micro-action suggérée
  factory MicroActionStatus.suggested({
    required String id,
    required String description,
    MicroActionDifficulty difficulty = MicroActionDifficulty.medium,
  }) => MicroActionStatus(
    id: id,
    description: description,
    suggested: DateTime.now(),
    difficulty: difficulty,
  );

  /// Sérialisation vers JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'suggested': suggested.toIso8601String(),
    'attempted': attempted?.toIso8601String(),
    'success': success,
    'feedback': feedback,
    'result': result.index,
    'difficulty': difficulty.index,
    'rating': rating,
  };

  /// Désérialisation depuis JSON
  factory MicroActionStatus.fromJson(Map<String, dynamic> json) => MicroActionStatus(
    id: json['id'] as String,
    description: json['description'] as String,
    suggested: DateTime.parse(json['suggested'] as String),
    attempted: json['attempted'] != null 
        ? DateTime.parse(json['attempted'] as String) 
        : null,
    success: json['success'] as bool?,
    feedback: json['feedback'] as String?,
    result: MicroActionResult.values[json['result'] as int? ?? 0],
    difficulty: MicroActionDifficulty.values[json['difficulty'] as int? ?? 1],
    rating: json['rating'] as int?,
  );

  /// Copie avec modifications
  MicroActionStatus copyWith({
    String? id,
    String? description,
    DateTime? suggested,
    DateTime? attempted,
    bool? success,
    String? feedback,
    MicroActionResult? result,
    MicroActionDifficulty? difficulty,
    int? rating,
  }) {
    return MicroActionStatus(
      id: id ?? this.id,
      description: description ?? this.description,
      suggested: suggested ?? this.suggested,
      attempted: attempted ?? this.attempted,
      success: success ?? this.success,
      feedback: feedback ?? this.feedback,
      result: result ?? this.result,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
    );
  }

  /// Marquer comme tentée avec succès
  MicroActionStatus markAsSuccess({String? feedback, int? rating}) {
    return copyWith(
      attempted: DateTime.now(),
      success: true,
      result: MicroActionResult.success,
      feedback: feedback,
      rating: rating,
    );
  }

  /// Marquer comme échouée
  MicroActionStatus markAsFailed({String? feedback}) {
    return copyWith(
      attempted: DateTime.now(),
      success: false,
      result: MicroActionResult.failed,
      feedback: feedback,
    );
  }

  /// Marquer comme en cours
  MicroActionStatus markAsInProgress() {
    return copyWith(
      attempted: DateTime.now(),
      result: MicroActionResult.inProgress,
    );
  }

  /// Getters utiles
  bool get isAttempted => attempted != null;
  bool get isSuccessful => success == true;
  bool get isFailed => success == false;
  bool get isInProgress => result == MicroActionResult.inProgress;
  bool get isPending => result == MicroActionResult.notAttempted;

  /// Temps écoulé depuis la suggestion
  Duration get timeSinceSuggested => DateTime.now().difference(suggested);
  
  /// Temps écoulé depuis la tentative (null si pas tentée)
  Duration? get timeSinceAttempted => 
      attempted != null ? DateTime.now().difference(attempted!) : null;

  /// Délai de réalisation (null si pas tentée)
  Duration? get completionDelay => 
      attempted != null ? attempted!.difference(suggested) : null;

  /// Niveau de difficulté en texte
  String get difficultyText {
    switch (difficulty) {
      case MicroActionDifficulty.easy:
        return 'Facile';
      case MicroActionDifficulty.medium:
        return 'Moyen';
      case MicroActionDifficulty.hard:
        return 'Difficile';
    }
  }

  /// Statut en texte français
  String get statusText {
    switch (result) {
      case MicroActionResult.notAttempted:
        return 'Non tentée';
      case MicroActionResult.inProgress:
        return 'En cours';
      case MicroActionResult.success:
        return 'Réussie';
      case MicroActionResult.failed:
        return 'Échouée';
    }
  }

  /// Couleur associée au statut
  String get statusColorHex {
    switch (result) {
      case MicroActionResult.notAttempted:
        return '#94A3B8'; // Gris
      case MicroActionResult.inProgress:
        return '#F59E0B'; // Orange
      case MicroActionResult.success:
        return '#10B981'; // Vert
      case MicroActionResult.failed:
        return '#EF4444'; // Rouge
    }
  }

  @override
  String toString() => 'MicroActionStatus($id: $statusText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MicroActionStatus &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description &&
          suggested == other.suggested;

  @override
  int get hashCode => id.hashCode ^ description.hashCode ^ suggested.hashCode;
}

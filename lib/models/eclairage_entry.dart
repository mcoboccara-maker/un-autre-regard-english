import 'dart:convert';

/// Modèle représentant un éclairage généré par l'IA pour une approche donnée
class EclairageEntry {
  final String approachKey;         // Clé de l'approche (ex: "stoicisme", "tcc")
  final String content;            // Contenu complet de la réponse IA
  final List<String> microActions; // Actions pratiques extraites
  final List<String> keyInsights;  // Insights clés extraits
  final DateTime timestamp;        // Moment de génération

  const EclairageEntry({
    required this.approachKey,
    required this.content,
    required this.microActions,
    required this.keyInsights,
    required this.timestamp,
  });

  /// Éclairage vide pour initialisation
  factory EclairageEntry.empty() => EclairageEntry(
    approachKey: '',
    content: '',
    microActions: const [],
    keyInsights: const [],
    timestamp: DateTime.now(),
  );

  /// Sérialisation vers JSON
  Map<String, dynamic> toJson() => {
    'approachKey': approachKey,
    'content': content,
    'microActions': microActions,
    'keyInsights': keyInsights,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Désérialisation depuis JSON
  factory EclairageEntry.fromJson(Map<String, dynamic> json) => EclairageEntry(
    approachKey: json['approachKey'] as String,
    content: json['content'] as String,
    microActions: List<String>.from(json['microActions'] as List),
    keyInsights: List<String>.from(json['keyInsights'] as List),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  /// Copie avec modifications
  EclairageEntry copyWith({
    String? approachKey,
    String? content,
    List<String>? microActions,
    List<String>? keyInsights,
    DateTime? timestamp,
  }) {
    return EclairageEntry(
      approachKey: approachKey ?? this.approachKey,
      content: content ?? this.content,
      microActions: microActions ?? this.microActions,
      keyInsights: keyInsights ?? this.keyInsights,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Vérifie si l'éclairage est valide
  bool get isValid => 
      approachKey.isNotEmpty && 
      content.isNotEmpty;

  /// Vérifie si l'éclairage a des actions pratiques
  bool get hasMicroActions => microActions.isNotEmpty;

  /// Vérifie si l'éclairage a des insights
  bool get hasInsights => keyInsights.isNotEmpty;

  /// Résumé court de l'éclairage (première phrase)
  String get summary {
    if (content.isEmpty) return '';
    
    final sentences = content.split('.');
    if (sentences.isEmpty) return content;
    
    return '${sentences.first.trim()}.';
  }

  /// Longueur du contenu en mots
  int get wordCount => content.split(' ').where((w) => w.isNotEmpty).length;

  @override
  String toString() => 'EclairageEntry(approach: $approachKey, words: $wordCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EclairageEntry &&
          runtimeType == other.runtimeType &&
          approachKey == other.approachKey &&
          content == other.content &&
          timestamp == other.timestamp;

  @override
  int get hashCode => approachKey.hashCode ^ content.hashCode ^ timestamp.hashCode;
}

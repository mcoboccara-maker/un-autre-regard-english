// lib/models/eclairage_entry.dart
// Modèle pour représenter un éclairage structuré en 3 niveaux

/// Représente une source d'éclairage (majeure ou secondaire)
class SourceEclairage {
  final String nom;
  final String type; // 'spiritual', 'literary', 'psychological', 'philosophical', 'philosopher'
  final String personnage;
  final String reference;
  final String contexte;
  final String interpretation;
  final bool isMajeure;
  
  const SourceEclairage({
    required this.nom,
    required this.type,
    required this.personnage,
    required this.reference,
    required this.contexte,
    required this.interpretation,
    required this.isMajeure,
  });
  
  factory SourceEclairage.fromMap(Map<String, dynamic> map) {
    return SourceEclairage(
      nom: map['nom'] ?? '',
      type: map['type'] ?? '',
      personnage: map['personnage'] ?? '',
      reference: map['reference'] ?? '',
      contexte: map['contexte'] ?? '',
      interpretation: map['interpretation'] ?? '',
      isMajeure: map['isMajeure'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'type': type,
      'personnage': personnage,
      'reference': reference,
      'contexte': contexte,
      'interpretation': interpretation,
      'isMajeure': isMajeure,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SourceEclairage.fromJson(Map<String, dynamic> json) => SourceEclairage.fromMap(json);
}

/// Représente un éclairage complet avec synthèse et sources
class EclairageEntry {
  final String synthese; // 80-120 mots
  final List<SourceEclairage> sourcesMajeures; // 1-2 sources, 180-250 mots
  final List<SourceEclairage> sourcesSecondaires; // 1-2 sources, 70-120 mots
  final String rawResponse; // Réponse brute pour fallback
  final DateTime createdAt;
  
  const EclairageEntry({
    required this.synthese,
    required this.sourcesMajeures,
    required this.sourcesSecondaires,
    required this.rawResponse,
    required this.createdAt,
  });
  
  /// Nombre total de sources
  int get totalSources => sourcesMajeures.length + sourcesSecondaires.length;
  
  /// Vérifie si l'éclairage est valide (au moins une synthèse)
  bool get isValid => synthese.isNotEmpty || rawResponse.isNotEmpty;
  
  /// Vérifie si le parsing a réussi (au moins une source majeure ou secondaire)
  bool get isParsed => sourcesMajeures.isNotEmpty || sourcesSecondaires.isNotEmpty;
  
  factory EclairageEntry.fromMap(Map<String, dynamic> map) {
    return EclairageEntry(
      synthese: map['synthese'] ?? '',
      sourcesMajeures: (map['sourcesMajeures'] as List?)
          ?.map((s) => SourceEclairage.fromMap(s))
          .toList() ?? [],
      sourcesSecondaires: (map['sourcesSecondaires'] as List?)
          ?.map((s) => SourceEclairage.fromMap(s))
          .toList() ?? [],
      rawResponse: map['rawResponse'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'synthese': synthese,
      'sourcesMajeures': sourcesMajeures.map((s) => s.toMap()).toList(),
      'sourcesSecondaires': sourcesSecondaires.map((s) => s.toMap()).toList(),
      'rawResponse': rawResponse,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory EclairageEntry.fromJson(Map<String, dynamic> json) => EclairageEntry.fromMap(json);
  
  /// Créer depuis une réponse brute (sans parsing)
  factory EclairageEntry.fromRawResponse(String response) {
    return EclairageEntry(
      synthese: '',
      sourcesMajeures: [],
      sourcesSecondaires: [],
      rawResponse: response,
      createdAt: DateTime.now(),
    );
  }
  
  /// Créer avec synthèse et sources parsées
  factory EclairageEntry.parsed({
    required String synthese,
    required List<SourceEclairage> majeures,
    required List<SourceEclairage> secondaires,
    required String rawResponse,
  }) {
    return EclairageEntry(
      synthese: synthese,
      sourcesMajeures: majeures,
      sourcesSecondaires: secondaires,
      rawResponse: rawResponse,
      createdAt: DateTime.now(),
    );
  }
}

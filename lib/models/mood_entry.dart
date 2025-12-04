// lib/models/mood_entry.dart
/// Entrée d'humeur quotidienne simplifiée (différente de DailyEntry qui est pour les réflexions)
/// Permet de saisir rapidement son état émotionnel sans passer par le processus complet de réflexion

class MoodEntry {
  final DateTime date;                          // Date du jour (normalisée à minuit)
  final Map<String, EmotionDetail> emotions;    // Émotions avec intensité et nuances
  final String? note;                           // Note optionnelle du jour
  final DateTime createdAt;                     // Horodatage exact de création (avec heure)
  
  const MoodEntry({
    required this.date,
    required this.emotions,
    this.note,
    required this.createdAt,
  });

  /// Factory pour créer une entrée du jour
  factory MoodEntry.forToday(Map<String, EmotionDetail> emotions, {String? note}) {
    final now = DateTime.now();
    return MoodEntry(
      date: DateTime(now.year, now.month, now.day), // Normalisation à minuit
      emotions: emotions,
      note: note,
      createdAt: now, // Garde l'heure exacte
    );
  }

  /// Sérialisation vers JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'emotions': emotions.map((key, value) => MapEntry(key, value.toJson())),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Désérialisation depuis JSON
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      date: DateTime.parse(json['date']),
      emotions: (json['emotions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, EmotionDetail.fromJson(value)),
      ),
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// Copie avec modifications
  MoodEntry copyWith({
    DateTime? date,
    Map<String, EmotionDetail>? emotions,
    String? note,
    DateTime? createdAt,
  }) {
    return MoodEntry(
      date: date ?? this.date,
      emotions: emotions ?? this.emotions,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Getters utiles
  bool get hasNote => note?.isNotEmpty ?? false;
  
  int get emotionsCount => emotions.length;
  
  /// Intensité moyenne des émotions
  double get averageIntensity {
    if (emotions.isEmpty) return 0;
    final total = emotions.values.fold<int>(0, (sum, e) => sum + e.intensity);
    return total / emotions.length;
  }

  /// Émotion la plus intense
  MapEntry<String, EmotionDetail>? get dominantEmotion {
    if (emotions.isEmpty) return null;
    return emotions.entries.reduce((a, b) => 
      a.value.intensity > b.value.intensity ? a : b
    );
  }

  /// Date formatée
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) return 'Aujourd\'hui';
    if (date == yesterday) return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Heure formatée
  String get formattedTime => 
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  @override
  String toString() => 'MoodEntry(${formattedDate}, ${emotionsCount} émotions)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodEntry &&
          runtimeType == other.runtimeType &&
          date == other.date;

  @override
  int get hashCode => date.hashCode;
}

/// Détail d'une émotion avec intensité et nuances
class EmotionDetail {
  final int intensity;        // Intensité de 0 à 100
  final List<String> nuances; // Nuances sélectionnées
  
  const EmotionDetail({
    required this.intensity,
    required this.nuances,
  });

  Map<String, dynamic> toJson() {
    return {
      'intensity': intensity,
      'nuances': nuances,
    };
  }

  factory EmotionDetail.fromJson(Map<String, dynamic> json) {
    return EmotionDetail(
      intensity: json['intensity'] as int,
      nuances: List<String>.from(json['nuances'] ?? []),
    );
  }

  EmotionDetail copyWith({
    int? intensity,
    List<String>? nuances,
  }) {
    return EmotionDetail(
      intensity: intensity ?? this.intensity,
      nuances: nuances ?? this.nuances,
    );
  }

  @override
  String toString() => 'EmotionDetail($intensity%, ${nuances.length} nuances)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionDetail &&
          runtimeType == other.runtimeType &&
          intensity == other.intensity;

  @override
  int get hashCode => intensity.hashCode;
}

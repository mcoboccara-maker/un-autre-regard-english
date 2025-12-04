import 'package:hive/hive.dart';

part 'emotional_state.g.dart';

@HiveType(typeId: 0)
class EmotionalState extends HiveObject {
  @HiveField(0)
  final Map<String, EmotionLevel> emotions;
  
  @HiveField(1)
  final DateTime timestamp;

  EmotionalState({
    required this.emotions,
    required this.timestamp,
  });

  factory EmotionalState.empty() {
    return EmotionalState(
      emotions: {
        'OUVERT': EmotionLevel(level: 0, nuances: []),
        'AIMANT': EmotionLevel(level: 0, nuances: []),
        'HEUREUX': EmotionLevel(level: 0, nuances: []),
        'INTERESSE': EmotionLevel(level: 0, nuances: []),
        'VIVANT': EmotionLevel(level: 0, nuances: []),
        'POSITIF': EmotionLevel(level: 0, nuances: []),
        'PAISIBLE': EmotionLevel(level: 0, nuances: []),
        'FORT': EmotionLevel(level: 0, nuances: []),
        'DETENDU': EmotionLevel(level: 0, nuances: []),
      },
      timestamp: DateTime.now(),
    );
  }

  EmotionalState copyWith({
    Map<String, EmotionLevel>? emotions,
    DateTime? timestamp,
  }) {
    return EmotionalState(
      emotions: emotions ?? this.emotions,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotions': emotions.map((key, value) => MapEntry(key, value.toJson())),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EmotionalState.fromJson(Map<String, dynamic> json) {
    return EmotionalState(
      emotions: (json['emotions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, EmotionLevel.fromJson(value)),
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

@HiveType(typeId: 1)
class EmotionLevel extends HiveObject {
  @HiveField(0)
  final int level; // 0-100
  
  @HiveField(1)
  final List<String> nuances;

  EmotionLevel({
    required this.level,
    required this.nuances,
  });

  EmotionLevel copyWith({
    int? level,
    List<String>? nuances,
  }) {
    return EmotionLevel(
      level: level ?? this.level,
      nuances: nuances ?? this.nuances,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'nuances': nuances,
    };
  }

  factory EmotionLevel.fromJson(Map<String, dynamic> json) {
    return EmotionLevel(
      level: json['level'] as int,
      nuances: List<String>.from(json['nuances']),
    );
  }
}

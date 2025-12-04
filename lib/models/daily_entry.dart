import '../models/emotional_state.dart';
import '../models/reflection.dart';
import '../models/eclairage_entry.dart';
import '../models/micro_action_status.dart';

/// Entrée quotidienne complète avec contexte, émotions et éclairages
class DailyEntry {
  final String id;                              // ID unique
  final DateTime timestamp;                     // Date/heure de création
  final String reflectionText;                  // Texte de la réflexion
  final ReflectionType reflectionType;          // Type (pensée/situation/etc.)
  final String? declencheur;                    // Ce qui a déclenché cette réflexion
  final String? souhait;                        // Ce que souhaite l'utilisateur
  final String? petitPas;                       // Petit pas envisagé
  final EmotionalState emotionalState;          // État émotionnel complet
  final int intensiteEmotionnelle;              // Intensité moyenne (0-10)
  final String? emotionPrincipale;              // Émotion dominante
  final List<String> selectedApproaches;        // 🔧 CORRIGÉ: selectedApproaches au lieu de selectedApproches
  final List<EclairageEntry> eclairages;        // Éclairages reçus
  final List<MicroActionStatus> microActionsStatus; // Statut des actions

  const DailyEntry({
    required this.id,
    required this.timestamp,
    required this.reflectionText,
    required this.reflectionType,
    this.declencheur,
    this.souhait,
    this.petitPas,
    required this.emotionalState,
    required this.intensiteEmotionnelle,
    this.emotionPrincipale,
    required this.selectedApproaches,  // 🔧 CORRIGÉ
    this.eclairages = const [],
    this.microActionsStatus = const [],
  });

  /// Entrée vide pour initialisation
  factory DailyEntry.empty() => DailyEntry(
    id: '',
    timestamp: DateTime.now(),
    reflectionText: '',
    reflectionType: ReflectionType.thought,
    emotionalState: EmotionalState.empty(),
    intensiteEmotionnelle: 0,
    selectedApproaches: const [],  // 🔧 CORRIGÉ
  );

  /// Sérialisation vers JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'reflectionText': reflectionText,
    'reflectionType': reflectionType.toString(),
    'declencheur': declencheur,
    'souhait': souhait,
    'petitPas': petitPas,
    'emotionalState': emotionalState.toJson(),
    'intensiteEmotionnelle': intensiteEmotionnelle,
    'emotionPrincipale': emotionPrincipale,
    'selectedApproaches': selectedApproaches,  // 🔧 CORRIGÉ
    'eclairages': eclairages.map((e) => e.toJson()).toList(),
    'microActionsStatus': microActionsStatus.map((m) => m.toJson()).toList(),
  };

  /// Désérialisation depuis JSON
  factory DailyEntry.fromJson(Map<String, dynamic> json) => DailyEntry(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    reflectionText: json['reflectionText'] as String,
    reflectionType: ReflectionType.values.firstWhere(
      (e) => e.toString() == json['reflectionType'],
      orElse: () => ReflectionType.thought,
    ),
    declencheur: json['declencheur'] as String?,
    souhait: json['souhait'] as String?,
    petitPas: json['petitPas'] as String?,
    emotionalState: EmotionalState.fromJson(json['emotionalState'] as Map<String, dynamic>),
    intensiteEmotionnelle: json['intensiteEmotionnelle'] as int,
    emotionPrincipale: json['emotionPrincipale'] as String?,
    selectedApproaches: List<String>.from(json['selectedApproaches'] as List),  // 🔧 CORRIGÉ
    eclairages: (json['eclairages'] as List?)
        ?.map((e) => EclairageEntry.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    microActionsStatus: (json['microActionsStatus'] as List?)
        ?.map((m) => MicroActionStatus.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
  );

  /// Copie avec modifications
  DailyEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? reflectionText,
    ReflectionType? reflectionType,
    String? declencheur,
    String? souhait,
    String? petitPas,
    EmotionalState? emotionalState,
    int? intensiteEmotionnelle,
    String? emotionPrincipale,
    List<String>? selectedApproaches,  // 🔧 CORRIGÉ
    List<EclairageEntry>? eclairages,
    List<MicroActionStatus>? microActionsStatus,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      reflectionText: reflectionText ?? this.reflectionText,
      reflectionType: reflectionType ?? this.reflectionType,
      declencheur: declencheur ?? this.declencheur,
      souhait: souhait ?? this.souhait,
      petitPas: petitPas ?? this.petitPas,
      emotionalState: emotionalState ?? this.emotionalState,
      intensiteEmotionnelle: intensiteEmotionnelle ?? this.intensiteEmotionnelle,
      emotionPrincipale: emotionPrincipale ?? this.emotionPrincipale,
      selectedApproaches: selectedApproaches ?? this.selectedApproaches,  // 🔧 CORRIGÉ
      eclairages: eclairages ?? this.eclairages,
      microActionsStatus: microActionsStatus ?? this.microActionsStatus,
    );
  }

  /// Getters utiles
  bool get hasContext => 
      (declencheur?.isNotEmpty ?? false) || 
      (souhait?.isNotEmpty ?? false) || 
      (petitPas?.isNotEmpty ?? false);

  bool get hasEclairages => eclairages.isNotEmpty;

  bool get hasMicroActions => microActionsStatus.isNotEmpty;

  bool get hasEmotions => emotionalState.emotions.values.any((e) => e.level > 0);

  /// Nombre d'émotions actives
  int get activeEmotionsCount => 
      emotionalState.emotions.values.where((e) => e.level > 0).length;

  /// Émotions les plus intenses (niveau ≥ 7)
  List<String> get highIntensityEmotions => 
      emotionalState.emotions.entries
          .where((e) => e.value.level >= 7)
          .map((e) => e.key)
          .toList();

  /// Actions réussies
  List<MicroActionStatus> get successfulActions => 
      microActionsStatus.where((a) => a.isSuccessful).toList();

  /// Actions échouées
  List<MicroActionStatus> get failedActions => 
      microActionsStatus.where((a) => a.isFailed).toList();

  /// Actions en attente
  List<MicroActionStatus> get pendingActions => 
      microActionsStatus.where((a) => a.isPending).toList();

  /// Taux de succès des actions (0.0 à 1.0)
  double get actionSuccessRate {
    if (microActionsStatus.isEmpty) return 0.0;
    
    final attempted = microActionsStatus.where((a) => a.isAttempted).length;
    if (attempted == 0) return 0.0;
    
    final successful = successfulActions.length;
    return successful / attempted;
  }

  /// Résumé de l'entrée
  String get summary {
    if (reflectionText.length <= 100) return reflectionText;
    return '${reflectionText.substring(0, 97)}...';
  }

  /// Date formatée
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).round()} semaines';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Heure formatée
  String get formattedTime => 
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  /// Tags automatiques basés sur le contenu
  List<String> get autoTags {
    final tags = <String>[];
    
    // Tag par intensité
    if (intensiteEmotionnelle >= 8) tags.add('Intense');
    if (intensiteEmotionnelle <= 3) tags.add('Calme');
    
    // Tag par contexte
    if (hasContext) tags.add('Contexte');
    if (hasMicroActions) tags.add('Actions');
    
    // Tag par type
    tags.add(reflectionType.toString().split('.').last.toLowerCase());
    
    // Tag par nombre d'approches
    if (selectedApproaches.length > 3) tags.add('Multi-approches');  // 🔧 CORRIGÉ
    
    return tags;
  }

  @override
  String toString() => 'DailyEntry($id: ${summary.substring(0, 30)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ timestamp.hashCode;
}

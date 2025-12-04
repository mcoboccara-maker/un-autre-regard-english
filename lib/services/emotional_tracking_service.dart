// lib/services/emotional_tracking_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_entry.dart';
import '../models/emotional_state.dart';
import 'persistent_storage_service.dart';

class EmotionalTrackingService {
  static final EmotionalTrackingService instance = EmotionalTrackingService._();
  EmotionalTrackingService._();

  final PersistentStorageService _storage = PersistentStorageService.instance;
  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String get _userEmail => _storage.currentUserEmail ?? '';

  /// Sauvegarder une saisie d'humeur quotidienne
  Future<void> saveMoodEntry(MoodEntry entry) async {
    await _ensureInitialized();
    
    if (_userEmail.isEmpty) return;
    
    final key = 'mood_entries_$_userEmail';
    final existingEntries = await getMoodEntries();
    
    // Vérifier si une entrée existe déjà pour cette date
    existingEntries.removeWhere((e) => 
      e.date.year == entry.date.year &&
      e.date.month == entry.date.month &&
      e.date.day == entry.date.day
    );
    
    existingEntries.add(entry);
    
    // Sauvegarder
    final jsonList = existingEntries.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs!.setStringList(key, jsonList);
    
    print('✅ Humeur quotidienne sauvegardée pour ${entry.date}');
  }

  /// Récupérer toutes les entrées d'humeur
  Future<List<MoodEntry>> getMoodEntries() async {
    await _ensureInitialized();
    
    if (_userEmail.isEmpty) return [];
    
    final key = 'mood_entries_$_userEmail';
    final jsonList = _prefs!.getStringList(key) ?? [];
    
    return jsonList.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return MoodEntry.fromJson(data);
    }).toList();
  }

  /// Récupérer les entrées des X derniers jours
  Future<List<MoodEntry>> getEntriesForLastDays(int days) async {
    final allEntries = await getMoodEntries();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allEntries.where((entry) => 
      entry.date.isAfter(cutoffDate) || entry.date.isAtSameMomentAs(cutoffDate)
    ).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Récupérer l'entrée d'aujourd'hui
  Future<MoodEntry?> getTodayEntry() async {
    final allEntries = await getMoodEntries();
    final today = DateTime.now();
    
    try {
      return allEntries.firstWhere(
        (entry) =>
          entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Agréger les émotions depuis les réflexions
  Future<Map<String, List<EmotionDataPoint>>> aggregateEmotionsFromReflections(int days) async {
    final reflections = _storage.getAllReflections();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final recentReflections = reflections.where((r) => 
      r.createdAt.isAfter(cutoffDate)  // ← Utiliser createdAt au lieu de timestamp
    ).toList();
    
    // Grouper par émotion
    final Map<String, List<EmotionDataPoint>> emotionTimelines = {};
    
    for (final reflection in recentReflections) {
      for (final emotionEntry in reflection.emotionalState.emotions.entries) {
        if (emotionEntry.value.level > 0) {
          emotionTimelines.putIfAbsent(emotionEntry.key, () => []);
          emotionTimelines[emotionEntry.key]!.add(
            EmotionDataPoint(
              date: reflection.createdAt,  // ← Utiliser createdAt
              intensity: emotionEntry.value.level,
              source: 'reflection',
              nuances: emotionEntry.value.nuances,
              timestamp: reflection.createdAt,  // ← Utiliser createdAt
            ),
          );
        }
      }
    }
    
    return emotionTimelines;
  }

  /// Fusionner les données des entrées quotidiennes et des réflexions
  Future<Map<String, List<EmotionDataPoint>>> getCompleteEmotionTimeline(int days) async {
    print('🔍 EmotionalTracking: Récupération timeline pour $days jours');
    
    final moodEntries = await getEntriesForLastDays(days);
    print('📊 MoodEntries trouvées: ${moodEntries.length}');
    
    final reflectionData = await aggregateEmotionsFromReflections(days);
    print('📊 Reflections agrégées: ${reflectionData.length} émotions');
    
    // Combiner les deux sources
    final Map<String, List<EmotionDataPoint>> combined = Map.from(reflectionData);
    
    for (final entry in moodEntries) {
      print('   Processing MoodEntry du ${entry.date}: ${entry.emotions.length} émotions');
      for (final emotionEntry in entry.emotions.entries) {
        combined.putIfAbsent(emotionEntry.key, () => []);
        combined[emotionEntry.key]!.add(
          EmotionDataPoint(
            date: entry.date,
            intensity: emotionEntry.value.intensity,
            source: 'mood',
            nuances: emotionEntry.value.nuances,
            timestamp: entry.createdAt,
          ),
        );
      }
    }
    
    // Trier chaque timeline par date
    for (final timeline in combined.values) {
      timeline.sort((a, b) => a.date.compareTo(b.date));
    }
    
    print('✅ Timeline combinée: ${combined.length} émotions au total');
    
    return combined;
  }

  /// Obtenir les statistiques d'humeur sur une période
  Future<MoodStatistics> getMoodStatistics(int days) async {
    final entries = await getEntriesForLastDays(days);
    
    if (entries.isEmpty) {
      return MoodStatistics.empty();
    }
    
    // Compter les occurrences de chaque émotion
    final emotionCounts = <String, int>{};
    final emotionIntensities = <String, List<int>>{};
    
    for (final entry in entries) {
      for (final emotion in entry.emotions.entries) {
        emotionCounts[emotion.key] = (emotionCounts[emotion.key] ?? 0) + 1;
        emotionIntensities.putIfAbsent(emotion.key, () => []);
        emotionIntensities[emotion.key]!.add(emotion.value.intensity);
      }
    }
    
    // Calculer les moyennes
    final emotionAverages = <String, double>{};
    for (final entry in emotionIntensities.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      emotionAverages[entry.key] = sum / entry.value.length;
    }
    
    // Trouver l'émotion dominante
    String? dominantEmotion;
    int maxCount = 0;
    for (final entry in emotionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominantEmotion = entry.key;
      }
    }
    
    return MoodStatistics(
      totalEntries: entries.length,
      emotionCounts: emotionCounts,
      emotionAverages: emotionAverages,
      dominantEmotion: dominantEmotion,
      periodDays: days,
    );
  }
}

/// Point de données pour le graphique
class EmotionDataPoint {
  final DateTime date;
  final int intensity;
  final String source;           // 'mood' ou 'reflection'
  final List<String> nuances;    // Nuances de l'émotion
  final DateTime? timestamp;     // Horodatage exact (avec heure)
  
  EmotionDataPoint({
    required this.date,
    required this.intensity,
    required this.source,
    this.nuances = const [],
    this.timestamp,
  });
}

/// Statistiques d'humeur
class MoodStatistics {
  final int totalEntries;
  final Map<String, int> emotionCounts;
  final Map<String, double> emotionAverages;
  final String? dominantEmotion;
  final int periodDays;
  
  const MoodStatistics({
    required this.totalEntries,
    required this.emotionCounts,
    required this.emotionAverages,
    this.dominantEmotion,
    required this.periodDays,
  });
  
  factory MoodStatistics.empty() => const MoodStatistics(
    totalEntries: 0,
    emotionCounts: {},
    emotionAverages: {},
    dominantEmotion: null,
    periodDays: 0,
  );
  
  bool get isEmpty => totalEntries == 0;
}

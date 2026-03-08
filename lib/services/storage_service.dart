import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();

  // Noms des boxes
  static const String _userProfileBox = 'user_profile';
  static const String _reflectionsBox = 'reflections';
  static const String _emotionalStatesBox = 'emotional_states';
  static const String _settingsBox = 'settings';

  // Boxes Hive
  late Box<UserProfile> _userProfileBox_;
  late Box<Reflection> _reflectionsBox_;
  late Box<EmotionalState> _emotionalStatesBox_;
  late Box _settingsBox_;

  bool _isInitialized = false;

  /// Initialise Hive et ouvre les boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Enregistrer les adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EmotionalStateAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EmotionLevelAdapter());
    }
    //if (!Hive.isAdapterRegistered(2)) {
    //  Hive.registerAdapter(ReflectionAdapter());
    //}
    //if (!Hive.isAdapterRegistered(3)) {
    //  Hive.registerAdapter(ReflectionTypeAdapter());
    //}
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(UserProfileAdapter());
    }

    // Ouvrir les boxes
    _userProfileBox_ = await Hive.openBox<UserProfile>(_userProfileBox);
    _reflectionsBox_ = await Hive.openBox<Reflection>(_reflectionsBox);
    _emotionalStatesBox_ = await Hive.openBox<EmotionalState>(_emotionalStatesBox);
    _settingsBox_ = await Hive.openBox(_settingsBox);

    _isInitialized = true;
  }

  /// Profil utilisateur
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userProfileBox_.put('current', profile);
  }

  UserProfile? getUserProfile() {
    return _userProfileBox_.get('current');
  }

  Future<void> deleteUserProfile() async {
    await _userProfileBox_.delete('current');
  }

  /// Réflexions
  Future<void> saveReflection(Reflection reflection) async {
    await _reflectionsBox_.put(reflection.id, reflection);
  }

  List<Reflection> getAllReflections() {
    return _reflectionsBox_.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Reflection? getReflection(String id) {
    return _reflectionsBox_.get(id);
  }

  Future<void> deleteReflection(String id) async {
    await _reflectionsBox_.delete(id);
  }

  Future<void> updateReflection(Reflection reflection) async {
    await _reflectionsBox_.put(reflection.id, reflection);
  }

  /// Obtenir les dernières réflexions pour le contexte IA
  List<Reflection> getRecentReflectionsForContext({int limit = 5}) {
    final reflections = getAllReflections();
    return reflections.take(limit).toList();
  }

  /// Rechercher des réflexions par mots-clés
  List<Reflection> searchReflections(String query) {
    if (query.trim().isEmpty) return getAllReflections();
    
    final lowerQuery = query.toLowerCase();
    return getAllReflections().where((reflection) {
      return reflection.text.toLowerCase().contains(lowerQuery) ||
             reflection.text.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// États émotionnels
  Future<void> saveEmotionalState(EmotionalState state) async {
    final key = state.timestamp.millisecondsSinceEpoch.toString();
    await _emotionalStatesBox_.put(key, state);
  }

  List<EmotionalState> getAllEmotionalStates() {
    return _emotionalStatesBox_.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  EmotionalState? getLatestEmotionalState() {
    final states = getAllEmotionalStates();
    return states.isNotEmpty ? states.first : null;
  }

  /// Obtenir les états émotionnels dans une période
  List<EmotionalState> getEmotionalStatesInPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    return getAllEmotionalStates().where((state) {
      return state.timestamp.isAfter(start) && state.timestamp.isBefore(end);
    }).toList();
  }

  /// Paramètres de l'application
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox_.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox_.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox_.delete(key);
  }

  /// Paramètres spécifiques
  
  // Approches sélectionnées par défaut
  Future<void> saveDefaultApproaches(List<String> approaches) async {
    await saveSetting('default_approaches', approaches);
  }

  List<String> getDefaultApproaches() {
    return List<String>.from(getSetting('default_approaches', defaultValue: []) ?? []);
  }

  // Première utilisation
  Future<void> setFirstLaunch(bool isFirst) async {
    await saveSetting('is_first_launch', isFirst);
  }

  bool isFirstLaunch() {
    return getSetting('is_first_launch', defaultValue: true) ?? true;
  }

  // Paramètres d'accessibilité
  Future<void> saveAccessibilitySettings(Map<String, dynamic> settings) async {
    await saveSetting('accessibility_settings', settings);
  }

  Map<String, dynamic> getAccessibilitySettings() {
    return Map<String, dynamic>.from(
      getSetting('accessibility_settings', defaultValue: {}) ?? {}
    );
  }

  /// Statistiques et analytics locales
  
  // Nombre total de réflexions
  int getTotalReflectionsCount() {
    return _reflectionsBox_.length;
  }

  // Réflexions par type
  Map<ReflectionType, int> getReflectionsByType() {
    final reflections = getAllReflections();
    final counts = <ReflectionType, int>{};
    
    for (final type in ReflectionType.values) {
      counts[type] = reflections.where((r) => r.type == type).length;
    }
    
    return counts;
  }

  // Émotions les plus fréquentes
  Map<String, double> getMostFrequentEmotions() {
    final states = getAllEmotionalStates();
    final emotionSums = <String, double>{};
    final emotionCounts = <String, int>{};

    for (final state in states) {
      for (final entry in state.emotions.entries) {
        if (entry.value.level > 0) {
          emotionSums[entry.key] = (emotionSums[entry.key] ?? 0) + entry.value.level;
          emotionCounts[entry.key] = (emotionCounts[entry.key] ?? 0) + 1;
        }
      }
    }

    final averages = <String, double>{};
    for (final emotion in emotionSums.keys) {
      averages[emotion] = emotionSums[emotion]! / emotionCounts[emotion]!;
    }

    // Trier par valeur décroissante
    final sortedEntries = averages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Nettoyage et maintenance
  
  // Supprimer les données anciennes (plus de X jours)
  Future<void> cleanOldData({int daysBefore = 365}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBefore));
    
    // Nettoyer les anciens états émotionnels
    final oldEmotionalStates = _emotionalStatesBox_.keys.where((key) {
      final state = _emotionalStatesBox_.get(key);
      return state?.timestamp.isBefore(cutoffDate) ?? false;
    }).toList();

    for (final key in oldEmotionalStates) {
      await _emotionalStatesBox_.delete(key);
    }
  }

  /// Export/Import des données
  
  // Exporter toutes les données en JSON
  Map<String, dynamic> exportAllData() {
    return {
      'userProfile': getUserProfile()?.toJson(),
      'reflections': getAllReflections().map((r) => r.toJson()).toList(),
      'emotionalStates': getAllEmotionalStates().map((e) => e.toJson()).toList(),
      'settings': _settingsBox_.toMap(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.0.0',
    };
  }

  // Importer des données depuis JSON
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Importer le profil utilisateur
      if (data['userProfile'] != null) {
        final profile = UserProfile.fromJson(data['userProfile']);
        await saveUserProfile(profile);
      }

      // Importer les réflexions
      if (data['reflections'] != null) {
        for (final reflectionData in data['reflections']) {
          final reflection = Reflection.fromJson(reflectionData);
          await saveReflection(reflection);
        }
      }

      // Importer les états émotionnels
      if (data['emotionalStates'] != null) {
        for (final stateData in data['emotionalStates']) {
          final state = EmotionalState.fromJson(stateData);
          await saveEmotionalState(state);
        }
      }

      // Importer les paramètres
      if (data['settings'] != null) {
        for (final entry in (data['settings'] as Map).entries) {
          await saveSetting(entry.key, entry.value);
        }
      }
    } catch (e) {
      throw Exception('Error during data import: $e');
    }
  }

  /// Fermer les boxes (pour les tests ou nettoyage)
  Future<void> closeBoxes() async {
    await _userProfileBox_.close();
    await _reflectionsBox_.close();
    await _emotionalStatesBox_.close();
    await _settingsBox_.close();
    _isInitialized = false;
  }

  /// Supprimer toutes les données
  Future<void> clearAllData() async {
    await _userProfileBox_.clear();
    await _reflectionsBox_.clear();
    await _emotionalStatesBox_.clear();
    await _settingsBox_.clear();
  }
}

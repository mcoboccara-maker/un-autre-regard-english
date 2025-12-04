import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../../services/persistent_storage_service.dart';

/// Extension du StorageService avec support email et sauvegarde par fichiers
class PersistentStorageService {
  static PersistentStorageService? _instance;
  static PersistentStorageService get instance => _instance ??= PersistentStorageService._();
  
  PersistentStorageService._();

  // Boxes Hive (similaires au StorageService original)
  late Box<UserProfile> _userProfileBox_;
  late Box<Reflection> _reflectionsBox_;
  late Box<EmotionalState> _emotionalStatesBox_;
  late Box _settingsBox_;

  bool _isInitialized = false;
  String? _currentUserEmail;

  /// 🆕 Initialise avec un email utilisateur spécifique
  Future<void> initializeWithEmail(String? email) async {
    if (_isInitialized && _currentUserEmail == email) return;

    _currentUserEmail = email?.trim().toLowerCase();
    
    // Fermer les boxes existantes si déjà ouvertes
    if (_isInitialized) {
      await _closeBoxes();
    }

    await Hive.initFlutter();

    // Enregistrer les adapters
    _registerAdapters();

    // Créer des noms de boxes uniques par email
    final suffix = _getSafeEmailSuffix(_currentUserEmail);
    
    // Ouvrir les boxes avec des noms uniques
    _userProfileBox_ = await Hive.openBox<UserProfile>('user_profile_$suffix');
    _reflectionsBox_ = await Hive.openBox<Reflection>('reflections_$suffix');
    _emotionalStatesBox_ = await Hive.openBox<EmotionalState>('emotional_states_$suffix');
    _settingsBox_ = await Hive.openBox('settings_$suffix');

    _isInitialized = true;
  }

  /// 🆕 Génère un suffixe sécurisé basé sur l'email
  String _getSafeEmailSuffix(String? email) {
    if (email == null || email.isEmpty) {
      return 'default';
    }
    
    return email
        .toLowerCase()
        .replaceAll('@', '_at_')
        .replaceAll('.', '_')
        .replaceAll('+', '_plus_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }

  void _registerAdapters() {
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
  }

  /// 🆕 Changer d'utilisateur (basculer vers un autre email)
  Future<void> switchUser(String? newEmail) async {
    if (_currentUserEmail != newEmail?.trim().toLowerCase()) {
      await initializeWithEmail(newEmail);
    }
  }

  /// 🆕 Sauvegarder les données utilisateur dans un fichier JSON local
  Future<String> exportUserDataToFile() async {
    if (!_isInitialized) {
      throw StateError('PersistentStorageService non initialisé');
    }

    try {
      final data = _exportAllUserData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Obtenir le répertoire de documents de l'application
      final directory = await getApplicationDocumentsDirectory();
      
      // Créer le dossier Un Autre Regard s'il n'existe pas
      final appDirectory = Directory('${directory.path}/UnAutreRegard');
      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
      }
      
      // Créer le nom de fichier avec email et timestamp
      final email = _currentUserEmail ?? 'default';
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'un_autre_regard_${_getSafeEmailSuffix(email)}_$timestamp.json';
      
      final file = File('${appDirectory.path}/$fileName');
      await file.writeAsString(jsonString);
      
      print('✅ Sauvegarde créée: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ Erreur lors de l\'export: $e');
      throw Exception('Erreur lors de l\'export: $e');
    }
  }

  /// 🆕 Charger les données utilisateur depuis un fichier JSON
  Future<void> importUserDataFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier non trouvé: $filePath');
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      await _importUserData(data);
      print('✅ Import réussi depuis: $filePath');
    } catch (e) {
      print('❌ Erreur lors de l\'import: $e');
      throw Exception('Erreur lors de l\'import: $e');
    }
  }

  /// 🆕 Sauvegarde automatique (appelée après chaque modification)
  Future<void> autoBackupUserData() async {
    try {
      // Ne faire la sauvegarde que si on a des données
      if (getUserProfile() != null || getAllReflections().isNotEmpty) {
        await exportUserDataToFile();
      }
    } catch (e) {
      print('⚠️ Erreur sauvegarde automatique: $e');
      // Ne pas faire échouer l'opération principale
    }
  }

  /// 🆕 Obtenir la liste des fichiers de sauvegarde existants
  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appDirectory = Directory('${directory.path}/UnAutreRegard');
      
      if (!await appDirectory.exists()) {
        return [];
      }
      
      final files = await appDirectory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      // Trier par date de modification (plus récent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      print('❌ Erreur lecture fichiers backup: $e');
      return [];
    }
  }

  // === MÉTHODES DE STOCKAGE (compatibles avec le StorageService original) ===
  
  /// Profil utilisateur
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userProfileBox_.put('current', profile);
    
    // 🆕 Déclencher une sauvegarde automatique
    await autoBackupUserData();
  }

  UserProfile? getUserProfile() {
    return _userProfileBox_.get('current');
  }

  Future<void> deleteUserProfile() async {
    await _userProfileBox_.delete('current');
    await autoBackupUserData();
  }

  /// Réflexions
  Future<void> saveReflection(Reflection reflection) async {
    await _reflectionsBox_.put(reflection.id, reflection);
    await autoBackupUserData();
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
    await autoBackupUserData();
  }

  List<Reflection> getRecentReflectionsForContext({int limit = 5}) {
    final reflections = getAllReflections();
    return reflections.take(limit).toList();
  }

  /// États émotionnels
  Future<void> saveEmotionalState(EmotionalState state) async {
    final key = state.timestamp.millisecondsSinceEpoch.toString();
    await _emotionalStatesBox_.put(key, state);
    await autoBackupUserData();
  }

  List<EmotionalState> getAllEmotionalStates() {
    return _emotionalStatesBox_.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  EmotionalState? getLatestEmotionalState() {
    final states = getAllEmotionalStates();
    return states.isNotEmpty ? states.first : null;
  }

  /// Paramètres
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox_.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox_.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> saveDefaultApproaches(List<String> approaches) async {
    await saveSetting('default_approaches', approaches);
  }

  List<String> getDefaultApproaches() {
    return List<String>.from(getSetting('default_approaches', defaultValue: []) ?? []);
  }

  // === MÉTHODES PRIVÉES ===

  Map<String, dynamic> _exportAllUserData() {
    return {
      'email': _currentUserEmail,
      'userProfile': getUserProfile()?.toJson(),
      'reflections': getAllReflections().map((r) => r.toJson()).toList(),
      'emotionalStates': getAllEmotionalStates().map((e) => e.toJson()).toList(),
      'settings': _settingsBox_.toMap(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.1.0',
    };
  }

  Future<void> _importUserData(Map<String, dynamic> data) async {
    try {
      // Importer le profil utilisateur
      if (data['userProfile'] != null) {
        final profile = UserProfile.fromJson(data['userProfile']);
        await _userProfileBox_.put('current', profile);
      }

      // Importer les réflexions
      if (data['reflections'] != null) {
        for (final reflectionData in data['reflections']) {
          final reflection = Reflection.fromJson(reflectionData);
          await _reflectionsBox_.put(reflection.id, reflection);
        }
      }

      // Importer les états émotionnels
      if (data['emotionalStates'] != null) {
        for (final stateData in data['emotionalStates']) {
          final state = EmotionalState.fromJson(stateData);
          final key = state.timestamp.millisecondsSinceEpoch.toString();
          await _emotionalStatesBox_.put(key, state);
        }
      }

      // Importer les paramètres
      if (data['settings'] != null) {
        for (final entry in (data['settings'] as Map).entries) {
          await _settingsBox_.put(entry.key, entry.value);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'importation: $e');
    }
  }

  Future<void> _closeBoxes() async {
    if (_isInitialized) {
      await _userProfileBox_.close();
      await _reflectionsBox_.close();
      await _emotionalStatesBox_.close();
      await _settingsBox_.close();
    }
  }

  /// Fermer toutes les connexions
  Future<void> dispose() async {
    await _closeBoxes();
    _isInitialized = false;
    _currentUserEmail = null;
  }

  /// Supprimer toutes les données de l'utilisateur actuel
  Future<void> clearAllData() async {
    await _userProfileBox_.clear();
    await _reflectionsBox_.clear();
    await _emotionalStatesBox_.clear();
    await _settingsBox_.clear();
    await autoBackupUserData(); // Sauvegarder l'état vide
  }
}

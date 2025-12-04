import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import 'complete_auth_service.dart';

/// SERVICE UNIFIE COMPLET AVEC TOUTES LES METHODES
class PersistentStorageService {
  static PersistentStorageService? _instance;
  static PersistentStorageService get instance => _instance ??= PersistentStorageService._();
  
  PersistentStorageService._();

  SharedPreferences? _prefs;
  String? _currentUserEmail;

  ///  Initialisation
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
    _currentUserEmail = _prefs!.getString('current_user_email');
  }

  bool get isUserLoggedIn => _currentUserEmail != null && _currentUserEmail!.isNotEmpty;

  String? get currentUserEmail => _currentUserEmail;  // â† GETTER AU NIVEAU CLASSE

  /// Definir l'utilisateur actuel
  Future<void> setCurrentUser(String email) async {
    await _ensureInitialized();
    _currentUserEmail = email;
    await _prefs!.setString('current_user_email', email);
    await _prefs!.setBool('user_logged_in', true);
  }

  /// Deconnexion
  Future<void> logout() async {
    await _ensureInitialized();
    _currentUserEmail = null;
    await _prefs!.remove('current_user_email');
    await _prefs!.setBool('user_logged_in', false);
    print(' Utilisateur deconnecte');
  }

  // ==================== REFLEXIONS ====================

  /// Sauvegarder une reflexion
  Future<void> saveReflection(Reflection reflection) async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) {
      print('âš ï¸ Tentative sauvegarde reflexion sans utilisateur connecte');
      return;
    }
    
    final email = _currentUserEmail!;
    final key = 'reflections_$email';
    
    final existingReflections = _prefs!.getStringList(key) ?? [];
    existingReflections.add(jsonEncode(reflection.toJson()));
    
    await _prefs!.setStringList(key, existingReflections);
    print(' Reflexion sauvegardee pour: $email');
  }

  /// Recuperer toutes les reflexions
  List<Reflection> getAllReflections() {
    if (!isUserLoggedIn) return [];
    
    final email = _currentUserEmail!;
    final key = 'reflections_$email';
    final reflectionsData = _prefs?.getStringList(key) ?? [];
    
    final reflections = <Reflection>[];
    for (final reflectionJson in reflectionsData) {
      try {
        final reflectionMap = jsonDecode(reflectionJson) as Map<String, dynamic>;
        reflections.add(Reflection.fromJson(reflectionMap));
      } catch (e) {
        print('âš ï¸ Erreur decodage reflexion: $e');
      }
    }
    
    // Trier par date decroissante
    reflections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reflections;
  }

  // ==================== PROFIL UTILISATEUR ====================

  /// Sauvegarde le profil utilisateur
  Future<void> saveUserProfile(UserProfile profile) async {
    await _ensureInitialized();
    
    final email = _currentUserEmail;
    if (email == null) {
      print('âš ï¸ Aucun utilisateur connecte pour sauvegarder le profil');
      return;
    }
    
    final profileJson = jsonEncode(profile.toJson());
    await _prefs!.setString('user_profile_$email', profileJson);
    
    print(' Profil sauvegarde pour : $email');
  }

  /// Recupere le profil utilisateur
  UserProfile? getUserProfile() {
    final email = _currentUserEmail;
    if (!isUserLoggedIn || email == null) return null;
    
    final profileJson = _prefs?.getString('user_profile_$email');
    if (profileJson == null) return null;
    
    try {
      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromJson(profileMap);
    } catch (e) {
      print('âŒ Erreur lecture profil: $e');
      return null;
    }
  }

  // ==================== APPROCHES UTILISATEUR ====================

  ///  Sauvegarder les approches par defaut de l'utilisateur
  Future<void> saveDefaultApproaches(List<String> approaches) async {
    await _ensureInitialized();
    
    final email = _currentUserEmail;
    if (email == null) return;
    
    await _prefs!.setStringList('default_approaches_$email', approaches);
    print(' Approches par defaut sauvegardees: $approaches');
  }

  ///  Recuperer les approches par defaut de l'utilisateur
  Future<List<String>> getDefaultApproaches() async {
    await _ensureInitialized();
    
    final email = _currentUserEmail;
    if (email == null) return [];
    
    return _prefs?.getStringList('default_approaches_$email') ?? [];
  }

  /// Obtenir les approches de l'utilisateur depuis son profil (5 categories)
  Future<List<String>> getUserApproaches() async {
    // D'abord essayer via CompleteAuthService pour avoir les 5 categories
    try {
      final profileData = await CompleteAuthService.instance.getProfile();
      if (profileData != null) {
        final List<String> allApproaches = [];
        
        // 1. Sources spirituelles
        allApproaches.addAll(List<String>.from(profileData['religionsSelectionnees'] ?? []));
        
        // 2. Courants litteraires
        allApproaches.addAll(List<String>.from(profileData['courantsLitteraires'] ?? []));
        
        // 3. Approches psychologiques
        allApproaches.addAll(List<String>.from(profileData['approchesPsychologiques'] ?? []));
        
        // 4. Courants philosophiques
        allApproaches.addAll(List<String>.from(profileData['courantsPhilosophiques'] ?? []));
        
        // 5. Philosophes individuels
        allApproaches.addAll(List<String>.from(profileData['philosophesSelectionnes'] ?? []));
        
        return allApproaches;
      }
    } catch (e) {
      print('Erreur getUserApproaches via CompleteAuthService: $e');
    }
    
    // Fallback sur le profil Hive (sans philosophies)
    final profile = getUserProfile();
    if (profile == null) return [];
    
    final List<String> allApproaches = [];
    allApproaches.addAll(profile.religionsSelectionnees);
    allApproaches.addAll(profile.courantsLitteraires);
    allApproaches.addAll(profile.approchesPsychologiques);
    
    return allApproaches;
  }

  // ==================== SAUVEGARDE FICHIERS ====================

  ///  Initialiser avec un email specifique
  Future<void> initializeWithEmail(String? email) async {
    await _ensureInitialized();
    if (email != null) {
      await setCurrentUser(email);
    }
  }

  ///  Export vers fichier JSON
  Future<String> exportUserDataToFile() async {
    if (!isUserLoggedIn) {
      throw StateError('Aucun utilisateur connecte');
    }

    try {
      final data = _exportAllUserData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Obtenir le repertoire de documents de l'application
      final directory = await getApplicationDocumentsDirectory();
      
      // Creer le dossier Un Autre Regard s'il n'existe pas
      final appDirectory = Directory('${directory.path}/UnAutreRegard');
      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
      }
      
      // Creer le nom de fichier avec email et timestamp
      final email = _currentUserEmail ?? 'default';
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'un_autre_regard_${_getSafeEmailSuffix(email)}_$timestamp.json';
      
      final file = File('${appDirectory.path}/$fileName');
      await file.writeAsString(jsonString);
      
      print(' Sauvegarde creee: ${file.path}');
      return file.path;
    } catch (e) {
      print('âŒ Erreur lors de l\'export: $e');
      throw Exception('Erreur lors de l\'export: $e');
    }
  }

  ///  Import depuis fichier JSON
  Future<void> importUserDataFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier non trouve: $filePath');
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      await _importUserData(data);
      print(' Import reussi depuis: $filePath');
    } catch (e) {
      print('âŒ Erreur lors de l\'import: $e');
      throw Exception('Erreur lors de l\'import: $e');
    }
  }

  ///  Obtenir la liste des fichiers de sauvegarde
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
      
      // Trier par date de modification (plus recent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      print('âŒ Erreur lecture fichiers backup: $e');
      return [];
    }
  }

  // ==================== METHODES PRIVEES ====================

  /// Genere un suffixe securise base sur l'email
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

  /// Exporter toutes les donnees utilisateur
  Map<String, dynamic> _exportAllUserData() {
    return {
      'email': _currentUserEmail,
      'userProfile': getUserProfile()?.toJson(),
      'reflections': getAllReflections().map((r) => r.toJson()).toList(),
      'settings': {
        'defaultApproaches': _prefs?.getStringList('default_approaches_$_currentUserEmail') ?? [],
      },
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.1.0',
    };
  }

  /// Importer des donnees utilisateur
  Future<void> _importUserData(Map<String, dynamic> data) async {
    try {
      // Importer le profil utilisateur
      if (data['userProfile'] != null) {
        final profile = UserProfile.fromJson(data['userProfile']);
        await saveUserProfile(profile);
      }

      // Importer les reflexions
      if (data['reflections'] != null) {
        for (final reflectionData in data['reflections']) {
          final reflection = Reflection.fromJson(reflectionData);
          await saveReflection(reflection);
        }
      }

      // Importer les parametres
      if (data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;
        if (settings['defaultApproaches'] != null) {
          final approaches = List<String>.from(settings['defaultApproaches']);
          await saveDefaultApproaches(approaches);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'importation: $e');
    }
  }

  // ==================== NETTOYAGE ====================

  /// Supprimer toutes les donnees de l'utilisateur actuel
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    final email = _currentUserEmail;
    if (email == null) return;
    
    // Supprimer toutes les donnees liees Ã  cet utilisateur
    await _prefs!.remove('user_profile_$email');
    await _prefs!.remove('reflections_$email');
    await _prefs!.remove('default_approaches_$email');
    
    print(' Toutes les donnees utilisateur supprimees');
  }

  /// Supprimer une reflexion specifique
  Future<void> deleteReflection(String reflectionId) async {
    if (!isUserLoggedIn) return;
    
    final reflections = getAllReflections();
    reflections.removeWhere((r) => r.id == reflectionId);
    
    // Resauvegarder la liste
    final email = _currentUserEmail!;
    final key = 'reflections_$email';
    final reflectionsJson = reflections.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs!.setStringList(key, reflectionsJson);
    
    print(' Reflexion supprimee: $reflectionId');
  }

  /// Obtenir une reflexion par ID
  Reflection? getReflection(String id) {
    final reflections = getAllReflections();
    try {
      return reflections.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les reflexions recentes pour le contexte IA
  List<Reflection> getRecentReflectionsForContext({int limit = 5}) {
    final reflections = getAllReflections();
    return reflections.take(limit).toList();
  }

  /// Sauvegarder un etat emotionnel
  Future<void> saveEmotionalState(EmotionalState state) async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) return;
    
    final email = _currentUserEmail!;
    final key = 'emotional_states_$email';
    final timestamp = state.timestamp.millisecondsSinceEpoch.toString();
    
    final existingStates = _prefs!.getStringList(key) ?? [];
    existingStates.add(jsonEncode({'timestamp': timestamp, 'state': state.toJson()}));
    
    await _prefs!.setStringList(key, existingStates);
    print(' Etat emotionnel sauvegarde');
  }

  /// Recuperer tous les etats emotionnels
  List<EmotionalState> getAllEmotionalStates() {
    if (!isUserLoggedIn) return [];
    
    final email = _currentUserEmail!;
    final key = 'emotional_states_$email';
    final statesData = _prefs?.getStringList(key) ?? [];
    
    final states = <EmotionalState>[];
    for (final stateJson in statesData) {
      try {
        final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
        final state = EmotionalState.fromJson(stateMap['state']);
        states.add(state);
      } catch (e) {
        print('âš ï¸ Erreur decodage etat emotionnel: $e');
      }
    }
    
    // Trier par timestamp decroissant
    states.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return states;
  }
}

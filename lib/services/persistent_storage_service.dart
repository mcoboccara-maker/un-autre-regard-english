import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import '../models/source_evaluation.dart';
import 'complete_auth_service.dart';

/// SERVICE UNIFIE COMPLET AVEC TOUTES LES METHODES
/// VERSION 2.1 - Ajout gestion des évaluations de perspectives
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

  /// 🆕 Initialise avec un email utilisateur spécifique (compatibilité)
  Future<void> initializeWithEmail(String? email) async {
    await _ensureInitialized();
    if (email != null && email.isNotEmpty) {
      _currentUserEmail = email.trim().toLowerCase();
      await _prefs!.setString('current_user_email', _currentUserEmail!);
      await _prefs!.setBool('user_logged_in', true);
      print('✓ Service initialisé avec email: $_currentUserEmail');
    }
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
    _currentUserEmail = _prefs!.getString('current_user_email');
  }

  bool get isUserLoggedIn => _currentUserEmail != null && _currentUserEmail!.isNotEmpty;

  String? get currentUserEmail => _currentUserEmail;  // GETTER AU NIVEAU CLASSE

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
    print('✓ Utilisateur deconnecte');
  }

  // ==================== REFLEXIONS ====================

  /// Sauvegarder une reflexion
  Future<void> saveReflection(Reflection reflection) async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) {
      print('⚠️ Tentative sauvegarde reflexion sans utilisateur connecte');
      return;
    }
    
    final email = _currentUserEmail!;
    final key = 'reflections_$email';
    
    final existingReflections = _prefs!.getStringList(key) ?? [];
    existingReflections.add(jsonEncode(reflection.toJson()));
    
    await _prefs!.setStringList(key, existingReflections);
    print('✓ Reflexion sauvegardee pour: $email');
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
        print('⚠️ Erreur decodage reflexion: $e');
      }
    }
    
    // Trier par date decroissante
    reflections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reflections;
  }

  // ==================== ÉCLAIRAGES SAUVEGARDÉS ====================

  /// Sauvegarder un éclairage complet (swipe Garder)
  Future<void> saveEclairage(Map<String, dynamic> eclairageJson) async {
    await _ensureInitialized();

    if (!isUserLoggedIn) {
      print('⚠️ Tentative sauvegarde éclairage sans utilisateur connecté');
      return;
    }

    final email = _currentUserEmail!;
    final key = 'saved_eclairages_$email';

    final existingEclairages = _prefs!.getStringList(key) ?? [];
    existingEclairages.add(jsonEncode(eclairageJson));

    await _prefs!.setStringList(key, existingEclairages);
    print('✓ Éclairage sauvegardé pour: $email');
  }

  /// Récupérer tous les éclairages sauvegardés
  List<Map<String, dynamic>> getAllSavedEclairages() {
    if (!isUserLoggedIn) return [];

    final email = _currentUserEmail!;
    final key = 'saved_eclairages_$email';
    final eclairagesData = _prefs?.getStringList(key) ?? [];

    final eclairages = <Map<String, dynamic>>[];
    for (final eclairageJson in eclairagesData) {
      try {
        eclairages.add(jsonDecode(eclairageJson) as Map<String, dynamic>);
      } catch (e) {
        print('⚠️ Erreur décodage éclairage: $e');
      }
    }

    return eclairages;
  }

  // ==================== PROFIL UTILISATEUR ====================

  /// Sauvegarde le profil utilisateur
  Future<void> saveUserProfile(UserProfile profile) async {
    await _ensureInitialized();
    
    final email = _currentUserEmail;
    if (email == null) {
      print('⚠️ Aucun utilisateur connecte pour sauvegarder le profil');
      return;
    }
    
    final profileJson = jsonEncode(profile.toJson());
    await _prefs!.setString('user_profile_$email', profileJson);
    
    print('✓ Profil sauvegarde pour : $email');
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
      print('❌ Erreur lecture profil: $e');
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
    print('✓ Approches par defaut sauvegardees: $approaches');
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
    
    // Fallback sur le profil Hive (5 catégories)
    final profile = getUserProfile();
    if (profile == null) return [];

    final List<String> allApproaches = [];
    allApproaches.addAll(profile.religionsSelectionnees);
    allApproaches.addAll(profile.courantsLitteraires);
    allApproaches.addAll(profile.approchesPsychologiques);
    allApproaches.addAll(profile.courantsPhilosophiques);
    allApproaches.addAll(profile.philosophesSelectionnes);

    return allApproaches;
  }

  // ==================== PERSONNAGES UTILISES (30 JOURS) ====================

  /// Récupérer les personnages utilisés (liste de JSON)
  Future<List<Map<String, dynamic>>> getPersonnagesUtilises() async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) return [];
    
    final email = _currentUserEmail!;
    final key = 'personnages_utilises_$email';
    final data = _prefs?.getString(key);
    
    if (data == null || data.isEmpty) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('⚠️ Erreur lecture personnages utilisés: $e');
      return [];
    }
  }

  /// Sauvegarder les personnages utilisés
  Future<void> savePersonnagesUtilises(List<Map<String, dynamic>> personnages) async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) {
      print('⚠️ Tentative sauvegarde personnages sans utilisateur connecté');
      return;
    }
    
    final email = _currentUserEmail!;
    final key = 'personnages_utilises_$email';
    
    try {
      final jsonString = jsonEncode(personnages);
      await _prefs!.setString(key, jsonString);
      print('✓ Personnages utilisés sauvegardés: ${personnages.length} entrées');
    } catch (e) {
      print('❌ Erreur sauvegarde personnages utilisés: $e');
    }
  }

  /// Ajouter un personnage à la liste des utilisés
  Future<void> addPersonnageUtilise(String nom) async {
    final personnages = await getPersonnagesUtilises();
    
    // Vérifier si déjà présent
    final normalise = nom.toLowerCase().trim();
    final existe = personnages.any((p) => 
        (p['nom'] as String?)?.toLowerCase().trim() == normalise);
    
    if (!existe) {
      personnages.add({
        'nom': nom,
        'date': DateTime.now().toIso8601String(),
      });
      await savePersonnagesUtilises(personnages);
    }
  }

  /// Nettoyer les personnages expirés (>30 jours)
  Future<void> cleanExpiredPersonnages() async {
    final personnages = await getPersonnagesUtilises();
    final now = DateTime.now();
    
    final valides = personnages.where((p) {
      try {
        final date = DateTime.parse(p['date'] as String);
        return now.difference(date).inDays <= 30;
      } catch (e) {
        return false; // Supprimer les entrées invalides
      }
    }).toList();
    
    if (valides.length != personnages.length) {
      await savePersonnagesUtilises(valides);
      print('✓ Personnages nettoyés: ${personnages.length - valides.length} expirés supprimés');
    }
  }

  /// Obtenir la liste des noms de personnages interdits (30 jours)
  Future<List<String>> getPersonnagesInterdits() async {
    await cleanExpiredPersonnages(); // Nettoyer d'abord
    
    final personnages = await getPersonnagesUtilises();
    return personnages
        .map((p) => p['nom'] as String? ?? '')
        .where((nom) => nom.isNotEmpty)
        .toList();
  }

  // ==================== EVALUATIONS DES PERSPECTIVES ====================

  /// Sauvegarder les évaluations d'une réflexion
  Future<void> saveReflectionEvaluations(ReflectionEvaluations evaluations) async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) {
      print('⚠️ Tentative sauvegarde évaluations sans utilisateur connecté');
      return;
    }
    
    final email = _currentUserEmail!;
    final key = 'evaluations_$email';
    
    try {
      // Charger les évaluations existantes
      final existingData = _prefs?.getString(key);
      List<Map<String, dynamic>> allEvaluations = [];
      
      if (existingData != null && existingData.isNotEmpty) {
        final decoded = jsonDecode(existingData) as List<dynamic>;
        allEvaluations = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      // Vérifier si cette réflexion existe déjà (mise à jour)
      final existingIndex = allEvaluations.indexWhere(
        (e) => e['reflectionId'] == evaluations.reflectionId
      );
      
      if (existingIndex >= 0) {
        // Mise à jour
        allEvaluations[existingIndex] = evaluations.toJson();
      } else {
        // Nouvelle entrée
        allEvaluations.add(evaluations.toJson());
      }
      
      // Sauvegarder
      await _prefs!.setString(key, jsonEncode(allEvaluations));
      print('✓ Évaluations sauvegardées: ${evaluations.evaluationCount} notes');
      
    } catch (e) {
      print('❌ Erreur sauvegarde évaluations: $e');
    }
  }

  /// Récupérer toutes les évaluations
  Future<List<ReflectionEvaluations>> getAllEvaluations() async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) return [];
    
    final email = _currentUserEmail!;
    final key = 'evaluations_$email';
    final data = _prefs?.getString(key);
    
    if (data == null || data.isEmpty) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => ReflectionEvaluations.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ Erreur lecture évaluations: $e');
      return [];
    }
  }

  /// Récupérer les évaluations non exportées
  Future<List<ReflectionEvaluations>> getUnexportedEvaluations() async {
    final all = await getAllEvaluations();
    return all.where((e) => !e.isExported).toList();
  }

  /// Marquer des évaluations comme exportées
  Future<void> markEvaluationsAsExported(List<String> reflectionIds) async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) return;
    
    final email = _currentUserEmail!;
    final key = 'evaluations_$email';
    
    try {
      final data = _prefs?.getString(key);
      if (data == null || data.isEmpty) return;
      
      final List<dynamic> decoded = jsonDecode(data);
      final updated = decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (reflectionIds.contains(map['reflectionId'])) {
          map['isExported'] = true;
        }
        return map;
      }).toList();
      
      await _prefs!.setString(key, jsonEncode(updated));
      print('✓ ${reflectionIds.length} évaluations marquées comme exportées');
      
    } catch (e) {
      print('❌ Erreur marquage export: $e');
    }
  }

  /// Exporter les évaluations vers un fichier texte
  Future<String> exportEvaluationsToFile() async {
    await _ensureInitialized();
    
    if (!isUserLoggedIn) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    try {
      final evaluations = await getAllEvaluations();
      
      if (evaluations.isEmpty) {
        throw Exception('Aucune évaluation à exporter');
      }
      
      // Générer le contenu
      final buffer = StringBuffer();
      buffer.writeln('╔════════════════════════════════════════════════════════╗');
      buffer.writeln('║           UN AUTRE REGARD - MES PERSPECTIVES           ║');
      buffer.writeln('╚════════════════════════════════════════════════════════╝');
      buffer.writeln();
      buffer.writeln('Utilisateur: ${_currentUserEmail}');
      buffer.writeln('Date d\'export: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}');
      buffer.writeln('Nombre de réflexions: ${evaluations.length}');
      buffer.writeln();
      buffer.writeln('════════════════════════════════════════════════════════════');
      buffer.writeln();
      
      for (int i = 0; i < evaluations.length; i++) {
        final eval = evaluations[i];
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln('RÉFLEXION #${i + 1} - ${eval.createdAt.day}/${eval.createdAt.month}/${eval.createdAt.year}');
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln();
        buffer.writeln(eval.toExportText());
        buffer.writeln();
      }
      
      // Sauvegarder dans un fichier
      final directory = await getApplicationDocumentsDirectory();
      final appDirectory = Directory('${directory.path}/UnAutreRegard');
      
      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'evaluations_$timestamp.txt';
      final file = File('${appDirectory.path}/$fileName');
      
      await file.writeAsString(buffer.toString());
      
      // Marquer comme exportées
      final ids = evaluations.map((e) => e.reflectionId).toList();
      await markEvaluationsAsExported(ids);
      
      print('✓ Évaluations exportées: ${file.path}');
      return file.path;
      
    } catch (e) {
      print('❌ Erreur export évaluations: $e');
      rethrow;
    }
  }

  // ==================== EXPORT/IMPORT ====================

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

  ///  Export vers fichier JSON
  Future<String> exportUserDataToFile() async {
    await _ensureInitialized();

    if (!isUserLoggedIn) {
      throw Exception('Aucun utilisateur connecte');
    }

    try {
      final data = await _exportAllUserData();
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
      
      print('✓ Sauvegarde creee: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ Erreur lors de l\'export: $e');
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
      print('✓ Import reussi depuis: $filePath');
    } catch (e) {
      print('❌ Erreur lors de l\'import: $e');
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
      print('❌ Erreur lecture fichiers backup: $e');
      return [];
    }
  }

  // ==================== METHODES PRIVEES ====================

  /// Exporter toutes les donnees utilisateur
  Future<Map<String, dynamic>> _exportAllUserData() async {
    // Récupérer les personnages utilisés
    final personnagesUtilises = await getPersonnagesUtilises();
    // Récupérer les évaluations
    final evaluations = await getAllEvaluations();
    
    return {
      'email': _currentUserEmail,
      'userProfile': getUserProfile()?.toJson(),
      'reflections': getAllReflections().map((r) => r.toJson()).toList(),
      'personnagesUtilises': personnagesUtilises,
      'evaluations': evaluations.map((e) => e.toJson()).toList(), // NOUVEAU
      'settings': {
        'defaultApproaches': _prefs?.getStringList('default_approaches_$_currentUserEmail') ?? [],
      },
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.3.0', // Version mise à jour
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

      // Importer les personnages utilisés
      if (data['personnagesUtilises'] != null) {
        final personnages = List<Map<String, dynamic>>.from(
          (data['personnagesUtilises'] as List).map((item) => Map<String, dynamic>.from(item))
        );
        await savePersonnagesUtilises(personnages);
      }

      // Importer les évaluations (NOUVEAU)
      if (data['evaluations'] != null) {
        for (final evalData in data['evaluations']) {
          final eval = ReflectionEvaluations.fromJson(evalData);
          await saveReflectionEvaluations(eval);
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
    
    // Supprimer toutes les donnees liees à cet utilisateur
    await _prefs!.remove('user_profile_$email');
    await _prefs!.remove('reflections_$email');
    await _prefs!.remove('default_approaches_$email');
    await _prefs!.remove('personnages_utilises_$email');
    await _prefs!.remove('evaluations_$email');
    await _prefs!.remove('emotional_states_$email');
    await _prefs!.remove('saved_eclairages_$email');
    
    print('✓ Toutes les donnees utilisateur supprimees');
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
    
    print('✓ Reflexion supprimee: $reflectionId');
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
    print('✓ Etat emotionnel sauvegarde');
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
        print('⚠️ Erreur decodage etat emotionnel: $e');
      }
    }
    
    // Trier par timestamp decroissant
    states.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return states;
  }
}

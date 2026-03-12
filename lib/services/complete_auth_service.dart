import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'persistent_storage_service.dart';

/// Méthode d'authentification utilisée par le compte
enum AuthMethod { password, google, apple, facebook }

/// SERVICE D'AUTHENTIFICATION COMPLET ET UNIFIÃ‰
/// GÃ¨re : Authentification + Profils + Persistance + Multi-comptes
class CompleteAuthService {
  static CompleteAuthService? _instance;
  static CompleteAuthService get instance => _instance ??= CompleteAuthService._();
  CompleteAuthService._();
  
  SharedPreferences? _prefs;
  String? _currentUser;
  bool _isInitialized = false;
  
  /// INITIALISATION OBLIGATOIRE
  Future<void> init() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _currentUser = _prefs?.getString('current_user');
    _isInitialized = true;
    
    print('ðŸ”„ CompleteAuthService initialisÃ©');
    print('   Utilisateur actuel: $_currentUser');
    print('   Comptes enregistrÃ©s: ${await getAllUsers()}');
  }
  
  // ========== AUTHENTIFICATION ==========
  
  /// Inscription d'un nouvel utilisateur
  Future<bool> register(String email, String password) async {
    await init();
    
    final emailKey = email.toLowerCase().trim();
    
    // VÃ©rifier si l'email existe dÃ©jÃ 
    if (await emailExists(emailKey)) {
      print('âŒ Inscription Ã©chouÃ©e - Email dÃ©jÃ  utilisÃ©: $emailKey');
      return false;
    }
    
    // Hasher le mot de passe
    final hash = sha256.convert(utf8.encode(password)).toString();
    
    // Sauvegarder les credentials
    await _prefs!.setString('password_$emailKey', hash);
    
    // Ajouter Ã  la liste des utilisateurs
    final users = await getAllUsers();
    users.add(emailKey);
    await _prefs!.setStringList('all_users', users);
    
    // CrÃ©er un profil vide
    await _createEmptyProfile(emailKey);
    
    // Se connecter immÃ©diatement
    await _setCurrentUser(emailKey);
    
    print('âœ… Inscription rÃ©ussie: $emailKey');
    return true;
  }
  
  /// Connexion d'un utilisateur existant
  Future<bool> login(String email, String password) async {
    await init();
    
    final emailKey = email.toLowerCase().trim();
    
    // VÃ©rifier si l'email existe
    if (!await emailExists(emailKey)) {
      print('âŒ Connexion Ã©chouÃ©e - Email inexistant: $emailKey');
      return false;
    }
    
    // VÃ©rifier le mot de passe
    final savedHash = _prefs!.getString('password_$emailKey');
    final inputHash = sha256.convert(utf8.encode(password)).toString();
    
    if (savedHash != inputHash) {
      print('âŒ Connexion Ã©chouÃ©e - Mot de passe incorrect: $emailKey');
      return false;
    }
    
    // Se connecter
    await _setCurrentUser(emailKey);
    
    print('âœ… Connexion rÃ©ussie: $emailKey');
    return true;
  }
  
  /// DÃ©connexion
  Future<void> logout() async {
    await init();
    
    _currentUser = null;
    await _prefs!.remove('current_user');
    await _prefs!.setBool('user_logged_in', false);
    
    print('âœ… DÃ©connexion effectuÃ©e');
  }
  
  /// VÃ©rifier si un email existe (password OU social)
  Future<bool> emailExists(String email) async {
    await init();
    final emailKey = email.toLowerCase().trim();
    return _prefs!.containsKey('password_$emailKey') ||
           _prefs!.containsKey('auth_method_$emailKey');
  }

  /// Réinitialiser le mot de passe et retourner le nouveau mot de passe temporaire
  Future<String?> resetPassword(String email) async {
    await init();

    final emailKey = email.toLowerCase().trim();

    // Vérifier si l'email existe
    if (!await emailExists(emailKey)) {
      print('❌ Réinitialisation échouée - Email inexistant: $emailKey');
      return null;
    }

    // Générer un mot de passe temporaire (8 caractères)
    final tempPassword = _generateTempPassword();

    // Hasher et sauvegarder le nouveau mot de passe
    final hash = sha256.convert(utf8.encode(tempPassword)).toString();
    await _prefs!.setString('password_$emailKey', hash);

    print('✅ Mot de passe réinitialisé pour: $emailKey');
    return tempPassword;
  }

  /// Générer un mot de passe temporaire
  String _generateTempPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  /// Vérifier le mot de passe temporaire et définir un nouveau mot de passe
  /// Retourne true si succès, false si le mot de passe temporaire est incorrect
  Future<bool> verifyTempAndSetNewPassword(String email, String tempPassword, String newPassword) async {
    await init();

    final emailKey = email.toLowerCase().trim();

    // Vérifier si l'email existe
    if (!await emailExists(emailKey)) {
      print('❌ Changement mot de passe échoué - Email inexistant: $emailKey');
      return false;
    }

    // Vérifier le mot de passe temporaire
    final tempHash = sha256.convert(utf8.encode(tempPassword)).toString();
    final storedHash = _prefs!.getString('password_$emailKey');

    if (storedHash != tempHash) {
      print('❌ Mot de passe temporaire incorrect pour: $emailKey');
      return false;
    }

    // Hasher et sauvegarder le nouveau mot de passe
    final newHash = sha256.convert(utf8.encode(newPassword)).toString();
    await _prefs!.setString('password_$emailKey', newHash);

    print('✅ Nouveau mot de passe défini pour: $emailKey');
    return true;
  }

  // ========== AUTHENTIFICATION SOCIALE ==========

  /// Connexion/inscription via un provider social (Google, Apple)
  /// Crée le compte si nouveau, connecte si existant, lie si email déjà utilisé avec password
  Future<bool> socialLogin({
    required String email,
    required AuthMethod method,
    String? displayName,
    String? photoUrl,
  }) async {
    await init();

    final emailKey = email.toLowerCase().trim();

    if (await emailExists(emailKey)) {
      // Compte existant — vérifier si c'est un compte password à lier
      final existingMethod = await getAuthMethod(emailKey);
      if (existingMethod == AuthMethod.password) {
        // Lier le compte social au compte password existant
        await _prefs!.setString('auth_method_$emailKey', method.name);
        await _prefs!.setBool('social_linked_$emailKey', true);
        print('🔗 Compte social lié au compte password: $emailKey');
      }

      // Connecter l'utilisateur existant
      await _setCurrentUser(emailKey);
    } else {
      // Nouveau compte — créer sans password
      await _prefs!.setString('auth_method_$emailKey', method.name);

      // Ajouter à la liste des utilisateurs
      final users = await getAllUsers();
      users.add(emailKey);
      await _prefs!.setStringList('all_users', users);

      // Créer un profil vide
      await _createEmptyProfile(emailKey);

      // Injecter le prénom depuis le provider social
      if (displayName != null && displayName.isNotEmpty) {
        final profile = _prefs!.getString('profile_$emailKey');
        if (profile != null) {
          try {
            final data = jsonDecode(profile) as Map<String, dynamic>;
            data['prenom'] = displayName.split(' ').first;
            await _prefs!.setString('profile_$emailKey', jsonEncode(data));
          } catch (_) {}
        }
      }

      // Connecter immédiatement
      await _setCurrentUser(emailKey);
      print('✅ Nouveau compte social créé: $emailKey ($method)');
    }

    // Stocker les métadonnées sociales
    if (displayName != null) {
      await _prefs!.setString('social_display_name_$emailKey', displayName);
    }
    if (photoUrl != null) {
      await _prefs!.setString('social_photo_url_$emailKey', photoUrl);
    }

    return true;
  }

  /// Récupérer la méthode d'authentification d'un compte
  Future<AuthMethod> getAuthMethod(String email) async {
    await init();
    final emailKey = email.toLowerCase().trim();
    final methodStr = _prefs!.getString('auth_method_$emailKey');
    if (methodStr == null) return AuthMethod.password; // comptes legacy
    return AuthMethod.values.firstWhere(
      (m) => m.name == methodStr,
      orElse: () => AuthMethod.password,
    );
  }

  /// Vérifier si un compte social est lié à un compte password
  Future<bool> isSocialLinked(String email) async {
    await init();
    final emailKey = email.toLowerCase().trim();
    return _prefs!.getBool('social_linked_$emailKey') ?? false;
  }

  /// DÃ©finir l'utilisateur actuel
  Future<void> _setCurrentUser(String email) async {
    final emailKey = email.toLowerCase().trim();
    _currentUser = emailKey;
    await _prefs!.setString('current_user', emailKey);
    await _prefs!.setBool('user_logged_in', true);
    
    // âœ… SYNCHRONISER avec PersistentStorageService
    try {
      await PersistentStorageService.instance.setCurrentUser(emailKey);
      print('âœ… PersistentStorageService synchronisÃ© avec: $emailKey');
    } catch (e) {
      print('â ï¸ Erreur sync PersistentStorageService: $e');
    }
  }
  
  // ========== ÉTAT DE L'UTILISATEUR ==========
  
  /// Récupérer l'email de l'utilisateur connecté (synchrone)
  /// ⚠️ Attention : retourne null si le service n'est pas initialisé
  String? get currentUserEmail => _currentUser;
  
  /// Vérifier si un utilisateur est connecté
  Future<bool> isLoggedIn() async {
    await init();
    return _currentUser != null && _prefs!.getBool('user_logged_in') == true;
  }
  
  /// RÃ©cupÃ©rer l'email de l'utilisateur connectÃ©
  Future<String?> getCurrentUser() async {
    await init();
    return _currentUser;
  }
  
  /// Liste de tous les utilisateurs enregistrÃ©s
  Future<List<String>> getAllUsers() async {
    await init();
    return _prefs!.getStringList('all_users') ?? [];
  }
  
  // ========== GESTION PROFILS ==========
  
  /// CrÃ©er un profil vide pour un nouvel utilisateur
  Future<void> _createEmptyProfile(String email) async {
    final emailKey = email.toLowerCase().trim();
    final emptyProfile = {
      'email': emailKey,
      'age': null,
      'situationFamiliale': null,
      'healthEnergy': null,
      'contraintes': null,
      'valeurs': null,
      'ressources': null,
      'contraintesRecurrentes': null,
      'religionsSelectionnees': <String>[],
      'courantsLitteraires': <String>[],
      'approchesPsychologiques': <String>[],
      'courantsPhilosophiques': <String>[],
      'philosophesSelectionnes': <String>[],
      'tonalitePrefere': null,
      'ouJenSuis': null,
      'ceQuiPese': null,
      'ceQuiTient': null,
      'lastUpdated': DateTime.now().toIso8601String(),
      'isCompleted': false,
    };
    
    await _prefs!.setString('profile_$emailKey', jsonEncode(emptyProfile));
    print('âœ… Profil vide crÃ©Ã© pour: $emailKey');
  }
  
  /// Sauvegarder le profil de l'utilisateur connectÃ©
  Future<bool> saveProfile(Map<String, dynamic> profileData) async {
    await init();
    
    if (_currentUser == null) {
      print('âŒ Sauvegarde profil Ã©chouÃ©e - Aucun utilisateur connectÃ©');
      return false;
    }
    
    profileData['email'] = _currentUser;
    profileData['lastUpdated'] = DateTime.now().toIso8601String();
    
    await _prefs!.setString('profile_$_currentUser', jsonEncode(profileData));
    
    print('âœ… Profil sauvegardÃ© pour: $_currentUser');
    print('   Champs: ${profileData.keys.toList()}');
    
    return true;
  }
  
  /// RÃ©cupÃ©rer le profil de l'utilisateur connectÃ©
  Future<Map<String, dynamic>?> getProfile() async {
    await init();
    
    if (_currentUser == null) {
      print('âŒ RÃ©cupÃ©ration profil Ã©chouÃ©e - Aucun utilisateur connectÃ©');
      return null;
    }
    
    final profileStr = _prefs!.getString('profile_$_currentUser');
    if (profileStr == null) {
      print('âš ï¸ Aucun profil trouvÃ© pour $_currentUser - CrÃ©ation profil vide');
      await _createEmptyProfile(_currentUser!);
      return await getProfile();
    }
    
    try {
      final profile = jsonDecode(profileStr) as Map<String, dynamic>;
      print('âœ… Profil rÃ©cupÃ©rÃ© pour: $_currentUser');
      return profile;
    } catch (e) {
      print('âŒ Erreur dÃ©codage profil pour $_currentUser: $e');
      await _createEmptyProfile(_currentUser!);
      return await getProfile();
    }
  }
  
  // ========== SAUVEGARDE DES SOURCES SÉLECTIONNÉES ==========

  /// Sauvegarder les sources sélectionnées dans le profil utilisateur
  /// Catégorise automatiquement par type (littéraire, psycho, philo, philosophe)
  /// et met à jour le profil existant sans écraser les autres champs
  Future<bool> saveSelectedSources(List<String> sourceIds) async {
    await init();

    if (_currentUser == null) {
      print('❌ Sauvegarde sources échouée - Aucun utilisateur connecté');
      return false;
    }

    // Récupérer le profil existant
    final profile = await getProfile() ?? {};

    // Catégoriser les sources par type via approach_config
    final List<String> religions = [];
    final List<String> litteratures = [];
    final List<String> psychologies = [];
    final List<String> philosophies = [];
    final List<String> philosophes = [];

    for (final id in sourceIds) {
      // Chercher dans approach_config pour déterminer le type
      final type = _getSourceType(id);
      switch (type) {
        case 'spiritual':
          religions.add(id);
          break;
        case 'literary':
          litteratures.add(id);
          break;
        case 'psychological':
          psychologies.add(id);
          break;
        case 'philosophical':
          philosophies.add(id);
          break;
        case 'philosopher':
          philosophes.add(id);
          break;
      }
    }

    // Mettre à jour UNIQUEMENT les champs sources, pas les autres
    profile['religionsSelectionnees'] = religions;
    profile['courantsLitteraires'] = litteratures;
    profile['approchesPsychologiques'] = psychologies;
    profile['courantsPhilosophiques'] = philosophies;
    profile['philosophesSelectionnes'] = philosophes;

    // Sauvegarder le profil mis à jour
    final success = await saveProfile(profile);
    if (success) {
      print('✅ Sources sauvegardées dans le profil: $sourceIds');
      print('   Religions: $religions');
      print('   Littéraires: $litteratures');
      print('   Psychologiques: $psychologies');
      print('   Philosophiques: $philosophies');
      print('   Philosophes: $philosophes');
    }
    return success;
  }

  /// Détermine le type d'une source par son ID
  /// Mapping basé sur les IDs de wisdom_wheel_dialog.dart et approach_config.dart
  String _getSourceType(String sourceId) {
    // Sources spirituelles
    const spiritual = [
      'judaisme_rabbinique', 'moussar', 'kabbale', 'christianisme',
      'islam', 'soufisme', 'theravada', 'zen', 'advaita_vedanta',
      'bhakti', 'stoicisme', 'spiritualite_contemporaine',
    ];
    // Sources littéraires
    const literary = [
      'humanisme', 'romantisme', 'realisme', 'existentialisme',
      'absurdisme', 'poetique', 'mystique', 'symboliste_moderne',
      'naturalisme', 'symbolisme', 'surrealisme', 'modernisme',
      'postmodernisme', 'tragedie_classique', 'roman_psychologique',
      'mythologie', 'science_fiction', 'fantasy',
    ];
    // Sources psychologiques
    const psychological = [
      'act', 'tcc', 'jungienne', 'logotherapie', 'schemas_young',
      'the_work', 'humaniste_rogers', 'psychanalyse',
      'analyse_transactionnelle', 'systemique',
    ];
    // Courants philosophiques
    const philosophical = [
      'stoicisme_philo', 'epicurisme', 'existentialisme_philo',
      'phenomenologie', 'absurdisme_philo', 'rationalisme',
      'empirisme', 'idealisme', 'pragmatisme', 'vitalisme',
      'humanisme_philo', 'utilitarisme', 'structuralisme',
      'philosophies_orientales',
    ];
    // Philosophes individuels
    const philosopher = [
      'socrate', 'platon', 'aristote', 'epicure', 'seneque',
      'epictete', 'marc_aurele', 'spinoza', 'kant', 'nietzsche',
      'kierkegaard', 'sartre', 'camus', 'simone_de_beauvoir',
      'hannah_arendt', 'schopenhauer', 'montaigne', 'diogene',
      'confucius', 'rousseau', 'hume', 'foucault', 'descartes',
    ];

    if (spiritual.contains(sourceId)) return 'spiritual';
    if (literary.contains(sourceId)) return 'literary';
    if (psychological.contains(sourceId)) return 'psychological';
    if (philosophical.contains(sourceId)) return 'philosophical';
    if (philosopher.contains(sourceId)) return 'philosopher';

    // Fallback: essayer de deviner par le nom
    print('⚠️ Source non catégorisée: $sourceId — défaut: philosophical');
    return 'philosophical';
  }

  // ========== RÉFLEXIONS/HISTORIQUE ==========

  /// Sauvegarder une réflexion pour l'utilisateur connecté
  Future<bool> saveReflection(Map<String, dynamic> reflection) async {
    await init();
    
    if (_currentUser == null) {
      print('âŒ Sauvegarde rÃ©flexion Ã©chouÃ©e - Aucun utilisateur connectÃ©');
      return false;
    }
    
    // RÃ©cupÃ©rer les rÃ©flexions existantes
    final reflections = await getAllReflections();
    
    // Ajouter la nouvelle rÃ©flexion
    reflection['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    reflection['createdAt'] = DateTime.now().toIso8601String();
    reflection['userId'] = _currentUser;
    
    reflections.add(reflection);
    
    // Sauvegarder la liste mise Ã  jour
    final reflectionsJson = reflections.map((r) => jsonEncode(r)).toList();
    await _prefs!.setStringList('reflections_$_currentUser', reflectionsJson);
    
    print('âœ… RÃ©flexion sauvegardÃ©e pour: $_currentUser (ID: ${reflection['id']})');
    return true;
  }
  
  /// RÃ©cupÃ©rer toutes les rÃ©flexions de l'utilisateur connectÃ©
  Future<List<Map<String, dynamic>>> getAllReflections() async {
    await init();
    
    if (_currentUser == null) {
      print('âŒ RÃ©cupÃ©ration rÃ©flexions Ã©chouÃ©e - Aucun utilisateur connectÃ©');
      return [];
    }
    
    final reflectionsStr = _prefs!.getStringList('reflections_$_currentUser') ?? [];
    final reflections = <Map<String, dynamic>>[];
    
    for (String reflectionStr in reflectionsStr) {
      try {
        final reflection = jsonDecode(reflectionStr) as Map<String, dynamic>;
        reflections.add(reflection);
      } catch (e) {
        print('âš ï¸ Erreur dÃ©codage rÃ©flexion: $e');
      }
    }
    
    // Trier par date de crÃ©ation (plus rÃ©cent en premier)
    reflections.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    print('âœ… ${reflections.length} rÃ©flexions rÃ©cupÃ©rÃ©es pour: $_currentUser');
    return reflections;
  }
  
  /// Supprimer une rÃ©flexion
  Future<bool> deleteReflection(String reflectionId) async {
    await init();
    
    if (_currentUser == null) {
      print('âŒ Suppression rÃ©flexion Ã©chouÃ©e - Aucun utilisateur connectÃ©');
      return false;
    }
    
    final reflections = await getAllReflections();
    reflections.removeWhere((r) => r['id'] == reflectionId);
    
    final reflectionsJson = reflections.map((r) => jsonEncode(r)).toList();
    await _prefs!.setStringList('reflections_$_currentUser', reflectionsJson);
    
    print('âœ… RÃ©flexion supprimÃ©e: $reflectionId');
    return true;
  }
  
  // ========== PARAMÃˆTRES/PRÃ‰FÃ‰RENCES ==========
  
  /// Sauvegarder un paramÃ¨tre pour l'utilisateur connectÃ©
  Future<bool> saveSetting(String key, dynamic value) async {
    await init();
    
    if (_currentUser == null) {
      print('âŒ Sauvegarde paramÃ¨tre Ã©chouÃ©e - Aucun utilisateur connectÃ©');
      return false;
    }
    
    final settingKey = 'setting_${_currentUser}_$key';
    
    if (value is bool) {
      await _prefs!.setBool(settingKey, value);
    } else if (value is int) {
      await _prefs!.setInt(settingKey, value);
    } else if (value is double) {
      await _prefs!.setDouble(settingKey, value);
    } else if (value is String) {
      await _prefs!.setString(settingKey, value);
    } else if (value is List<String>) {
      await _prefs!.setStringList(settingKey, value);
    } else {
      await _prefs!.setString(settingKey, jsonEncode(value));
    }
    
    print('âœ… ParamÃ¨tre sauvegardÃ©: $key = $value');
    return true;
  }
  
  /// RÃ©cupÃ©rer un paramÃ¨tre pour l'utilisateur connectÃ©
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    await init();
    
    if (_currentUser == null) return defaultValue;
    
    final settingKey = 'setting_${_currentUser}_$key';
    final value = _prefs!.get(settingKey) as T?;
    return value ?? defaultValue;
  }
  
  // ========== OUTILS DE DEBUG/MAINTENANCE ==========
  
  /// Statistiques complÃ¨tes du systÃ¨me
  Future<Map<String, dynamic>> getSystemStats() async {
    await init();
    
    final allUsers = await getAllUsers();
    final currentUser = await getCurrentUser();
    final isLoggedIn = await this.isLoggedIn();
    
    Map<String, dynamic> stats = {
      'system_initialized': _isInitialized,
      'current_user': currentUser,
      'is_logged_in': isLoggedIn,
      'total_users': allUsers.length,
      'all_users': allUsers,
      'storage_keys': _prefs!.getKeys().toList(),
    };
    
    if (currentUser != null) {
      final profile = await getProfile();
      final reflections = await getAllReflections();
      
      stats['current_user_data'] = {
        'profile_exists': profile != null,
        'profile_completed': profile?['isCompleted'] ?? false,
        'reflections_count': reflections.length,
        'last_activity': profile?['lastUpdated'],
      };
    }
    
    return stats;
  }
  
  /// Effacer toutes les donnÃ©es (pour debug)
  Future<void> clearAllData() async {
    await init();
    
    await _prefs!.clear();
    _currentUser = null;
    _isInitialized = false;
    
    print('ðŸ—‘ï¸ Toutes les donnÃ©es effacÃ©es');
    await init(); // Re-initialiser
  }
  
  /// Effacer les donnÃ©es d'un utilisateur spÃ©cifique
  Future<void> clearUserData(String email) async {
    await init();
    
    final emailKey = email.toLowerCase().trim();
    
    // Supprimer mot de passe
    await _prefs!.remove('password_$emailKey');
    
    // Supprimer profil
    await _prefs!.remove('profile_$emailKey');
    
    // Supprimer rÃ©flexions
    await _prefs!.remove('reflections_$emailKey');
    
    // Supprimer paramÃ¨tres
    final allKeys = _prefs!.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('setting_${emailKey}_')) {
        await _prefs!.remove(key);
      }
    }
    
    // Retirer de la liste des utilisateurs
    final users = await getAllUsers();
    users.remove(emailKey);
    await _prefs!.setStringList('all_users', users);
    
    // Si c'est l'utilisateur actuel, le dÃ©connecter
    if (_currentUser == emailKey) {
      await logout();
    }
    
    print('âœ… DonnÃ©es utilisateur supprimÃ©es: $emailKey');
  }
  
  /// Migrer les anciennes donnÃ©es vers ce systÃ¨me (si nÃ©cessaire)
  Future<void> migrateOldData() async {
    await init();
    
    // Migrer l'ancien format simple vers le nouveau format multi-utilisateurs
    final oldEmail = _prefs!.getString('user_email');
    final oldPasswordHash = _prefs!.getString('user_password_hash');
    
    if (oldEmail != null && oldPasswordHash != null) {
      print('ðŸ”„ Migration dÃ©tectÃ©e pour: $oldEmail');
      
      final emailKey = oldEmail.toLowerCase().trim();
      
      // Migrer les credentials
      await _prefs!.setString('password_$emailKey', oldPasswordHash);
      
      // Ajouter Ã  la liste des utilisateurs
      final users = await getAllUsers();
      if (!users.contains(emailKey)) {
        users.add(emailKey);
        await _prefs!.setStringList('all_users', users);
      }
      
      // Migrer l'ancien profil s'il existe
      final oldProfile = _prefs!.getString('user_profile_$oldEmail');
      if (oldProfile != null) {
        await _prefs!.setString('profile_$emailKey', oldProfile);
      } else {
        await _createEmptyProfile(emailKey);
      }
      
      // Se connecter Ã  ce compte migrÃ©
      await _setCurrentUser(emailKey);
      
      // Nettoyer l'ancien format
      await _prefs!.remove('user_email');
      await _prefs!.remove('user_password_hash');
      await _prefs!.remove('user_profile_$oldEmail');
      
      print('âœ… Migration terminÃ©e pour: $emailKey');
    }
  }
}

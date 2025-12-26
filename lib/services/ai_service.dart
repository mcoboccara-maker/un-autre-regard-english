import 'dart:convert';
import 'dart:math';
import 'dart:async'; // AJOUT: Pour TimeoutException
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import '../services/persistent_storage_service.dart';
import '../services/character_tracking_service.dart';
import '../config/approach_config.dart';
// ═══════════════════════════════════════════════════════════════════════════════
// IMPORTS UNIFIÉS - Remplacent les 4 anciens fichiers prompts
// ═══════════════════════════════════════════════════════════════════════════════
import '../config/prompts/prompt_unifie.dart';
import '../config/prompts/prompt_system_unifie.dart';
import '../config/prompts/prompt_positive_thought.dart';
// import '../config/prompts/prompt_synthesis.dart'; // Garder si utilisé

/// SERVICE IA - VERSION CLAUDE (ANTHROPIC)
/// 
/// Refactorisé pour:
/// - Utiliser l'API Claude au lieu d'OpenAI
/// - Prompts unifiés (1 appel au lieu de 2)
/// - Auto-contrôle intégré (pas de boucle de régénération)
/// - Extraction des métadonnées de figures pour historisation
/// 
class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();
  AIService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION API CLAUDE (ANTHROPIC)
  // ═══════════════════════════════════════════════════════════════════════════
  
  final String _baseUrl = 'https://api.anthropic.com/v1/messages';
  String _apiKey = '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'; // À remplacer
  final String _model = 'claude-sonnet-4-5-20250929';
  final String _anthropicVersion = '2023-06-01';
  
  // AJOUT: Timeout pour les requêtes (en secondes)
  static const int _requestTimeoutSeconds = 60;
  
  // AJOUT: Configuration du retry automatique (erreurs 429/529)
  static const int _maxRetryAttempts = 3;           // Nombre max de tentatives
  static const int _initialRetryDelaySeconds = 2;   // Délai initial (2s, 4s, 8s)

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCES PAR DEFAUT (utilisées si aucune source choisie par l'utilisateur)
  // REGLE: 1 source par type hors spirituel
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<String> _defaultSources = [
    'roman_psychologique',    // Littéraire
    'schemas_young',          // Psychologique
    'existentialisme_philo',  // Philosophique (courant)
    'hannah_arendt',          // Philosophe
  ];

  /// Approches utilisateur
  List<String> get userApproches => _userApproaches;
  List<String> _userApproaches = [];

  /// Historique d'utilisation des sources pour pensée positive
  Map<String, int> _sourceUsageHistory = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // CHARGEMENT DES APPROCHES UTILISATEUR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Charger les approches de l'utilisateur (5 catégories)
  /// REGLE: Si aucune source choisie, utiliser les sources par défaut
  Future<void> loadUserApproaches() async {
    try {
      _userApproaches = await PersistentStorageService.instance.getUserApproaches();
      print('AIService: Approches utilisateur chargées: $_userApproaches');
      
      if (_userApproaches.isEmpty) {
        print('AIService: Aucune source utilisateur -> Application des sources par défaut');
        _userApproaches = List.from(_defaultSources);
      }
    } catch (e) {
      print('AIService: Erreur chargement approches: $e');
      _userApproaches = List.from(_defaultSources);
    }
  }

  /// Message de configuration
  String getSetupMessage() {
    if (_userApproaches.isEmpty) {
      return 'Aucune approche sélectionnée. Veuillez compléter votre profil.';
    }
    return 'Vos approches sélectionnées : ${_userApproaches.join(", ")}';
  }

  /// Formatage des noms d'approches  
  String formatApproachNames(List<String> approaches) {
    final formattedNames = <String>[];
    
    for (final approachKey in approaches) {
      final config = ApproachCategories.allApproaches.firstWhere(
        (a) => a.key == approachKey,
        orElse: () => ApproachConfig(
          key: approachKey,
          name: approachKey,
          description: '',
          credo: '',
          tonEmotionnel: '',
          exemples: [],
          icon: Icons.help,
          color: Colors.grey,
          type: ApproachType.psychological,
        ),
      );
      formattedNames.add(config.name);
    }
    
    return formattedNames.join(', ');
  }

  /// Catégoriser les approches en 5 catégories
  Map<String, List<String>> _categorizeApproaches(List<String> approaches) {
    final religions = <String>[];
    final litteratures = <String>[];
    final psychologies = <String>[];
    final philosophies = <String>[];
    final philosophes = <String>[];
    
    for (final approachKey in approaches) {
      final config = ApproachCategories.allApproaches.firstWhere(
        (a) => a.key == approachKey,
        orElse: () => ApproachConfig(
          key: approachKey,
          name: approachKey,
          description: '',
          credo: '',
          tonEmotionnel: '',
          exemples: [],
          icon: Icons.help,
          color: Colors.grey,
          type: ApproachType.psychological,
        ),
      );
      
      switch (config.type) {
        case ApproachType.spiritual:
          religions.add(config.name);
          break;
        case ApproachType.literary:
          litteratures.add(config.name);
          break;
        case ApproachType.psychological:
          psychologies.add(config.name);
          break;
        case ApproachType.philosophical:
          philosophies.add(config.name);
          break;
        case ApproachType.philosopher:
          philosophes.add(config.name);
          break;
      }
    }
    
    return {
      'religions': religions,
      'litteratures': litteratures,
      'psychologies': psychologies,
      'philosophies': philosophies,
      'philosophes': philosophes,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AJOUT: GESTION DES ERREURS API CLAUDE
  // ═══════════════════════════════════════════════════════════════════════════

  /// AJOUT: Convertit un code d'erreur HTTP en message utilisateur compréhensible
  String _getErrorMessage(int statusCode, String responseBody) {
    // Essayer d'extraire le message d'erreur JSON
    String? apiMessage;
    try {
      final json = jsonDecode(responseBody);
      apiMessage = json['error']?['message'];
    } catch (_) {}
    
    switch (statusCode) {
      case 400:
        return 'Requête invalide. ${apiMessage ?? "Vérifiez les paramètres."}';
      case 401:
        return 'Clé API invalide ou expirée. Veuillez vérifier votre configuration.';
      case 403:
        return 'Accès refusé. ${apiMessage ?? "Vérifiez vos permissions API."}';
      case 404:
        return 'Service non trouvé. L\'API Claude est peut-être indisponible.';
      case 429:
        return 'Limite de requêtes atteinte. Veuillez patienter quelques secondes et réessayer.';
      case 500:
        return 'Erreur serveur Claude. Le service est temporairement indisponible.';
      case 529:
        return 'API Claude surchargée. Veuillez réessayer dans quelques instants.';
      default:
        return 'Erreur inattendue ($statusCode). ${apiMessage ?? "Veuillez réessayer."}';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPEL API CLAUDE (ANTHROPIC)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Appel à l'API Claude avec séparation System/User prompts
  /// 
  /// [userPrompt] : La demande spécifique (prompt_unifie, prompt_positive_thought, etc.)
  /// [systemPrompt] : L'identité de l'IA (utilise PromptSystemUnifie.content par défaut)
  /// [maxTokens] : Limite de tokens pour la réponse
  /// 
  /// MODIFIÉ: Retourne maintenant un message d'erreur explicite au lieu de chaîne vide
  /// AJOUT: Retry automatique avec backoff exponentiel pour erreurs 429/529
  Future<String> _callClaude(
    String userPrompt, {
    String? systemPrompt,
    int maxTokens = 4096,
    double temperature = 0.7,
  }) async {
    final effectiveSystemPrompt = systemPrompt ?? PromptSystemUnifie.content;
    
    // ═══════════════════════════════════════════════════════════════════════════
    // RETRY AUTOMATIQUE AVEC BACKOFF EXPONENTIEL
    // Tentatives: 1, 2, 3 avec délais: 2s, 4s, 8s entre chaque
    // ═══════════════════════════════════════════════════════════════════════════
    
    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        print('AIService: Envoi requête Claude (tentative $attempt/$_maxRetryAttempts)...');
        print('AIService: Model: $_model');
        print('AIService: MaxTokens: $maxTokens');
        print('AIService: Prompt length: ${userPrompt.length} chars');
        
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey,
            'anthropic-version': _anthropicVersion,
          },
          body: jsonEncode({
            'model': _model,
            'max_tokens': maxTokens,
            'system': effectiveSystemPrompt,
            'messages': [
              {
                'role': 'user',
                'content': userPrompt,
              }
            ],
            'temperature': temperature,
          }),
        ).timeout(
          Duration(seconds: _requestTimeoutSeconds),
          onTimeout: () {
            throw TimeoutException('La requête a pris trop de temps (>${_requestTimeoutSeconds}s)');
          },
        );

        print('AIService: Status code: ${response.statusCode}');

        // ✅ SUCCÈS
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['content']?[0]?['text'] ?? '';
          print('AIService: ✅ Réponse reçue: ${content.length} caractères');
          return content.trim();
        }
        
        // ⚠️ ERREUR RETRYABLE (429 = rate limit, 529 = overloaded)
        if (response.statusCode == 429 || response.statusCode == 529) {
          if (attempt < _maxRetryAttempts) {
            final delaySeconds = _initialRetryDelaySeconds * (1 << (attempt - 1)); // 2s, 4s, 8s
            print('AIService: ⏳ Erreur ${response.statusCode} - Retry dans ${delaySeconds}s (tentative $attempt/$_maxRetryAttempts)');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue; // Réessayer
          }
          // Dernière tentative échouée
          final errorMsg = _getErrorMessage(response.statusCode, response.body);
          print('AIService: ❌ Échec après $_maxRetryAttempts tentatives: $errorMsg');
          return '[ERREUR_API] $errorMsg';
        }
        
        // ❌ ERREUR NON-RETRYABLE (400, 401, 403, 500, etc.)
        final errorMsg = _getErrorMessage(response.statusCode, response.body);
        print('AIService: ❌ Erreur API Claude: ${response.statusCode}');
        print('AIService: Body: ${response.body}');
        print('AIService: Message: $errorMsg');
        return '[ERREUR_API] $errorMsg';
        
      } on TimeoutException catch (e) {
        print('AIService: ❌ Timeout: $e');
        if (attempt < _maxRetryAttempts) {
          final delaySeconds = _initialRetryDelaySeconds * (1 << (attempt - 1));
          print('AIService: ⏳ Timeout - Retry dans ${delaySeconds}s (tentative $attempt/$_maxRetryAttempts)');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }
        return '[ERREUR_API] Délai d\'attente dépassé après $_maxRetryAttempts tentatives. Vérifiez votre connexion internet.';
      } on FormatException catch (e) {
        print('AIService: ❌ Erreur parsing JSON: $e');
        return '[ERREUR_API] Erreur de format dans la réponse du serveur.';
      } catch (e) {
        print('AIService: ❌ Erreur requête Claude: $e');
        
        // Détecter les erreurs réseau courantes (incluant ClientException)
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('socketexception') || 
            errorStr.contains('connection refused') ||
            errorStr.contains('network is unreachable') ||
            errorStr.contains('clientexception') ||
            errorStr.contains('connection abort') ||
            errorStr.contains('connection reset')) {
          if (attempt < _maxRetryAttempts) {
            final delaySeconds = _initialRetryDelaySeconds * (1 << (attempt - 1));
            print('AIService: ⏳ Erreur réseau - Retry dans ${delaySeconds}s (tentative $attempt/$_maxRetryAttempts)');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }
          return '[ERREUR_API] Cette source n\'a pas pu répondre. Tu peux continuer avec les autres perspectives ou soumettre à nouveau ta pensée un peu plus tard.';
        }
        if (errorStr.contains('handshake') || errorStr.contains('certificate')) {
          return '[ERREUR_API] Erreur de sécurité SSL. Vérifiez la date/heure de votre appareil.';
        }
        
        // Message générique pour les autres erreurs (sans détails techniques)
        return '[ERREUR_API] Cette source n\'a pas pu répondre. Tu peux continuer avec les autres perspectives ou soumettre à nouveau ta pensée un peu plus tard.';
      }
    }
    
    // Ne devrait jamais arriver, mais par sécurité
    return '[ERREUR_API] Erreur inattendue après $_maxRetryAttempts tentatives.';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTRACTION DES MÉTADONNÉES DE FIGURE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extrait les métadonnées de la figure depuis la réponse IA
  /// Format attendu:
  /// [FIGURE_META]
  /// nom: ...
  /// source: ...
  /// reference: ...
  /// motif: ...
  /// [/FIGURE_META]
  Map<String, String>? _extractFigureMeta(String response) {
    final regex = RegExp(
      r'\[FIGURE_META\]\s*\n'
      r'nom:\s*(.+)\n'
      r'source:\s*(.+)\n'
      r'reference:\s*(.+)\n'
      r'motif:\s*(.+)\n'
      r'\[/FIGURE_META\]',
      multiLine: true,
    );
    
    final match = regex.firstMatch(response);
    if (match == null) {
      print('AIService: Métadonnées figure non trouvées dans la réponse');
      return null;
    }
    
    return {
      'nom': match.group(1)?.trim() ?? '',
      'source': match.group(2)?.trim() ?? '',
      'reference': match.group(3)?.trim() ?? '',
      'motifUniversel': match.group(4)?.trim() ?? '',
    };
  }

  /// Retire le bloc [FIGURE_META] de la réponse affichée à l'utilisateur
  String _removeMetaBlock(String response) {
    return response.replaceAll(
      RegExp(r'\[FIGURE_META\][\s\S]*?\[/FIGURE_META\]'),
      '',
    ).trim();
  }

  /// Sauvegarder le personnage extrait
  Future<void> _saveExtractedCharacter(Map<String, String>? characterData) async {
    if (characterData == null || characterData['nom']?.isEmpty == true) return;
    
    try {
      await CharacterTrackingService.instance.saveMultipleCharacters([characterData]);
      print('AIService: Personnage sauvegardé: ${characterData['nom']}');
    } catch (e) {
      print('AIService: Erreur sauvegarde personnage: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION UNIVERSELLE (TOUTES LES SOURCES DU PROFIL)
  // Version simplifiée : 1 seul appel API, auto-contrôle intégré
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<String> generateUniversalResponse({
    required String reflectionText,
    required ReflectionType reflectionType,
    required EmotionalState emotionalState,
    UserProfile? userProfile,
    String? declencheur,
    String? souhait,
    String? petitPas,
    int intensiteEmotionnelle = 5,
    String? historique30Jours,
  }) async {
    
    await loadUserApproaches();
    
    // Charger les personnages interdits (30 derniers jours)
    final personnagesInterdits = await CharacterTrackingService.instance.getForbiddenCharactersText();
    
    // Catégoriser les approches
    final categories = _categorizeApproaches(_userApproaches);
    
    // Calculer l'âge
    String ageStr = _calculateAge(userProfile);
    
    // ═══════════════════════════════════════════════════════════════════════
    // CONSTRUIRE LE PROMPT UNIFIÉ (remplace prompt_general + prompt_control)
    // ═══════════════════════════════════════════════════════════════════════
    
    final prompt = PromptUnifie.build(
      userPrenom: userProfile?.prenom,
      userAge: ageStr,
      userValeursSelectionnees: userProfile?.valeursSelectionnees?.join(', '),
      userValeursLibres: userProfile?.valeursLibres,
      typeEntree: _getTypeDisplayName(reflectionType),
      contenu: reflectionText,
      declencheur: declencheur,
      souhait: souhait,
      petitPas: petitPas,
      religions: categories['religions']!.isNotEmpty 
          ? categories['religions']!.join(', ') 
          : 'Aucune selectionnee',
      litteratures: categories['litteratures']!.isNotEmpty 
          ? categories['litteratures']!.join(', ') 
          : 'Aucun selectionne',
      psychologies: categories['psychologies']!.isNotEmpty 
          ? categories['psychologies']!.join(', ') 
          : 'Aucune selectionnee',
      philosophies: categories['philosophies']!.isNotEmpty 
          ? categories['philosophies']!.join(', ') 
          : 'Aucun selectionne',
      philosophes: categories['philosophes']!.isNotEmpty 
          ? categories['philosophes']!.join(', ') 
          : 'Aucun selectionne',
      historique30Jours: historique30Jours,
      personnagesInterdits: personnagesInterdits,
    );

    try {
      // ═══════════════════════════════════════════════════════════════════════
      // UN SEUL APPEL API (plus de boucle de régénération)
      // L'auto-contrôle est intégré dans le prompt système
      // ═══════════════════════════════════════════════════════════════════════
      
      final response = await _callClaude(prompt);
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        return '❌ ${response.replaceFirst('[ERREUR_API] ', '')}';
      }
      
      if (response.isEmpty) {
        return '❌ Erreur lors de la génération de la réponse. Veuillez réessayer.';
      }
      
      // Extraire et sauvegarder les métadonnées de la figure
      final figureMeta = _extractFigureMeta(response);
      await _saveExtractedCharacter(figureMeta);
      
      // Retourner la réponse sans le bloc de métadonnées
      return _removeMetaBlock(response);
      
    } catch (e) {
      print('AIService: Erreur génération universelle: $e');
      return '❌ Erreur lors de la génération de la réponse. Veuillez réessayer.';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION POUR APPROCHE SPÉCIFIQUE (ROUE DU HASARD)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<String> generateApproachSpecificResponse({
    required String approach,
    required String reflectionText,
    required ReflectionType reflectionType,
    required EmotionalState emotionalState,
    UserProfile? userProfile,
    String? declencheur,
    String? souhait,
    String? petitPas,
    required int intensiteEmotionnelle,
    String? historique30Jours,
  }) async {
    
    // Trouver la configuration de l'approche sélectionnée via la roue
    final approachConfig = ApproachCategories.allApproaches.firstWhere(
      (a) => a.key == approach,
      orElse: () => ApproachConfig(
        key: approach,
        name: approach,
        description: 'Approche de développement personnel',
        credo: 'Chaque difficulté est une opportunité de croissance',
        tonEmotionnel: 'Bienveillant et encourageant',
        exemples: ['Sagesse universelle'],
        icon: Icons.psychology,
        color: Colors.blue,
        type: ApproachType.psychological,
      ),
    );

    print('AIService: Génération pour approche spécifique: ${approachConfig.name}');

    // Charger les personnages interdits
    final personnagesInterdits = await CharacterTrackingService.instance.getForbiddenCharactersText();
    
    // Calculer l'âge
    String ageStr = _calculateAge(userProfile);
    
    // ═══════════════════════════════════════════════════════════════════════
    // CONSTRUIRE LE PROMPT AVEC UNIQUEMENT LA SOURCE DEMANDÉE
    // ═══════════════════════════════════════════════════════════════════════
    
    String religionsStr = 'Aucune';
    String litteraturesStr = 'Aucun';
    String psychologiesStr = 'Aucune';
    String philosophiesStr = 'Aucun';
    String philosophesStr = 'Aucun';
    
    switch (approachConfig.type) {
      case ApproachType.spiritual:
        religionsStr = approachConfig.name;
        break;
      case ApproachType.literary:
        litteraturesStr = approachConfig.name;
        break;
      case ApproachType.psychological:
        psychologiesStr = approachConfig.name;
        break;
      case ApproachType.philosophical:
        philosophiesStr = approachConfig.name;
        break;
      case ApproachType.philosopher:
        philosophesStr = approachConfig.name;
        break;
    }
    
    final prompt = PromptUnifie.build(
      userPrenom: userProfile?.prenom,
      userAge: ageStr,
      userValeursSelectionnees: userProfile?.valeursSelectionnees?.join(', '),
      userValeursLibres: userProfile?.valeursLibres,
      typeEntree: _getTypeDisplayName(reflectionType),
      contenu: reflectionText,
      declencheur: declencheur,
      souhait: souhait,
      petitPas: petitPas,
      religions: religionsStr,
      litteratures: litteraturesStr,
      psychologies: psychologiesStr,
      philosophies: philosophiesStr,
      philosophes: philosophesStr,
      historique30Jours: historique30Jours,
      personnagesInterdits: personnagesInterdits,
    );

    try {
      final response = await _callClaude(prompt);
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        return '❌ ${response.replaceFirst('[ERREUR_API] ', '')}';
      }
      
      if (response.isEmpty) {
        return '❌ Erreur lors de la génération de la réponse. Veuillez réessayer.';
      }
      
      // Extraire et sauvegarder les métadonnées de la figure
      final figureMeta = _extractFigureMeta(response);
      await _saveExtractedCharacter(figureMeta);
      
      // Retourner la réponse sans le bloc de métadonnées
      return _removeMetaBlock(response);
      
    } catch (e) {
      print('AIService: Erreur génération approche spécifique: $e');
      return '❌ Erreur lors de la génération de la réponse. Veuillez réessayer.';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION PENSÉE POSITIVE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<String> generatePositiveThought({
    UserProfile? userProfile,
    String? penseeOuSituation,
    String? historique7Jours,
  }) async {
    
    List<String> allSources = await PersistentStorageService.instance.getUserApproaches();
    
    debugPrint('AIService: Pensée Positive - Sources: ${allSources.length}');
    
    if (allSources.isEmpty) {
      debugPrint('AIService: Pensée Positive - Aucune source -> Application des sources par défaut');
      allSources = List.from(_defaultSources);
    }
    
    final selectedSource = _selectWeightedSource(allSources);
    _sourceUsageHistory[selectedSource] = (_sourceUsageHistory[selectedSource] ?? 0) + 1;
    
    final sourceConfig = ApproachCategories.allApproaches.firstWhere(
      (a) => a.key == selectedSource,
      orElse: () => ApproachConfig(
        key: selectedSource,
        name: selectedSource,
        description: '',
        credo: '',
        tonEmotionnel: '',
        exemples: [],
        icon: Icons.help,
        color: Colors.grey,
        type: ApproachType.psychological,
      ),
    );
    
    final categories = _categorizeApproaches(allSources);
    String ageStr = _calculateAge(userProfile);
    
    final prompt = PromptPositiveThought.build(
      userPrenom: userProfile?.prenom,
      userAge: ageStr,
      userValeursSelectionnees: userProfile?.valeursSelectionnees?.join(', '),
      userValeursLibres: userProfile?.valeursLibres,
      religions: categories['religions']!.isNotEmpty 
          ? categories['religions']!.join(', ') 
          : 'Aucune',
      litteratures: categories['litteratures']!.isNotEmpty 
          ? categories['litteratures']!.join(', ') 
          : 'Aucun',
      psychologies: categories['psychologies']!.isNotEmpty 
          ? categories['psychologies']!.join(', ') 
          : 'Aucune',
      philosophies: categories['philosophies']!.isNotEmpty 
          ? categories['philosophies']!.join(', ') 
          : 'Aucun',
      philosophes: categories['philosophes']!.isNotEmpty 
          ? categories['philosophes']!.join(', ') 
          : 'Aucun',
      sourceChoisie: sourceConfig.name,
      penseeOuSituation: penseeOuSituation,
      historique7Jours: historique7Jours,
    );

    try {
      final response = await _callClaude(prompt, maxTokens: 500);
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        return '❌ ${response.replaceFirst('[ERREUR_API] ', '')}';
      }
      
      return response.isNotEmpty 
        ? response 
        : '❌ Impossible de générer une pensée positive pour le moment.';
    } catch (e) {
      print('AIService: Erreur pensée positive: $e');
      return '❌ Impossible de générer une pensée positive pour le moment.';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION SYNTHÈSE VOCALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Générer une synthèse vocale d'un texte
  /// Utilisé pour condenser une réponse longue en 2-3 phrases
  /// 
  /// [model] : Ignoré (utilise le modèle Claude configuré)
  /// [temperature] : Température pour la génération
  /// [maxTokens] : Limite de tokens pour la réponse
  Future<String> generateSynthesis({
    required String systemPrompt,
    required String userPrompt,
    String? model, // Paramètre conservé pour compatibilité, ignoré avec Claude
    double temperature = 0.3,
    int maxTokens = 150,
  }) async {
    try {
      final response = await _callClaude(
        userPrompt,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        throw Exception(response.replaceFirst('[ERREUR_API] ', ''));
      }
      
      if (response.isNotEmpty) {
        print('✅ Synthèse générée: ${response.length} caractères');
        return response;
      } else {
        throw Exception('Réponse vide');
      }
    } catch (e) {
      print('❌ Erreur requête synthèse: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION MULTIPLE (PLUSIEURS APPROCHES)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyser plusieurs approches
  Future<Map<String, String>> generateMultipleApproachResponses({
    required String reflectionText,
    required ReflectionType reflectionType,
    required EmotionalState emotionalState,
    required List<String> selectedApproaches,
    UserProfile? userProfile,
    String? declencheur,
    String? souhait,
    String? petitPas,
    int intensiteEmotionnelle = 5,
    String? historique30Jours,
  }) async {
    final responses = <String, String>{};
    
    final approachesToProcess = selectedApproaches.take(5).toList();
    
    for (final approach in approachesToProcess) {
      try {
        final response = await generateApproachSpecificResponse(
          approach: approach,
          reflectionText: reflectionText,
          reflectionType: reflectionType,
          emotionalState: emotionalState,
          userProfile: userProfile,
          declencheur: declencheur,
          souhait: souhait,
          petitPas: petitPas,
          intensiteEmotionnelle: intensiteEmotionnelle,
          historique30Jours: historique30Jours,
        );
        
        responses[approach] = response;
      } catch (e) {
        print('AIService: Erreur pour $approach: $e');
        responses[approach] = '❌ Une erreur est survenue lors de la génération de cette perspective.';
      }
    }
    
    return responses;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculer l'âge depuis la date de naissance
  String _calculateAge(UserProfile? userProfile) {
    if (userProfile?.dateNaissance != null) {
      final now = DateTime.now();
      int age = now.year - userProfile!.dateNaissance!.year;
      if (now.month < userProfile.dateNaissance!.month || 
          (now.month == userProfile.dateNaissance!.month && now.day < userProfile.dateNaissance!.day)) {
        age--;
      }
      return age.toString();
    } else if (userProfile?.age != null) {
      return userProfile!.age.toString();
    }
    return 'Non renseigné';
  }

  /// Obtenir le nom d'affichage du type de réflexion
  String _getTypeDisplayName(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'Pensée';
      case ReflectionType.situation:
        return 'Situation émotionnelle';
      case ReflectionType.existential:
        return 'Question existentielle';
      case ReflectionType.dilemma:
        return 'Dilemme';
    }
  }

  /// Sélection pondérée d'une source (favorise les moins utilisées)
  String _selectWeightedSource(List<String> sources) {
    if (sources.isEmpty) return '';
    if (sources.length == 1) return sources[0];
    
    final weights = <String, double>{};
    int maxUsage = 0;
    
    for (final source in sources) {
      final usage = _sourceUsageHistory[source] ?? 0;
      if (usage > maxUsage) maxUsage = usage;
    }
    
    if (maxUsage == 0) {
      return sources[Random().nextInt(sources.length)];
    }
    
    double totalWeight = 0.0;
    for (final source in sources) {
      final usage = _sourceUsageHistory[source] ?? 0;
      final weight = (maxUsage - usage + 1).toDouble();
      weights[source] = weight;
      totalWeight += weight;
    }
    
    double random = Random().nextDouble() * totalWeight;
    double cumulative = 0.0;
    
    for (final source in sources) {
      cumulative += weights[source]!;
      if (random <= cumulative) {
        return source;
      }
    }
    
    return sources[0];
  }

  /// Valider la configuration de l'API
  bool isConfigured() {
    return _apiKey != 'VOTRE_CLE_API_ANTHROPIC' && _apiKey.isNotEmpty;
  }

  /// Mettre à jour la clé API
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Récupérer l'historique d'utilisation des sources
  Map<String, int> getSourceUsageHistory() {
    return Map.from(_sourceUsageHistory);
  }

  /// Réinitialiser l'historique d'utilisation des sources
  void resetSourceUsageHistory() {
    _sourceUsageHistory.clear();
  }
}

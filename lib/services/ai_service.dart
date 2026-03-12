import 'dart:convert';
import 'dart:math';
import 'dart:async'; // AJOUT: Pour TimeoutException
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import '../services/persistent_storage_service.dart';
import '../services/character_tracking_service.dart';
import '../services/language_detector.dart'; // NOUVEAU: Détection de langue
import '../config/approach_config.dart';
// ═══════════════════════════════════════════════════════════════════════════════
// IMPORTS PROMPTS MULTILINGUES
// ═══════════════════════════════════════════════════════════════════════════════
import '../config/prompts/prompt_selector.dart'; // NOUVEAU: Sélecteur multilingue
// Imports directs pour les cas où on n'a pas de texte utilisateur
import '../config/prompts/fr/prompt_system_unifie.dart';
import '../config/prompts/fr/prompt_synthese.dart';

/// SERVICE IA - VERSION CLAUDE (ANTHROPIC)
/// 
/// Refactorisé pour:
/// - Utiliser l'API Claude au lieu d'OpenAI
/// - Prompts unifiés (1 appel au lieu de 2)
/// - Auto-contrôle intégré (pas de boucle de régénération)
/// - Extraction des métadonnées de figures pour historisation
/// - NOUVEAU: Double modèle (Sonnet pour spiritualités, Haiku pour le reste)
/// - NOUVEAU: Approfondissement des perspectives
/// 
class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();
  AIService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION API CLAUDE (ANTHROPIC)
  // ═══════════════════════════════════════════════════════════════════════════

  final String _baseUrl = 'https://api.anthropic.com/v1/messages';
  String _apiKey = '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';
  
  // MODÈLES CLAUDE — Sonnet 4.6 partout (qualité max pour toutes les sources)
  final String _model = 'claude-sonnet-4-6';                  // Qualité (toutes sources + approfondissement)
  final String _modelFast = 'claude-sonnet-4-6';              // Idem — plus de distinction rapide/qualité
  
  final String _anthropicVersion = '2023-06-01';
  
  // AJOUT: Timeout pour les requêtes (en secondes)
  static const int _requestTimeoutSeconds = 60;
  
  // AJOUT: Configuration du retry automatique (erreurs 429/529)
  static const int _maxRetryAttempts = 3;           // Nombre max de tentatives
  static const int _initialRetryDelaySeconds = 2;   // Délai initial (2s, 4s, 8s)

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: SOURCES NÉCESSITANT LE MODÈLE DE QUALITÉ (SONNET)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Sources nécessitant le modèle de qualité (références textuelles précises)
  static const List<String> _spiritualSources = [
    // Religions/Spiritualités
    'judaisme', 'christianisme', 'islam', 'theravada', 'zen',
    'advaita_vedanta', 'bhakti', 'soufisme', 'taoisme',
    // Traditions juives spécifiques
    'kabbale', 'hassidisme', 'moussar', 'rabbinique',
    // Mystique
    'mystique', 'contemplatif',
    // Sources spirituelles complémentaires
    'stoicisme', 'spiritualite',
  ];

  /// Détermine si une source nécessite le modèle de qualité
  bool _requiresQualityModel(String sourceKey) {
    return _spiritualSources.any((s) => sourceKey.toLowerCase().contains(s));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCES PAR DEFAUT (utilisées si aucune source choisie par l'utilisateur)
  // REGLE: 1 source par type hors spirituel
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<String> _defaultSources = [
    'aristote',               // Philosophe
    'existentialisme',        // Littéraire
    'realisme',               // Littéraire
    'schemas_young',          // Psychologique
  ];

  /// Approches utilisateur
  List<String> get userApproches => _userApproaches;
  List<String> _userApproaches = [];

  /// Historique d'utilisation des sources pour pensée positive
  Map<String, int> _sourceUsageHistory = {};

  /// Dernières métadonnées FIGURE_META extraites (accessibles après génération)
  Map<String, String>? _lastFigureMeta;
  Map<String, String>? get lastFigureMeta => _lastFigureMeta;

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
      return 'No approach selected. Please complete your profile.';
    }
    return 'Your selected approaches: ${_userApproaches.join(", ")}';
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
        return 'Invalid request. ${apiMessage ?? "Please check the parameters."}';
      case 401:
        return 'Invalid or expired API key. Please check your configuration.';
      case 403:
        return 'Access denied. ${apiMessage ?? "Please check your API permissions."}';
      case 404:
        return 'Service not found. The Claude API may be unavailable.';
      case 429:
        return 'Request limit reached. Please wait a few seconds and try again.';
      case 500:
        return 'Claude server error. The service is temporarily unavailable.';
      case 529:
        return 'Claude API overloaded. Please try again in a moment.';
      default:
        return 'Unexpected error ($statusCode). ${apiMessage ?? "Please try again."}';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPEL API CLAUDE (ANTHROPIC)
  // MODIFIÉ: Ajout du paramètre useQualityModel pour choisir le modèle
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Appel à l'API Claude avec séparation System/User prompts
  /// 
  /// [userPrompt] : La demande spécifique (prompt_unifie, prompt_positive_thought, etc.)
  /// [systemPrompt] : L'identité de l'IA (utilise PromptSystemUnifie.content par défaut)
  /// [maxTokens] : Limite de tokens pour la réponse (MODIFIÉ: 800 par défaut au lieu de 4096)
  /// [useQualityModel] : NOUVEAU - Si true, utilise Sonnet, sinon Haiku
  /// 
  /// MODIFIÉ: Retourne maintenant un message d'erreur explicite au lieu de chaîne vide
  /// AJOUT: Retry automatique avec backoff exponentiel pour erreurs 429/529
  Future<String> _callClaude(
    String userPrompt, {
    String? systemPrompt,
    int maxTokens = 800,              // MODIFIÉ: 800 au lieu de 4096
    double temperature = 0.7,
    bool useQualityModel = false,     // NOUVEAU: choix du modèle
  }) async {
    final effectiveSystemPrompt = systemPrompt ?? PromptSystemUnifie.content;
    final effectiveModel = useQualityModel ? _model : _modelFast;  // NOUVEAU
    
    // ═══════════════════════════════════════════════════════════════════════════
    // RETRY AUTOMATIQUE AVEC BACKOFF EXPONENTIEL
    // Tentatives: 1, 2, 3 avec délais: 2s, 4s, 8s entre chaque
    // ═══════════════════════════════════════════════════════════════════════════
    
    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        print('AIService: Envoi requête Claude (tentative $attempt/$_maxRetryAttempts)...');
        print('AIService: Model: $effectiveModel');  // MODIFIÉ: affiche le modèle effectif
        print('AIService: MaxTokens: $maxTokens');
        print('AIService: Prompt length: ${userPrompt.length} chars');
        
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey,
            'anthropic-version': _anthropicVersion,
            // Header requis pour les appels depuis le navigateur (Flutter Web)
            // Permet a l'API Anthropic de retourner les headers CORS
            if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: jsonEncode({
            'model': effectiveModel,  // MODIFIÉ: utilise le modèle effectif
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
            throw TimeoutException('The request took too long (>${_requestTimeoutSeconds}s)');
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
        return '[ERREUR_API] Timeout exceeded after $_maxRetryAttempts attempts. Please check your internet connection.';
      } on FormatException catch (e) {
        print('AIService: ❌ Erreur parsing JSON: $e');
        return '[ERREUR_API] Format error in the server response.';
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
          return '[ERREUR_API] This source could not respond. You can continue with the other perspectives or submit your thought again a bit later.';
        }
        if (errorStr.contains('handshake') || errorStr.contains('certificate')) {
          return '[ERREUR_API] SSL security error. Please check the date/time on your device.';
        }
        
        // Message générique pour les autres erreurs (sans détails techniques)
        return '[ERREUR_API] Cette source n\'a pas pu répondre. Tu peux continuer avec les autres perspectives ou soumettre à nouveau ta pensée un peu plus tard.';
      }
    }
    
    // Ne devrait jamais arriver, mais par sécurité
    return '[ERREUR_API] Unexpected error after $_maxRetryAttempts attempts.';
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
  // MODIFIÉ: Utilise PromptSelector pour la détection automatique de langue
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
    // NOUVEAU: Réinitialiser le cache de langue pour cette nouvelle génération
    // ═══════════════════════════════════════════════════════════════════════
    PromptSelector.resetCache();
    
    // ═══════════════════════════════════════════════════════════════════════
    // CONSTRUIRE LE PROMPT UNIFIÉ MULTILINGUE
    // Le PromptSelector détecte la langue du reflectionText et retourne
    // le prompt dans la langue appropriée (fr, en, ou he)
    // ═══════════════════════════════════════════════════════════════════════

    // Construire la description des émotions pour le prompt
    final emotionsStr = _buildEmotionsString(emotionalState);

    final prompt = PromptSelector.buildUnifiedPrompt(
      userText: reflectionText,  // NOUVEAU: texte pour détection de langue
      userPrenom: userProfile?.prenom,
      userAge: ageStr,
      userValeursSelectionnees: userProfile?.valeursSelectionnees?.join(', '),
      userValeursLibres: userProfile?.valeursLibres,
      typeEntree: _getTypeDisplayName(reflectionType),
      contenu: reflectionText,
      // Note: declencheur, souhait, petitPas ne sont plus utilisés dans le prompt unifié
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
      emotionsActuelles: emotionsStr,
      intensiteEmotionnelle: intensiteEmotionnelle,
    );
    
    // NOUVEAU: Récupérer le system prompt dans la langue détectée
    final systemPrompt = PromptSelector.getSystemPrompt(reflectionText);
    print('AIService: Langue détectée: ${PromptSelector.currentLanguageName}');

    try {
      // ═══════════════════════════════════════════════════════════════════════
      // UN SEUL APPEL API (plus de boucle de régénération)
      // L'auto-contrôle est intégré dans le prompt système
      // ═══════════════════════════════════════════════════════════════════════
      
      final response = await _callClaude(
        prompt,
        systemPrompt: systemPrompt,  // NOUVEAU: system prompt multilingue
        maxTokens: 800,
        useQualityModel: true, // Génération universelle = qualité
      );
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        return '❌ ${response.replaceFirst('[ERREUR_API] ', '')}';
      }
      
      if (response.isEmpty) {
        return '❌ Error generating the response. Please try again.';
      }
      
      // Extraire et sauvegarder les métadonnées de la figure
      final figureMeta = _extractFigureMeta(response);
      _lastFigureMeta = figureMeta; // Stocker pour accès externe
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
  // MODIFIÉ: Utilise Sonnet pour spiritualités, Haiku pour le reste
  // MODIFIÉ: Utilise PromptSelector pour la détection automatique de langue
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
    
    // NOUVEAU: Réinitialiser le cache de langue pour cette nouvelle génération
    PromptSelector.resetCache();
    
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
    
    // Construire la description des émotions pour le prompt
    final emotionsStr = _buildEmotionsString(emotionalState);

    // MODIFIÉ: Utilise PromptSelector pour le prompt multilingue
    final prompt = PromptSelector.buildUnifiedPrompt(
      userText: reflectionText,  // NOUVEAU: texte pour détection de langue
      userPrenom: userProfile?.prenom,
      userAge: ageStr,
      userValeursSelectionnees: userProfile?.valeursSelectionnees?.join(', '),
      userValeursLibres: userProfile?.valeursLibres,
      typeEntree: _getTypeDisplayName(reflectionType),
      contenu: reflectionText,
      // Note: declencheur, souhait, petitPas ne sont plus utilisés dans le prompt unifié
      religions: religionsStr,
      litteratures: litteraturesStr,
      psychologies: psychologiesStr,
      philosophies: philosophiesStr,
      philosophes: philosophesStr,
      historique30Jours: historique30Jours,
      personnagesInterdits: personnagesInterdits,
      emotionsActuelles: emotionsStr,
      intensiteEmotionnelle: intensiteEmotionnelle,
    );
    
    // NOUVEAU: Récupérer le system prompt dans la langue détectée
    final systemPrompt = PromptSelector.getSystemPrompt(reflectionText);
    print('AIService: Langue détectée: ${PromptSelector.currentLanguageName}');

    try {
      // NOUVEAU: Déterminer le modèle selon la source
      final useQuality = _requiresQualityModel(approach);
      print('AIService: Modèle utilisé: ${useQuality ? "Sonnet (qualité)" : "Haiku (rapide)"}');
      
      final response = await _callClaude(
        prompt,
        systemPrompt: systemPrompt,  // NOUVEAU: system prompt multilingue
        maxTokens: 800,
        useQualityModel: useQuality,
      );
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        return '❌ ${response.replaceFirst('[ERREUR_API] ', '')}';
      }
      
      if (response.isEmpty) {
        return '❌ Error generating the response. Please try again.';
      }
      
      // Extraire et sauvegarder les métadonnées de la figure
      final figureMeta = _extractFigureMeta(response);
      _lastFigureMeta = figureMeta; // Stocker pour accès externe
      await _saveExtractedCharacter(figureMeta);

      // Retourner la réponse sans le bloc de métadonnées
      return _removeMetaBlock(response);

    } catch (e) {
      print('AIService: Erreur génération approche spécifique: $e');
      return '❌ Erreur lors de la génération de la réponse. Veuillez réessayer.';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOUVEAU: GÉNÉRATION APPROFONDISSEMENT
  // Utilise toujours Sonnet pour la qualité des références
  // ═══════════════════════════════════════════════════════════════════════════

  /// Génère un approfondissement d'une perspective
  /// Utilise toujours le modèle de qualité (Sonnet)
  /// MODIFIÉ: Utilise PromptSelector pour la détection automatique de langue
  Future<String> generateDeepening({
    required String penseeOriginale,
    required String reponseCourte,
    required String sourceNom,
    required String figureNom,
  }) async {
    print('AIService: Approfondissement pour $sourceNom (figure: $figureNom)');
    
    // NOUVEAU: Réinitialiser le cache de langue
    PromptSelector.resetCache();
    
    // MODIFIÉ: Utilise PromptSelector pour le prompt multilingue
    final prompt = PromptSelector.buildDeepeningPrompt(
      userText: penseeOriginale,  // NOUVEAU: texte pour détection de langue
      penseeOriginale: penseeOriginale,
      reponseCourte: reponseCourte,
      sourceNom: sourceNom,
      figureNom: figureNom,
    );
    
    // NOUVEAU: Récupérer le system prompt dans la langue détectée
    final systemPrompt = PromptSelector.getSystemPrompt(penseeOriginale);
    print('AIService: Langue détectée: ${PromptSelector.currentLanguageName}');
    
    try {
      final response = await _callClaude(
        prompt,
        systemPrompt: systemPrompt,  // NOUVEAU: system prompt multilingue
        maxTokens: 1500,           // Plus long pour l'approfondissement
        useQualityModel: true,     // Toujours Sonnet pour la qualité
      );
      
      // Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        throw Exception(response.replaceFirst('[ERREUR_API] ', ''));
      }
      
      if (response.isEmpty) {
        throw Exception('Réponse vide');
      }
      
      print('AIService: ✅ Approfondissement généré: ${response.length} caractères');
      return response;
      
    } catch (e) {
      print('AIService: ❌ Erreur approfondissement: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION PENSÉE POSITIVE
  // ═══════════════════════════════════════════════════════════════════════════
  // MODIFIÉ: Utilise PromptSelector pour la détection automatique de langue
  
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
    
    // NOUVEAU: Déterminer le texte de référence pour la langue
    // Si historique disponible, utiliser le premier élément comme référence
    final langReference = historique7Jours ?? penseeOuSituation ?? 'fr';
    
    // NOUVEAU: Réinitialiser le cache de langue
    PromptSelector.resetCache();
    
    // MODIFIÉ: Utilise PromptSelector pour le prompt multilingue
    final prompt = PromptSelector.buildPositiveThoughtPrompt(
      userText: langReference,  // NOUVEAU: texte pour détection de langue
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
    
    // NOUVEAU: Récupérer le system prompt dans la langue détectée
    final systemPrompt = PromptSelector.getSystemPrompt(langReference);
    print('AIService: Langue détectée pour pensée positive: ${PromptSelector.currentLanguageName}');

    try {
      final response = await _callClaude(
        prompt,
        systemPrompt: systemPrompt,  // NOUVEAU: system prompt multilingue
        maxTokens: 500,
        useQualityModel: _requiresQualityModel(selectedSource),
      );
      
      // MODIFIÉ: Vérifier si c'est une erreur API
      if (response.startsWith('[ERREUR_API]')) {
        return '❌ ${response.replaceFirst('[ERREUR_API] ', '')}';
      }
      
      return response.isNotEmpty 
        ? response 
        : '❌ Unable to generate a positive thought at this time.';
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
        useQualityModel: false, // Synthèse = rapide
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
    
    final approachesToProcess = selectedApproaches.toList();
    
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
        responses[approach] = '❌ An error occurred while generating this perspective.';
      }
    }
    
    return responses;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Construire une description lisible de l'état émotionnel pour le prompt
  String? _buildEmotionsString(EmotionalState emotionalState) {
    final activeEmotions = emotionalState.emotions.entries
        .where((e) => e.value.level > 0)
        .toList();

    if (activeEmotions.isEmpty) return null;

    final parts = activeEmotions.map((e) {
      final nuancesStr = e.value.nuances.isNotEmpty
          ? ' (${e.value.nuances.join(', ')})'
          : '';
      return '${e.key} ${e.value.level}/100$nuancesStr';
    }).toList();

    return parts.join(', ');
  }

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
    return 'Not specified';
  }

  /// Obtenir le nom d'affichage du type de réflexion
  String _getTypeDisplayName(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'Thought';
      case ReflectionType.situation:
        return 'Emotional situation';
      case ReflectionType.existential:
        return 'Existential question';
      case ReflectionType.dilemma:
        return 'Dilemma';
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

  // ═══════════════════════════════════════════════════════════════════════════
  // RESET COMPLET LORS DU LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Réinitialiser toutes les données utilisateur (appelé lors du logout)
  /// IMPORTANT: Doit être appelé lors de chaque déconnexion pour éviter
  /// que les sources de la session précédente persistent en mémoire
  void clearUserData() {
    _userApproaches = [];
    _sourceUsageHistory.clear();
    print('AIService: Données utilisateur effacées (logout)');
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import '../services/persistent_storage_service.dart';
import '../services/character_tracking_service.dart';
import '../config/approach_config.dart';
import '../config/prompts/prompt_general.dart';
import '../config/prompts/prompt_control.dart';
import '../config/prompts/prompt_positive_thought.dart';
import '../config/prompts/prompt_synthesis.dart';
import '../config/prompts/prompt_system.dart';
import '../config/prompts/prompt_system_control.dart';

/// SERVICE IA - VERSION CORRIGEE
/// Les sources du profil utilisateur sont maintenant transmises correctement
/// a toutes les methodes de generation
class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();
  AIService._();

  // Configuration OpenAI
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  String _apiKey = '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';
  final String _model = 'gpt-4o-mini';

  // Limite de regeneration
  static const int _maxRegenerationAttempts = 2;

  // =========================================================================
  // SOURCES PAR DEFAUT (utilisees si aucune source choisie par l'utilisateur)
  // REGLE: 1 source par type hors spirituel
  // =========================================================================
  static const List<String> _defaultSources = [
    'roman_psychologique',    // Littéraire
    'schemas_young',          // Psychologique
    'existentialisme_philo',  // Philosophique (courant)
    'hannah_arendt',          // Philosophe
  ];

  /// Approches utilisateur
  List<String> get userApproches => _userApproaches;
  List<String> _userApproaches = [];

  /// Historique d'utilisation des sources pour pensee positive
  Map<String, int> _sourceUsageHistory = {};

  /// Charger les approches de l'utilisateur (5 categories)
  /// REGLE: Si aucune source choisie, utiliser les sources par defaut
  Future<void> loadUserApproaches() async {
    try {
      _userApproaches = await PersistentStorageService.instance.getUserApproaches();
      print('AIService: Approches utilisateur chargees: $_userApproaches');
      
      // Si aucune source choisie, appliquer les sources par defaut
      if (_userApproaches.isEmpty) {
        print('AIService: Aucune source utilisateur -> Application des sources par defaut');
        _userApproaches = List.from(_defaultSources);
      }
    } catch (e) {
      print('AIService: Erreur chargement approches: $e');
      // En cas d'erreur, utiliser les sources par defaut
      _userApproaches = List.from(_defaultSources);
    }
  }

  /// Message de configuration
  String getSetupMessage() {
    if (_userApproaches.isEmpty) {
      return 'Aucune approche selectionnee. Veuillez completer votre profil.';
    }
    return 'Vos approches selectionnees : ${_userApproaches.join(", ")}';
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

  /// Categoriser les approches en 5 categories
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

  /// Identifier le motif universel a partir de la pensee
  String _identifyUniversalMotif(String pensee) {
    final penseeLower = pensee.toLowerCase();
    
    final motifs = {
      'peur': ['peur', 'angoisse', 'anxieux', 'anxiete', 'effray', 'terrifi', 'inquiet', 'stress'],
      'perte': ['perte', 'perdu', 'deuil', 'mort', 'disparu', 'fini', 'termine'],
      'doute': ['doute', 'incertain', 'hesit', 'confus', 'perplexe', 'indecis'],
      'culpabilite': ['culpab', 'faute', 'responsable', 'regret', 'remords', 'honte'],
      'colere': ['colere', 'enerv', 'furieux', 'rage', 'irrit', 'agac', 'frustre'],
      'tristesse': ['triste', 'melanc', 'deprim', 'abattu', 'morose', 'cafard'],
      'solitude': ['seul', 'isol', 'abandon', 'incompris', 'exclu'],
      'impuissance': ['impuissant', 'bloqu', 'coinc', 'paralyse', 'incapable', 'depass'],
      'epuisement': ['epuis', 'fatigu', 'burn', 'bout', 'vide', 'extenua'],
      'injustice': ['injust', 'inegal', 'arbitraire', 'trahi', 'exploit'],
      'rupture': ['rupture', 'separation', 'divorce', 'quitt', 'rompu'],
      'dependance': ['depend', 'attach', 'besoin', 'manque', 'addict'],
      'conflit': ['conflit', 'dispute', 'tension', 'desaccord', 'opposi'],
      'echec': ['echec', 'rate', 'echou', 'fiasco', 'defaite'],
      'vide': ['vide', 'sens', 'absurde', 'inutile', 'pourquoi'],
    };
    
    for (final entry in motifs.entries) {
      for (final keyword in entry.value) {
        if (penseeLower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return 'questionnement existentiel';
  }

  /// ==========================================================================
  /// GENERATION UNIVERSELLE AVEC CONTROLE QUALITE
  /// ==========================================================================
  
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
    
    // Note: loadUserApproaches() applique automatiquement les sources par defaut si vide
    
    // Charger les personnages interdits
    final personnagesInterdits = await CharacterTrackingService.instance.getForbiddenCharactersText();
    
    // Identifier le motif universel
    final motifUniversel = _identifyUniversalMotif(reflectionText);
    
    // Categoriser les approches
    final categories = _categorizeApproaches(_userApproaches);
    
    // Calculer l'age depuis la date de naissance si disponible
    String ageStr = 'Non renseigne';
    if (userProfile?.dateNaissance != null) {
      final now = DateTime.now();
      int age = now.year - userProfile!.dateNaissance!.year;
      if (now.month < userProfile!.dateNaissance!.month || 
          (now.month == userProfile!.dateNaissance!.month && now.day < userProfile!.dateNaissance!.day)) {
        age--;
      }
      ageStr = age.toString();
    } else if (userProfile?.age != null) {
      ageStr = userProfile!.age.toString();
    }
    
    // Construire le prompt
    final prompt = PromptGeneral.build(
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
      var response = await _callOpenAI(prompt);
      
      if (response.isEmpty) {
        return 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
      }
      
      // Controle qualite
      final sourcesList = _userApproaches.join(', ');
      final controlResult = await _controlResponse(
        response: response,
        source: sourcesList,
        motifUniversel: motifUniversel,
        penseeUtilisateur: reflectionText,
      );
      
      if (controlResult.isValid) {
        await _saveExtractedCharacters(controlResult.extractedCharacters);
        return controlResult.correctedResponse ?? response;
      }
      
      // Regeneration si necessaire
      if (controlResult.needsRegeneration) {
        for (int attempt = 1; attempt <= _maxRegenerationAttempts; attempt++) {
          print('AIService: Tentative de regeneration $attempt/$_maxRegenerationAttempts');
          
          final constrainedPrompt = '$prompt\n\nCONTRAINTES:\n${controlResult.constraintsToAdd}';
          response = await _callOpenAI(constrainedPrompt);
          
          if (response.isEmpty) continue;
          
          final newControlResult = await _controlResponse(
            response: response,
            source: sourcesList,
            motifUniversel: motifUniversel,
            penseeUtilisateur: reflectionText,
          );
          
          if (newControlResult.isValid) {
            await _saveExtractedCharacters(newControlResult.extractedCharacters);
            return newControlResult.correctedResponse ?? response;
          }
        }
        
        print('AIService: Max tentatives atteintes');
        await _saveExtractedCharacters(controlResult.extractedCharacters);
        return controlResult.correctedResponse ?? response;
      }
      
      await _saveExtractedCharacters(controlResult.extractedCharacters);
      return controlResult.correctedResponse ?? response;
      
    } catch (e) {
      print('AIService: Erreur generation universelle: $e');
      return 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
    }
  }

  /// ==========================================================================
  /// GENERATION POUR APPROCHE SPECIFIQUE (ROUE DU HASARD)
  /// CORRIGE: Utilise maintenant les sources du profil + la source de la roue
  /// ==========================================================================
  
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
  }) async {
    
    // Trouver la configuration de l'approche selectionnee via la roue
    final approachConfig = ApproachCategories.allApproaches.firstWhere(
      (a) => a.key == approach,
      orElse: () => ApproachConfig(
        key: approach,
        name: approach,
        description: 'Approche de developpement personnel',
        credo: 'Chaque difficulte est une opportunite de croissance',
        tonEmotionnel: 'Bienveillant et encourageant',
        exemples: ['Sagesse universelle'],
        icon: Icons.psychology,
        color: Colors.blue,
        type: ApproachType.psychological,
      ),
    );

    print('AIService: Generation pour approche specifique: ${approachConfig.name}');

    // =========================================================================
    // CORRECTION: Utiliser getUserApproaches() qui fonctionne correctement
    // au lieu des champs du userProfile qui peuvent etre null
    // =========================================================================
    List<String> profileSources = await PersistentStorageService.instance.getUserApproaches();
    
    print('AIService: Sources du profil utilisateur: $profileSources');
    
    // =========================================================================
    // REGLE: Si AUCUNE source choisie (profil vide), utiliser les sources par defaut
    // Les sources par defaut ne s'appliquent que si l'utilisateur n'a fait aucun choix
    // =========================================================================
    final bool userHasNoSources = profileSources.isEmpty;
    
    if (userHasNoSources) {
      print('AIService: Aucune source utilisateur -> Application des sources par defaut');
      profileSources = List.from(_defaultSources);
    }
    
    // Ajouter la source de la roue si pas deja presente
    if (!profileSources.contains(approach)) {
      profileSources.add(approach);
    }
    
    // Categoriser TOUTES les sources (profil + roue)
    final categories = _categorizeApproaches(profileSources);

    // Charger les personnages interdits
    final personnagesInterdits = await CharacterTrackingService.instance.getForbiddenCharactersText();
    
    // Identifier le motif universel
    final motifUniversel = _identifyUniversalMotif(reflectionText);

    // Calculer l'age depuis la date de naissance si disponible
    String ageStr = 'Non renseigne';
    if (userProfile?.dateNaissance != null) {
      final now = DateTime.now();
      int age = now.year - userProfile!.dateNaissance!.year;
      if (now.month < userProfile!.dateNaissance!.month || 
          (now.month == userProfile!.dateNaissance!.month && now.day < userProfile!.dateNaissance!.day)) {
        age--;
      }
      ageStr = age.toString();
    } else if (userProfile?.age != null) {
      ageStr = userProfile!.age.toString();
    }

    // =========================================================================
    // CONSTRUIRE LE PROMPT AVEC UNIQUEMENT LA SOURCE DEMANDEE
    // Chaque appel traite UNE SEULE source (approche itérative)
    // =========================================================================
    
    // Déterminer dans quelle catégorie placer la source demandée
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
    
    final prompt = PromptGeneral.build(
      userPrenom: userProfile?.prenom,
      userAge: ageStr,
      userValeursSelectionnees: userProfile?.valeursSelectionnees?.join(', '),
      userValeursLibres: userProfile?.valeursLibres,
      typeEntree: _getTypeDisplayName(reflectionType),
      contenu: reflectionText,
      declencheur: declencheur,
      souhait: souhait,
      petitPas: petitPas,
      // CORRECTION: Utilise UNIQUEMENT la source demandée (pas toutes les sources du profil)
      religions: religionsStr,
      litteratures: litteraturesStr,
      psychologies: psychologiesStr,
      philosophies: philosophiesStr,
      philosophes: philosophesStr,
      historique30Jours: null,
      personnagesInterdits: personnagesInterdits,
    );

    try {
      var response = await _callOpenAI(prompt);
      
      if (response.isEmpty) {
        return 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
      }
      
      // Controle qualite
      final controlResult = await _controlResponse(
        response: response,
        source: approachConfig.name,
        motifUniversel: motifUniversel,
        penseeUtilisateur: reflectionText,
      );
      
      if (controlResult.isValid) {
        await _saveExtractedCharacters(controlResult.extractedCharacters);
        return controlResult.correctedResponse ?? response;
      }
      
      // Regeneration si necessaire
      if (controlResult.needsRegeneration) {
        for (int attempt = 1; attempt <= _maxRegenerationAttempts; attempt++) {
          print('AIService: Regeneration approche specifique $attempt/$_maxRegenerationAttempts');
          
          final constrainedPrompt = '$prompt\n\nCONTRAINTES:\n${controlResult.constraintsToAdd}';
          response = await _callOpenAI(constrainedPrompt);
          
          if (response.isEmpty) continue;
          
          final newControlResult = await _controlResponse(
            response: response,
            source: approachConfig.name,
            motifUniversel: motifUniversel,
            penseeUtilisateur: reflectionText,
          );
          
          if (newControlResult.isValid) {
            await _saveExtractedCharacters(newControlResult.extractedCharacters);
            return newControlResult.correctedResponse ?? response;
          }
        }
      }
      
      await _saveExtractedCharacters(controlResult.extractedCharacters);
      return controlResult.correctedResponse ?? response;
      
    } catch (e) {
      print('AIService: Erreur generation approche specifique: $e');
      return 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
    }
  }

  /// Helper pour construire la chaine de sources avec mise en evidence de la source principale
  String _buildSourceString(List<String> categorySources, ApproachConfig mainApproach, ApproachType targetType) {
    if (categorySources.isEmpty) {
      // Si la source de la roue est de ce type, l'utiliser
      if (mainApproach.type == targetType) {
        return '${mainApproach.name} (source principale)';
      }
      return 'Aucune';
    }
    
    // Si la source de la roue est de ce type, la mettre en evidence
    if (mainApproach.type == targetType) {
      final otherSources = categorySources.where((s) => s != mainApproach.name).toList();
      if (otherSources.isNotEmpty) {
        return '${mainApproach.name} (source principale), ${otherSources.join(', ')}';
      }
      return '${mainApproach.name} (source principale)';
    }
    
    return categorySources.join(', ');
  }

  /// ==========================================================================
  /// CONTROLE QUALITE DES REPONSES
  /// ==========================================================================
  
  Future<ControlResult> _controlResponse({
    required String response,
    required String source,
    required String motifUniversel,
    required String penseeUtilisateur,
  }) async {
    final controlPrompt = PromptControl.build(
      reponseAControler: response,
      sourceUtilisee: source,
      motifUniverselAttendu: motifUniversel,
      penseeUtilisateur: penseeUtilisateur,
    );
    
    try {
      // Utiliser le system prompt spécifique au contrôle (pas le prompt génératif)
      final controlResponse = await _callOpenAI(
        controlPrompt,
        systemPrompt: PromptSystemControl.content,
        maxTokens: 2000,
      );
      
      if (controlResponse.isEmpty) {
        return ControlResult(isValid: true, extractedCharacters: []);
      }
      
      return _parseControlResult(controlResponse, response);
      
    } catch (e) {
      print('AIService: Erreur controle: $e');
      return ControlResult(isValid: true, extractedCharacters: []);
    }
  }

  /// Parser le resultat JSON du controle
  ControlResult _parseControlResult(String jsonResponse, String originalResponse) {
    try {
      var cleanJson = jsonResponse.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();
      
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;
      
      final isValid = data['valid'] as bool? ?? true;
      final problems = (data['problems'] as List<dynamic>?) ?? [];
      final actions = (data['actions'] as List<dynamic>?) ?? [];
      final extractedChars = (data['extractedCharacters'] as List<dynamic>?) ?? [];
      final correctedResponse = data['correctedResponse'] as String?;
      
      bool needsRegeneration = false;
      final constraintsBuffer = StringBuffer();
      
      for (final action in actions) {
        final actionMap = action as Map<String, dynamic>;
        if (actionMap['type'] == 'REGENERATE') {
          needsRegeneration = true;
          constraintsBuffer.writeln('- ${actionMap['detail']}');
        }
      }
      
      final characters = <Map<String, dynamic>>[];
      for (final char in extractedChars) {
        final charMap = char as Map<String, dynamic>;
        characters.add({
          'nom': charMap['nom'] ?? '',
          'source': charMap['source'] ?? '',
          'reference': charMap['reference'] ?? '',
          'motifUniversel': charMap['motifUniversel'] ?? '',
        });
      }
      
      return ControlResult(
        isValid: isValid,
        needsRegeneration: needsRegeneration,
        constraintsToAdd: constraintsBuffer.toString(),
        extractedCharacters: characters,
        correctedResponse: correctedResponse ?? (isValid ? originalResponse : null),
        problems: problems.map((p) => p.toString()).toList(),
      );
      
    } catch (e) {
      print('AIService: Erreur parsing JSON controle: $e');
      return ControlResult(
        isValid: true,
        extractedCharacters: [],
        correctedResponse: originalResponse,
      );
    }
  }

  /// Sauvegarder les personnages extraits
  Future<void> _saveExtractedCharacters(List<Map<String, dynamic>> characters) async {
    if (characters.isEmpty) return;
    
    try {
      await CharacterTrackingService.instance.saveMultipleCharacters(characters);
      print('AIService: ${characters.length} personnages sauvegardes');
    } catch (e) {
      print('AIService: Erreur sauvegarde personnages: $e');
    }
  }

  /// ==========================================================================
  /// GENERATION PENSEE POSITIVE
  /// ==========================================================================
  
  Future<String> generatePositiveThought({
    UserProfile? userProfile,
    String? penseeOuSituation,
    String? historique7Jours,
  }) async {
    // =========================================================================
    // CORRECTION: Utiliser getUserApproaches() qui fonctionne correctement
    // =========================================================================
    List<String> allSources = await PersistentStorageService.instance.getUserApproaches();
    
    debugPrint('AIService: Pensee Positive - Sources: ${allSources.length}');
    
    // =========================================================================
    // REGLE: Si AUCUNE source choisie (profil vide), utiliser les sources par defaut
    // =========================================================================
    if (allSources.isEmpty) {
      debugPrint('AIService: Pensee Positive - Aucune source -> Application des sources par defaut');
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
    
    // Calculer l'age depuis la date de naissance si disponible
    String ageStr = 'Non renseigne';
    if (userProfile?.dateNaissance != null) {
      final now = DateTime.now();
      int age = now.year - userProfile!.dateNaissance!.year;
      if (now.month < userProfile!.dateNaissance!.month || 
          (now.month == userProfile!.dateNaissance!.month && now.day < userProfile!.dateNaissance!.day)) {
        age--;
      }
      ageStr = age.toString();
    } else if (userProfile?.age != null) {
      ageStr = userProfile!.age.toString();
    }
    
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
      final response = await _callOpenAI(prompt);
      return response.isNotEmpty 
        ? response 
        : 'Impossible de generer une pensee positive pour le moment.';
    } catch (e) {
      print('AIService: Erreur pensee positive: $e');
      return 'Impossible de generer une pensee positive pour le moment.';
    }
  }

  /// Selection ponderee d'une source
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

  /// Appel a l'API OpenAI avec séparation System/User prompts
  /// 
  /// [userPrompt] : La demande spécifique (prompt_general, prompt_positive_thought, etc.)
  /// [systemPrompt] : L'identité de l'IA (utilise PromptSystem.content par défaut)
  /// [maxTokens] : Limite de tokens pour la réponse (4096 par défaut, pas de restriction artificielle)
  Future<String> _callOpenAI(
    String userPrompt, {
    String? systemPrompt,
    int maxTokens = 4096,
  }) async {
    try {
      // Utiliser le system prompt par défaut si non fourni
      final effectiveSystemPrompt = systemPrompt ?? PromptSystem.content;
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': effectiveSystemPrompt,
            },
            {
              'role': 'user',
              'content': userPrompt,
            }
          ],
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        return content.trim();
      } else {
        print('AIService: Erreur API OpenAI: ${response.statusCode}');
        print('AIService: Body: ${response.body}');
        return '';
      }
    } catch (e) {
      print('AIService: Erreur requete OpenAI: $e');
      return '';
    }
  }

  /// Obtenir le nom d'affichage du type de reflexion
  String _getTypeDisplayName(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'Pensee';
      case ReflectionType.situation:
        return 'Situation emotionnelle';
      case ReflectionType.existential:
        return 'Question existentielle';
      case ReflectionType.dilemma:
        return 'Dilemme';
    }
  }

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
        );
        
        responses[approach] = response;
      } catch (e) {
        print('AIService: Erreur pour $approach: $e');
        responses[approach] = 'Une erreur est survenue lors de la generation de cette perspective.';
      }
    }
    
    return responses;
  }

  /// Valider la configuration de l'API
  bool isConfigured() {
    return _apiKey != 'YOUR_OPENAI_API_KEY' && _apiKey.isNotEmpty;
  }

  /// Mettre a jour la cle API
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Recuperer l'historique d'utilisation des sources
  Map<String, int> getSourceUsageHistory() {
    return Map.from(_sourceUsageHistory);
  }

  /// Reinitialiser l'historique d'utilisation des sources
  void resetSourceUsageHistory() {
    _sourceUsageHistory.clear();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // AJOUTER CETTE MÉTHODE DANS lib/services/ai_service.dart
  // À insérer AVANT la méthode isConfigured() (vers ligne 496)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Générer une synthèse vocale d'un texte
  /// Utilisé pour condenser une réponse longue en 2-3 phrases
  Future<String> generateSynthesis({
    required String systemPrompt,
    required String userPrompt,
    String model = 'gpt-4o-mini',
    double temperature = 0.3,
    int maxTokens = 150,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userPrompt,
            }
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        print('✅ Synthèse générée: ${content.length} caractères');
        return content.trim();
      } else {
        print('❌ Erreur API synthèse: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur requête synthèse: $e');
      rethrow;
    }
  }
}

/// ==========================================================================
/// CLASSE RESULTAT DU CONTROLE
/// ==========================================================================

class ControlResult {
  final bool isValid;
  final bool needsRegeneration;
  final String constraintsToAdd;
  final List<Map<String, dynamic>> extractedCharacters;
  final String? correctedResponse;
  final List<String> problems;

  ControlResult({
    required this.isValid,
    this.needsRegeneration = false,
    this.constraintsToAdd = '',
    required this.extractedCharacters,
    this.correctedResponse,
    this.problems = const [],
  });
}


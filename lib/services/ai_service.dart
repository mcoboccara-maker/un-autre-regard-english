import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';
import '../services/persistent_storage_service.dart';
import '../config/approach_config.dart';
import '../config/prompts_config.dart';

/// SERVICE IA - VERSION AVEC PROMPTS EXTERNALISES
/// Les prompts sont dans prompts_config.dart pour eviter les pertes
class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();
  AIService._();

  // Configuration OpenAI
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  String _apiKey = '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';
  final String _model = 'gpt-4o-mini';

  /// Approches utilisateur
  List<String> get userApproches => _userApproaches;
  List<String> _userApproaches = [];

  /// Historique d'utilisation des sources pour pensee positive
  Map<String, int> _sourceUsageHistory = {};

  /// Charger les approches de l'utilisateur (5 categories)
  Future<void> loadUserApproaches() async {
    try {
      _userApproaches = await PersistentStorageService.instance.getUserApproaches();
      print('Approches utilisateur chargees: $_userApproaches');
    } catch (e) {
      print('Erreur chargement approches: $e');
      _userApproaches = [];
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

  /// GENERATION UNIVERSELLE AVEC PROMPT EXTERNALISE
  /// Version finalisee avec tous les parametres du profil
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
    
    if (_userApproaches.isEmpty) {
      return 'Erreur : Veuillez activer au moins une source d\'inspiration dans votre profil.';
    }
    
    // Categoriser les approches
    final categories = _categorizeApproaches(_userApproaches);
    
    // Construire le prompt via PromptsConfig
    final prompt = PromptsConfig.buildGeneralPrompt(
      userAge: userProfile?.age?.toString() ?? 'Non renseigne',
      userSituationFamiliale: userProfile?.situationFamiliale ?? 'Non renseignee',
      userSanteEnergie: userProfile?.healthEnergy ?? 'Non renseigne',
      userContraintes: userProfile?.contraintes ?? 'Non renseignees',
      userValeurs: userProfile?.valeurs ?? 'Non renseignees',
      userRessources: userProfile?.ressources ?? 'Non renseignees',
      userContraintesRecurrentes: userProfile?.contraintesRecurrentes ?? 'Non renseignees',
      userOuJenSuis: userProfile?.ouJenSuis ?? 'Non renseigne',
      userCeQuiPese: userProfile?.ceQuiPese ?? 'Non renseigne',
      userCeQuiTient: userProfile?.ceQuiTient ?? 'Non renseigne',
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
    );

    try {
      final response = await _callOpenAI(prompt, maxTokens: 2000);
      return response.isNotEmpty 
        ? response 
        : 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
    } catch (e) {
      print('Erreur generation reponse universelle: $e');
      return 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
    }
  }

  /// GENERATION PENSEE POSITIVE AVEC PROMPT EXTERNALISE
  /// Version simplifiee et exigeante - pas de conseils, pas de genericite
  Future<String> generatePositiveThought({
    UserProfile? userProfile,
    String? penseeOuSituation,
    String? historique30Jours,
  }) async {
    // Extraire TOUTES les sources du profil (5 categories)
    final List<String> allSources = [];
    
    if (userProfile != null) {
      allSources.addAll(userProfile.religionsSelectionnees);
      allSources.addAll(userProfile.courantsLitteraires);
      allSources.addAll(userProfile.approchesPsychologiques);
      allSources.addAll(userProfile.courantsPhilosophiques);
      allSources.addAll(userProfile.philosophesSelectionnes);
    }
    
    debugPrint('DEBUG Pensee Positive:');
    debugPrint('  - Profil fourni: ${userProfile?.email ?? "Aucun profil"}');
    debugPrint('  - Sources TOTALES: ${allSources.length}');
    debugPrint('  - Detail: $allSources');
    debugPrint('  - Pensee/Situation: ${penseeOuSituation ?? "Aucune"}');
    
    if (allSources.isEmpty) {
      return 'Erreur : Veuillez activer au moins une source d\'inspiration dans votre profil.';
    }
    
    // Selectionner une source de maniere ponderee
    final selectedSource = _selectWeightedSource(allSources);
    _sourceUsageHistory[selectedSource] = (_sourceUsageHistory[selectedSource] ?? 0) + 1;
    
    debugPrint('Source selectionnee: $selectedSource');
    
    // Recuperer le nom complet de la source
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
    
    // Categoriser les approches
    final categories = _categorizeApproaches(allSources);
    
    // Construire le prompt via PromptsConfig
    final prompt = PromptsConfig.buildPositiveThoughtPrompt(
      userAge: userProfile?.age?.toString() ?? 'Non renseigne',
      userSituation: userProfile?.situationFamiliale ?? 'Non renseignee',
      userValeurs: userProfile?.valeurs ?? 'Non renseignees',
      userContraintes: userProfile?.contraintes ?? 'Non renseignees',
      userRessources: userProfile?.ressources ?? 'Non renseignees',
      userTonalite: userProfile?.tonalitePrefere ?? 'neutre',
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
      historique30Jours: historique30Jours,
      penseeOuSituation: penseeOuSituation,
    );

    try {
      final response = await _callOpenAI(prompt, maxTokens: 400);
      return response.isNotEmpty 
        ? response 
        : 'Impossible de generer une pensee positive pour le moment.';
    } catch (e) {
      print('Erreur generation pensee positive: $e');
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

  /// Formater les emotions pour le prompt
  String _formatEmotions(EmotionalState emotionalState) {
    final buffer = StringBuffer();
    
    if (emotionalState.emotions.isNotEmpty) {
      buffer.writeln('Emotions ressenties :');
      for (final entry in emotionalState.emotions.entries) {
        if (entry.value.level > 0) {
          buffer.write('- ${entry.key} : ${entry.value.level}%');
          if (entry.value.nuances.isNotEmpty) {
            buffer.write(' (${entry.value.nuances.join(', ')})');
          }
          buffer.writeln();
        }
      }
    }
    
    if (buffer.isEmpty) {
      return 'Aucune emotion renseignee';
    }
    
    return buffer.toString();
  }

  /// Generer une reponse specifique a une approche
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
    
    // Trouver la configuration de l'approche
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

    final userContext = userProfile?.getContextForAI() ?? '';
    
    // Construire le prompt via PromptsConfig
    final prompt = PromptsConfig.buildApproachSpecificPrompt(
      approachName: approachConfig.name,
      approachCredo: approachConfig.credo,
      approachTon: approachConfig.tonEmotionnel,
      userContext: userContext,
      reflectionText: reflectionText,
      typeEntree: _getTypeDisplayName(reflectionType),
      intensite: intensiteEmotionnelle,
      declencheur: declencheur,
      souhait: souhait,
      petitPas: petitPas,
    );

    try {
      final response = await _callOpenAI(prompt, maxTokens: 1000);
      return response.isNotEmpty 
        ? response 
        : 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
    } catch (e) {
      print('Erreur generation reponse specifique: $e');
      return 'Erreur lors de la generation de la reponse. Veuillez reessayer.';
    }
  }

  /// Appel a l'API OpenAI
  Future<String> _callOpenAI(String prompt, {int maxTokens = 500}) async {
    try {
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
              'role': 'user',
              'content': prompt,
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
        print('Erreur API OpenAI: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      print('Erreur requete OpenAI: $e');
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

  /// Analyser plusieurs approches en parallele
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
        print('Erreur generation pour $approach: $e');
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
}

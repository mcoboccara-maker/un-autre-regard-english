import 'dart:async';
import 'semantic_search_service.dart';
import 'ai_service.dart';
import '../config/semantic_search_config.dart';
import '../config/consultation_mode_config.dart';
import '../models/reflection.dart';
import '../models/emotional_state.dart';
import '../models/user_profile.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// SERVICE RAG - RETRIEVAL AUGMENTED GENERATION
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Service intégrant la recherche sémantique dans l'Encyclopedia Judaica
/// avec la génération de réponses par Claude.
///
/// Le RAG permet d'enrichir les réponses de l'IA avec des connaissances
/// précises extraites de l'Encyclopedia Judaica, améliorant:
/// - La précision des références textuelles
/// - La pertinence des citations
/// - La profondeur des explications
///
/// Architecture:
/// 1. Analyse de la requête utilisateur
/// 2. Recherche sémantique dans l'Encyclopedia
/// 3. Injection du contexte pertinent dans le prompt
/// 4. Génération de la réponse enrichie
///
/// Usage:
/// ```dart
/// final ragService = RAGService.instance;
/// await ragService.initialize();
///
/// final response = await ragService.generateEnrichedResponse(
///   reflectionText: 'Que signifie le Shabbat pour moi?',
///   reflectionType: ReflectionType.existential,
///   emotionalState: emotionalState,
/// );
/// ```
///
class RAGService {
  static RAGService? _instance;
  static RAGService get instance => _instance ??= RAGService._();
  RAGService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // DÉPENDANCES
  // ═══════════════════════════════════════════════════════════════════════════

  final SemanticSearchService _searchService = SemanticSearchService.instance;
  final AIService _aiService = AIService.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Activer/désactiver le RAG
  bool _ragEnabled = false;
  bool get ragEnabled => _ragEnabled;

  /// Nombre de passages à récupérer
  int _topK = SemanticSearchConfig.ragTopK;

  /// Score minimum de similarité
  double _minScore = SemanticSearchConfig.ragMinScore;

  /// État d'initialisation
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Mode de consultation actuel
  ConsultationMode _consultationMode = ConsultationMode.unified;
  ConsultationMode get consultationMode => _consultationMode;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialise le service RAG
  ///
  /// [embeddingProvider] : Provider pour les embeddings
  /// [vectorStore] : Type de vector store
  /// [config] : Configuration des clés API
  /// [topK] : Nombre de passages à récupérer (défaut: 3)
  /// [minScore] : Score minimum de similarité (défaut: 0.75)
  Future<void> initialize({
    EmbeddingProvider embeddingProvider = EmbeddingProvider.openAI,
    VectorStoreType vectorStore = VectorStoreType.pinecone,
    Map<String, String>? config,
    int topK = 3,
    double minScore = 0.75,
  }) async {
    try {
      // Utiliser la configuration fournie ou celle des variables d'environnement
      final effectiveConfig = config ?? SemanticSearchConfig.getConfigFromEnvironment();

      await _searchService.initialize(
        embeddingProvider: embeddingProvider,
        vectorStore: vectorStore,
        config: effectiveConfig,
      );

      _topK = topK;
      _minScore = minScore;
      _ragEnabled = true;
      _isInitialized = true;

      print('RAGService: ✅ Initialisé avec RAG activé');
    } catch (e) {
      print('RAGService: ⚠️ Initialisation échouée, RAG désactivé: $e');
      _ragEnabled = false;
      _isInitialized = true; // Marqué comme initialisé mais sans RAG
    }
  }

  /// Initialise le service en mode dégradé (sans RAG)
  void initializeWithoutRAG() {
    _ragEnabled = false;
    _isInitialized = true;
    print('RAGService: ✅ Initialisé sans RAG');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION ENRICHIE AVEC RAG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Génère une réponse universelle enrichie avec le contexte de l'Encyclopedia
  ///
  /// Si le RAG est activé, recherche d'abord des passages pertinents
  /// et les injecte dans le contexte avant de générer la réponse.
  Future<String> generateEnrichedResponse({
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
    if (!_isInitialized) {
      print('RAGService: ⚠️ Non initialisé, appel direct à AIService');
      return _aiService.generateUniversalResponse(
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
    }

    // Si le RAG est désactivé, appeler directement l'AIService
    if (!_ragEnabled) {
      return _aiService.generateUniversalResponse(
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
    }

    try {
      // 1. Rechercher des passages pertinents dans l'Encyclopedia
      print('RAGService: Recherche de contexte pour: "${reflectionText.substring(0, reflectionText.length.clamp(0, 50))}..."');

      final encyclopediaContext = await _searchService.searchForRAG(
        reflectionText,
        topK: _topK,
        minScore: _minScore,
      );

      // 2. Si du contexte a été trouvé, l'enrichir dans l'historique
      String enrichedHistorique = historique30Jours ?? '';
      if (encyclopediaContext.isNotEmpty) {
        print('RAGService: ✅ Contexte Encyclopedia trouvé');
        enrichedHistorique = _buildEnrichedHistorique(
          historique30Jours,
          encyclopediaContext,
        );
      } else {
        print('RAGService: ⚠️ Aucun contexte Encyclopedia pertinent trouvé');
      }

      // 3. Générer la réponse avec le contexte enrichi
      return _aiService.generateUniversalResponse(
        reflectionText: reflectionText,
        reflectionType: reflectionType,
        emotionalState: emotionalState,
        userProfile: userProfile,
        declencheur: declencheur,
        souhait: souhait,
        petitPas: petitPas,
        intensiteEmotionnelle: intensiteEmotionnelle,
        historique30Jours: enrichedHistorique,
      );

    } catch (e) {
      print('RAGService: ❌ Erreur RAG, fallback vers AIService: $e');
      // En cas d'erreur RAG, fallback vers la génération normale
      return _aiService.generateUniversalResponse(
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
    }
  }

  /// Génère une réponse pour une approche spécifique avec RAG
  Future<String> generateEnrichedApproachResponse({
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
    if (!_isInitialized || !_ragEnabled) {
      return _aiService.generateApproachSpecificResponse(
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
    }

    try {
      // Recherche contextuelle avec filtre sur l'approche
      final filters = _getFiltersForApproach(approach);

      final encyclopediaContext = await _searchService.searchForRAG(
        reflectionText,
        topK: _topK,
        minScore: _minScore,
        filters: filters,
      );

      String enrichedHistorique = historique30Jours ?? '';
      if (encyclopediaContext.isNotEmpty) {
        enrichedHistorique = _buildEnrichedHistorique(
          historique30Jours,
          encyclopediaContext,
        );
      }

      return _aiService.generateApproachSpecificResponse(
        approach: approach,
        reflectionText: reflectionText,
        reflectionType: reflectionType,
        emotionalState: emotionalState,
        userProfile: userProfile,
        declencheur: declencheur,
        souhait: souhait,
        petitPas: petitPas,
        intensiteEmotionnelle: intensiteEmotionnelle,
        historique30Jours: enrichedHistorique,
      );

    } catch (e) {
      print('RAGService: ❌ Erreur RAG approche, fallback: $e');
      return _aiService.generateApproachSpecificResponse(
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
    }
  }

  /// Génère un approfondissement enrichi avec RAG
  Future<String> generateEnrichedDeepening({
    required String penseeOriginale,
    required String reponseCourte,
    required String sourceNom,
    required String figureNom,
  }) async {
    if (!_isInitialized || !_ragEnabled) {
      return _aiService.generateDeepening(
        penseeOriginale: penseeOriginale,
        reponseCourte: reponseCourte,
        sourceNom: sourceNom,
        figureNom: figureNom,
      );
    }

    try {
      // Recherche spécifique sur la figure mentionnée
      List<SearchResult> results = [];

      // Rechercher d'abord la figure
      if (figureNom.isNotEmpty && figureNom != 'Aucune figure') {
        results = await _searchService.searchFigures(
          figureNom,
          topK: 2,
          minScore: 0.6,
        );
      }

      // Rechercher aussi sur le concept principal
      final conceptResults = await _searchService.search(
        penseeOriginale,
        topK: 2,
        minScore: _minScore,
      );
      results.addAll(conceptResults);

      // Construire le contexte
      String context = '';
      if (results.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('\n=== RÉFÉRENCES ENCYCLOPEDIA JUDAICA ===\n');
        for (final result in results.take(3)) {
          buffer.writeln('• ${result.title}');
          buffer.writeln('  ${result.content.substring(0, result.content.length.clamp(0, 300))}...');
          if (result.reference != null) {
            buffer.writeln('  [${result.reference}]');
          }
          buffer.writeln('');
        }
        context = buffer.toString();
      }

      // Injecter le contexte dans la pensée originale
      final enrichedPensee = context.isNotEmpty
          ? '$penseeOriginale\n$context'
          : penseeOriginale;

      return _aiService.generateDeepening(
        penseeOriginale: enrichedPensee,
        reponseCourte: reponseCourte,
        sourceNom: sourceNom,
        figureNom: figureNom,
      );

    } catch (e) {
      print('RAGService: ❌ Erreur RAG deepening, fallback: $e');
      return _aiService.generateDeepening(
        penseeOriginale: penseeOriginale,
        reponseCourte: reponseCourte,
        sourceNom: sourceNom,
        figureNom: figureNom,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECHERCHE DIRECTE (SANS GÉNÉRATION)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recherche directe dans l'Encyclopedia Judaica
  ///
  /// Permet de faire une recherche sans générer de réponse IA.
  /// Utile pour afficher des résultats de recherche à l'utilisateur.
  Future<List<SearchResult>> searchEncyclopedia(
    String query, {
    int topK = 5,
    double minScore = 0.7,
    EncyclopediaCategory? category,
  }) async {
    if (!_isInitialized || !_ragEnabled) {
      throw SemanticSearchException('Service de recherche non disponible');
    }

    if (category != null) {
      return _searchService.searchInCategory(
        query,
        category,
        topK: topK,
        minScore: minScore,
      );
    }

    return _searchService.search(
      query,
      topK: topK,
      minScore: minScore,
    );
  }

  /// Recherche de personnages/figures
  Future<List<SearchResult>> searchFigures(String query, {int topK = 5}) async {
    if (!_isInitialized || !_ragEnabled) {
      throw SemanticSearchException('Service de recherche non disponible');
    }
    return _searchService.searchFigures(query, topK: topK);
  }

  /// Recherche de concepts halakhiques
  Future<List<SearchResult>> searchHalakha(String query, {int topK = 5}) async {
    if (!_isInitialized || !_ragEnabled) {
      throw SemanticSearchException('Service de recherche non disponible');
    }
    return _searchService.searchHalakha(query, topK: topK);
  }

  /// Recherche de concepts kabbalistiques
  Future<List<SearchResult>> searchKabbala(String query, {int topK = 5}) async {
    if (!_isInitialized || !_ragEnabled) {
      throw SemanticSearchException('Service de recherche non disponible');
    }
    return _searchService.searchKabbala(query, topK: topK);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Construit l'historique enrichi avec le contexte Encyclopedia
  String _buildEnrichedHistorique(String? historique, String encyclopediaContext) {
    final buffer = StringBuffer();

    // Ajouter d'abord le contexte Encyclopedia
    buffer.writeln(encyclopediaContext);

    // Puis l'historique existant s'il y en a
    if (historique != null && historique.isNotEmpty) {
      buffer.writeln('\n=== HISTORIQUE UTILISATEUR ===\n');
      buffer.writeln(historique);
    }

    return buffer.toString();
  }

  /// Retourne les filtres appropriés pour une approche donnée
  Map<String, dynamic>? _getFiltersForApproach(String approach) {
    final approachLower = approach.toLowerCase();

    if (approachLower.contains('kabbale') || approachLower.contains('mystique')) {
      return EncyclopediaFilters.kabbala;
    }
    if (approachLower.contains('hassid') || approachLower.contains('chassid')) {
      return EncyclopediaFilters.chassidism;
    }
    if (approachLower.contains('moussar') || approachLower.contains('ethique')) {
      return EncyclopediaFilters.moussar;
    }
    if (approachLower.contains('talmud')) {
      return EncyclopediaFilters.talmudConcepts;
    }
    if (approachLower.contains('torah') || approachLower.contains('rabbinique')) {
      return EncyclopediaFilters.torahConcepts;
    }

    // Pas de filtre spécifique pour les autres approches
    return null;
  }

  /// Active ou désactive le RAG
  void setRagEnabled(bool enabled) {
    if (_searchService.isInitialized) {
      _ragEnabled = enabled;
      print('RAGService: RAG ${enabled ? "activé" : "désactivé"}');
    } else if (enabled) {
      print('RAGService: ⚠️ Impossible d\'activer le RAG - SearchService non initialisé');
    }
  }

  /// Met à jour les paramètres de recherche
  void updateSearchParams({int? topK, double? minScore}) {
    if (topK != null) _topK = topK;
    if (minScore != null) _minScore = minScore;
    print('RAGService: Paramètres mis à jour - topK: $_topK, minScore: $_minScore');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTION DES MODES DE CONSULTATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Définit le mode de consultation (Historien, Encyclopédie, Unifié)
  void setConsultationMode(ConsultationMode mode) {
    _consultationMode = mode;
    print('RAGService: Mode de consultation changé vers ${mode.label}');
  }

  /// Retourne le prompt système adapté au mode actuel
  String getSystemPromptForCurrentMode() {
    return ConsultationModeConfig.getSystemPrompt(_consultationMode);
  }

  /// Retourne les filtres de catégorie pour le mode actuel
  Map<String, dynamic>? getFiltersForCurrentMode() {
    return ConsultationModeConfig.getCategoryFilters(_consultationMode);
  }

  /// Génère une réponse enrichie avec le mode de consultation spécifié
  ///
  /// Cette méthode utilise le mode de consultation pour:
  /// 1. Filtrer les sources (historiques vs encyclopédiques)
  /// 2. Adapter le prompt système (ton narratif vs académique)
  /// 3. Formater les citations selon le mode
  Future<String> generateEnrichedResponseWithMode({
    required String reflectionText,
    required ReflectionType reflectionType,
    required EmotionalState emotionalState,
    required ConsultationMode mode,
    UserProfile? userProfile,
    String? declencheur,
    String? souhait,
    String? petitPas,
    int intensiteEmotionnelle = 5,
    String? historique30Jours,
  }) async {
    // Sauvegarder le mode actuel et appliquer le nouveau
    final previousMode = _consultationMode;
    _consultationMode = mode;

    try {
      if (!_isInitialized || !_ragEnabled) {
        return _aiService.generateUniversalResponse(
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
      }

      // 1. Rechercher avec les filtres du mode
      print('RAGService: Recherche en mode ${mode.label} pour: "${reflectionText.substring(0, reflectionText.length.clamp(0, 50))}..."');

      final filters = ConsultationModeConfig.getCategoryFilters(mode);
      final category = ConsultationModeConfig.getPrimaryCategory(mode);

      List<SearchResult> results;
      if (category != null) {
        // Recherche filtrée par catégorie
        results = await _searchService.search(
          reflectionText,
          topK: _topK,
          minScore: _minScore,
          filters: filters,
        );
      } else {
        // Recherche sans filtre (mode unifié)
        results = await _searchService.search(
          reflectionText,
          topK: _topK,
          minScore: _minScore,
        );
      }

      // 2. Construire le contexte enrichi avec attribution de source
      String enrichedHistorique = historique30Jours ?? '';
      if (results.isNotEmpty) {
        final contextBuffer = StringBuffer();
        contextBuffer.writeln('\n=== ${ConsultationModeConfig.getSourceAttribution(mode).toUpperCase()} ===\n');

        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          contextBuffer.writeln('--- Source ${i + 1}: ${result.title} ---');
          if (result.category != null) {
            contextBuffer.writeln('Catégorie: ${result.category}');
          }
          contextBuffer.writeln('Pertinence: ${(result.score * 100).toStringAsFixed(1)}%\n');
          contextBuffer.writeln(result.content);
          if (result.reference != null) {
            contextBuffer.writeln('\nRéférence: ${result.reference}');
          }
          contextBuffer.writeln('');
        }

        enrichedHistorique = _buildEnrichedHistorique(
          historique30Jours,
          contextBuffer.toString(),
        );
        print('RAGService: ✅ ${results.length} sources ${mode.label} trouvées');
      } else {
        print('RAGService: ⚠️ Aucune source ${mode.label} pertinente trouvée');
      }

      // 3. Ajouter le prompt système du mode au contexte
      final modePrompt = ConsultationModeConfig.getSystemPrompt(mode);
      final fullContext = '''
$modePrompt

$enrichedHistorique
''';

      // 4. Générer la réponse
      return _aiService.generateUniversalResponse(
        reflectionText: reflectionText,
        reflectionType: reflectionType,
        emotionalState: emotionalState,
        userProfile: userProfile,
        declencheur: declencheur,
        souhait: souhait,
        petitPas: petitPas,
        intensiteEmotionnelle: intensiteEmotionnelle,
        historique30Jours: fullContext,
      );

    } catch (e) {
      print('RAGService: ❌ Erreur mode $mode, fallback: $e');
      return _aiService.generateUniversalResponse(
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
    } finally {
      // Restaurer le mode précédent
      _consultationMode = previousMode;
    }
  }

  /// Recherche directe avec mode de consultation
  Future<List<SearchResult>> searchWithMode(
    String query,
    ConsultationMode mode, {
    int topK = 5,
    double minScore = 0.7,
  }) async {
    if (!_isInitialized || !_ragEnabled) {
      throw SemanticSearchException('Service de recherche non disponible');
    }

    final filters = ConsultationModeConfig.getCategoryFilters(mode);
    final category = ConsultationModeConfig.getPrimaryCategory(mode);

    if (category != null) {
      return _searchService.search(
        query,
        topK: topK,
        minScore: minScore,
        filters: filters,
      );
    }

    return _searchService.search(
      query,
      topK: topK,
      minScore: minScore,
    );
  }

  /// Recherche historique (raccourci pour mode Historien)
  Future<List<SearchResult>> searchHistorical(String query, {int topK = 5}) async {
    return searchWithMode(query, ConsultationMode.historian, topK: topK);
  }

  /// Recherche encyclopédique (raccourci pour mode Encyclopédie)
  Future<List<SearchResult>> searchEncyclopedic(String query, {int topK = 5}) async {
    return searchWithMode(query, ConsultationMode.encyclopedia, topK: topK);
  }

  /// Retourne les statistiques du service
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'ragEnabled': _ragEnabled,
      'topK': _topK,
      'minScore': _minScore,
      'searchServiceStats': _searchService.isInitialized
          ? _searchService.getStats()
          : null,
    };
  }

  /// Réinitialise le service
  void reset() {
    _searchService.reset();
    _ragEnabled = false;
    _isInitialized = false;
    print('RAGService: Service réinitialisé');
  }

  /// Vide le cache de recherche
  void clearCache() {
    _searchService.clearCache();
  }
}

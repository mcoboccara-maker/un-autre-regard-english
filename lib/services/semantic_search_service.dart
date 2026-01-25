import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════════
/// SERVICE DE RECHERCHE SÉMANTIQUE - ENCYCLOPEDIA JUDAICA
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Service permettant d'interroger les embeddings de l'Encyclopedia Judaica
/// pour une recherche sémantique intelligente.
///
/// Fonctionnalités:
/// - Génération d'embeddings pour les requêtes utilisateur
/// - Recherche par similarité dans la base vectorielle
/// - Support multiple backends (Pinecone, Qdrant, Weaviate, Supabase)
/// - Cache des résultats pour optimisation
/// - Filtrage par catégorie/thème
///
/// Architecture:
/// - EmbeddingProvider: Génère les vecteurs (OpenAI, Voyage, local)
/// - VectorStore: Stocke et recherche les embeddings
/// - SemanticSearchService: Orchestre les composants
///
/// Usage:
/// ```dart
/// final service = SemanticSearchService.instance;
/// await service.initialize(
///   embeddingProvider: EmbeddingProvider.openAI,
///   vectorStore: VectorStoreType.pinecone,
/// );
/// final results = await service.search('Qu\'est-ce que le Shabbat?');
/// ```
///
class SemanticSearchService {
  static SemanticSearchService? _instance;
  static SemanticSearchService get instance => _instance ??= SemanticSearchService._();
  SemanticSearchService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Provider d'embeddings actuel
  EmbeddingProvider _embeddingProvider = EmbeddingProvider.openAI;

  /// Type de vector store actuel
  VectorStoreType _vectorStoreType = VectorStoreType.pinecone;

  /// Configuration API
  String _openAiApiKey = '';
  String _voyageApiKey = '';
  String _pineconeApiKey = '';
  String _pineconeEnvironment = '';
  String _pineconeIndexName = 'encyclopedia-judaica';
  String _qdrantUrl = '';
  String _qdrantApiKey = '';
  String _supabaseUrl = '';
  String _supabaseApiKey = '';
  String _chromaUrl = 'http://127.0.0.1:8765'; // Serveur Chroma local

  /// Configuration des modèles d'embedding
  static const String _openAiEmbeddingModel = 'text-embedding-3-small';
  static const String _voyageEmbeddingModel = 'voyage-3';
  static const int _embeddingDimension = 1536; // OpenAI text-embedding-3-small

  /// Timeouts
  static const int _embeddingTimeoutSeconds = 30;
  static const int _searchTimeoutSeconds = 10;

  /// Cache des embeddings de requêtes récentes
  final Map<String, List<double>> _queryEmbeddingCache = {};
  static const int _maxCacheSize = 100;

  /// État d'initialisation
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialise le service avec la configuration souhaitée
  ///
  /// [embeddingProvider] : Provider pour générer les embeddings
  /// [vectorStore] : Type de base vectorielle à utiliser
  /// [config] : Configuration spécifique (clés API, URLs, etc.)
  Future<void> initialize({
    EmbeddingProvider embeddingProvider = EmbeddingProvider.openAI,
    VectorStoreType vectorStore = VectorStoreType.pinecone,
    required Map<String, String> config,
  }) async {
    _embeddingProvider = embeddingProvider;
    _vectorStoreType = vectorStore;

    // Charger la configuration
    _openAiApiKey = config['openAiApiKey'] ?? '';
    _voyageApiKey = config['voyageApiKey'] ?? '';
    _pineconeApiKey = config['pineconeApiKey'] ?? '';
    _pineconeEnvironment = config['pineconeEnvironment'] ?? '';
    _pineconeIndexName = config['pineconeIndexName'] ?? 'encyclopedia-judaica';
    _qdrantUrl = config['qdrantUrl'] ?? '';
    _qdrantApiKey = config['qdrantApiKey'] ?? '';
    _supabaseUrl = config['supabaseUrl'] ?? '';
    _supabaseApiKey = config['supabaseApiKey'] ?? '';
    _chromaUrl = config['chromaUrl'] ?? 'http://127.0.0.1:8765';

    // Valider la configuration
    _validateConfiguration();

    _isInitialized = true;
    print('SemanticSearchService: ✅ Initialisé avec $embeddingProvider + $vectorStore');
  }

  /// Valide que la configuration est complète
  void _validateConfiguration() {
    // Vérifier le provider d'embeddings
    switch (_embeddingProvider) {
      case EmbeddingProvider.openAI:
        if (_openAiApiKey.isEmpty) {
          throw SemanticSearchException('Clé API OpenAI manquante');
        }
        break;
      case EmbeddingProvider.voyage:
        if (_voyageApiKey.isEmpty) {
          throw SemanticSearchException('Clé API Voyage manquante');
        }
        break;
      case EmbeddingProvider.local:
        // Pas de validation nécessaire pour le mode local
        break;
    }

    // Vérifier le vector store
    switch (_vectorStoreType) {
      case VectorStoreType.pinecone:
        if (_pineconeApiKey.isEmpty || _pineconeEnvironment.isEmpty) {
          throw SemanticSearchException('Configuration Pinecone incomplète');
        }
        break;
      case VectorStoreType.qdrant:
        if (_qdrantUrl.isEmpty) {
          throw SemanticSearchException('URL Qdrant manquante');
        }
        break;
      case VectorStoreType.supabase:
        if (_supabaseUrl.isEmpty || _supabaseApiKey.isEmpty) {
          throw SemanticSearchException('Configuration Supabase incomplète');
        }
        break;
      case VectorStoreType.chroma:
        // Chroma local - URL par défaut, pas de validation stricte
        break;
      case VectorStoreType.inMemory:
        // Pas de validation nécessaire
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECHERCHE SÉMANTIQUE PRINCIPALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Effectue une recherche sémantique dans l'Encyclopedia Judaica
  ///
  /// [query] : La requête en langage naturel
  /// [topK] : Nombre de résultats à retourner (défaut: 5)
  /// [minScore] : Score de similarité minimum (0.0-1.0, défaut: 0.7)
  /// [filters] : Filtres optionnels (catégorie, langue, etc.)
  ///
  /// Retourne une liste de [SearchResult] triée par pertinence
  Future<List<SearchResult>> search(
    String query, {
    int topK = 5,
    double minScore = 0.7,
    Map<String, dynamic>? filters,
  }) async {
    if (!_isInitialized) {
      throw SemanticSearchException('Service non initialisé. Appelez initialize() d\'abord.');
    }

    if (query.trim().isEmpty) {
      return [];
    }

    print('SemanticSearchService: Recherche: "$query"');

    try {
      // 1. Générer l'embedding de la requête
      final queryEmbedding = await _getQueryEmbedding(query);

      // 2. Rechercher dans le vector store
      final results = await _searchVectorStore(
        queryEmbedding,
        topK: topK,
        minScore: minScore,
        filters: filters,
      );

      print('SemanticSearchService: ✅ ${results.length} résultats trouvés');
      return results;

    } catch (e) {
      print('SemanticSearchService: ❌ Erreur recherche: $e');
      rethrow;
    }
  }

  /// Recherche avec contexte enrichi pour le RAG
  ///
  /// Retourne les passages pertinents formatés pour être injectés
  /// dans un prompt de génération
  Future<String> searchForRAG(
    String query, {
    int topK = 3,
    double minScore = 0.75,
    Map<String, dynamic>? filters,
  }) async {
    final results = await search(
      query,
      topK: topK,
      minScore: minScore,
      filters: filters,
    );

    if (results.isEmpty) {
      return '';
    }

    // Formater les résultats pour le RAG
    final buffer = StringBuffer();
    buffer.writeln('=== SOURCES ENCYCLOPEDIA JUDAICA ===\n');

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('--- Source ${i + 1}: ${result.title} ---');
      if (result.category != null) {
        buffer.writeln('Catégorie: ${result.category}');
      }
      buffer.writeln('Pertinence: ${(result.score * 100).toStringAsFixed(1)}%');
      buffer.writeln('\n${result.content}\n');
      if (result.reference != null) {
        buffer.writeln('Référence: ${result.reference}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GÉNÉRATION D'EMBEDDINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Génère ou récupère du cache l'embedding d'une requête
  Future<List<double>> _getQueryEmbedding(String query) async {
    // Vérifier le cache
    final normalizedQuery = query.toLowerCase().trim();
    if (_queryEmbeddingCache.containsKey(normalizedQuery)) {
      print('SemanticSearchService: Embedding trouvé en cache');
      return _queryEmbeddingCache[normalizedQuery]!;
    }

    // Générer l'embedding
    final embedding = await _generateEmbedding(query);

    // Mettre en cache (avec limite de taille)
    if (_queryEmbeddingCache.length >= _maxCacheSize) {
      _queryEmbeddingCache.remove(_queryEmbeddingCache.keys.first);
    }
    _queryEmbeddingCache[normalizedQuery] = embedding;

    return embedding;
  }

  /// Génère un embedding selon le provider configuré
  Future<List<double>> _generateEmbedding(String text) async {
    switch (_embeddingProvider) {
      case EmbeddingProvider.openAI:
        return _generateOpenAIEmbedding(text);
      case EmbeddingProvider.voyage:
        return _generateVoyageEmbedding(text);
      case EmbeddingProvider.local:
        throw SemanticSearchException('Embeddings locaux non implémentés');
    }
  }

  /// Génère un embedding via l'API OpenAI
  Future<List<double>> _generateOpenAIEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': _openAiEmbeddingModel,
          'input': text,
        }),
      ).timeout(
        Duration(seconds: _embeddingTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Timeout embedding OpenAI'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = List<double>.from(data['data'][0]['embedding']);
        print('SemanticSearchService: Embedding généré (${embedding.length} dimensions)');
        return embedding;
      } else {
        throw SemanticSearchException(
          'Erreur API OpenAI: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      if (e is SemanticSearchException) rethrow;
      throw SemanticSearchException('Erreur génération embedding: $e');
    }
  }

  /// Génère un embedding via l'API Voyage AI
  Future<List<double>> _generateVoyageEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.voyageai.com/v1/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_voyageApiKey',
        },
        body: jsonEncode({
          'model': _voyageEmbeddingModel,
          'input': text,
        }),
      ).timeout(
        Duration(seconds: _embeddingTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Timeout embedding Voyage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = List<double>.from(data['data'][0]['embedding']);
        print('SemanticSearchService: Embedding Voyage généré (${embedding.length} dimensions)');
        return embedding;
      } else {
        throw SemanticSearchException(
          'Erreur API Voyage: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      if (e is SemanticSearchException) rethrow;
      throw SemanticSearchException('Erreur génération embedding Voyage: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECHERCHE DANS LES VECTOR STORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recherche dans le vector store configuré
  Future<List<SearchResult>> _searchVectorStore(
    List<double> queryEmbedding, {
    required int topK,
    required double minScore,
    Map<String, dynamic>? filters,
  }) async {
    switch (_vectorStoreType) {
      case VectorStoreType.pinecone:
        return _searchPinecone(queryEmbedding, topK: topK, minScore: minScore, filters: filters);
      case VectorStoreType.qdrant:
        return _searchQdrant(queryEmbedding, topK: topK, minScore: minScore, filters: filters);
      case VectorStoreType.supabase:
        return _searchSupabase(queryEmbedding, topK: topK, minScore: minScore, filters: filters);
      case VectorStoreType.chroma:
        return _searchChroma(topK: topK, minScore: minScore, filters: filters);
      case VectorStoreType.inMemory:
        throw SemanticSearchException('Vector store in-memory non implémenté');
    }
  }

  /// Recherche dans Pinecone
  Future<List<SearchResult>> _searchPinecone(
    List<double> queryEmbedding, {
    required int topK,
    required double minScore,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final url = 'https://$_pineconeIndexName-$_pineconeEnvironment.svc.pinecone.io/query';

      final body = <String, dynamic>{
        'vector': queryEmbedding,
        'topK': topK,
        'includeMetadata': true,
        'includeValues': false,
      };

      // Ajouter les filtres si présents
      if (filters != null && filters.isNotEmpty) {
        body['filter'] = filters;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: _searchTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Timeout recherche Pinecone'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = data['matches'] as List<dynamic>? ?? [];

        return matches
            .where((match) => (match['score'] as num) >= minScore)
            .map((match) => SearchResult.fromPinecone(match))
            .toList();
      } else {
        throw SemanticSearchException(
          'Erreur Pinecone: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      if (e is SemanticSearchException) rethrow;
      throw SemanticSearchException('Erreur recherche Pinecone: $e');
    }
  }

  /// Recherche dans Qdrant
  Future<List<SearchResult>> _searchQdrant(
    List<double> queryEmbedding, {
    required int topK,
    required double minScore,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final url = '$_qdrantUrl/collections/encyclopedia_judaica/points/search';

      final body = <String, dynamic>{
        'vector': queryEmbedding,
        'limit': topK,
        'with_payload': true,
        'score_threshold': minScore,
      };

      // Ajouter les filtres Qdrant si présents
      if (filters != null && filters.isNotEmpty) {
        body['filter'] = _convertToQdrantFilter(filters);
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (_qdrantApiKey.isNotEmpty) {
        headers['api-key'] = _qdrantApiKey;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: _searchTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Timeout recherche Qdrant'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['result'] as List<dynamic>? ?? [];

        return results
            .map((result) => SearchResult.fromQdrant(result))
            .toList();
      } else {
        throw SemanticSearchException(
          'Erreur Qdrant: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      if (e is SemanticSearchException) rethrow;
      throw SemanticSearchException('Erreur recherche Qdrant: $e');
    }
  }

  /// Recherche dans Supabase (pgvector)
  Future<List<SearchResult>> _searchSupabase(
    List<double> queryEmbedding, {
    required int topK,
    required double minScore,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Appel à la fonction RPC Supabase pour la recherche vectorielle
      final url = '$_supabaseUrl/rest/v1/rpc/search_encyclopedia';

      final body = <String, dynamic>{
        'query_embedding': queryEmbedding,
        'match_count': topK,
        'match_threshold': minScore,
      };

      // Ajouter les filtres si présents
      if (filters != null) {
        if (filters.containsKey('category')) {
          body['filter_category'] = filters['category'];
        }
        if (filters.containsKey('language')) {
          body['filter_language'] = filters['language'];
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseApiKey,
          'Authorization': 'Bearer $_supabaseApiKey',
        },
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: _searchTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Timeout recherche Supabase'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        return data
            .map((item) => SearchResult.fromSupabase(item))
            .toList();
      } else {
        throw SemanticSearchException(
          'Erreur Supabase: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      if (e is SemanticSearchException) rethrow;
      throw SemanticSearchException('Erreur recherche Supabase: $e');
    }
  }

  /// Recherche dans Chroma (serveur local)
  /// Note: Chroma gère les embeddings côté serveur via le script Python
  Future<List<SearchResult>> _searchChroma({
    required int topK,
    required double minScore,
    Map<String, dynamic>? filters,
  }) async {
    // Pour Chroma, on doit d'abord récupérer la requête originale
    // Le serveur Python génère l'embedding et fait la recherche
    throw SemanticSearchException(
      'Pour Chroma, utilisez searchChromaWithQuery() avec le texte de la requête'
    );
  }

  /// Recherche dans Chroma avec une requête texte
  /// Le serveur Python génère l'embedding et effectue la recherche
  Future<List<SearchResult>> searchChromaWithQuery(
    String query, {
    int topK = 5,
    String? category,
  }) async {
    if (_vectorStoreType != VectorStoreType.chroma) {
      throw SemanticSearchException('searchChromaWithQuery requiert VectorStoreType.chroma');
    }

    try {
      final body = <String, dynamic>{
        'query': query,
        'top_k': topK,
      };

      if (category != null) {
        body['category'] = category;
      }

      final response = await http.post(
        Uri.parse('$_chromaUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: _searchTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Timeout recherche Chroma'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        return results.map((item) => SearchResult.fromChroma(item)).toList();
      } else {
        throw SemanticSearchException(
          'Erreur Chroma: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      if (e is SemanticSearchException) rethrow;
      throw SemanticSearchException('Erreur recherche Chroma: $e');
    }
  }

  /// Vérifie si le serveur Chroma est disponible
  Future<bool> isChromaServerAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_chromaUrl/health'),
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupère les statistiques du serveur Chroma
  Future<Map<String, dynamic>> getChromaStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_chromaUrl/stats'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Convertit les filtres génériques en format Qdrant
  Map<String, dynamic> _convertToQdrantFilter(Map<String, dynamic> filters) {
    final must = <Map<String, dynamic>>[];

    filters.forEach((key, value) {
      if (value is String) {
        must.add({
          'key': key,
          'match': {'value': value},
        });
      } else if (value is List) {
        must.add({
          'key': key,
          'match': {'any': value},
        });
      }
    });

    return {'must': must};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vide le cache des embeddings
  void clearCache() {
    _queryEmbeddingCache.clear();
    print('SemanticSearchService: Cache vidé');
  }

  /// Récupère les statistiques du service
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'embeddingProvider': _embeddingProvider.name,
      'vectorStoreType': _vectorStoreType.name,
      'cacheSize': _queryEmbeddingCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }

  /// Réinitialise le service (pour les tests ou changement de config)
  void reset() {
    _isInitialized = false;
    _queryEmbeddingCache.clear();
    print('SemanticSearchService: Service réinitialisé');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECHERCHE PAR CATÉGORIE - HELPERS POUR L'ENCYCLOPEDIA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recherche dans une catégorie spécifique de l'Encyclopedia
  Future<List<SearchResult>> searchInCategory(
    String query,
    EncyclopediaCategory category, {
    int topK = 5,
    double minScore = 0.7,
  }) async {
    return search(
      query,
      topK: topK,
      minScore: minScore,
      filters: {'category': category.value},
    );
  }

  /// Recherche de personnages/figures bibliques ou rabbiniques
  Future<List<SearchResult>> searchFigures(
    String query, {
    int topK = 5,
    double minScore = 0.7,
  }) async {
    return search(
      query,
      topK: topK,
      minScore: minScore,
      filters: {'category': EncyclopediaCategory.figures.value},
    );
  }

  /// Recherche de concepts halakhiques
  Future<List<SearchResult>> searchHalakha(
    String query, {
    int topK = 5,
    double minScore = 0.7,
  }) async {
    return search(
      query,
      topK: topK,
      minScore: minScore,
      filters: {'category': EncyclopediaCategory.halakha.value},
    );
  }

  /// Recherche de concepts kabbalistiques
  Future<List<SearchResult>> searchKabbala(
    String query, {
    int topK = 5,
    double minScore = 0.7,
  }) async {
    return search(
      query,
      topK: topK,
      minScore: minScore,
      filters: {'category': EncyclopediaCategory.kabbala.value},
    );
  }

  /// Recherche historique
  Future<List<SearchResult>> searchHistory(
    String query, {
    int topK = 5,
    double minScore = 0.7,
  }) async {
    return search(
      query,
      topK: topK,
      minScore: minScore,
      filters: {'category': EncyclopediaCategory.history.value},
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS ET CLASSES DE SUPPORT
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider d'embeddings supportés
enum EmbeddingProvider {
  openAI,    // OpenAI text-embedding-3-small/large
  voyage,    // Voyage AI (optimisé pour le retrieval)
  local,     // Embeddings locaux (à implémenter)
}

/// Types de vector stores supportés
enum VectorStoreType {
  pinecone,   // Pinecone (cloud, scalable)
  qdrant,     // Qdrant (self-hosted ou cloud)
  supabase,   // Supabase avec pgvector
  chroma,     // Chroma local (via serveur HTTP)
  inMemory,   // In-memory (développement/tests)
}

/// Catégories de l'Encyclopedia Judaica
enum EncyclopediaCategory {
  figures('figures'),           // Personnages bibliques et rabbiniques
  halakha('halakha'),           // Loi juive
  kabbala('kabbala'),           // Mystique juive
  history('history'),           // Histoire juive
  philosophy('philosophy'),     // Philosophie juive
  liturgy('liturgy'),           // Liturgie et prières
  holidays('holidays'),         // Fêtes juives
  customs('customs'),           // Coutumes et traditions
  texts('texts'),               // Textes sacrés
  communities('communities'),   // Communautés juives
  ethics('ethics'),             // Éthique (Moussar)
  chassidism('chassidism'),     // Hassidisme
  ;

  final String value;
  const EncyclopediaCategory(this.value);
}

/// Résultat d'une recherche sémantique
class SearchResult {
  /// Identifiant unique du document
  final String id;

  /// Titre de l'entrée encyclopédique
  final String title;

  /// Contenu/passage pertinent
  final String content;

  /// Score de similarité (0.0 - 1.0)
  final double score;

  /// Catégorie de l'entrée
  final String? category;

  /// Référence bibliographique
  final String? reference;

  /// Métadonnées additionnelles
  final Map<String, dynamic>? metadata;

  SearchResult({
    required this.id,
    required this.title,
    required this.content,
    required this.score,
    this.category,
    this.reference,
    this.metadata,
  });

  /// Crée un SearchResult depuis une réponse Pinecone
  factory SearchResult.fromPinecone(Map<String, dynamic> match) {
    final metadata = match['metadata'] as Map<String, dynamic>? ?? {};
    return SearchResult(
      id: match['id'] as String,
      title: metadata['title'] as String? ?? 'Sans titre',
      content: metadata['content'] as String? ?? metadata['text'] as String? ?? '',
      score: (match['score'] as num).toDouble(),
      category: metadata['category'] as String?,
      reference: metadata['reference'] as String?,
      metadata: metadata,
    );
  }

  /// Crée un SearchResult depuis une réponse Qdrant
  factory SearchResult.fromQdrant(Map<String, dynamic> result) {
    final payload = result['payload'] as Map<String, dynamic>? ?? {};
    return SearchResult(
      id: result['id'].toString(),
      title: payload['title'] as String? ?? 'Sans titre',
      content: payload['content'] as String? ?? payload['text'] as String? ?? '',
      score: (result['score'] as num).toDouble(),
      category: payload['category'] as String?,
      reference: payload['reference'] as String?,
      metadata: payload,
    );
  }

  /// Crée un SearchResult depuis une réponse Supabase
  factory SearchResult.fromSupabase(Map<String, dynamic> item) {
    return SearchResult(
      id: item['id'].toString(),
      title: item['title'] as String? ?? 'Sans titre',
      content: item['content'] as String? ?? '',
      score: (item['similarity'] as num? ?? 0).toDouble(),
      category: item['category'] as String?,
      reference: item['reference'] as String?,
      metadata: item['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Crée un SearchResult depuis une réponse Chroma (serveur local)
  factory SearchResult.fromChroma(Map<String, dynamic> item) {
    final metadata = item['metadata'] as Map<String, dynamic>? ?? {};
    return SearchResult(
      id: item['id'] as String? ?? '',
      title: metadata['title'] as String? ?? 'Sans titre',
      content: item['content'] as String? ?? '',
      score: (item['score'] as num? ?? 0).toDouble(),
      category: metadata['category'] as String?,
      reference: '${metadata['source_file'] ?? ''} p.${metadata['page_start'] ?? '?'}-${metadata['page_end'] ?? '?'}',
      metadata: metadata,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'score': score,
    'category': category,
    'reference': reference,
    'metadata': metadata,
  };

  @override
  String toString() => 'SearchResult(title: $title, score: ${(score * 100).toStringAsFixed(1)}%)';
}

/// Exception personnalisée pour le service de recherche sémantique
class SemanticSearchException implements Exception {
  final String message;
  SemanticSearchException(this.message);

  @override
  String toString() => 'SemanticSearchException: $message';
}

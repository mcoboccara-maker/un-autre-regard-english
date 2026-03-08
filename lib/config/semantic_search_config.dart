import '../services/semantic_search_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// CONFIGURATION RECHERCHE SÉMANTIQUE - ENCYCLOPEDIA JUDAICA
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Configuration centralisée pour le service de recherche sémantique.
///
/// IMPORTANT: Les clés API doivent être stockées de manière sécurisée.
/// En production, utilisez des variables d'environnement ou un service
/// de gestion des secrets (Firebase Remote Config, AWS Secrets Manager, etc.)
///
class SemanticSearchConfig {
  SemanticSearchConfig._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION PAR DÉFAUT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Provider d'embeddings par défaut
  /// Note: Pour Chroma local, le serveur Python gère les embeddings
  static const EmbeddingProvider defaultEmbeddingProvider = EmbeddingProvider.openAI;

  /// Vector store par défaut - Chroma local recommandé
  static const VectorStoreType defaultVectorStore = VectorStoreType.chroma;

  /// Nom de l'index Encyclopedia Judaica
  static const String encyclopediaIndexName = 'encyclopedia-judaica';

  /// Namespace pour les embeddings (si supporté)
  static const String encyclopediaNamespace = 'judaica';

  // ═══════════════════════════════════════════════════════════════════════════
  // PARAMÈTRES DE RECHERCHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nombre de résultats par défaut
  static const int defaultTopK = 5;

  /// Score minimum de similarité par défaut
  static const double defaultMinScore = 0.7;

  /// Score minimum pour le RAG (plus strict)
  static const double ragMinScore = 0.75;

  /// Nombre de résultats pour le RAG
  static const int ragTopK = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // CLÉS API (À CONFIGURER)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // SÉCURITÉ: En production, ces valeurs doivent venir de:
  // - Variables d'environnement (--dart-define)
  // - Firebase Remote Config
  // - Service de secrets sécurisé
  //
  // NE JAMAIS COMMITTER LES VRAIES CLÉS API DANS LE CODE SOURCE
  //

  /// Clé API OpenAI pour les embeddings
  /// Configurer via: --dart-define=OPENAI_API_KEY=sk-...
  static String get openAiApiKey =>
      const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  /// Clé API Voyage AI (alternative)
  static String get voyageApiKey =>
      const String.fromEnvironment('VOYAGE_API_KEY', defaultValue: '');

  /// Clé API Pinecone
  static String get pineconeApiKey =>
      const String.fromEnvironment('PINECONE_API_KEY', defaultValue: '');

  /// Environnement Pinecone (ex: us-east1-gcp)
  static String get pineconeEnvironment =>
      const String.fromEnvironment('PINECONE_ENVIRONMENT', defaultValue: '');

  /// URL Qdrant (si utilisé)
  static String get qdrantUrl =>
      const String.fromEnvironment('QDRANT_URL', defaultValue: '');

  /// Clé API Qdrant (optionnelle)
  static String get qdrantApiKey =>
      const String.fromEnvironment('QDRANT_API_KEY', defaultValue: '');

  /// URL Supabase (si utilisé)
  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Clé API Supabase
  static String get supabaseApiKey =>
      const String.fromEnvironment('SUPABASE_API_KEY', defaultValue: '');

  /// URL du serveur Encyclopedia API
  /// - Dev local: http://127.0.0.1:8765
  /// - Production: Configurer via --dart-define=ENCYCLOPEDIA_API_URL=https://votre-serveur.railway.app
  static String get chromaUrl =>
      const String.fromEnvironment('ENCYCLOPEDIA_API_URL', defaultValue: 'http://127.0.0.1:8765');

  /// Alias plus explicite
  static String get encyclopediaApiUrl => chromaUrl;

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER D'INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Génère la map de configuration depuis les variables d'environnement
  static Map<String, String> getConfigFromEnvironment() {
    return {
      'openAiApiKey': openAiApiKey,
      'voyageApiKey': voyageApiKey,
      'pineconeApiKey': pineconeApiKey,
      'pineconeEnvironment': pineconeEnvironment,
      'pineconeIndexName': encyclopediaIndexName,
      'qdrantUrl': qdrantUrl,
      'qdrantApiKey': qdrantApiKey,
      'supabaseUrl': supabaseUrl,
      'supabaseApiKey': supabaseApiKey,
      'chromaUrl': chromaUrl,
    };
  }

  /// Génère une configuration personnalisée
  static Map<String, String> getCustomConfig({
    String? openAiKey,
    String? voyageKey,
    String? pineconeKey,
    String? pineconeEnv,
    String? pineconeIndex,
    String? qdrantUrlOverride,
    String? qdrantKey,
    String? supabaseUrlOverride,
    String? supabaseKey,
  }) {
    return {
      'openAiApiKey': openAiKey ?? openAiApiKey,
      'voyageApiKey': voyageKey ?? voyageApiKey,
      'pineconeApiKey': pineconeKey ?? pineconeApiKey,
      'pineconeEnvironment': pineconeEnv ?? pineconeEnvironment,
      'pineconeIndexName': pineconeIndex ?? encyclopediaIndexName,
      'qdrantUrl': qdrantUrlOverride ?? qdrantUrl,
      'qdrantApiKey': qdrantKey ?? qdrantApiKey,
      'supabaseUrl': supabaseUrlOverride ?? supabaseUrl,
      'supabaseApiKey': supabaseKey ?? supabaseApiKey,
    };
  }

  /// Vérifie si la configuration minimale est présente
  static bool isConfigured({
    EmbeddingProvider embeddingProvider = defaultEmbeddingProvider,
    VectorStoreType vectorStore = defaultVectorStore,
  }) {
    // Vérifier le provider d'embeddings
    bool hasEmbeddingKey = false;
    switch (embeddingProvider) {
      case EmbeddingProvider.openAI:
        hasEmbeddingKey = openAiApiKey.isNotEmpty;
        break;
      case EmbeddingProvider.voyage:
        hasEmbeddingKey = voyageApiKey.isNotEmpty;
        break;
      case EmbeddingProvider.local:
        hasEmbeddingKey = true;
        break;
    }

    // Vérifier le vector store
    bool hasVectorStoreConfig = false;
    switch (vectorStore) {
      case VectorStoreType.pinecone:
        hasVectorStoreConfig = pineconeApiKey.isNotEmpty && pineconeEnvironment.isNotEmpty;
        break;
      case VectorStoreType.qdrant:
        hasVectorStoreConfig = qdrantUrl.isNotEmpty;
        break;
      case VectorStoreType.supabase:
        hasVectorStoreConfig = supabaseUrl.isNotEmpty && supabaseApiKey.isNotEmpty;
        break;
      case VectorStoreType.chroma:
        // Chroma local - toujours configuré (URL par défaut)
        hasVectorStoreConfig = true;
        // Pour Chroma, pas besoin de clé embedding côté Flutter
        // Le serveur Python gère les embeddings
        return true;
      case VectorStoreType.inMemory:
        hasVectorStoreConfig = true;
        break;
    }

    return hasEmbeddingKey && hasVectorStoreConfig;
  }

  /// Retourne un message d'erreur décrivant ce qui manque
  static String getMissingConfigMessage({
    EmbeddingProvider embeddingProvider = defaultEmbeddingProvider,
    VectorStoreType vectorStore = defaultVectorStore,
  }) {
    final missing = <String>[];

    switch (embeddingProvider) {
      case EmbeddingProvider.openAI:
        if (openAiApiKey.isEmpty) missing.add('OPENAI_API_KEY');
        break;
      case EmbeddingProvider.voyage:
        if (voyageApiKey.isEmpty) missing.add('VOYAGE_API_KEY');
        break;
      case EmbeddingProvider.local:
        break;
    }

    switch (vectorStore) {
      case VectorStoreType.pinecone:
        if (pineconeApiKey.isEmpty) missing.add('PINECONE_API_KEY');
        if (pineconeEnvironment.isEmpty) missing.add('PINECONE_ENVIRONMENT');
        break;
      case VectorStoreType.qdrant:
        if (qdrantUrl.isEmpty) missing.add('QDRANT_URL');
        break;
      case VectorStoreType.supabase:
        if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
        if (supabaseApiKey.isEmpty) missing.add('SUPABASE_API_KEY');
        break;
      case VectorStoreType.inMemory:
        break;
    }

    if (missing.isEmpty) return '';
    return 'Missing configuration: ${missing.join(', ')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CATÉGORIES PRÉDÉFINIES POUR L'ENCYCLOPEDIA JUDAICA
// ═══════════════════════════════════════════════════════════════════════════════

/// Filtres prédéfinis pour les recherches courantes
class EncyclopediaFilters {
  EncyclopediaFilters._();

  /// Filtre pour les textes historiques antiques (Josèphe, Maccabées, etc.)
  static Map<String, dynamic> get historicalTexts => {
    'category': 'history',
  };

  /// Filtre pour l'encyclopédie moderne
  static Map<String, dynamic> get encyclopediaArticles => {
    'category': 'encyclopedia',
  };

  /// Filtre pour les personnages bibliques
  static Map<String, dynamic> get biblicalFigures => {
    'category': 'figures',
    'subcategory': 'biblical',
  };

  /// Filtre pour les rabbins et sages
  static Map<String, dynamic> get rabbinicalFigures => {
    'category': 'figures',
    'subcategory': 'rabbinical',
  };

  /// Filtre pour les concepts de la Torah
  static Map<String, dynamic> get torahConcepts => {
    'category': 'texts',
    'source': 'torah',
  };

  /// Filtre pour le Talmud
  static Map<String, dynamic> get talmudConcepts => {
    'category': 'texts',
    'source': 'talmud',
  };

  /// Filtre pour le Zohar et la Kabbale
  static Map<String, dynamic> get kabbala => {
    'category': 'kabbala',
  };

  /// Filtre pour le Hassidisme
  static Map<String, dynamic> get chassidism => {
    'category': 'chassidism',
  };

  /// Filtre pour le Moussar (éthique)
  static Map<String, dynamic> get moussar => {
    'category': 'ethics',
  };

  /// Filtre pour les fêtes juives
  static Map<String, dynamic> get holidays => {
    'category': 'holidays',
  };

  /// Filtre pour les lois du Shabbat
  static Map<String, dynamic> get shabbat => {
    'category': 'halakha',
    'topic': 'shabbat',
  };

  /// Filtre pour les prières
  static Map<String, dynamic> get prayers => {
    'category': 'liturgy',
  };
}

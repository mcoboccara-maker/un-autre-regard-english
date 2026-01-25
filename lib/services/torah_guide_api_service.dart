import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════════
/// TORAH GUIDE API SERVICE
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Service HTTP pour communiquer avec l'API Torah Guide (FastAPI).
/// Recherche sémantique dans l'Encyclopaedia Judaica et sources historiques.
///
/// Configuration:
/// - Développement local: http://localhost:8000
/// - Production: Configurer via [TorahGuideApiConfig]
///
/// Usage:
/// ```dart
/// // Initialisation
/// TorahGuideApiService.instance.configure(baseUrl: 'http://localhost:8000');
///
/// // Recherche
/// final results = await TorahGuideApiService.instance.search('Passover');
///
/// // Récupérer une entrée
/// final entry = await TorahGuideApiService.instance.getEntry('passover_123');
/// ```
///
class TorahGuideApiService {
  static TorahGuideApiService? _instance;
  static TorahGuideApiService get instance => _instance ??= TorahGuideApiService._();
  TorahGuideApiService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  String _baseUrl = 'http://localhost:8000';
  Duration _timeout = const Duration(seconds: 30);
  bool _isConfigured = false;

  /// Configure le service avec l'URL de l'API
  void configure({
    required String baseUrl,
    Duration? timeout,
  }) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    _timeout = timeout ?? const Duration(seconds: 30);
    _isConfigured = true;
    print('TorahGuideApiService: Configuré pour $_baseUrl');
  }

  /// URL de base de l'API
  String get baseUrl => _baseUrl;

  /// Vérifie si le service est configuré
  bool get isConfigured => _isConfigured;

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si l'API est disponible
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('TorahGuideApiService: API non disponible - $e');
      return false;
    }
  }

  /// Récupère le statut de l'API
  Future<HealthStatus> getHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthStatus(
          status: data['status'] ?? 'unknown',
          database: data['database'] ?? 'unknown',
          documents: data['documents'] ?? 0,
        );
      }
      throw ApiException('Health check failed: ${response.statusCode}');
    } catch (e) {
      throw ApiException('Health check error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECHERCHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recherche sémantique dans la base
  ///
  /// [query] : Requête en langage naturel
  /// [n] : Nombre de résultats (1-20, défaut: 5)
  /// [volume] : Filtrer par volume (0=histoire, 1-21=Encyclopaedia, null=tous)
  ///
  /// Retourne une [SearchResponse] avec les résultats
  Future<SearchResponse> search(
    String query, {
    int n = 5,
    int? volume,
  }) async {
    try {
      final params = {
        'q': query,
        'n': n.toString(),
      };
      if (volume != null) {
        params['volume'] = volume.toString();
      }

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return SearchResponse.fromJson(data);
      }
      throw ApiException('Search failed: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Search error: $e');
    }
  }

  /// Recherche uniquement dans l'Encyclopaedia Judaica (volumes 1-21)
  Future<SearchResponse> searchEncyclopedia(String query, {int n = 5}) async {
    // Les volumes 1-21 sont l'Encyclopaedia
    // On fait une recherche générale et on filtre
    final response = await search(query, n: n * 2);
    final encyclopediaResults = response.results
        .where((r) => r.volume > 0 && r.volume <= 21)
        .take(n)
        .toList();

    return SearchResponse(
      query: response.query,
      results: encyclopediaResults,
      count: encyclopediaResults.length,
      timeMs: response.timeMs,
    );
  }

  /// Recherche uniquement dans les sources historiques (volume 0)
  Future<SearchResponse> searchHistory(String query, {int n = 5}) async {
    return search(query, n: n, volume: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRÉES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupère une entrée par son ID
  Future<EntryResult> getEntry(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/entry/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return EntryResult.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ApiException('Entry not found: $id');
      }
      throw ApiException('Get entry failed: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Get entry error: $e');
    }
  }

  /// Récupère des entrées aléatoires (pour suggestions)
  Future<List<EntrySummary>> getRandomEntries({int n = 5}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/random?n=$n'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final entries = data['entries'] as List;
        return entries.map((e) => EntrySummary.fromJson(e)).toList();
      }
      throw ApiException('Get random failed: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Get random error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTIQUES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupère les statistiques de la base
  Future<StatsResponse> getStats() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/stats'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StatsResponse.fromJson(data);
      }
      throw ApiException('Get stats failed: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Get stats error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES
// ═══════════════════════════════════════════════════════════════════════════════

/// Statut de santé de l'API
class HealthStatus {
  final String status;
  final String database;
  final int documents;

  HealthStatus({
    required this.status,
    required this.database,
    required this.documents,
  });

  bool get isHealthy => status == 'healthy';
}

/// Réponse de recherche
class SearchResponse {
  final String query;
  final List<SearchResult> results;
  final int count;
  final double timeMs;

  SearchResponse({
    required this.query,
    required this.results,
    required this.count,
    required this.timeMs,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] ?? '',
      results: (json['results'] as List?)
              ?.map((r) => SearchResult.fromJson(r))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      timeMs: (json['time_ms'] ?? 0).toDouble(),
    );
  }

  /// Temps de recherche formaté
  String get timeFormatted => '${timeMs.toStringAsFixed(0)}ms';
}

/// Résultat de recherche individuel
class SearchResult {
  final String id;
  final String title;
  final int volume;
  final String content;
  final int chunkIndex;
  final int totalChunks;
  final double distance;

  SearchResult({
    required this.id,
    required this.title,
    required this.volume,
    required this.content,
    required this.chunkIndex,
    required this.totalChunks,
    required this.distance,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      volume: json['volume'] ?? 0,
      content: json['content'] ?? '',
      chunkIndex: json['chunk_index'] ?? 0,
      totalChunks: json['total_chunks'] ?? 1,
      distance: (json['distance'] ?? 0).toDouble(),
    );
  }

  /// Score de similarité (inverse de la distance)
  double get similarity => 1 / (1 + distance);

  /// Score en pourcentage
  String get similarityPercent => '${(similarity * 100).toStringAsFixed(0)}%';

  /// Source de l'entrée
  String get source {
    if (volume == 0) return 'Histoire';
    return 'EJ Vol. $volume';
  }

  /// Extrait court du contenu
  String get excerpt {
    if (content.length <= 200) return content;
    return '${content.substring(0, 197)}...';
  }

  /// Est-ce une source historique?
  bool get isHistorical => volume == 0;

  /// Est-ce de l'Encyclopaedia Judaica?
  bool get isEncyclopedia => volume > 0;
}

/// Entrée complète
class EntryResult {
  final String id;
  final String title;
  final int volume;
  final String content;
  final int chunkIndex;
  final int totalChunks;

  EntryResult({
    required this.id,
    required this.title,
    required this.volume,
    required this.content,
    required this.chunkIndex,
    required this.totalChunks,
  });

  factory EntryResult.fromJson(Map<String, dynamic> json) {
    return EntryResult(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      volume: json['volume'] ?? 0,
      content: json['content'] ?? '',
      chunkIndex: json['chunk_index'] ?? 0,
      totalChunks: json['total_chunks'] ?? 1,
    );
  }

  /// Source formatée
  String get source {
    if (volume == 0) return 'Sources historiques';
    return 'Encyclopaedia Judaica, Vol. $volume';
  }

  /// Indication de position dans l'article
  String get position {
    if (totalChunks == 1) return '';
    return 'Part ${chunkIndex + 1}/$totalChunks';
  }
}

/// Résumé d'une entrée (pour suggestions)
class EntrySummary {
  final String id;
  final String title;
  final int volume;

  EntrySummary({
    required this.id,
    required this.title,
    required this.volume,
  });

  factory EntrySummary.fromJson(Map<String, dynamic> json) {
    return EntrySummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      volume: json['volume'] ?? 0,
    );
  }
}

/// Statistiques de la base
class StatsResponse {
  final int totalDocuments;
  final Map<String, int> sources;
  final String status;

  StatsResponse({
    required this.totalDocuments,
    required this.sources,
    required this.status,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    final sourcesJson = json['sources'] as Map<String, dynamic>? ?? {};
    final sources = sourcesJson.map((k, v) => MapEntry(k, v as int));

    return StatsResponse(
      totalDocuments: json['total_documents'] ?? 0,
      sources: sources,
      status: json['status'] ?? 'unknown',
    );
  }

  /// Nombre formaté de documents
  String get documentsFormatted => '${totalDocuments.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} documents';
}

/// Exception de l'API
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════════

/// Configuration de l'API Torah Guide
class TorahGuideApiConfig {
  /// URL de production (Railway)
  static const String productionUrl = 'https://torah-guide-api-production.up.railway.app';

  /// URL pour le développement local
  static const String localUrl = 'http://localhost:8000';

  /// URL pour le développement Android Emulator (10.0.2.2 = localhost de l'hôte)
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';

  /// URL pour iOS Simulator (localhost fonctionne)
  static const String iosSimulatorUrl = 'http://localhost:8000';

  /// Mode production activé
  static const bool isProduction = true;

  /// Retourne l'URL appropriée selon la plateforme et le mode
  static String getPlatformUrl() {
    if (isProduction) {
      return productionUrl;
    }
    // Pour le développement local, adapter selon la plateforme
    return localUrl;
  }
}

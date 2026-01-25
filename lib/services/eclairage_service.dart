import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'sefaria_api_service.dart';
import 'torah_guide_api_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// ÉCLAIRAGE SERVICE
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Service d'orchestration pour le module "Éclairage".
/// Combine:
/// - LLM (Claude/OpenAI) pour l'éclairage existentiel
/// - Torah Guide API pour le contexte historique (Encyclopaedia Judaica)
/// - Sefaria API pour les sources textuelles
///
/// Flux:
/// 1. Question utilisateur → LLM génère un éclairage personnalisé
/// 2. En parallèle: recherche dans Encyclopaedia + Sefaria
/// 3. Synthèse des trois sources
///
class EclairageService {
  static EclairageService? _instance;
  static EclairageService get instance => _instance ??= EclairageService._();
  EclairageService._();

  // Configuration
  String? _openAiApiKey;
  String _llmModel = 'gpt-4o-mini'; // ou 'claude-3-haiku' pour Anthropic

  /// Configure le service avec la clé API
  void configure({required String openAiApiKey, String? model}) {
    _openAiApiKey = openAiApiKey;
    if (model != null) _llmModel = model;
  }

  /// Génère un éclairage complet pour une question
  ///
  /// [question] : La question ou pensée de l'utilisateur
  /// [selectedSources] : Sources spirituelles sélectionnées par l'utilisateur
  /// [language] : Langue de réponse ('fr', 'en', 'he')
  ///
  /// Retourne un [EclairageResponse] avec:
  /// - Éclairage existentiel (LLM)
  /// - Contexte historique (Encyclopaedia Judaica)
  /// - Sources textuelles (Sefaria)
  ///
  Stream<EclairageResponse> generateEclairage({
    required String question,
    List<String>? selectedSources,
    String language = 'fr',
  }) async* {
    // Réponse initiale vide
    var response = EclairageResponse(
      question: question,
      status: EclairageStatus.loading,
    );
    yield response;

    try {
      // Lancer les 3 recherches en parallèle
      final futures = await Future.wait([
        _generateLlmInsight(question, selectedSources, language),
        _searchEncyclopedia(question),
        _searchSefaria(question),
      ]);

      final llmInsight = futures[0] as LlmInsight;
      final encyclopediaResults = futures[1] as List<EncyclopediaContext>;
      final sefariaResults = futures[2] as List<SefariaSource>;

      // Construire la réponse complète
      response = EclairageResponse(
        question: question,
        status: EclairageStatus.complete,
        insight: llmInsight,
        historicalContext: encyclopediaResults,
        textualSources: sefariaResults,
      );

      yield response;
    } catch (e) {
      yield EclairageResponse(
        question: question,
        status: EclairageStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Génère un éclairage en streaming (pour affichage progressif)
  Stream<EclairageResponse> generateEclairageStreaming({
    required String question,
    List<String>? selectedSources,
    String language = 'fr',
  }) async* {
    var response = EclairageResponse(
      question: question,
      status: EclairageStatus.loading,
    );
    yield response;

    try {
      // Étape 1: Lancer les recherches contextuelles en arrière-plan
      final encyclopediaFuture = _searchEncyclopedia(question);
      final sefariaFuture = _searchSefaria(question);

      // Étape 2: Streamer l'éclairage LLM
      response = response.copyWith(status: EclairageStatus.generatingInsight);
      yield response;

      final llmInsight = await _generateLlmInsight(question, selectedSources, language);
      response = response.copyWith(insight: llmInsight);
      yield response;

      // Étape 3: Ajouter le contexte encyclopédique
      response = response.copyWith(status: EclairageStatus.loadingContext);
      yield response;

      final encyclopediaResults = await encyclopediaFuture;
      response = response.copyWith(historicalContext: encyclopediaResults);
      yield response;

      // Étape 4: Ajouter les sources Sefaria
      response = response.copyWith(status: EclairageStatus.loadingSources);
      yield response;

      final sefariaResults = await sefariaFuture;
      response = response.copyWith(
        textualSources: sefariaResults,
        status: EclairageStatus.complete,
      );
      yield response;

    } catch (e) {
      yield response.copyWith(
        status: EclairageStatus.error,
        error: e.toString(),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Génère l'éclairage existentiel via LLM
  Future<LlmInsight> _generateLlmInsight(
    String question,
    List<String>? selectedSources,
    String language,
  ) async {
    if (_openAiApiKey == null) {
      throw EclairageException('API key not configured. Call configure() first.');
    }

    final systemPrompt = _buildSystemPrompt(selectedSources, language);
    final userPrompt = _buildUserPrompt(question, language);

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': _llmModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        return _parseInsightResponse(content);
      } else {
        throw EclairageException('LLM API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is EclairageException) rethrow;
      throw EclairageException('LLM error: $e');
    }
  }

  /// Recherche dans l'Encyclopaedia Judaica
  Future<List<EncyclopediaContext>> _searchEncyclopedia(String question) async {
    try {
      // Configurer le service si nécessaire
      if (!TorahGuideApiService.instance.isConfigured) {
        TorahGuideApiService.instance.configure(
          baseUrl: TorahGuideApiConfig.getPlatformUrl(),
        );
      }

      final results = await TorahGuideApiService.instance.search(question, n: 3);

      return results.results.map((r) => EncyclopediaContext(
        id: r.id,
        title: r.title,
        content: r.content,
        source: r.source,
        volume: r.volume,
        relevanceScore: r.similarity,
      )).toList();
    } catch (e) {
      print('Encyclopedia search error: $e');
      return []; // Retourner liste vide en cas d'erreur
    }
  }

  /// Recherche dans Sefaria
  Future<List<SefariaSource>> _searchSefaria(String question) async {
    try {
      final results = await SefariaApiService.instance.search(question, size: 5);

      final sources = <SefariaSource>[];

      for (final hit in results.hits.take(3)) {
        try {
          // Récupérer le texte complet pour chaque résultat
          final text = await SefariaApiService.instance.getText(hit.ref);

          sources.add(SefariaSource(
            ref: hit.ref,
            heRef: hit.heRef,
            hebrewText: text.hebrewText,
            englishText: text.englishText,
            category: hit.category,
          ));
        } catch (e) {
          // Ajouter quand même avec le texte de recherche
          sources.add(SefariaSource(
            ref: hit.ref,
            heRef: hit.heRef,
            hebrewText: '',
            englishText: hit.text,
            category: hit.category,
          ));
        }
      }

      return sources;
    } catch (e) {
      print('Sefaria search error: $e');
      return [];
    }
  }

  /// Construit le prompt système pour le LLM
  String _buildSystemPrompt(List<String>? sources, String language) {
    final langInstruction = language == 'fr'
        ? 'Réponds en français.'
        : language == 'he'
            ? 'Réponds en hébreu.'
            : 'Respond in English.';

    final sourcesContext = sources != null && sources.isNotEmpty
        ? '''
Les sources spirituelles préférées de l'utilisateur sont: ${sources.join(', ')}.
Privilégie les enseignements et perspectives de ces courants dans ta réponse.
'''
        : '';

    return '''
Tu es un guide spirituel juif bienveillant et érudit. Tu offres des éclairages existentiels
inspirés de la tradition juive, en les rendant accessibles et pertinents pour la vie quotidienne.

$langInstruction

$sourcesContext

PRINCIPES:
1. Entre par la vie vécue, pas par la doctrine
2. Respecte la pluralité des voix du judaïsme
3. Contextualise historiquement quand c'est pertinent
4. Cite des sources quand possible (Talmud, rabbins, etc.)
5. Reste humble et non-prescriptif

FORMAT DE RÉPONSE:
Utilise ce format JSON:
{
  "eclairage": "L'éclairage existentiel principal (2-3 paragraphes)",
  "reflexion": "Une question de réflexion personnelle",
  "citation": {
    "texte": "Une citation pertinente de la tradition",
    "source": "L'origine de la citation"
  },
  "mots_cles": ["mot1", "mot2", "mot3"]
}
''';
  }

  /// Construit le prompt utilisateur
  String _buildUserPrompt(String question, String language) {
    final intro = language == 'fr'
        ? 'Voici ma question ou ma réflexion:'
        : language == 'he'
            ? 'הנה השאלה שלי:'
            : 'Here is my question or thought:';

    return '''
$intro

"$question"

Offre-moi un éclairage juif sur cette question, en lien avec ma vie concrète.
''';
  }

  /// Parse la réponse du LLM
  LlmInsight _parseInsightResponse(String content) {
    try {
      // Extraire le JSON de la réponse
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr);

        return LlmInsight(
          eclairage: data['eclairage'] ?? content,
          reflexion: data['reflexion'],
          citation: data['citation'] != null
              ? Citation(
                  texte: data['citation']['texte'] ?? '',
                  source: data['citation']['source'] ?? '',
                )
              : null,
          motsCles: (data['mots_cles'] as List?)?.cast<String>() ?? [],
        );
      }
    } catch (e) {
      print('Error parsing LLM response: $e');
    }

    // Fallback: utiliser le contenu brut
    return LlmInsight(
      eclairage: content,
      motsCles: [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES
// ═══════════════════════════════════════════════════════════════════════════════

/// Statut de génération de l'éclairage
enum EclairageStatus {
  loading,
  generatingInsight,
  loadingContext,
  loadingSources,
  complete,
  error,
}

/// Réponse complète du module Éclairage
class EclairageResponse {
  final String question;
  final EclairageStatus status;
  final LlmInsight? insight;
  final List<EncyclopediaContext> historicalContext;
  final List<SefariaSource> textualSources;
  final String? error;

  EclairageResponse({
    required this.question,
    required this.status,
    this.insight,
    this.historicalContext = const [],
    this.textualSources = const [],
    this.error,
  });

  EclairageResponse copyWith({
    String? question,
    EclairageStatus? status,
    LlmInsight? insight,
    List<EncyclopediaContext>? historicalContext,
    List<SefariaSource>? textualSources,
    String? error,
  }) {
    return EclairageResponse(
      question: question ?? this.question,
      status: status ?? this.status,
      insight: insight ?? this.insight,
      historicalContext: historicalContext ?? this.historicalContext,
      textualSources: textualSources ?? this.textualSources,
      error: error ?? this.error,
    );
  }

  bool get isComplete => status == EclairageStatus.complete;
  bool get hasError => status == EclairageStatus.error;
  bool get isLoading => status != EclairageStatus.complete && status != EclairageStatus.error;
}

/// Éclairage généré par le LLM
class LlmInsight {
  final String eclairage;
  final String? reflexion;
  final Citation? citation;
  final List<String> motsCles;

  LlmInsight({
    required this.eclairage,
    this.reflexion,
    this.citation,
    this.motsCles = const [],
  });
}

/// Citation de la tradition
class Citation {
  final String texte;
  final String source;

  Citation({required this.texte, required this.source});
}

/// Contexte de l'Encyclopaedia Judaica
class EncyclopediaContext {
  final String id;
  final String title;
  final String content;
  final String source;
  final int volume;
  final double relevanceScore;

  EncyclopediaContext({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.volume,
    required this.relevanceScore,
  });

  /// Extrait court du contenu
  String get excerpt {
    if (content.length <= 200) return content;
    return '${content.substring(0, 197)}...';
  }
}

/// Source textuelle de Sefaria
class SefariaSource {
  final String ref;
  final String heRef;
  final String hebrewText;
  final String englishText;
  final String category;

  SefariaSource({
    required this.ref,
    required this.heRef,
    required this.hebrewText,
    required this.englishText,
    required this.category,
  });

  /// URL vers Sefaria
  String get sefariaUrl => 'https://www.sefaria.org/$ref';
}

/// Exception du service Éclairage
class EclairageException implements Exception {
  final String message;
  EclairageException(this.message);

  @override
  String toString() => 'EclairageException: $message';
}

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════════
/// SEFARIA API SERVICE
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Service HTTP pour l'API Sefaria - Bibliothèque de textes juifs.
/// Documentation: https://developers.sefaria.org/
///
/// Fonctionnalités:
/// - Textes (Torah, Talmud, Midrash...)
/// - Calendrier (Paracha, Daf Yomi...)
/// - Commentaires (Rashi, Ramban, Sforno...)
/// - Recherche dans les textes
///
/// Usage:
/// ```dart
/// // Paracha de la semaine
/// final calendar = await SefariaApiService.instance.getCalendar();
/// print(calendar.parasha?.displayName); // "Beshalach"
///
/// // Texte d'un verset
/// final text = await SefariaApiService.instance.getText('Genesis.1.1');
///
/// // Commentaire de Rashi
/// final rashi = await SefariaApiService.instance.getRashiCommentary('Genesis.1.1');
/// ```
///
class SefariaApiService {
  static SefariaApiService? _instance;
  static SefariaApiService get instance => _instance ??= SefariaApiService._();
  SefariaApiService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _baseUrl = 'https://www.sefaria.org/api';
  final Duration _timeout = const Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDRIER - Paracha, Daf Yomi, etc.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupère le calendrier du jour (paracha, daf yomi, etc.)
  ///
  /// [diaspora] : true pour la diaspora, false pour Israël
  Future<SefariaCalendar> getCalendar({bool diaspora = true}) async {
    try {
      final params = diaspora ? '?diaspora=1' : '?diaspora=0';
      final response = await http
          .get(Uri.parse('$_baseUrl/calendars$params'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SefariaCalendar.fromJson(data);
      }
      throw SefariaException('Calendar failed: ${response.statusCode}');
    } catch (e) {
      if (e is SefariaException) rethrow;
      throw SefariaException('Calendar error: $e');
    }
  }

  /// Récupère uniquement la paracha de la semaine
  Future<CalendarItem?> getParasha({bool diaspora = true}) async {
    final calendar = await getCalendar(diaspora: diaspora);
    return calendar.parasha;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTES - Torah, Talmud, Midrash, etc.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupère un texte par sa référence
  ///
  /// [ref] : Référence Sefaria (ex: "Genesis.1", "Exodus.13.17-14.8")
  /// [withContext] : Inclure le contexte (versets avant/après)
  Future<SefariaText> getText(String ref, {bool withContext = false}) async {
    try {
      final encodedRef = Uri.encodeComponent(ref);
      final contextParam = withContext ? '?context=1' : '';
      final response = await http
          .get(Uri.parse('$_baseUrl/v3/texts/$encodedRef$contextParam'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SefariaText.fromJson(data, ref);
      }
      throw SefariaException('Get text failed: ${response.statusCode}');
    } catch (e) {
      if (e is SefariaException) rethrow;
      throw SefariaException('Get text error: $e');
    }
  }

  /// Récupère le texte de la paracha de la semaine
  Future<SefariaText> getParashaText({bool diaspora = true}) async {
    final parasha = await getParasha(diaspora: diaspora);
    if (parasha == null) {
      throw SefariaException('No parasha found');
    }
    return getText(parasha.ref);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMENTAIRES - Rashi, Ramban, etc.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupère tous les commentaires liés à une référence
  Future<SefariaRelated> getRelated(String ref) async {
    try {
      final encodedRef = Uri.encodeComponent(ref);
      final response = await http
          .get(Uri.parse('$_baseUrl/related/$encodedRef'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SefariaRelated.fromJson(data, ref);
      }
      throw SefariaException('Get related failed: ${response.statusCode}');
    } catch (e) {
      if (e is SefariaException) rethrow;
      throw SefariaException('Get related error: $e');
    }
  }

  /// Récupère le commentaire de Rashi sur une référence
  Future<SefariaText> getRashiCommentary(String ref) async {
    try {
      // Convertir la référence pour Rashi (ex: Genesis.1.1 -> Rashi on Genesis.1.1)
      final rashiRef = 'Rashi on $ref';
      return getText(rashiRef);
    } catch (e) {
      throw SefariaException('Rashi commentary error: $e');
    }
  }

  /// Récupère un commentaire spécifique
  ///
  /// [commentator] : Nom du commentateur (Rashi, Ramban, Sforno, Ibn Ezra, etc.)
  Future<SefariaText> getCommentary(String ref, String commentator) async {
    try {
      final commentaryRef = '$commentator on $ref';
      return getText(commentaryRef);
    } catch (e) {
      throw SefariaException('$commentator commentary error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECHERCHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recherche dans les textes Sefaria
  ///
  /// [query] : Terme de recherche
  /// [filters] : Filtres optionnels (ex: ["Tanakh", "Talmud"])
  Future<SefariaSearchResults> search(
    String query, {
    List<String>? filters,
    int size = 20,
  }) async {
    try {
      final body = {
        'query': query,
        'size': size,
        if (filters != null && filters.isNotEmpty) 'filters': filters,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/search-wrapper'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SefariaSearchResults.fromJson(data, query);
      }
      throw SefariaException('Search failed: ${response.statusCode}');
    } catch (e) {
      if (e is SefariaException) rethrow;
      throw SefariaException('Search error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INDEX & MÉTADONNÉES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupère la table des matières complète
  Future<List<SefariaCategory>> getTableOfContents() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/index'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((c) => SefariaCategory.fromJson(c)).toList();
      }
      throw SefariaException('TOC failed: ${response.statusCode}');
    } catch (e) {
      if (e is SefariaException) rethrow;
      throw SefariaException('TOC error: $e');
    }
  }

  /// Récupère les métadonnées d'un livre
  Future<SefariaBookInfo> getBookInfo(String book) async {
    try {
      final encodedBook = Uri.encodeComponent(book);
      final response = await http
          .get(Uri.parse('$_baseUrl/v2/index/$encodedBook'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SefariaBookInfo.fromJson(data);
      }
      throw SefariaException('Book info failed: ${response.statusCode}');
    } catch (e) {
      if (e is SefariaException) rethrow;
      throw SefariaException('Book info error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES
// ═══════════════════════════════════════════════════════════════════════════════

/// Calendrier Sefaria (paracha, daf yomi, etc.)
class SefariaCalendar {
  final String date;
  final String timezone;
  final List<CalendarItem> items;

  SefariaCalendar({
    required this.date,
    required this.timezone,
    required this.items,
  });

  factory SefariaCalendar.fromJson(Map<String, dynamic> json) {
    final items = (json['calendar_items'] as List?)
            ?.map((i) => CalendarItem.fromJson(i))
            .toList() ??
        [];
    return SefariaCalendar(
      date: json['date'] ?? '',
      timezone: json['timezone'] ?? '',
      items: items,
    );
  }

  /// La paracha de la semaine
  CalendarItem? get parasha => items.firstWhere(
        (i) => i.title.en.toLowerCase().contains('parashat'),
        orElse: () => items.first,
      );

  /// Le daf yomi du jour
  CalendarItem? get dafYomi => items.cast<CalendarItem?>().firstWhere(
        (i) => i?.title.en.toLowerCase().contains('daf yomi') ?? false,
        orElse: () => null,
      );

  /// La haftara de la semaine
  CalendarItem? get haftarah => items.cast<CalendarItem?>().firstWhere(
        (i) => i?.title.en.toLowerCase().contains('haftarah') ?? false,
        orElse: () => null,
      );
}

/// Élément du calendrier
class CalendarItem {
  final LocalizedString title;
  final LocalizedString displayValue;
  final String url;
  final String ref;
  final String heRef;
  final int order;
  final String category;
  final LocalizedString? description;
  final List<String>? aliyot;

  CalendarItem({
    required this.title,
    required this.displayValue,
    required this.url,
    required this.ref,
    required this.heRef,
    required this.order,
    required this.category,
    this.description,
    this.aliyot,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    final extraDetails = json['extraDetails'] as Map<String, dynamic>?;
    final aliyotRaw = extraDetails?['aliyot'] as List?;

    return CalendarItem(
      title: LocalizedString.fromJson(json['title'] ?? {}),
      displayValue: LocalizedString.fromJson(json['displayValue'] ?? {}),
      url: json['url'] ?? '',
      ref: json['ref'] ?? '',
      heRef: json['heRef'] ?? '',
      order: json['order'] ?? 0,
      category: json['category'] ?? '',
      description: json['description'] != null
          ? LocalizedString.fromJson(json['description'])
          : null,
      aliyot: aliyotRaw?.map((a) => a.toString()).toList(),
    );
  }

  /// Nom affiché (préfère l'hébreu)
  String get displayName => displayValue.he.isNotEmpty
      ? displayValue.he
      : displayValue.en;
}

/// Texte bilingue
class LocalizedString {
  final String en;
  final String he;

  LocalizedString({required this.en, required this.he});

  factory LocalizedString.fromJson(Map<String, dynamic> json) {
    return LocalizedString(
      en: json['en'] ?? '',
      he: json['he'] ?? '',
    );
  }

  /// Retourne le texte dans la langue préférée
  String get(String lang) => lang == 'he' ? he : en;
}

/// Texte Sefaria
class SefariaText {
  final String ref;
  final List<TextVersion> versions;

  SefariaText({
    required this.ref,
    required this.versions,
  });

  factory SefariaText.fromJson(Map<String, dynamic> json, String ref) {
    final versions = (json['versions'] as List?)
            ?.map((v) => TextVersion.fromJson(v))
            .toList() ??
        [];
    return SefariaText(ref: ref, versions: versions);
  }

  /// Version hébraïque principale
  TextVersion? get hebrew => versions.cast<TextVersion?>().firstWhere(
        (v) => v?.language == 'he',
        orElse: () => null,
      );

  /// Version anglaise principale
  TextVersion? get english => versions.cast<TextVersion?>().firstWhere(
        (v) => v?.language == 'en',
        orElse: () => null,
      );

  /// Texte hébreu formaté
  String get hebrewText => hebrew?.textAsString ?? '';

  /// Texte anglais formaté
  String get englishText => english?.textAsString ?? '';
}

/// Version d'un texte
class TextVersion {
  final String language;
  final String versionTitle;
  final String versionSource;
  final dynamic text; // String ou List<String> ou List<List<String>>
  final String direction;
  final bool isSource;

  TextVersion({
    required this.language,
    required this.versionTitle,
    required this.versionSource,
    required this.text,
    required this.direction,
    required this.isSource,
  });

  factory TextVersion.fromJson(Map<String, dynamic> json) {
    return TextVersion(
      language: json['language'] ?? '',
      versionTitle: json['versionTitle'] ?? '',
      versionSource: json['versionSource'] ?? '',
      text: json['text'],
      direction: json['direction'] ?? 'ltr',
      isSource: json['isSource'] ?? false,
    );
  }

  /// Texte sous forme de string (aplati si nécessaire)
  String get textAsString {
    if (text == null) return '';
    if (text is String) return _cleanHtml(text);
    if (text is List) {
      return _flattenList(text).map(_cleanHtml).join('\n');
    }
    return text.toString();
  }

  /// Texte sous forme de liste de versets
  List<String> get textAsList {
    if (text == null) return [];
    if (text is String) return [_cleanHtml(text)];
    if (text is List) {
      return _flattenList(text).map(_cleanHtml).toList();
    }
    return [text.toString()];
  }

  List<String> _flattenList(List list) {
    final result = <String>[];
    for (final item in list) {
      if (item is String) {
        result.add(item);
      } else if (item is List) {
        result.addAll(_flattenList(item));
      }
    }
    return result;
  }

  String _cleanHtml(String text) {
    // Supprimer les balises HTML simples
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

/// Liens et commentaires liés à une référence
class SefariaRelated {
  final String ref;
  final List<RelatedLink> links;

  SefariaRelated({
    required this.ref,
    required this.links,
  });

  factory SefariaRelated.fromJson(Map<String, dynamic> json, String ref) {
    final links = (json['links'] as List?)
            ?.map((l) => RelatedLink.fromJson(l))
            .toList() ??
        [];
    return SefariaRelated(ref: ref, links: links);
  }

  /// Commentaires uniquement
  List<RelatedLink> get commentaries =>
      links.where((l) => l.type == 'commentary').toList();

  /// Commentaires par auteur
  List<RelatedLink> getCommentariesBy(String author) =>
      commentaries.where((l) =>
        l.collectiveTitle.en.toLowerCase() == author.toLowerCase()
      ).toList();

  /// Rashi
  List<RelatedLink> get rashi => getCommentariesBy('Rashi');

  /// Ramban
  List<RelatedLink> get ramban => getCommentariesBy('Ramban');

  /// Liste des commentateurs disponibles
  List<String> get availableCommentators =>
      commentaries.map((l) => l.collectiveTitle.en).toSet().toList();
}

/// Lien vers un texte lié
class RelatedLink {
  final String ref;
  final String sourceRef;
  final String indexTitle;
  final String category;
  final String type;
  final LocalizedString collectiveTitle;
  final bool hasEnglish;

  RelatedLink({
    required this.ref,
    required this.sourceRef,
    required this.indexTitle,
    required this.category,
    required this.type,
    required this.collectiveTitle,
    required this.hasEnglish,
  });

  factory RelatedLink.fromJson(Map<String, dynamic> json) {
    return RelatedLink(
      ref: json['ref'] ?? '',
      sourceRef: json['sourceRef'] ?? '',
      indexTitle: json['index_title'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      collectiveTitle: LocalizedString.fromJson(json['collectiveTitle'] ?? {}),
      hasEnglish: json['sourceHasEn'] ?? false,
    );
  }
}

/// Résultats de recherche
class SefariaSearchResults {
  final String query;
  final int total;
  final List<SearchHit> hits;

  SefariaSearchResults({
    required this.query,
    required this.total,
    required this.hits,
  });

  factory SefariaSearchResults.fromJson(Map<String, dynamic> json, String query) {
    final hitsData = json['hits'] as Map<String, dynamic>?;
    final hitsList = hitsData?['hits'] as List? ?? [];

    return SefariaSearchResults(
      query: query,
      total: hitsData?['total']?['value'] ?? hitsList.length,
      hits: hitsList.map((h) => SearchHit.fromJson(h)).toList(),
    );
  }
}

/// Résultat de recherche individuel
class SearchHit {
  final String ref;
  final String heRef;
  final String text;
  final String category;
  final double score;

  SearchHit({
    required this.ref,
    required this.heRef,
    required this.text,
    required this.category,
    required this.score,
  });

  factory SearchHit.fromJson(Map<String, dynamic> json) {
    final source = json['_source'] as Map<String, dynamic>? ?? {};
    final highlight = json['highlight'] as Map<String, dynamic>?;
    final exactText = highlight?['exact'] as List?;

    return SearchHit(
      ref: source['ref'] ?? '',
      heRef: source['heRef'] ?? '',
      text: exactText?.first?.toString() ?? source['exact'] ?? '',
      category: source['path'] ?? '',
      score: (json['_score'] ?? 0).toDouble(),
    );
  }
}

/// Catégorie de la table des matières
class SefariaCategory {
  final String name;
  final String hebrewName;
  final List<SefariaCategory> contents;
  final List<String> books;

  SefariaCategory({
    required this.name,
    required this.hebrewName,
    required this.contents,
    required this.books,
  });

  factory SefariaCategory.fromJson(Map<String, dynamic> json) {
    final contentsList = json['contents'] as List? ?? [];
    final subCategories = <SefariaCategory>[];
    final books = <String>[];

    for (final item in contentsList) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey('contents') || item.containsKey('category')) {
          subCategories.add(SefariaCategory.fromJson(item));
        } else if (item.containsKey('title')) {
          books.add(item['title'] ?? '');
        }
      }
    }

    return SefariaCategory(
      name: json['category'] ?? json['title'] ?? '',
      hebrewName: json['heCategory'] ?? json['heTitle'] ?? '',
      contents: subCategories,
      books: books,
    );
  }
}

/// Informations sur un livre
class SefariaBookInfo {
  final String title;
  final String heTitle;
  final List<String> categories;
  final String? description;

  SefariaBookInfo({
    required this.title,
    required this.heTitle,
    required this.categories,
    this.description,
  });

  factory SefariaBookInfo.fromJson(Map<String, dynamic> json) {
    return SefariaBookInfo(
      title: json['title'] ?? '',
      heTitle: json['heTitle'] ?? '',
      categories: (json['categories'] as List?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      description: json['enDesc'] ?? json['heDesc'],
    );
  }
}

/// Exception Sefaria
class SefariaException implements Exception {
  final String message;
  SefariaException(this.message);

  @override
  String toString() => 'SefariaException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS & CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

/// Livres de la Torah (Pentateuque)
class TorahBooks {
  static const genesis = 'Genesis';
  static const exodus = 'Exodus';
  static const leviticus = 'Leviticus';
  static const numbers = 'Numbers';
  static const deuteronomy = 'Deuteronomy';

  static const all = [genesis, exodus, leviticus, numbers, deuteronomy];

  static const hebrewNames = {
    genesis: 'בראשית',
    exodus: 'שמות',
    leviticus: 'ויקרא',
    numbers: 'במדבר',
    deuteronomy: 'דברים',
  };
}

/// Commentateurs principaux
class Commentators {
  static const rashi = 'Rashi';
  static const ramban = 'Ramban';
  static const ibnEzra = 'Ibn Ezra';
  static const sforno = 'Sforno';
  static const rashbam = 'Rashbam';
  static const orHaChaim = 'Or HaChaim';
  static const kliYakar = 'Kli Yakar';
  static const baalHaTurim = 'Baal HaTurim';

  static const all = [
    rashi, ramban, ibnEzra, sforno, rashbam, orHaChaim, kliYakar, baalHaTurim
  ];
}

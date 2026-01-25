import 'package:flutter/material.dart';
import '../services/torah_guide_api_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// TORAH SEARCH WIDGET
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Widget de recherche sémantique pour Torah Guide.
/// Inclut une barre de recherche et affiche les résultats.
///
/// Usage:
/// ```dart
/// TorahSearchWidget(
///   onResultTap: (result) {
///     // Naviguer vers le détail
///   },
/// )
/// ```
///

class TorahSearchWidget extends StatefulWidget {
  /// Callback quand un résultat est sélectionné
  final void Function(SearchResult result)? onResultTap;

  /// Placeholder de la barre de recherche
  final String hintText;

  /// Nombre de résultats à afficher
  final int maxResults;

  /// Afficher les sources historiques uniquement
  final bool historyOnly;

  /// Afficher l'Encyclopaedia uniquement
  final bool encyclopediaOnly;

  const TorahSearchWidget({
    super.key,
    this.onResultTap,
    this.hintText = 'Rechercher dans Torah Guide...',
    this.maxResults = 5,
    this.historyOnly = false,
    this.encyclopediaOnly = false,
  });

  @override
  State<TorahSearchWidget> createState() => _TorahSearchWidgetState();
}

class _TorahSearchWidgetState extends State<TorahSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final TorahGuideApiService _api = TorahGuideApiService.instance;

  bool _isLoading = false;
  String? _error;
  SearchResponse? _response;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _response = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      SearchResponse response;

      if (widget.historyOnly) {
        response = await _api.searchHistory(query, n: widget.maxResults);
      } else if (widget.encyclopediaOnly) {
        response = await _api.searchEncyclopedia(query, n: widget.maxResults);
      } else {
        response = await _api.search(query, n: widget.maxResults);
      }

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        _buildSearchBar(),

        // Indicateur de chargement
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),

        // Erreur
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),

        // Résultats
        if (_response != null && !_isLoading) _buildResults(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _response = null;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onSubmitted: _search,
        onChanged: (value) {
          // Debounce la recherche
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_controller.text == value && value.length >= 2) {
              _search(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildResults() {
    final results = _response!.results;

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aucun résultat trouvé'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_response!.count} résultat(s) en ${_response!.timeFormatted}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        const SizedBox(height: 8),

        // Liste des résultats
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return TorahSearchResultCard(
              result: results[index],
              onTap: widget.onResultTap != null
                  ? () => widget.onResultTap!(results[index])
                  : null,
            );
          },
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// CARTE DE RÉSULTAT
/// ═══════════════════════════════════════════════════════════════════════════════

class TorahSearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onTap;

  const TorahSearchResultCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Titre + Source
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSourceChip(context),
                ],
              ),

              const SizedBox(height: 8),

              // Extrait du contenu
              Text(
                result.excerpt,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Footer: Score
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.insights,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pertinence: ${result.similarityPercent}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceChip(BuildContext context) {
    final isHistory = result.isHistorical;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHistory
            ? Colors.amber.withOpacity(0.2)
            : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        result.source,
        style: TextStyle(
          fontSize: 11,
          color: isHistory ? Colors.amber.shade800 : Colors.blue.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// PAGE DE DÉTAIL
/// ═══════════════════════════════════════════════════════════════════════════════

class TorahEntryDetailPage extends StatefulWidget {
  final String entryId;
  final String? initialTitle;

  const TorahEntryDetailPage({
    super.key,
    required this.entryId,
    this.initialTitle,
  });

  @override
  State<TorahEntryDetailPage> createState() => _TorahEntryDetailPageState();
}

class _TorahEntryDetailPageState extends State<TorahEntryDetailPage> {
  final TorahGuideApiService _api = TorahGuideApiService.instance;

  bool _isLoading = true;
  String? _error;
  EntryResult? _entry;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    try {
      final entry = await _api.getEntry(widget.entryId);
      setState(() {
        _entry = entry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTitle ?? 'Détail'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEntry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_entry == null) {
      return const Center(child: Text('Entrée non trouvée'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            _entry!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          // Source et position
          Row(
            children: [
              Chip(
                label: Text(_entry!.source),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
              if (_entry!.position.isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(_entry!.position),
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
              ],
            ],
          ),

          const Divider(height: 32),

          // Contenu
          SelectableText(
            _entry!.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

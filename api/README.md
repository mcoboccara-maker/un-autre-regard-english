# Torah Guide API

API de recherche sémantique pour l'application mobile Torah Guide.

## Démarrage

```bash
cd "C:\Source j\api"
python server.py
```

L'API démarre sur `http://localhost:8000`

## Endpoints

### GET /
Information sur l'API.

### GET /health
Health check.

### GET /stats
Statistiques de la base de données.

### GET /search
Recherche sémantique.

**Paramètres:**
- `q` (requis): Requête de recherche
- `n` (optionnel): Nombre de résultats (1-20, défaut: 5)
- `volume` (optionnel): Filtrer par volume (0=histoire, 1-21=Encyclopaedia)

**Exemple:**
```bash
curl "http://localhost:8000/search?q=King%20Solomon&n=5"
```

### GET /entry/{id}
Récupérer une entrée par son ID.

**Exemple:**
```bash
curl "http://localhost:8000/entry/solomon_part_12_178c02_57fe985b"
```

### GET /random
Entrées aléatoires pour suggestions.

## Documentation Interactive

Swagger UI: http://localhost:8000/docs
ReDoc: http://localhost:8000/redoc

## Base de données

- **57,136 documents** au total
- Encyclopaedia Judaica (21 volumes)
- Flavius Josèphe (Guerre des Juifs, Antiquités, Contre Apion)
- Maccabées 1 & 2
- Amarna Letters
- Jews Under Roman Rule
- Strabon - Géographie Livre XVI

## Intégration Flutter

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TorahGuideApi {
  final String baseUrl = 'http://YOUR_SERVER:8000';

  Future<List<SearchResult>> search(String query, {int n = 5}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}&n=$n'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['results'] as List)
          .map((r) => SearchResult.fromJson(r))
          .toList();
    }
    throw Exception('Search failed');
  }
}
```

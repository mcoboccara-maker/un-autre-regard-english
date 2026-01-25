# Log de Conversation - Projet Torah Guide / Encyclopaedia Judaica

## Session: 2026-01-25

### Contexte du Projet
- **Application**: Torah Guide (app mobile Flutter)
- **Agent actuel**: Encyclopaedia Judaica RAG Agent
- **Données**: 21 volumes de l'Encyclopaedia Judaica traités

### État Actuel des Données (conversation/00000/)

| Fichier | Taille | Description |
|---------|--------|-------------|
| encyclopaedia_embeddings.jsonl | 1.87 GB | 54,756 embeddings générés (OpenAI text-embedding-3-small) |
| encyclopaedia_judaica_chunks.json | 112 MB | Chunks indexés |
| encyclopaedia_judaica_complete.json | 98 MB | Données complètes |
| encyclopaedia_index.json | 2.7 MB | Index de recherche |
| volume1_final.json ... volume21_final.json | ~4-5 MB chacun | 21 volumes parsés |

### Architecture Proposée (discussion précédente)

Pour l'app mobile Torah Guide, 3 options ont été discutées:

**Option A: API Backend (RECOMMANDÉE)**
- ChromaDB tourne sur un serveur (VPS, Azure, etc.)
- L'app Flutter fait des requêtes HTTP: "cherche X dans l'Encyclopaedia"
- Le serveur fait la recherche sémantique et retourne les 5-10 résultats pertinents
- Mémoire mobile: quasi nulle

**Option B: Base locale allégée**
- Tu pré-calcules les embeddings côté serveur
- Tu stockes sur mobile une version SQLite + modèle d'embedding léger (MiniLM ~80MB)
- MAIS 850K chunks + embeddings = plusieurs GB → PAS VIABLE

**Option C: Hybride**
- Contenu fréquent/essentiel en cache local (quelques MB)
- Recherche sémantique via API pour le reste

**Conclusion**: Pour 21 volumes, API backend est OBLIGATOIRE. Même compressé, c'est trop gros pour le mobile.

---

## DIAGNOSTIC DU CRASH - 2026-01-25

### Symptômes Observés (screenshots analyse_bug/)

1. **Erreur principale**:
   ```
   FATAL ERROR: Committing semi space failed. Allocation failed - JavaScript heap out of memory
   ```

2. **Contexte du crash**:
   - Claude Code essayait de traiter le fichier `chunks.jsonl` (~850,000 lignes)
   - Memory allocation failure à ~400 MB
   - GC (Garbage Collection) échouait: "Scavenge 358.2 (391.1) -> 344.8 (407.1) MB"

3. **Erreur Windows associée**:
   - msedge.exe - Erreur d'application
   - Exception logicielle inconnue (0xe0000008) à l'emplacement 0x00007FFCEF6AA80A

### Fichiers Dump Windows Trouvés

| Fichier | Date | Taille |
|---------|------|--------|
| C:\Windows\Minidump\012326-13703-01.dmp | 23 janv 18:00 | 5.7 MB |
| C:\Windows\Minidump\012426-14046-01.dmp | 24 janv 21:10 | 5.8 MB |
| C:\Windows\Minidump\012526-13484-01.dmp | 25 janv 13:14 | 5.8 MB |

### Cause Racine

**Claude Code (Node.js) a une limite de mémoire heap par défaut (~2GB sur 64-bit).**

Quand on lui demande de:
- Lire le fichier `encyclopaedia_embeddings.jsonl` (1.87 GB)
- Ou traiter des fichiers JSON volumineux

Le moteur V8 JavaScript atteint sa limite et crash avec "heap out of memory".

### Solutions Proposées (de la conversation précédente)

1. **Augmenter la mémoire Node.js**:
   ```bash
   NODE_OPTIONS="--max-old-space-size=16384" # 16GB de RAM
   ```

2. **Découper le fichier avant de relancer**:
   ```powershell
   $i = 0
   Get-Content "C:\Source j\scripts\output\chunks.jsonl" -ReadCount 50000 | ForEach-Object {
       $_ | Set-Content "C:\Source j\scripts\output\chunks_part_$i.jsonl"
       $i++
   }
   ```

3. **Script Python externe pour ChromaDB** (RECOMMANDÉ):
   ```python
   import chromadb
   import json

   client = chromadb.PersistentClient(path="./chromadb")
   collection = client.get_or_create_collection("encyclopaedia")

   batch_size = 500
   with open("chunks.jsonl", "r", encoding="utf-8") as f:
       for i, line in enumerate(f):
           # Traiter par batches...
   ```

**Ma recommandation**: Ne pas utiliser Claude Code pour le traitement bulk de fichiers >100MB. Utiliser Claude Code pour écrire/débugger les scripts Python, puis exécuter les scripts directement.

---

## Prochaines Étapes

### Phase 1: Indexation Vectorielle (TERMINÉ - 25 janv 13:35)

**Note**: ChromaDB incompatible avec Python 3.14, utilisation de **LanceDB** à la place.

- [x] Créer un script Python qui lit les embeddings en streaming
- [x] Script de recherche sémantique
- [x] **Indexation terminée**: 54,756 documents en 48 secondes
- [x] **Recherche testée**: fonctionne parfaitement

**Scripts créés:**
- `index_lancedb.py` - Indexation streaming (EXÉCUTÉ)
- `search_lancedb.py` - Recherche sémantique interactive

**Base de données unifiée:**
- Chemin: `conversation/00000/lancedb_judaica/`
- **57,136 documents vectoriels** total:
  - 54,756 chunks Encyclopaedia Judaica (21 volumes)
  - 2,371 chunks livres d'histoire antique (Josèphe, Maccabées, Amarna, etc.)
  - 9 chunks Strabon Livre XVI

**Usage:**
```bash
cd "C:\Source j\conversation\00000"
python search_lancedb.py "What is Passover?"
python search_lancedb.py --interactive
```

### Phase 2: API Backend (DÉPLOYÉ - 25 janv)
- [x] Serveur FastAPI créé
- [x] Endpoints fonctionnels:
  - `GET /search?q=...&n=5` - Recherche sémantique
  - `GET /entry/{id}` - Récupérer une entrée
  - `GET /stats` - Statistiques
  - `GET /health` - Health check
  - `GET /random` - Suggestions aléatoires
- [x] **DÉPLOYÉ sur Railway** ✅

**Fichiers:**
- `C:\Source j\api\server.py` - Serveur FastAPI
- `C:\Source j\api\requirements.txt` - Dépendances Python
- `C:\Source j\api\railway.toml` - Config Railway
- `C:\Source j\api\Procfile` - Commande de démarrage

**URLs:**
- **Production:** https://torah-guide-api-production.up.railway.app
- **Docs Swagger:** https://torah-guide-api-production.up.railway.app/docs
- **Local dev:** http://localhost:8000

### Déploiement Railway (25 janv)

**Configuration:**
- Plateforme: Railway (https://railway.app)
- Région: Auto-sélectionnée
- Base de données: Auto-téléchargée depuis Google Drive au démarrage

**Variables d'environnement Railway:**
```
OPENAI_API_KEY=sk-proj-...
DATA_DIR=/tmp
TABLE_NAME=encyclopaedia
```

**Auto-téléchargement de la base:**
- L'API télécharge automatiquement la base LanceDB (446 MB) depuis Google Drive au premier démarrage
- Google Drive File ID: `1VLvPfHtlaPySX7OZN7ff9bvqUKG86tZC`
- Archive: `lancedb_judaica.tar.gz`

**Commandes Railway utiles:**
```bash
railway login
railway link
railway up        # Déployer
railway logs      # Voir les logs
railway domain    # Voir l'URL
```

**Tests de l'API en production:**
```bash
# Health check
curl https://torah-guide-api-production.up.railway.app/health

# Recherche
curl "https://torah-guide-api-production.up.railway.app/search?q=Moses&n=3"
```

**Résultats vérifiés:**
- 57,136 documents connectés
- Recherche fonctionnelle (~1.2s)
- Toutes les sources disponibles (Encyclopaedia + Histoire)

### Phase 3: Intégration Flutter (CONFIGURÉ PRODUCTION - 25 janv)
- [x] Service HTTP: `torah_guide_api_service.dart`
- [x] Widget de recherche: `torah_search_widget.dart`
- [x] Carte de résultat avec source (EJ vs Histoire)
- [x] Page de détail d'entrée
- [x] **URL de production configurée** ✅

**Fichiers créés:**
- `lib/services/torah_guide_api_service.dart` - Service HTTP
- `lib/widgets/torah_search_widget.dart` - Widgets UI

**Configuration production:**
```dart
// TorahGuideApiConfig contient maintenant:
static const String productionUrl = 'https://torah-guide-api-production.up.railway.app';
static const bool isProduction = true;
```

**Usage:**
```dart
// Configuration (au démarrage de l'app)
TorahGuideApiService.instance.configure(
  baseUrl: TorahGuideApiConfig.getPlatformUrl(), // Utilise production automatiquement
);

// Widget de recherche
TorahSearchWidget(
  onResultTap: (result) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TorahEntryDetailPage(
        entryId: result.id,
        initialTitle: result.title,
      ),
    ));
  },
)
```

### Livres d'Histoire Antique (INTÉGRÉS - 25 janv)

**Architecture choisie**: Base unifiée (tout dans LanceDB)

**Sources traitées** (2,371 chunks ajoutés):

| Livre | Auteur | Chunks |
|-------|--------|--------|
| Contre Apion | Flavius Josèphe | 92 |
| Guerre des Juifs | Flavius Josèphe | 500 |
| Antiquities of the Jews | Flavius Josephus | 965 |
| 1 Maccabees | Anonyme | 49 |
| 2 Maccabees | Anonyme | 36 |
| The Amarna Letters | W.L. Moran | 389 |
| The Jews Under Roman Rule | - | 340 |

**Strabon ajouté** (25 janv):
- Livre XVI (Assyrie, Babylonie, Syrie, Phénicie, Judée, Arabie)
- Source: Lacus Curtius (texte en ligne, PDF était un scan)
- 9 chunks ajoutés

**Convention**:
- `volume = 0` pour les livres d'histoire (vs volumes 1-21 pour Encyclopaedia)
- Titre inclut l'auteur: "Guerre des Juifs (Flavius Josèphe)"

**Script**: `C:\Source j\judaisme histoire antique\process_history_books.py`

---

## Notes Techniques

### Clé API OpenAI
⚠️ **ATTENTION**: La clé API est exposée dans `run_embeddings_v2.py` ligne 27.
Recommandation: Utiliser des variables d'environnement ou un fichier .env

### Structure des Embeddings
```json
{
  "id": "aaron_4a5067_597b9899",
  "title": "AARON",
  "volume": 1,
  "embedding": [0.045..., -0.012..., ...]  // 1536 dimensions
}
```

---

*Log créé automatiquement par Claude Code - Session 2026-01-25*

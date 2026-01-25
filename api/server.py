#!/usr/bin/env python3
"""
Torah Guide API - Recherche sémantique
======================================

API FastAPI pour l'application mobile Torah Guide.
Télécharge automatiquement la base de données au premier démarrage.
"""

import os
import sys
import time
import tarfile
import subprocess
from typing import Optional, List
from contextlib import asynccontextmanager
from pathlib import Path

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import lancedb
from openai import OpenAI

# ============================================================
# CONFIGURATION
# ============================================================

PORT = int(os.environ.get('PORT', 8000))
HOST = "0.0.0.0"

# Base de données
DATA_DIR = os.environ.get('DATA_DIR', '/data')
LANCEDB_PATH = os.path.join(DATA_DIR, 'lancedb_judaica')
TABLE_NAME = os.environ.get('TABLE_NAME', 'encyclopaedia')

# Google Drive - Archive de la base
GDRIVE_FILE_ID = "1VLvPfHtlaPySX7OZN7ff9bvqUKG86tZC"
ARCHIVE_NAME = "lancedb_judaica.tar.gz"

# OpenAI
EMBEDDING_MODEL = 'text-embedding-3-small'
API_KEY = os.environ.get('OPENAI_API_KEY')

# ============================================================
# TÉLÉCHARGEMENT BASE DE DONNÉES
# ============================================================

def download_database():
    """Télécharge et extrait la base de données depuis Google Drive"""

    # Créer le répertoire data si nécessaire
    os.makedirs(DATA_DIR, exist_ok=True)

    archive_path = os.path.join(DATA_DIR, ARCHIVE_NAME)

    print(f"Téléchargement de la base de données depuis Google Drive...")
    print(f"  File ID: {GDRIVE_FILE_ID}")

    # Installer gdown si nécessaire
    try:
        import gdown
    except ImportError:
        print("  Installation de gdown...")
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'gdown', '-q'])
        import gdown

    # Télécharger
    url = f"https://drive.google.com/uc?id={GDRIVE_FILE_ID}"
    print(f"  URL: {url}")
    print(f"  Destination: {archive_path}")

    try:
        gdown.download(url, archive_path, quiet=False)
    except Exception as e:
        print(f"  Erreur téléchargement: {e}")
        # Essayer avec confirmation forcée (pour gros fichiers)
        gdown.download(url, archive_path, quiet=False, fuzzy=True)

    if not os.path.exists(archive_path):
        raise Exception("Échec du téléchargement")

    print(f"  Téléchargé: {os.path.getsize(archive_path) / 1024 / 1024:.1f} MB")

    # Extraire
    print(f"Extraction de l'archive...")
    with tarfile.open(archive_path, 'r:gz') as tar:
        tar.extractall(DATA_DIR)

    print(f"  Extrait dans: {LANCEDB_PATH}")

    # Nettoyer l'archive
    os.remove(archive_path)
    print(f"  Archive supprimée")

    return True

# ============================================================
# MODELS
# ============================================================

class SearchResult(BaseModel):
    id: str
    title: str
    volume: int
    content: str
    chunk_index: int
    total_chunks: int
    distance: float

class SearchResponse(BaseModel):
    query: str
    results: List[SearchResult]
    count: int
    time_ms: float

class EntryResponse(BaseModel):
    id: str
    title: str
    volume: int
    content: str
    chunk_index: int
    total_chunks: int

class StatsResponse(BaseModel):
    total_documents: int
    sources: dict
    status: str

class HealthResponse(BaseModel):
    status: str
    database: str
    documents: int

# ============================================================
# APPLICATION
# ============================================================

db = None
table = None
openai_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize resources on startup"""
    global db, table, openai_client

    print("=" * 50)
    print("TORAH GUIDE API - Démarrage")
    print("=" * 50)
    print(f"Port: {PORT}")
    print(f"Data dir: {DATA_DIR}")
    print(f"LanceDB path: {LANCEDB_PATH}")

    # Vérifier/télécharger la base
    if not os.path.exists(LANCEDB_PATH):
        print(f"Base non trouvée, téléchargement...")
        try:
            download_database()
        except Exception as e:
            print(f"ERREUR téléchargement: {e}")
            print("L'API démarrera sans base de données")

    # Connexion LanceDB
    if os.path.exists(LANCEDB_PATH):
        print(f"Connexion à LanceDB...")
        db = lancedb.connect(LANCEDB_PATH)
        table = db.open_table(TABLE_NAME)
        doc_count = table.count_rows()
        print(f"  {doc_count:,} documents chargés")
    else:
        print("  Base non disponible")

    # OpenAI
    print("Initialisation client OpenAI...")
    openai_client = OpenAI(api_key=API_KEY)
    print("  OK")

    print()
    print(f"API prête sur http://{HOST}:{PORT}")
    print("=" * 50)

    yield

    print("Arrêt de l'API...")

app = FastAPI(
    title="Torah Guide API",
    description="API de recherche sémantique - Encyclopaedia Judaica & Sources Historiques",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# ENDPOINTS
# ============================================================

@app.get("/")
async def root():
    """Information sur l'API"""
    return {
        "name": "Torah Guide API",
        "version": "1.0.0",
        "description": "Recherche sémantique dans l'Encyclopaedia Judaica et sources historiques",
        "documents": table.count_rows() if table else 0,
        "endpoints": {
            "/search": "GET ?q=query&n=5",
            "/entry/{id}": "GET",
            "/stats": "GET",
            "/health": "GET"
        }
    }


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check"""
    try:
        if table is None:
            return HealthResponse(
                status="degraded",
                database="not_connected",
                documents=0
            )
        count = table.count_rows()
        return HealthResponse(
            status="healthy",
            database="connected",
            documents=count
        )
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@app.get("/stats", response_model=StatsResponse)
async def stats():
    """Statistiques de la base"""
    if table is None:
        raise HTTPException(status_code=503, detail="Database not connected")

    try:
        total = table.count_rows()
        sources = {
            "encyclopaedia_judaica": 54756,
            "flavius_josephus": 1557,
            "maccabees": 85,
            "amarna_letters": 389,
            "jews_under_roman_rule": 340,
            "strabo": 9
        }
        return StatsResponse(
            total_documents=total,
            sources=sources,
            status="ok"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/search", response_model=SearchResponse)
async def search(
    q: str = Query(..., min_length=2, description="Requête de recherche"),
    n: int = Query(5, ge=1, le=20, description="Nombre de résultats"),
    volume: Optional[int] = Query(None, description="Filtrer par volume")
):
    """Recherche sémantique"""
    if table is None:
        raise HTTPException(status_code=503, detail="Database not connected")

    start_time = time.time()

    try:
        response = openai_client.embeddings.create(
            model=EMBEDDING_MODEL,
            input=q
        )
        query_embedding = response.data[0].embedding

        search_query = table.search(query_embedding).limit(n * 2)

        if volume is not None:
            search_query = search_query.where(f"volume = {volume}")

        raw_results = search_query.limit(n).to_list()

        results = []
        for r in raw_results:
            results.append(SearchResult(
                id=r.get('id', ''),
                title=r.get('title', 'Sans titre'),
                volume=r.get('volume', 0),
                content=r.get('content', '')[:2000],
                chunk_index=r.get('chunk_index', 0),
                total_chunks=r.get('total_chunks', 1),
                distance=r.get('_distance', 0)
            ))

        elapsed = (time.time() - start_time) * 1000

        return SearchResponse(
            query=q,
            results=results,
            count=len(results),
            time_ms=round(elapsed, 2)
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/entry/{entry_id}", response_model=EntryResponse)
async def get_entry(entry_id: str):
    """Récupérer une entrée par ID"""
    if table is None:
        raise HTTPException(status_code=503, detail="Database not connected")

    try:
        results = table.search().where(f"id = '{entry_id}'").limit(1).to_list()

        if not results:
            raise HTTPException(status_code=404, detail=f"Entry not found: {entry_id}")

        r = results[0]
        return EntryResponse(
            id=r.get('id', ''),
            title=r.get('title', ''),
            volume=r.get('volume', 0),
            content=r.get('content', ''),
            chunk_index=r.get('chunk_index', 0),
            total_chunks=r.get('total_chunks', 1)
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/random")
async def random_entries(n: int = Query(5, ge=1, le=10)):
    """Entrées aléatoires pour suggestions"""
    if table is None:
        raise HTTPException(status_code=503, detail="Database not connected")

    try:
        results = table.head(n * 10).to_pydict()

        import random
        indices = random.sample(range(len(results['id'])), min(n, len(results['id'])))

        entries = []
        for i in indices:
            entries.append({
                'id': results['id'][i],
                'title': results['title'][i],
                'volume': results['volume'][i]
            })

        return {"entries": entries}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=HOST,
        port=PORT,
        reload=False,
        log_level="info"
    )

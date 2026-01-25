# Déploiement Railway - Torah Guide API

## Prérequis

- Compte Railway (https://railway.app)
- Git installé
- Base de données LanceDB prête (446 MB)

## Étapes

### 1. Créer le projet Railway

```bash
# Installer Railway CLI
npm install -g @railway/cli

# Se connecter
railway login

# Créer le projet
cd "C:\Source j\api"
railway init
```

### 2. Configurer les variables d'environnement

Dans le dashboard Railway > Settings > Variables :

```
OPENAI_API_KEY=sk-proj-votre-cle-openai
LANCEDB_PATH=/data/lancedb_judaica
TABLE_NAME=encyclopaedia
```

### 3. Ajouter un volume persistant

1. Dashboard Railway > Service > Settings > Volumes
2. Ajouter un volume : `/data`
3. Taille recommandée : 1 GB

### 4. Uploader la base de données

Option A - Via Railway CLI :
```bash
# Ouvrir un shell dans le container
railway shell

# Dans le container, télécharger la base (à héberger quelque part)
cd /data
wget https://votre-url/lancedb_judaica.zip
unzip lancedb_judaica.zip
```

Option B - Via SFTP (avec volume) :
```bash
# Zipper la base localement
cd "C:\Source j\conversation\00000"
tar -czvf lancedb_judaica.tar.gz lancedb_judaica/

# Uploader via les outils Railway
# (voir documentation Railway pour SFTP/volumes)
```

### 5. Déployer

```bash
cd "C:\Source j\api"
git init
git add .
git commit -m "Initial deploy"

# Lier au projet Railway
railway link

# Déployer
railway up
```

### 6. Vérifier

```bash
# Obtenir l'URL
railway domain

# Tester
curl https://votre-app.railway.app/health
```

## Structure finale sur Railway

```
/app
├── server.py
├── requirements.txt
├── railway.toml
└── Procfile

/data (volume persistant)
└── lancedb_judaica/
    └── encyclopaedia.lance/
```

## Variables d'environnement

| Variable | Description | Exemple |
|----------|-------------|---------|
| `PORT` | Port (auto par Railway) | 8000 |
| `OPENAI_API_KEY` | Clé API OpenAI | sk-proj-... |
| `LANCEDB_PATH` | Chemin base de données | /data/lancedb_judaica |
| `TABLE_NAME` | Nom de la table | encyclopaedia |

## Coûts estimés

- **Hobby Plan** : $5/mois
  - 512 MB RAM
  - 1 GB Volume
  - Suffisant pour cette API

## Troubleshooting

### "Database not connected"
- Vérifier que le volume `/data` existe
- Vérifier que `LANCEDB_PATH` pointe vers le bon chemin
- Vérifier que la base a été uploadée

### "OpenAI error"
- Vérifier que `OPENAI_API_KEY` est définie
- Vérifier le solde du compte OpenAI

### Logs
```bash
railway logs
```

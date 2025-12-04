# 🍎 Guide de Déploiement iOS - Un Autre Regard

Ce guide te permet de compiler et publier ton app sur l'App Store **sans Mac**, en utilisant Codemagic (CI/CD cloud).

---

## 📋 Prérequis

- ✅ Compte Apple Developer (99$/an) - **Tu l'as déjà**
- ✅ Projet Flutter fonctionnel
- ⬜ Compte GitHub (gratuit)
- ⬜ Compte Codemagic (gratuit - 500 min/mois)

---

## 🚀 ÉTAPE 1 : Préparer ton projet localement

### 1.1 Régénérer les fichiers iOS

Ouvre PowerShell dans ton dossier projet et exécute :

```powershell
# Nettoyer et régénérer les fichiers de plateforme
flutter clean
flutter pub get

# Régénérer les fichiers iOS (même sur Windows, ça crée la structure de base)
flutter create --platforms=ios .
```

### 1.2 Vérifier la structure

Après cette commande, tu devrais avoir ces fichiers dans `ios/` :

```
ios/
├── Runner/
│   ├── AppDelegate.swift
│   ├── Assets.xcassets/
│   ├── Base.lproj/
│   ├── Info.plist
│   └── Runner-Bridging-Header.h
├── Runner.xcodeproj/
├── Runner.xcworkspace/
├── Podfile
└── .gitignore
```

### 1.3 Copier les fichiers de configuration

Copie les fichiers que j'ai créés dans ton projet :
- `.gitignore` → racine du projet
- `codemagic.yaml` → racine du projet

---

## 🌐 ÉTAPE 2 : Créer un dépôt GitHub

### 2.1 Créer le dépôt

1. Va sur [github.com/new](https://github.com/new)
2. Nom : `un-autre-regard`
3. Visibilité : **Private** (recommandé)
4. NE PAS initialiser avec README

### 2.2 Pousser ton code

```powershell
# Dans le dossier de ton projet
cd C:\MOBILE PSY\UN_AUTRE_REGARD

# Initialiser Git
git init

# Ajouter tous les fichiers
git add .

# Premier commit
git commit -m "Initial commit - Un Autre Regard v2.0"

# Lier au dépôt GitHub
git remote add origin https://github.com/TON_USERNAME/un-autre-regard.git

# Pousser
git branch -M main
git push -u origin main
```

---

## 🍏 ÉTAPE 3 : Configurer Apple Developer Portal

### 3.1 Créer l'identifiant d'app (Bundle ID)

1. Va sur [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. Clique **+** (bouton bleu)
4. Sélectionne **App IDs** → Continue
5. Sélectionne **App** → Continue
6. Remplis :
   - **Description** : `Un Autre Regard`
   - **Bundle ID** : Sélectionne "Explicit"
   - **Valeur** : `com.unautreregard.app` (ou ton propre domaine inversé)
7. **Capabilities** : Active selon tes besoins :
   - ⬜ Push Notifications (si tu veux des notifs plus tard)
   - ⬜ Sign in with Apple (si connexion Apple)
8. Clique **Continue** → **Register**

### 3.2 Créer l'app sur App Store Connect

1. Va sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Apps** (menu gauche) → **+** → **New App**
3. Remplis :
   - **Platforms** : iOS
   - **Name** : `Un Autre Regard`
   - **Primary Language** : French
   - **Bundle ID** : Sélectionne celui créé à l'étape 3.1
   - **SKU** : `unautreregard2024` (identifiant interne unique)
   - **User Access** : Full Access
4. Clique **Create**

### 3.3 Créer une clé API App Store Connect

1. Toujours sur App Store Connect
2. **Users and Access** (menu gauche)
3. Onglet **Integrations** → **App Store Connect API**
4. Clique **+** pour créer une clé
5. Remplis :
   - **Name** : `Codemagic CI`
   - **Access** : `App Manager`
6. Clique **Generate**
7. **IMPORTANT** : Télécharge la clé `.p8` immédiatement (tu ne pourras plus la télécharger après !)
8. Note aussi :
   - **Issuer ID** (en haut de la page)
   - **Key ID** (dans la liste des clés)

---

## ⚙️ ÉTAPE 4 : Configurer Codemagic

### 4.1 Créer un compte Codemagic

1. Va sur [codemagic.io](https://codemagic.io)
2. Clique **Start building**
3. **Sign up with GitHub**
4. Autorise l'accès à tes dépôts

### 4.2 Ajouter ton projet

1. Sur le dashboard, clique **Add application**
2. Sélectionne **GitHub**
3. Trouve et sélectionne `un-autre-regard`
4. **Project type** : Flutter App
5. Clique **Finish: Add application**

### 4.3 Configurer l'intégration Apple

1. Va dans **Teams** (menu en haut) → ton équipe
2. **Integrations** → **App Store Connect**
3. Clique **Connect**
4. Remplis avec les infos de l'étape 3.3 :
   - **Issuer ID** : colle l'ID
   - **Key ID** : colle l'ID de la clé
   - **Private Key** : colle le contenu du fichier `.p8`
5. **Integration name** : `Un Autre Regard`
6. Clique **Save**

### 4.4 Configurer la signature de code

1. Retourne sur ton app dans Codemagic
2. Clique sur l'engrenage ⚙️ (Settings)
3. Section **Code signing**
4. **iOS code signing** → **Automatic**
5. Sélectionne :
   - **App Store Connect integration** : `Un Autre Regard`
   - **Bundle identifier** : `com.unautreregard.app`
6. Clique **Save changes**

### 4.5 Modifier le fichier codemagic.yaml

Dans ton fichier `codemagic.yaml`, modifie ces valeurs :

```yaml
# Ligne 16 - Ton Bundle ID
bundle_identifier: com.unautreregard.app

# Ligne 22 - ID de ton app (visible dans App Store Connect)
APP_ID: 123456789  # Remplace par ton vrai App ID

# Lignes avec email - Ton email
recipients:
  - ton.vrai.email@example.com
```

---

## 🏗️ ÉTAPE 5 : Lancer le premier build

### 5.1 Pousser les modifications

```powershell
git add .
git commit -m "Add Codemagic configuration"
git push
```

### 5.2 Déclencher le build

1. Sur Codemagic, va sur ton app
2. Clique **Start new build**
3. Sélectionne :
   - **Workflow** : `iOS Release - Un Autre Regard`
   - **Branch** : `main`
4. Clique **Start new build**

### 5.3 Surveiller le build

Le build prend environ 10-15 minutes. Tu peux suivre les logs en direct.

---

## ✅ ÉTAPE 6 : Résultat

Si tout se passe bien :

1. **Codemagic** génère un fichier `.ipa`
2. L'app est **automatiquement uploadée** sur TestFlight
3. Tu reçois un **email** de confirmation
4. Dans **App Store Connect** → **TestFlight**, tu verras ta build

---

## 🔧 Dépannage courant

### Erreur "Bundle ID not found"
→ Vérifie que le Bundle ID dans `codemagic.yaml` correspond exactement à celui créé sur Apple Developer.

### Erreur "Code signing failed"
→ Vérifie l'intégration App Store Connect dans Codemagic (clé API valide).

### Erreur "pod install failed"
→ Le Podfile sera généré par `flutter create`. Si problème, ajoute un Podfile manuellement.

### Build trop long (>60 min)
→ Augmente `max_build_duration` dans `codemagic.yaml`.

---

## 📱 Tester sur un vrai iPhone

Une fois sur TestFlight :

1. Installe l'app **TestFlight** sur ton iPhone
2. Connecte-toi avec ton Apple ID
3. Accepte l'invitation de test
4. Installe **Un Autre Regard**

---

## 💰 Récapitulatif des coûts

| Élément | Coût |
|---------|------|
| Apple Developer Program | 99$/an ✅ |
| GitHub (privé) | Gratuit |
| Codemagic | Gratuit (500 min/mois) |
| **Total additionnel** | **0$** |

---

## 📞 Support

- **Codemagic** : [docs.codemagic.io](https://docs.codemagic.io)
- **Flutter iOS** : [docs.flutter.dev/deployment/ios](https://docs.flutter.dev/deployment/ios)
- **Apple Developer** : [developer.apple.com/support](https://developer.apple.com/support)

---

*Guide créé pour Un Autre Regard v2.0 - Décembre 2024*

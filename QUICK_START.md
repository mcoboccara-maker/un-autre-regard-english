# 🚀 Guide de Démarrage Rapide - Un Autre Regard

## ⚡ Installation Immédiate

### 1. Prérequis
```bash
# Vérifier Flutter
flutter --version
# Doit être >= 3.10.0

# Si Flutter n'est pas installé :
# https://docs.flutter.dev/get-started/install
```

### 2. Lancement Direct
```bash
# Naviguer vers le projet
cd un_autre_regard

# Installer les dépendances
flutter pub get

# Lancer sur un émulateur/appareil connecté
flutter run
```

### 3. En cas d'erreurs Hive
```bash
# Générer les adapters Hive manquants
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 📱 Test de l'Application

### Flux Complet à Tester
1. **Écran d'accueil** → 4 pages de présentation
2. **Onboarding** → Profil utilisateur (peut être passé)
3. **Wizard principal** :
   - **Étape 1** : Saisir une pensée/situation
   - **Étape 2** : Ajuster les émotions avec les cartes
   - **Étape 3** : Voir la génération des perspectives

### Fonctionnalités Clés
- ✅ **Cartes émotionnelles** interactives avec curseurs
- ✅ **Modal de détail** avec nuances Byron Katie
- ✅ **Sélection d'approches** par onglets
- ✅ **Génération simulée** des réponses IA
- ✅ **Bouton pensée positive** (FAB rose)

## 🛠️ Développement

### Structure Important
```
lib/
├── main.dart                 # Point d'entrée
├── models/                   # Modèles Hive
├── screens/                  # Écrans principaux
├── widgets/                  # Composants réutilisables
├── services/                 # Services (stockage, IA)
└── config/                   # Configuration
```

### Prochaines Étapes
1. **Intégrer vraie IA** : Remplacer `ai_service.dart` par Claude API
2. **Ajouter historique** : Écran de consultation des réflexions
3. **Implémenter audio** : Text-to-speech pour les réponses
4. **Tests utilisateurs** : UX testing du wizard

### Debug Utile
```bash
# Hot reload
r

# Hot restart  
R

# Voir les logs
flutter logs

# Build release
flutter build apk
```

## 📄 Fichiers Importants
- `lib/main.dart` → Navigation et thème
- `lib/screens/main_app/main_screen.dart` → Écran principal avec wizard
- `lib/widgets/emotion_widgets/` → Composants émotionnels
- `lib/config/emotion_config.dart` → Configuration Byron Katie
- `lib/services/storage_service.dart` → Stockage local Hive

L'application est **100% fonctionnelle** en simulation ! 🎉

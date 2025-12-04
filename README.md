# Un Autre Regard - Application Flutter

> *"Parce qu'une autre vie est possible, dès qu'on regarde autrement."*

## 📱 Description

**Un Autre Regard** est une application d'écoute et de connaissance de soi qui aide l'utilisateur à ne plus être seul avec ses pensées ou émotions fortes. L'application offre des perspectives personnalisées basées sur différentes approches spirituelles, psychologiques et littéraires.

## 🎯 Mission

Offrir à chaque utilisateur un espace où ses pensées sont accueillies, comprises et mises en perspective — non pour les faire taire, mais pour apprendre à **les regarder sans s'y perdre**.

## ✨ Fonctionnalités Principales

### 🌟 Wizard en 3 Étapes (Refonte UX)
1. **Saisie de la pensée/situation** - Interface moderne avec suggestions
2. **Sélection émotionnelle** - Cartes interactives basées sur Byron Katie (9 catégories)
3. **Génération des perspectives** - Réponses IA personnalisées

### 🎭 Interface Émotionnelle
- **9 catégories d'émotions positives** selon Byron Katie
- **Cartes visuelles modernes** avec curseurs d'intensité
- **Sélection de nuances** pour chaque émotion
- **Sauvegarde et historique** des états émotionnels

### 📚 7 Approches Littéraires + Spirituelles/Psychologiques
- **Spirituelles** : Méditation, Sagesses anciennes, Spiritualité contemporaine
- **Psychologiques** : TCC, Humaniste, Jung, Logothérapie  
- **Littéraires** : Classique, Romantique, Réalisme, Existentialisme, Humanisme spirituel, Mystique/Symboliste, Contemporain/Introspectif

### 👤 Profil Utilisateur Contextuel
- **6 sections personnalisables** : profil, santé, travail, finances, valeurs, ressources
- **Intégration automatique** dans les prompts IA
- **Stockage local chiffré**

### 💝 Bouton "Pensée Positive"
- **Accessible partout** dans l'application
- **Génération contextuelle** basée sur l'état émotionnel
- **Ton bienveillant** (contraste avec le neutre par défaut)

## 🏗️ Architecture Technique

### Framework & Outils
- **Flutter** 3.10+ (cross-platform)
- **Dart** 3.0+
- **Hive** pour le stockage local
- **Provider** pour la gestion d'état
- **Google Fonts** (Inter) pour la typographie

### Structure du Projet
```
lib/
├── main.dart                 # Point d'entrée
├── models/                   # Modèles de données (Hive)
│   ├── emotional_state.dart
│   ├── reflection.dart
│   └── user_profile.dart
├── screens/                  # Écrans de l'application
│   ├── welcome/
│   ├── onboarding/
│   ├── main_app/
│   ├── reflection/
│   ├── emotions/
│   └── results/
├── widgets/                  # Composants réutilisables
│   └── emotion_widgets/
├── services/                 # Services (stockage, IA)
│   ├── storage_service.dart
│   └── ai_service.dart
└── config/                   # Configuration
    ├── emotion_config.dart
    └── approach_config.dart
```

### Stockage et Sécurité
- **Chiffrement AES-256** pour les données sensibles
- **Stockage local uniquement** (pas de cloud par défaut)
- **Export/Import JSON** optionnel
- **Limite configurable** (1000 entrées par défaut)

## 🎨 Design System

### Couleurs
- **Primaire** : #6366F1 (Indigo moderne)
- **Secondaire** : #10B981 (Emerald)
- **Accent** : #F59E0B (Amber)
- **Surface** : #F8FAFC (Slate 50)
- **Pensée positive** : #EC4899 (Pink)

### Typographie
- **Famille** : Inter (Google Fonts)
- **H1** : Inter Bold 28pt
- **H2** : Inter SemiBold 20pt
- **Body** : Inter Regular 16pt

### Composants
- **Cards** : Corner radius 16px, shadow subtile
- **Buttons** : Rounded, animations fluides
- **Micro-interactions** : Haptic feedback, animations 60fps

## 🚀 Installation & Lancement

### Prérequis
- Flutter SDK 3.10+
- Dart 3.0+
- Android Studio / VS Code
- Émulateur Android/iOS ou appareil physique

### Installation
```bash
# Cloner le projet
git clone [repository-url]
cd un_autre_regard

# Installer les dépendances
flutter pub get

# Générer les adapters Hive
flutter packages pub run build_runner build

# Lancer l'application
flutter run
```

### Configuration
1. **API IA** : Configurer les clés API dans les paramètres
2. **Fonts** : Ajouter les fichiers Inter dans `assets/fonts/`
3. **Images** : Placer les assets dans `assets/images/`

## 📊 Fonctionnalités Implémentées

### ✅ Phase 1 - Fondations
- [x] Navigation de base + Écran d'accueil
- [x] Architecture de stockage local (Hive)
- [x] Interface de base pour saisie de pensées
- [x] Wizard en 3 étapes selon refonte UX

### ✅ Phase 2 - Interface Émotionnelle
- [x] 9 catégories émotionnelles Byron Katie
- [x] Cartes visuelles modernes avec curseurs
- [x] Modal de détail avec nuances
- [x] Sauvegarde des états émotionnels

### ✅ Phase 3 - Approches Étendues
- [x] 7 courants littéraires intégrés
- [x] Sélecteur d'approches par onglets
- [x] Configuration des approches par défaut

### 🔄 Phase 4 - En Cours
- [x] Service de stockage complet
- [x] Modèles de données avec Hive
- [ ] Intégration IA réelle (actuellement simulée)
- [ ] Historique et consultation

### 📋 Phase 5 - À Venir
- [ ] Bouton pensée positive opérationnel
- [ ] Outils d'analyse et statistiques
- [ ] Export/Import des données
- [ ] Mode audio et accessibilité

## 🎯 Philosophie & Approche

### Ton des Réponses IA
- **Neutre et analytique** par défaut
- **Pas de facilitation excessive**
- **Objectif et informatif**
- **Conversation intérieure augmentée**

### Respect de Byron Katie
- **9 catégories positives** (Question 4 : "Qui seriez-vous sans cette pensée ?")
- **Nuances détaillées** pour chaque catégorie
- **Interface fidèle** à la méthodologie

### Approches Littéraires Uniques
Chaque courant littéraire offre son **ton émotionnel** et son **credo** :
- **Classique** : "La mesure est la dignité de l'homme"
- **Romantique** : "J'ai quelquefois pleuré, voilà ma gloire"
- **Existentialisme** : "L'homme est condamné à être libre"
- etc.

## 🛡️ Éthique & Sécurité

### Disclaimers
- **Non-thérapeutique** : clairement affiché
- **Complément** et non remplacement du suivi professionnel
- **Responsabilité** de l'utilisateur

### Données Personnelles
- **Stockage local uniquement**
- **Chiffrement** des données sensibles
- **Aucune télémétrie** non consentie
- **Contrôle total** de l'utilisateur

## 📈 Roadmap Future

### Version 2.1
- Intégration IA réelle (Claude API / OpenAI)
- Historique complet avec recherche
- Statistiques émotionnelles avancées

### Version 2.2
- Mode audio (lecture vocale)
- Synchronisation cloud optionnelle
- Partage anonyme d'insights

### Version 2.3
- Rituels personnalisés
- Recommandations de lectures
- Communauté bienveillante

## 🤝 Contribution

Ce projet suit les principes du **développement éthique** :
- Priorité au bien-être utilisateur
- Transparence sur les fonctionnalités
- Respect de la vie privée
- Approche non-commerciale de la croissance personnelle

## 📄 Licence

[À définir - probablement MIT ou équivalent éthique]

---

> *"Nous ne sommes pas nos pensées — nous sommes ceux qui les observent."*

**Un Autre Regard** - Version 2.0  
Développé avec 💜 pour l'épanouissement humain

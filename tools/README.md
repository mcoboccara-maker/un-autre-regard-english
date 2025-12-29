# Système de Prompts Multilingues

## 📋 Vue d'ensemble

Ce système permet de maintenir une seule version des prompts (en français) et de générer automatiquement les versions anglaise et hébraïque via l'API Claude.

## 🏗️ Architecture

```
lib/config/prompts/
├── fr/                           # 📝 VERSION MAÎTRESSE (seule à maintenir)
│   ├── prompt_system_unifie.dart
│   ├── prompt_unifie.dart
│   ├── prompt_approfondissement.dart
│   └── prompt_positive_thought.dart
│
├── en/                           # 🇬🇧 GÉNÉRÉ AUTOMATIQUEMENT
│   ├── prompt_system_unifie.dart
│   ├── prompt_unifie.dart
│   ├── prompt_approfondissement.dart
│   └── prompt_positive_thought.dart
│
├── he/                           # 🇮🇱 GÉNÉRÉ AUTOMATIQUEMENT
│   ├── prompt_system_unifie.dart
│   ├── prompt_unifie.dart
│   ├── prompt_approfondissement.dart
│   └── prompt_positive_thought.dart
│
└── prompt_selector.dart          # Sélecteur automatique de langue

lib/services/
└── language_detector.dart        # Détection de langue locale

tools/
├── prompt_translation_service.dart  # Service de traduction via Claude
└── generate_translated_prompts.dart # Script exécutable
```

## 🔄 Workflow

### 1. Modifier un prompt

Éditez **uniquement** les fichiers dans `lib/config/prompts/fr/`

### 2. Générer les traductions

```bash
# Définir la clé API (une seule fois)
export ANTHROPIC_API_KEY="sk-ant-..."

# Exécuter le script de génération
dart run tools/generate_translated_prompts.dart
```

### 3. Vérifier les traductions

Les fichiers générés contiennent un avertissement :
```dart
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
```

**Ne modifiez jamais les fichiers dans `/en/` ou `/he/` directement !**

## 🔍 Détection de langue

Le `LanguageDetector` analyse le texte de l'utilisateur :

```dart
final lang = LanguageDetector.detect("Je me sens triste");  // → 'fr'
final lang = LanguageDetector.detect("I feel sad");         // → 'en'
final lang = LanguageDetector.detect("אני מרגיש עצוב");      // → 'he'
```

### Algorithme de détection

1. **Hébreu** : Détection par caractères Unicode (U+0590-U+05FF)
2. **Français vs Anglais** : Scoring basé sur :
   - Pronoms (je/I, tu/you, etc.)
   - Articles (le/the, un/a, etc.)
   - Mots-clés fréquents
   - Caractères accentués (é, è, ê, etc.)
   - Patterns de phrases

## 🌐 Utilisation dans l'app

### Dans `ai_service.dart`

```dart
import '../config/prompts/prompt_selector.dart';

// Avant la génération
final userText = "I'm feeling lost today";

// Le sélecteur détecte la langue et retourne le bon prompt
final systemPrompt = PromptSelector.getSystemPrompt(userText);
final userPrompt = PromptSelector.buildUnifiedPrompt(
  userText: userText,
  contenu: userText,
  // ... autres paramètres
);

// Appel API avec les prompts dans la bonne langue
final response = await _callClaude(userPrompt, systemPrompt: systemPrompt);
```

## 🔧 Configuration de la traduction

### Modèle utilisé

Claude Sonnet (claude-sonnet-4-5-20250929) pour :
- Haute qualité de traduction
- Compréhension des nuances philosophiques/spirituelles
- Préservation de la structure du prompt

### Instructions de traduction

Le service inclut des instructions spécifiques pour :
- Préserver les variables Dart (`$variable`, `${expression}`)
- Conserver les caractères de formatage (═, ─, •, ❌, ✅)
- Adapter les références culturelles
- Utiliser le vocabulaire approprié (hébreu moderne, etc.)

## ⚠️ Bonnes pratiques

1. **Toujours modifier le français d'abord**
   - Les fichiers en/, he/ sont écrasés à chaque génération

2. **Tester après chaque génération**
   - Vérifier quelques réponses en anglais et hébreu
   - Ajuster le français si la traduction n'est pas satisfaisante

3. **Versionner les fichiers générés**
   - Inclure en/, he/ dans git pour déploiement
   - Permet de voir les différences entre versions

4. **Ne pas modifier les traductions directement**
   - Si une traduction est incorrecte, améliorer les instructions de traduction
   - Ou adapter le texte français source

## 📊 Langues supportées

| Code | Langue   | Direction | Status |
|------|----------|-----------|--------|
| fr   | Français | LTR       | ✅ Master |
| en   | Anglais  | LTR       | ✅ Généré |
| he   | Hébreu   | RTL       | ✅ Généré |

## 🚀 Ajouter une nouvelle langue

1. Ajouter le code dans `language_detector.dart`
2. Ajouter la détection de caractères/mots-clés
3. Ajouter le switch case dans `prompt_selector.dart`
4. Ajouter la langue dans `generate_translated_prompts.dart`
5. Exécuter le script de génération

## 🐛 Dépannage

### La détection de langue est incorrecte

- Vérifier que le texte contient suffisamment de mots
- Les textes très courts peuvent être ambigus
- Ajouter des mots-clés dans `language_detector.dart`

### La traduction est de mauvaise qualité

- Vérifier les instructions de traduction dans `prompt_translation_service.dart`
- Ajouter des exemples spécifiques pour les termes problématiques
- Considérer une relecture manuelle pour les premiers fichiers

### Erreur d'API pendant la génération

- Vérifier la clé API
- Vérifier le rate limiting (le script inclut des pauses)
- Relancer le script (il reprend là où il s'est arrêté)

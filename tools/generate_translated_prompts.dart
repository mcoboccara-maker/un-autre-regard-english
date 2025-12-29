#!/usr/bin/env dart
/// SCRIPT DE GÉNÉRATION DES PROMPTS TRADUITS
/// 
/// Fichier : tools/generate_translated_prompts.dart
/// Usage  : dart run tools/generate_translated_prompts.dart
/// 
/// Ce script :
/// 1. Lit les prompts français dans lib/config/prompts/fr/
/// 2. Les traduit vers anglais et hébreu via Claude API
/// 3. Génère les fichiers dans lib/config/prompts/en/ et lib/config/prompts/he/
/// 
/// Prérequis :
/// - Variable d'environnement ANTHROPIC_API_KEY définie
/// - Ou modifier la clé API dans ce fichier (non recommandé en production)

import 'dart:io';
import 'prompt_translation_service.dart';

void main() async {
  print('''
════════════════════════════════════════════════════════════════════════════════
       GÉNÉRATEUR DE PROMPTS MULTILINGUES - Un Autre Regard
════════════════════════════════════════════════════════════════════════════════

Ce script traduit les prompts français vers :
  • 🇬🇧 Anglais (en)
  • 🇮🇱 Hébreu (he)

════════════════════════════════════════════════════════════════════════════════
''');

  // Récupérer la clé API
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? 
                 'YOUR_API_KEY_HERE'; // Remplacer en dev local
  
  if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
    print('❌ ERREUR: Clé API Anthropic non configurée');
    print('');
    print('Solutions :');
    print('  1. Définir la variable d\'environnement ANTHROPIC_API_KEY');
    print('     export ANTHROPIC_API_KEY="sk-ant-..."');
    print('');
    print('  2. Ou modifier directement ce fichier (non recommandé)');
    exit(1);
  }
  
  // Chemins des dossiers
  final projectRoot = Directory.current.path;
  final masterDir = '$projectRoot/lib/config/prompts/fr';
  final outputBaseDir = '$projectRoot/lib/config/prompts';
  
  // Vérifier que le dossier master existe
  if (!await Directory(masterDir).exists()) {
    print('❌ ERREUR: Dossier master non trouvé: $masterDir');
    print('');
    print('Assurez-vous que les prompts français sont dans :');
    print('  lib/config/prompts/fr/');
    print('');
    print('Structure attendue :');
    print('  lib/config/prompts/');
    print('    ├── fr/');
    print('    │   ├── prompt_system_unifie.dart');
    print('    │   ├── prompt_unifie.dart');
    print('    │   ├── prompt_approfondissement.dart');
    print('    │   └── prompt_positive_thought.dart');
    print('    ├── en/  (sera généré)');
    print('    └── he/  (sera généré)');
    exit(1);
  }
  
  // Créer le service de traduction
  final translationService = PromptTranslationService(apiKey);
  
  // Traduire tous les prompts
  print('🚀 Démarrage de la traduction...\n');
  
  final results = await translationService.translateAllPrompts(
    masterDir: masterDir,
    outputBaseDir: outputBaseDir,
    targetLanguages: ['en', 'he'],
  );
  
  // Afficher le résumé
  print('''

════════════════════════════════════════════════════════════════════════════════
                              RÉSUMÉ
════════════════════════════════════════════════════════════════════════════════
''');

  int success = 0;
  int failed = 0;
  
  results.forEach((key, value) {
    final status = value ? '✅' : '❌';
    print('$status $key');
    if (value) success++; else failed++;
  });
  
  print('''

────────────────────────────────────────────────────────────────────────────────
Résultat : $success/${results.length} fichiers générés avec succès
────────────────────────────────────────────────────────────────────────────────
''');

  if (failed > 0) {
    print('⚠️  Certains fichiers n\'ont pas pu être générés.');
    print('    Vérifiez les erreurs ci-dessus et relancez le script.');
    exit(1);
  } else {
    print('🎉 Tous les prompts ont été traduits avec succès !');
    print('');
    print('Prochaines étapes :');
    print('  1. Vérifier les fichiers générés');
    print('  2. Tester avec des textes en anglais et hébreu');
    print('  3. Ajuster les traductions si nécessaire');
  }
}

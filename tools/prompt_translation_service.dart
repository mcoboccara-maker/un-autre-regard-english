/// SERVICE DE TRADUCTION DES PROMPTS
/// 
/// Fichier : tools/prompt_translation_service.dart
/// Usage  : Traduit les prompts français vers anglais et hébreu via Claude API
/// 
/// Ce service :
/// 1. Lit les fichiers prompts français (master)
/// 2. Appelle Claude pour traduire
/// 3. Génère les fichiers Dart dans les dossiers de langue
/// 
/// Exécution : dart run tools/generate_translated_prompts.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PromptTranslationService {
  
  /// Clé API Claude (à remplacer par variable d'environnement en production)
  final String _apiKey;
  
  /// URL de l'API Claude
  final String _baseUrl = 'https://api.anthropic.com/v1/messages';
  
  /// Modèle Claude à utiliser (Sonnet pour qualité)
  final String _model = 'claude-sonnet-4-5-20250929';
  
  /// Version de l'API
  final String _anthropicVersion = '2023-06-01';
  
  PromptTranslationService(this._apiKey);
  
  // ════════════════════════════════════════════════════════════════════════════
  // TRADUCTION D'UN FICHIER PROMPT
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Traduit un fichier prompt Dart vers une langue cible
  /// 
  /// [sourceFile] : Chemin du fichier français source
  /// [targetLanguage] : Code de langue cible ('en' ou 'he')
  /// [outputFile] : Chemin du fichier de sortie
  Future<bool> translatePromptFile({
    required String sourceFile,
    required String targetLanguage,
    required String outputFile,
  }) async {
    try {
      // 1. Lire le fichier source
      final sourceContent = await File(sourceFile).readAsString();
      print('📖 Lecture de: $sourceFile');
      
      // 2. Extraire la partie à traduire (le contenu du prompt)
      final promptContent = _extractPromptContent(sourceContent);
      if (promptContent == null) {
        print('❌ Impossible d\'extraire le contenu du prompt');
        return false;
      }
      
      // 3. Traduire via Claude
      print('🔄 Traduction vers $targetLanguage en cours...');
      final translatedContent = await _translateWithClaude(
        promptContent, 
        targetLanguage,
        _getPromptType(sourceFile),
      );
      
      if (translatedContent == null) {
        print('❌ Échec de la traduction');
        return false;
      }
      
      // 4. Reconstruire le fichier Dart avec le contenu traduit
      final translatedFile = _reconstructDartFile(
        sourceContent, 
        translatedContent,
        targetLanguage,
      );
      
      // 5. Écrire le fichier de sortie
      final outputDir = Directory(outputFile.substring(0, outputFile.lastIndexOf('/')));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      await File(outputFile).writeAsString(translatedFile);
      print('✅ Fichier généré: $outputFile');
      
      return true;
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // EXTRACTION DU CONTENU DU PROMPT
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Extrait le contenu textuel du prompt (entre les triples quotes)
  String? _extractPromptContent(String dartFileContent) {
    // Pattern pour extraire le contenu entre ''' ... '''
    final regex = RegExp(r"'''([\s\S]*?)'''", multiLine: true);
    final match = regex.firstMatch(dartFileContent);
    
    if (match != null) {
      return match.group(1);
    }
    
    // Essayer avec """ ... """
    final regex2 = RegExp(r'"""([\s\S]*?)"""', multiLine: true);
    final match2 = regex2.firstMatch(dartFileContent);
    
    return match2?.group(1);
  }
  
  /// Détermine le type de prompt à partir du nom de fichier
  String _getPromptType(String filePath) {
    if (filePath.contains('system')) return 'system';
    if (filePath.contains('approfondissement')) return 'deepening';
    if (filePath.contains('positive')) return 'positive_thought';
    return 'unified';
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // TRADUCTION VIA CLAUDE
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Appelle Claude pour traduire le contenu du prompt
  Future<String?> _translateWithClaude(
    String content, 
    String targetLanguage,
    String promptType,
  ) async {
    final languageName = targetLanguage == 'en' ? 'English' : 'Hebrew';
    final languageCode = targetLanguage;
    
    final systemPrompt = '''
You are an expert translator specialized in:
1. Psychological and philosophical texts
2. Spiritual and religious terminology
3. Technical AI prompts and instructions

Your task is to translate a French AI prompt into $languageName.

CRITICAL RULES:
1. PRESERVE all Dart variable interpolations: \$variable, \${expression}
2. PRESERVE all special characters and formatting: ═, ─, ────, ════, •, ❌, ✅, →
3. PRESERVE the exact structure and section organization
4. TRANSLATE the semantic meaning, not word-for-word
5. ADAPT cultural references when necessary while preserving the intent
6. For Hebrew: Use modern Hebrew, maintain RTL text naturally
7. DO NOT translate proper names (Byron Katie, Viktor Frankl, etc.)
8. DO NOT translate source names (Stoïcisme → Stoicism, not translated phonetically)
9. PRESERVE technical terms that are universally understood

For Hebrew specifically:
- Use תיאור for "description"
- Use מסורת for "tradition" 
- Use דמות for "figure/character"
- Use תובנה for "insight"
- Use הארה for "enlightenment/illumination"

Return ONLY the translated content, no explanations.
''';

    final userPrompt = '''
Translate the following French AI prompt content to $languageName.

This is a "$promptType" prompt used in an introspective psychology application.

FRENCH CONTENT TO TRANSLATE:
$content

Remember:
- Keep all \$variables and \${expressions} intact
- Keep all formatting characters (═, ─, •, ❌, ✅, →)
- Keep all section markers and structure
- Translate naturally for native $languageName speakers

Translated content in $languageName:
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _anthropicVersion,
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 8000,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userPrompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'];
        if (content is List && content.isNotEmpty) {
          return content[0]['text'];
        }
      } else {
        print('❌ Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur HTTP: $e');
    }
    
    return null;
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // RECONSTRUCTION DU FICHIER DART
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Reconstruit le fichier Dart avec le contenu traduit
  String _reconstructDartFile(
    String originalDartContent, 
    String translatedContent,
    String targetLanguage,
  ) {
    // Remplacer le contenu entre ''' ... ''' par la traduction
    final regex = RegExp(r"'''[\s\S]*?'''", multiLine: true);
    
    var result = originalDartContent.replaceFirst(
      regex, 
      "'''\n$translatedContent\n'''",
    );
    
    // Mettre à jour le commentaire d'en-tête
    final languageName = targetLanguage == 'en' ? 'ENGLISH' : 'HEBREW';
    result = result.replaceFirst(
      RegExp(r'/// PROMPT.*\n'),
      '/// PROMPT - $languageName VERSION (AUTO-GENERATED)\n',
    );
    
    // Ajouter un avertissement de génération automatique
    final generatedWarning = '''
/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version and re-run the translation script:
///   dart run tools/generate_translated_prompts.dart
/// 
/// Generated: ${DateTime.now().toIso8601String()}
/// Language: $languageName
/// ════════════════════════════════════════════════════════════════════════════

''';
    
    result = generatedWarning + result;
    
    return result;
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // TRADUCTION DE TOUS LES PROMPTS
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Traduit tous les prompts français vers les langues cibles
  Future<Map<String, bool>> translateAllPrompts({
    required String masterDir,
    required String outputBaseDir,
    required List<String> targetLanguages,
  }) async {
    final results = <String, bool>{};
    
    final promptFiles = [
      'prompt_system_unifie.dart',
      'prompt_unifie.dart',
      'prompt_approfondissement.dart',
      'prompt_positive_thought.dart',
      'prompt_synthese.dart',
    ];
    
    for (final lang in targetLanguages) {
      print('\n════════════════════════════════════════════════════════════════');
      print('🌐 Traduction vers: ${lang == 'en' ? 'Anglais' : 'Hébreu'}');
      print('════════════════════════════════════════════════════════════════\n');
      
      for (final file in promptFiles) {
        final sourceFile = '$masterDir/$file';
        final outputFile = '$outputBaseDir/$lang/$file';
        
        final key = '$lang/$file';
        results[key] = await translatePromptFile(
          sourceFile: sourceFile,
          targetLanguage: lang,
          outputFile: outputFile,
        );
        
        // Pause entre les appels API pour éviter le rate limiting
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    return results;
  }
}

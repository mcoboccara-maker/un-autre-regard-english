/// SÉLECTEUR DE PROMPTS MULTILINGUE
/// 
/// Fichier : lib/config/prompts/prompt_selector.dart
/// Usage  : Sélectionne automatiquement le prompt dans la langue détectée
/// 
/// Ce sélecteur utilise :
/// 1. LanguageDetector pour détecter la langue du texte utilisateur
/// 2. Les prompts générés dans chaque langue (fr, en, he)

import '../../services/language_detector.dart';

// ════════════════════════════════════════════════════════════════════════════
// IMPORTS DES PROMPTS FRANÇAIS (MASTER)
// ════════════════════════════════════════════════════════════════════════════
import 'fr/prompt_system_unifie.dart' as fr_system;
import 'fr/prompt_unifie.dart' as fr_unifie;
import 'fr/prompt_approfondissement.dart' as fr_approfondissement;
import 'fr/prompt_positive_thought.dart' as fr_positive;
import 'fr/prompt_synthese.dart' as fr_synthese;

// ════════════════════════════════════════════════════════════════════════════
// IMPORTS DES PROMPTS ANGLAIS (GÉNÉRÉS)
// ════════════════════════════════════════════════════════════════════════════
import 'en/prompt_system_unifie.dart' as en_system;
import 'en/prompt_unifie.dart' as en_unifie;
import 'en/prompt_approfondissement.dart' as en_approfondissement;
import 'en/prompt_positive_thought.dart' as en_positive;
import 'en/prompt_synthese.dart' as en_synthese;

// ════════════════════════════════════════════════════════════════════════════
// IMPORTS DES PROMPTS HÉBREUX (GÉNÉRÉS)
// ════════════════════════════════════════════════════════════════════════════
import 'he/prompt_system_unifie.dart' as he_system;
import 'he/prompt_unifie.dart' as he_unifie;
import 'he/prompt_approfondissement.dart' as he_approfondissement;
import 'he/prompt_positive_thought.dart' as he_positive;
import 'he/prompt_synthese.dart' as he_synthese;

/// Sélecteur de prompts basé sur la langue détectée
class PromptSelector {
  
  /// Langue actuellement détectée (cache pour éviter les détections multiples)
  static String? _cachedLanguage;
  static String? _cachedText;
  
  // ════════════════════════════════════════════════════════════════════════════
  // DÉTECTION ET CACHE
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Détecte la langue et la met en cache
  static String detectAndCache(String userText) {
    // Si le texte est le même, retourner le cache
    if (_cachedText == userText && _cachedLanguage != null) {
      return _cachedLanguage!;
    }
    
    // Nouvelle détection
    _cachedText = userText;
    _cachedLanguage = LanguageDetector.detect(userText);
    
    final preview = userText.length > 50 ? '${userText.substring(0, 50)}...' : userText;
    print('PromptSelector: Langue détectée = $_cachedLanguage pour: "$preview"');
    
    return _cachedLanguage!;
  }
  
  /// Réinitialise le cache (à appeler lors d'une nouvelle génération)
  static void resetCache() {
    _cachedLanguage = null;
    _cachedText = null;
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // PROMPT SYSTEM
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Retourne le prompt system dans la langue appropriée
  static String getSystemPrompt(String userText) {
    final lang = detectAndCache(userText);
    
    switch (lang) {
      case LanguageDetector.english:
        return en_system.PromptSystemUnifie.content;
      case LanguageDetector.hebrew:
        return he_system.PromptSystemUnifie.content;
      default:
        return fr_system.PromptSystemUnifie.content;
    }
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // PROMPT UNIFIÉ (GÉNÉRATION PRINCIPALE)
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Retourne le prompt unifié dans la langue appropriée
  static String buildUnifiedPrompt({
    required String userText,
    String? userPrenom,
    required String userAge,
    String? userValeursSelectionnees,
    String? userValeursLibres,
    required String typeEntree,
    required String contenu,
    required String religions,
    required String litteratures,
    required String psychologies,
    required String philosophies,
    required String philosophes,
    String? historique30Jours,
    String? personnagesInterdits,
  }) {
    final lang = detectAndCache(userText);
    
    switch (lang) {
      case LanguageDetector.english:
        return en_unifie.PromptUnifie.build(
          userPrenom: userPrenom,
          userAge: userAge,
          userValeursSelectionnees: userValeursSelectionnees,
          userValeursLibres: userValeursLibres,
          typeEntree: typeEntree,
          contenu: contenu,
          religions: religions,
          litteratures: litteratures,
          psychologies: psychologies,
          philosophies: philosophies,
          philosophes: philosophes,
          historique30Jours: historique30Jours,
          personnagesInterdits: personnagesInterdits,
        );
      case LanguageDetector.hebrew:
        return he_unifie.PromptUnifie.build(
          userPrenom: userPrenom,
          userAge: userAge,
          userValeursSelectionnees: userValeursSelectionnees,
          userValeursLibres: userValeursLibres,
          typeEntree: typeEntree,
          contenu: contenu,
          religions: religions,
          litteratures: litteratures,
          psychologies: psychologies,
          philosophies: philosophies,
          philosophes: philosophes,
          historique30Jours: historique30Jours,
          personnagesInterdits: personnagesInterdits,
        );
      default:
        return fr_unifie.PromptUnifie.build(
          userPrenom: userPrenom,
          userAge: userAge,
          userValeursSelectionnees: userValeursSelectionnees,
          userValeursLibres: userValeursLibres,
          typeEntree: typeEntree,
          contenu: contenu,
          religions: religions,
          litteratures: litteratures,
          psychologies: psychologies,
          philosophies: philosophies,
          philosophes: philosophes,
          historique30Jours: historique30Jours,
          personnagesInterdits: personnagesInterdits,
        );
    }
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // PROMPT APPROFONDISSEMENT
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Retourne le prompt d'approfondissement dans la langue appropriée
  static String buildDeepeningPrompt({
    required String userText,
    required String penseeOriginale,
    required String reponseCourte,
    required String sourceNom,
    required String figureNom,
  }) {
    final lang = detectAndCache(userText);
    
    switch (lang) {
      case LanguageDetector.english:
        return en_approfondissement.PromptApprofondissement.build(
          penseeOriginale: penseeOriginale,
          reponseCourte: reponseCourte,
          sourceNom: sourceNom,
          figureNom: figureNom,
        );
      case LanguageDetector.hebrew:
        return he_approfondissement.PromptApprofondissement.build(
          penseeOriginale: penseeOriginale,
          reponseCourte: reponseCourte,
          sourceNom: sourceNom,
          figureNom: figureNom,
        );
      default:
        return fr_approfondissement.PromptApprofondissement.build(
          penseeOriginale: penseeOriginale,
          reponseCourte: reponseCourte,
          sourceNom: sourceNom,
          figureNom: figureNom,
        );
    }
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // PROMPT PENSÉE POSITIVE
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Retourne le prompt de pensée positive dans la langue appropriée
  static String buildPositiveThoughtPrompt({
    required String userText,
    String? userPrenom,
    required String userAge,
    String? userValeursSelectionnees,
    String? userValeursLibres,
    required String religions,
    required String litteratures,
    required String psychologies,
    required String philosophies,
    required String philosophes,
    required String sourceChoisie,
    String? penseeOuSituation,
    String? historique7Jours,
  }) {
    final lang = detectAndCache(userText);
    
    switch (lang) {
      case LanguageDetector.english:
        return en_positive.PromptPositiveThought.build(
          userPrenom: userPrenom,
          userAge: userAge,
          userValeursSelectionnees: userValeursSelectionnees,
          userValeursLibres: userValeursLibres,
          religions: religions,
          litteratures: litteratures,
          psychologies: psychologies,
          philosophies: philosophies,
          philosophes: philosophes,
          sourceChoisie: sourceChoisie,
          penseeOuSituation: penseeOuSituation,
          historique7Jours: historique7Jours,
        );
      case LanguageDetector.hebrew:
        return he_positive.PromptPositiveThought.build(
          userPrenom: userPrenom,
          userAge: userAge,
          userValeursSelectionnees: userValeursSelectionnees,
          userValeursLibres: userValeursLibres,
          religions: religions,
          litteratures: litteratures,
          psychologies: psychologies,
          philosophies: philosophies,
          philosophes: philosophes,
          sourceChoisie: sourceChoisie,
          penseeOuSituation: penseeOuSituation,
          historique7Jours: historique7Jours,
        );
      default:
        return fr_positive.PromptPositiveThought.build(
          userPrenom: userPrenom,
          userAge: userAge,
          userValeursSelectionnees: userValeursSelectionnees,
          userValeursLibres: userValeursLibres,
          religions: religions,
          litteratures: litteratures,
          psychologies: psychologies,
          philosophies: philosophies,
          philosophes: philosophes,
          sourceChoisie: sourceChoisie,
          penseeOuSituation: penseeOuSituation,
          historique7Jours: historique7Jours,
        );
    }
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // PROMPT SYNTHÈSE (LECTURE VOCALE)
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Retourne le system prompt de synthèse dans la langue appropriée
  static String getSynthesisSystemPrompt(String userText) {
    final lang = detectAndCache(userText);
    
    switch (lang) {
      case LanguageDetector.english:
        return en_synthese.PromptSynthese.systemPrompt;
      case LanguageDetector.hebrew:
        return he_synthese.PromptSynthese.systemPrompt;
      default:
        return fr_synthese.PromptSynthese.systemPrompt;
    }
  }
  
  /// Retourne le user prompt de synthèse dans la langue appropriée
  static String buildSynthesisUserPrompt({
    required String userText,
    required String sourceName,
    required String originalText,
  }) {
    final lang = detectAndCache(userText);
    
    switch (lang) {
      case LanguageDetector.english:
        return en_synthese.PromptSynthese.buildUserPrompt(
          sourceName: sourceName,
          originalText: originalText,
        );
      case LanguageDetector.hebrew:
        return he_synthese.PromptSynthese.buildUserPrompt(
          sourceName: sourceName,
          originalText: originalText,
        );
      default:
        return fr_synthese.PromptSynthese.buildUserPrompt(
          sourceName: sourceName,
          originalText: originalText,
        );
    }
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════════════════════════
  
  /// Retourne le code de langue actuellement en cache
  static String? get currentLanguage => _cachedLanguage;
  
  /// Retourne le nom de la langue actuellement en cache
  static String get currentLanguageName {
    if (_cachedLanguage == null) return 'Non détectée';
    return LanguageDetector.getLanguageName(_cachedLanguage!);
  }
  
  /// Force une langue spécifique (pour les tests)
  static void forceLanguage(String langCode) {
    _cachedLanguage = langCode;
    print('PromptSelector: Langue forcée à $langCode');
  }
}

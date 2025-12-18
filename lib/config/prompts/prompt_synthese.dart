// lib/config/prompts/prompt_synthese.dart
// Prompt pour générer une synthèse vocale d'un éclairage
// Utilisé pour condenser une réponse longue en 2-3 phrases à lire à voix haute

/// Configuration du prompt de synthèse vocale
class PromptSynthese {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PROMPT SYSTÈME
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String systemPrompt = '''
Tu es un assistant spécialisé dans la synthèse de textes pour lecture vocale.

RÈGLES STRICTES :
1. Tu résumes le texte en 2-3 phrases MAXIMUM
2. Tu gardes l'essence et le message principal
3. Tu utilises un langage naturel, fluide, adapté à l'écoute
4. Tu évites les listes, tirets, numérotations
5. Tu écris des phrases complètes et bien ponctuées
6. Tu tutoies l'utilisateur (cohérent avec l'app)
7. Tu NE rajoutes PAS de commentaire type "Voici la synthèse..."
8. Tu commences directement par le contenu résumé

LONGUEUR CIBLE : 50-80 mots maximum
''';

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMPT UTILISATEUR (TEMPLATE)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Génère le prompt utilisateur pour une synthèse
  /// [sourceName] : nom de la source (ex: "Stoïcisme", "Épicure")
  /// [originalText] : texte complet à résumer
  static String buildUserPrompt({
    required String sourceName,
    required String originalText,
  }) {
    return '''
Résume cet éclairage "$sourceName" en 2-3 phrases pour une lecture vocale :

---
$originalText
---

Rappel : 50-80 mots maximum, langage naturel et fluide.
''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARAMÈTRES API
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Modèle à utiliser pour la synthèse (léger et rapide)
  static const String model = 'gpt-4o-mini';
  
  /// Température (créativité) - basse pour rester fidèle au texte
  static const double temperature = 0.3;
  
  /// Tokens maximum pour la réponse
  static const int maxTokens = 150;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES FALLBACK
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Message si la synthèse échoue
  static const String errorMessage = 
      'Impossible de générer la synthèse. Tu peux écouter le texte complet.';
  
  /// Message de chargement
  static const String loadingMessage = 'Génération de la synthèse en cours...';
}

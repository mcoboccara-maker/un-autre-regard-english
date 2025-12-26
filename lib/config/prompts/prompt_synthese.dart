/// PROMPT SYNTHESE - GENERATION DE SYNTHESE VOCALE
/// 
/// Fichier : lib/config/prompts/prompt_synthese.dart
/// Usage  : Condenser une réponse longue en 2-3 phrases pour lecture vocale
/// Appelé : wisdom_wheel_screen.dart, streaming_results_screen.dart

class PromptSynthese {
  
  /// Modèle à utiliser pour la synthèse (plus léger = plus rapide)
  static const String model = 'claude-sonnet-4-5-20250929';
  
  /// Température basse pour une synthèse fidèle
  static const double temperature = 0.3;
  
  /// Tokens limités pour une synthèse courte
  static const int maxTokens = 150;
  
  /// Message d'erreur standard
  static const String errorMessage = 'Impossible de générer la synthèse vocale';
  
  /// System prompt pour la synthèse
  static const String systemPrompt = '''
Tu es un assistant de synthèse vocale.

Ta mission : condenser un texte long en 2-3 phrases essentielles,
adaptées à une lecture à voix haute.

Règles :
- Maximum 2-3 phrases courtes et fluides
- Conserver l'essence et le ton du texte original
- Pas de formules d'introduction ("Voici la synthèse...")
- Pas de listes à puces
- Style oral naturel, pas écrit
- Tutoiement si le texte original tutoie
- Garder les termes clés de la tradition/source mentionnée

Tu ne changes pas le sens, tu concentres.
''';

  /// Construire le user prompt pour la synthèse
  static String buildUserPrompt({
    required String sourceName,
    required String originalText,
  }) {
    return '''
SOURCE : $sourceName

TEXTE À SYNTHÉTISER :
$originalText

CONSIGNE :
Condense ce texte en 2-3 phrases essentielles pour une lecture vocale.
Garde le ton et les concepts clés de la source "$sourceName".
''';
  }
}

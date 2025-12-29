/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version in fr/prompt_synthese.dart
/// 
/// Language: ENGLISH
/// ════════════════════════════════════════════════════════════════════════════

/// SYNTHESIS PROMPT - VOICE SYNTHESIS GENERATION
/// 
/// File: lib/config/prompts/en/prompt_synthese.dart
/// Usage: Condense a long response into 2-3 sentences for voice reading
/// Called by: wisdom_wheel_screen.dart, streaming_results_screen.dart

class PromptSynthese {
  
  /// Model to use for synthesis (lighter = faster)
  static const String model = 'claude-sonnet-4-5-20250929';
  
  /// Low temperature for faithful synthesis
  static const double temperature = 0.3;
  
  /// Limited tokens for short synthesis
  static const int maxTokens = 150;
  
  /// Standard error message
  static const String errorMessage = 'Unable to generate voice synthesis';
  
  /// System prompt for synthesis
  static const String systemPrompt = '''
You are a voice synthesis assistant.

Your mission: condense a long text into 2-3 essential sentences,
adapted for reading aloud.

Rules:
- Maximum 2-3 short and fluid sentences
- Keep the essence and tone of the original text
- No introductory phrases ("Here is the summary...")
- No bullet points
- Natural oral style, not written
- Use informal address if the original text does
- Keep key terms from the tradition/source mentioned

You don't change the meaning, you concentrate.
''';

  /// Build the user prompt for synthesis
  static String buildUserPrompt({
    required String sourceName,
    required String originalText,
  }) {
    return '''
SOURCE: $sourceName

TEXT TO SYNTHESIZE:
$originalText

INSTRUCTION:
Condense this text into 2-3 essential sentences for voice reading.
Keep the tone and key concepts from the source "$sourceName".
''';
  }
}

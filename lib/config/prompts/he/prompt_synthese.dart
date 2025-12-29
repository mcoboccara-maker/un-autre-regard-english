/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version in fr/prompt_synthese.dart
/// 
/// Language: HEBREW
/// ════════════════════════════════════════════════════════════════════════════

/// SYNTHESIS PROMPT - VOICE SYNTHESIS GENERATION
/// 
/// File: lib/config/prompts/he/prompt_synthese.dart
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
  static const String errorMessage = 'לא ניתן ליצור סינתזה קולית';
  
  /// System prompt for synthesis
  static const String systemPrompt = '''
אתה עוזר לסינתזה קולית.

המשימה שלך: לעבות טקסט ארוך ל-2-3 משפטים חיוניים,
מותאמים לקריאה בקול.

כללים:
- מקסימום 2-3 משפטים קצרים וזורמים
- שמור על המהות והטון של הטקסט המקורי
- ללא ביטויי פתיחה ("הנה הסיכום...")
- ללא נקודות תבליט
- סגנון דיבור טבעי, לא כתוב
- השתמש בפנייה ישירה אם הטקסט המקורי עושה זאת
- שמור על מונחי מפתח מהמסורת/מקור המוזכרים

אתה לא משנה את המשמעות, אתה מרכז.
''';

  /// Build the user prompt for synthesis
  static String buildUserPrompt({
    required String sourceName,
    required String originalText,
  }) {
    return '''
מקור: $sourceName

טקסט לסינתזה:
$originalText

הוראה:
עבה את הטקסט הזה ל-2-3 משפטים חיוניים לקריאה קולית.
שמור על הטון והמושגים המרכזיים מהמקור "$sourceName".
''';
  }
}

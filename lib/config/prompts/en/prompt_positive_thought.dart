/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version in fr/prompt_positive_thought.dart
/// 
/// Language: ENGLISH
/// ════════════════════════════════════════════════════════════════════════════

/// POSITIVE THOUGHT PROMPT - INDEPENDENT GENERATION
/// 
/// File: lib/config/prompts/en/prompt_positive_thought.dart
/// Usage: Generate a short positive thought anchored in history
/// Called by: generatePositiveThought in ai_service.dart

class PromptPositiveThought {
  
  static String build({
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
    
    // Build history section if available
    final historiqueSection = (historique7Jours != null && historique7Jours.isNotEmpty)
        ? '''
RECENT HISTORY (last 7 days):
$historique7Jours
'''
        : 'No history available.';
    
    // Build values section
    final valeursSection = <String>[];
    if (userValeursSelectionnees != null && userValeursSelectionnees.isNotEmpty) {
      valeursSection.add('Chosen values: $userValeursSelectionnees');
    }
    if (userValeursLibres != null && userValeursLibres.isNotEmpty) {
      valeursSection.add('Personal values: $userValeursLibres');
    }
    final valeursTexte = valeursSection.isNotEmpty 
        ? valeursSection.join('\n') 
        : 'No values specified.';
    
    return '''
USER PROFILE
${userPrenom != null && userPrenom.isNotEmpty ? 'First name: $userPrenom' : ''}
Age: $userAge

VALUES
$valeursTexte

SELECTED SOURCES
- Spiritualities: $religions
- Literature: $litteratures
- Psychology: $psychologies
- Philosophy: $philosophies
- Philosophers: $philosophes

SOURCE CHOSEN FOR THIS STATEMENT: $sourceChoisie

$historiqueSection

INSTRUCTION

Generate ONE brief statement (1 to 3 sentences maximum)
that offers a sober and non-prescriptive illumination,
inspired by the selected source ($sourceChoisie).

This statement is not a response to a specific thought.
It fits within the continuity of what the person is going through,
as it appears in their recent history.

It does not seek to encourage, reassure, correct, or guide.

It aims only to resonate a voice,
an image, or a concept from the chosen source,
in connection with the dominant patterns observed in the history.

${userPrenom != null && userPrenom.isNotEmpty ? 'Use the first name $userPrenom and informal address.' : 'Use informal address.'}

Language: English
''';
  }
}

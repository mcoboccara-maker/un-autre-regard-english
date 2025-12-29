/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version in fr/prompt_positive_thought.dart
/// 
/// Language: HEBREW
/// ════════════════════════════════════════════════════════════════════════════

/// POSITIVE THOUGHT PROMPT - INDEPENDENT GENERATION
/// 
/// File: lib/config/prompts/he/prompt_positive_thought.dart
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
היסטוריה אחרונה (7 ימים אחרונים):
$historique7Jours
'''
        : 'אין היסטוריה זמינה.';
    
    // Build values section
    final valeursSection = <String>[];
    if (userValeursSelectionnees != null && userValeursSelectionnees.isNotEmpty) {
      valeursSection.add('ערכים שנבחרו: $userValeursSelectionnees');
    }
    if (userValeursLibres != null && userValeursLibres.isNotEmpty) {
      valeursSection.add('ערכים אישיים: $userValeursLibres');
    }
    final valeursTexte = valeursSection.isNotEmpty 
        ? valeursSection.join('\n') 
        : 'לא צוינו ערכים.';
    
    return '''
פרופיל משתמש
${userPrenom != null && userPrenom.isNotEmpty ? 'שם פרטי: $userPrenom' : ''}
גיל: $userAge

ערכים
$valeursTexte

מקורות שנבחרו
- רוחניות: $religions
- ספרות: $litteratures
- פסיכולוגיה: $psychologies
- פילוסופיה: $philosophies
- פילוסופים: $philosophes

מקור שנבחר להצהרה זו: $sourceChoisie

$historiqueSection

הוראה

צור הצהרה אחת קצרה (1 עד 3 משפטים מקסימום)
שמציעה הארה מאופקת ולא מכוונת,
בהשראת המקור שנבחר ($sourceChoisie).

הצהרה זו אינה תגובה למחשבה ספציפית.
היא משתלבת בהמשכיות של מה שהאדם עובר,
כפי שזה מופיע בהיסטוריה האחרונה שלו.

היא לא מחפשת לעודד, להרגיע, לתקן או להכוון.

היא שואפת רק להדהד קול,
תמונה או מושג מהמקור שנבחר,
בקשר עם הדפוסים הדומיננטיים שנצפו בהיסטוריה.

${userPrenom != null && userPrenom.isNotEmpty ? 'השתמש בשם הפרטי $userPrenom ובפנייה ישירה.' : 'השתמש בפנייה ישירה.'}

שפה: עברית
''';
  }
}

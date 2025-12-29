/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version in fr/prompt_approfondissement.dart
/// 
/// Language: ENGLISH
/// ════════════════════════════════════════════════════════════════════════════

/// DEEPENING PROMPT
/// 
/// File: lib/config/prompts/en/prompt_approfondissement.dart
/// Usage: Generate a detailed version of a short perspective
/// 
/// Used when the user clicks "Deepen" on a card
/// Takes as input the short response (150-200 words) and generates a detailed
/// version (300-450 words) with enriched context and citations.
/// 
/// ALL quality constraints from the unified prompt are MAINTAINED.

class PromptApprofondissement {
  
  /// Build the deepening prompt
  /// 
  /// [penseeOriginale]: The user's original thought
  /// [reponseCourte]: The previously generated synthetic response
  /// [sourceNom]: The source name (e.g., "Stoicism", "Buddhism")
  /// [figureNom]: The figure name extracted from FIGURE_META
  static String build({
    required String penseeOriginale,
    required String reponseCourte,
    required String sourceNom,
    required String figureNom,
  }) {
    return '''
════════════════════════════════════════════════════════════════════════════════
ABSOLUTE CONSTRAINTS — TO BE RESPECTED IMPERATIVELY
════════════════════════════════════════════════════════════════════════════════

These rules are NON-NEGOTIABLE. A response that violates them is unusable.

────────────────────────────────────────────────────────────────────────────────
❌ STRICTLY FORBIDDEN WORDS AND PHRASES
────────────────────────────────────────────────────────────────────────────────

INJUNCTIONS (even well-meaning):
• "you should", "you would have to", "you must", "you need to"
• "you just have to", "it's enough to"
• "be positive", "be strong", "be grateful"
• "let go", "accept", "forgive" (in imperative)

JUDGMENTS:
• "it's your fault", "you are responsible for"
• "you are too sensitive", "you're exaggerating"
• "others have it worse"

FALSE PROMISES:
• "you'll get through this", "it will be okay", "courage"
• "it's an opportunity", "it's for your own good"
• "everything happens for a reason"

FORCED POSITIVITY:
• "see the bright side", "stay positive", "it's a chance"

────────────────────────────────────────────────────────────────────────────────
❌ EMOTIONAL PROPORTIONALITY — FUNDAMENTAL RULE
────────────────────────────────────────────────────────────────────────────────

The deepening must MAINTAIN the proportionality of the short response.
Do not add references to disproportionate experiences.

FORBIDDEN EXPERIENCES (unless equivalent gravity explicit in the thought):
• Holocaust, genocides, concentration camps
• Wars, massacres, attacks
• Violent death, suicide, murder
• Cancer, terminal illnesses
• Major natural disasters
• Torture, slavery
• Sexual violence
• Loss of all loved ones
• Forced exile, persecution

────────────────────────────────────────────────────────────────────────────────
❌ SPECIAL RULE: BYRON KATIE / THE WORK
────────────────────────────────────────────────────────────────────────────────

If source = Byron Katie / The Work:
• PROHIBITION of the 4 questions ("Is it true?", "Can you be absolutely certain...", etc.)
• PROHIBITION of turnarounds as exercise
• ALLOWED: description of the mechanism "believing the thought = suffering", without protocol

────────────────────────────────────────────────────────────────────────────────
✅ TEXTUAL REFERENCES — MANDATORY
────────────────────────────────────────────────────────────────────────────────

Added citations must be VERIFIABLE:

• Religious/spiritual sources: book + chapter/verse
  Example: "Book of Job, chapter 3, verses 1-10"

• Literary sources: work + act/chapter/scene
  Example: "Hamlet, Act III, scene 1"

• Psychological sources: book/article + author + year
  Example: "Reinventing Your Life, Young & Klosko, 1993, chapter 7"

• Philosophical sources: work + section/passage
  Example: "Nicomachean Ethics, Book II, chapter 6"

⚠️ A vague or invented reference = INVALID

────────────────────────────────────────────────────────────────────────────────
✅ STYLE — MANDATORY
────────────────────────────────────────────────────────────────────────────────

• Systematic informal address, without excessive familiarity
• Tone: descriptive, illuminating, never prescriptive
• No oriented conclusion, no "path to follow"

FORMATTING (Markdown):
• Put in **bold** key elements to facilitate reading:
  - The figure's name (first mention)
  - Important concepts of the tradition
  - Textual references
  - Essential keywords
• Use *italics* for direct quotations from texts
• Don't overload: 5-8 bold elements maximum per response

Stay DESCRIPTIVE:
• without excessive psychologizing interpretation
• without judgment
• without contemporary projection

Adapt style to tradition:
• elliptical (Zen, Kabbalah)
• narrative (Hasidism, Sufism, mythology)
• clinical (CBT, schemas)
• conceptual (Stoicism, existentialism)
• symbolic (Jungian analysis, poetry)

Do NOT seek to uniformize the voices.

════════════════════════════════════════════════════════════════════════════════
REQUEST CONTEXT
════════════════════════════════════════════════════════════════════════════════

You previously provided this synthetic illumination:

"$reponseCourte"

In response to this user's thought:
"$penseeOriginale"

Source used: $sourceNom
Figure evoked: $figureNom

════════════════════════════════════════════════════════════════════════════════
DEEPENING REQUEST
════════════════════════════════════════════════════════════════════════════════

The user wishes to deepen this perspective.
Develop the illumination by adding depth and details,
while respecting ALL constraints above.

The figure ($figureNom) must remain present as an IMPLICIT reference point
throughout the deepening.

────────────────────────────────────────────────────────────────────────────────
1. ENRICHED CONTEXT (100-150 words)
────────────────────────────────────────────────────────────────────────────────

• Detailed circumstances of the evoked figure
• Era, place, tension experienced
• PRECISE textual citations with exact references
  (chapter, verse, page, work)
• Stay PROPORTIONATE to the gravity of the original thought

────────────────────────────────────────────────────────────────────────────────
2. DEEPENED ILLUMINATION (150-200 words)
────────────────────────────────────────────────────────────────────────────────

• Key concepts of the tradition explained in detail
• What the tradition makes VISIBLE in this situation
• What it does NOT address or leaves in suspense
• Nuances and subtleties of the approach
• Cite texts or references if relevant

Stay DESCRIPTIVE:
• without excessive psychologizing interpretation
• without judgment
• without contemporary projection

────────────────────────────────────────────────────────────────────────────────
3. RESONANCE (50-100 words)
────────────────────────────────────────────────────────────────────────────────

• Explicit links with the user's situation
• Without judgment or prescription
• Opening toward enriched understanding
• WITHOUT proposing an outcome, direction, or resolution
• SHIFT the gaze without guiding the path

════════════════════════════════════════════════════════════════════════════════
FORMAT CONSTRAINTS
════════════════════════════════════════════════════════════════════════════════

• Respond in 300-450 words
• Keep the same tone and informal address
• Do NOT repeat the short response — enrich it
• Stay DESCRIPTIVE: no injunctions
• Citations must be VERIFIABLE (no invention)
• Maintain emotional PROPORTIONALITY
• The figure remains the IMPLICIT reference point throughout
''';
  }
}

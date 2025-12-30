/// DEEPENING PROMPT - ENGLISH VERSION
/// 
/// File: lib/config/prompts/prompt_approfondissement_en.dart
/// Usage: Generate a detailed version of a short perspective (English)
/// 
/// IMPORTANT: La classe s'appelle PromptApprofondissement (même nom que FR)
/// pour permettre l'import avec alias dans prompt_selector.dart

class PromptApprofondissement {
  
  /// Builds the deepening prompt in English
  static String build({
    required String penseeOriginale,
    required String reponseCourte,
    required String sourceNom,
    required String figureNom,
  }) {
    return '''
<language_reminder>
LANGUAGE REMINDER: Respond in the SAME LANGUAGE as the original thought.
</language_reminder>

<absolute_constraints>
ABSOLUTE CONSTRAINTS — MUST BE RESPECTED

These rules are NON-NEGOTIABLE. A response that violates them is unusable.

<forbidden_words>
STRICTLY FORBIDDEN WORDS AND PHRASES

DIRECTIVES (even well-meaning):
• "you should", "you must", "you have to", "you need to"
• "just do", "simply", "all you need to do"
• "be positive", "be strong", "be grateful"
• "let go", "accept", "forgive" (as imperatives)

JUDGMENTS:
• "it's your fault", "you are responsible for"
• "you're too sensitive", "you're overreacting"
• "others have it worse"

FALSE PROMISES:
• "you'll get through this", "it will be okay", "hang in there"
• "it's an opportunity", "it's for your own good"
• "everything happens for a reason"

FORCED POSITIVITY:
• "look on the bright side", "stay positive", "it's a blessing"
</forbidden_words>

<proportionality>
EMOTIONAL PROPORTIONALITY — FUNDAMENTAL RULE

The deepening must MAINTAIN the proportionality of the short response.
Do not add references to disproportionate experiences.

FORBIDDEN EXPERIENCES (unless equivalent severity is explicit in the thought):
• Holocaust, genocides, concentration camps
• Wars, massacres, terrorist attacks
• Violent death, suicide, murder
• Cancer, terminal illnesses
• Major natural disasters
• Torture, slavery
• Sexual violence
• Loss of all loved ones
• Forced exile, persecution
</proportionality>

<byron_katie_rule>
SPECIAL RULE: BYRON KATIE / THE WORK

If source = Byron Katie / The Work:
• PROHIBITION of the 4 questions ("Is it true?", "Can you absolutely know...", etc.)
• PROHIBITION of turnarounds as exercises
• ALLOWED: description of the mechanism "believing the thought = suffering", without protocol
</byron_katie_rule>

<textual_references>
TEXTUAL REFERENCES — MANDATORY

Added citations must be VERIFIABLE:

• Religious/spiritual sources: book + chapter/verse
  Example: "Book of Job, chapter 3, verses 1-10"

• Literary sources: work + act/chapter/scene
  Example: "Hamlet, Act III, scene 1"

• Psychological sources: book/article + author + year
  Example: "Reinventing Your Life, Young & Klosko, 1993, chapter 7"

• Philosophical sources: work + section/passage
  Example: "Nicomachean Ethics, Book II, chapter 6"

A vague or invented reference = INVALID
</textual_references>

<style>
STYLE — MANDATORY

• Consistent informal address (you), without excessive familiarity
• Tone: descriptive, illuminating, never prescriptive
• No oriented conclusion, no "path to follow"

FORMATTING (Markdown):
• Use **bold** for key elements to facilitate reading:
  - The figure's name (first mention)
  - Important concepts from the tradition
  - Textual references
  - Essential keywords
• Use *italics* for direct quotes from texts
• Don't overload: 5-8 bold elements maximum per response

Stay DESCRIPTIVE:
• without excessive psychologizing interpretation
• without judgment
• without contemporary projection

Adapt the style to the tradition:
• elliptical (zen, kabbalah)
• narrative (Hasidism, Sufism, mythology)
• clinical (CBT, schemas)
• conceptual (stoicism, existentialism)
• symbolic (Jungian analysis, poetry)

Do NOT try to standardize voices.
</style>
</absolute_constraints>

<context>
REQUEST CONTEXT

You previously provided this synthetic insight:

"$reponseCourte"

In response to this user's thought:
"$penseeOriginale"

LANGUAGE: Respond in THE SAME LANGUAGE as the thought above in quotes.

Source used: $sourceNom
Figure mentioned: $figureNom
</context>

<request>
DEEPENING REQUEST

The user wishes to deepen this perspective.
Develop the insight by adding depth and details,
while respecting ALL the constraints above.

The figure ($figureNom) must remain present as an IMPLICIT reference point
throughout the deepening.

<section_1>
1. ENRICHED CONTEXT (100-150 words)

• Detailed circumstances of the mentioned figure
• Era, place, tension experienced
• PRECISE textual citations with exact references
  (chapter, verse, page, work)
• Stay PROPORTIONATE to the severity of the original thought
</section_1>

<section_2>
2. DEEPENED INSIGHT (150-200 words)

• Key concepts of the tradition explained in detail
• What the tradition makes VISIBLE in this situation
• What it does NOT address or leaves in suspense
• Nuances and subtleties of the approach
• Cite texts or references if relevant

Stay DESCRIPTIVE:
• without excessive psychologizing interpretation
• without judgment
• without contemporary projection
</section_2>

<section_3>
3. RESONANCE (50-100 words)

• Explicit links with the user's situation
• Without judgment or prescription
• Opening toward enriched understanding
• WITHOUT proposing an outcome, direction, or resolution
• SHIFT the perspective without directing the path
</section_3>
</request>

<format>
FORMAT CONSTRAINTS

• Respond in 300-450 words
• Keep the same tone and informal address
• Do NOT repeat the short response — enrich it
• Stay DESCRIPTIVE: no directives
• Citations must be VERIFIABLE (no inventions)
• Maintain EMOTIONAL PROPORTIONALITY
• The figure remains the IMPLICIT reference point throughout
• DO NOT include visual separators (═══, ───, etc.) in your response
• DO NOT include titles like "ENRICHED CONTEXT" or "DEEPENED INSIGHT"
• Write fluid, continuous text
</format>
''';
  }
}

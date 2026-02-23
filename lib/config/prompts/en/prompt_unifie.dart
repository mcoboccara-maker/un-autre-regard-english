/// ════════════════════════════════════════════════════════════════════════════
/// ⚠️  AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// This file was automatically generated from the French master file.
/// To modify, edit the French version in fr/prompt_unifie.dart
/// 
/// Language: ENGLISH
/// ════════════════════════════════════════════════════════════════════════════

/// UNIFIED PROMPT - GENERATION WITH INTEGRATED CONSTRAINTS
/// 
/// File: lib/config/prompts/en/prompt_unifie.dart
/// Usage: Generate illuminations with integrated quality control (1 API call)
/// 
/// Optimized for Claude (Anthropic) - Constraints are placed UPSTREAM
/// to ensure compliance from generation.
/// 
/// VERSION 2.0: Condensed structure (3 sections instead of 6) + 150-200 words limit
/// ALL quality constraints are FULLY PRESERVED.

class PromptUnifie {
  
  static String build({
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
    String? emotionsActuelles,
    int? intensiteEmotionnelle,
  }) {

    // ══════════════════════════════════════════════════════════════════════
    // BUILD USER CONTEXT
    // ══════════════════════════════════════════════════════════════════════

    final contexteParts = <String>[];
    if (userPrenom != null && userPrenom.isNotEmpty) {
      contexteParts.add('My name is $userPrenom');
    }
    if (userAge != 'Non renseigne' && userAge.isNotEmpty) {
      contexteParts.add('I am $userAge years old');
    }
    if (userValeursSelectionnees != null && userValeursSelectionnees.isNotEmpty) {
      contexteParts.add('my values are: $userValeursSelectionnees');
    }

    final contexteUtilisateur = contexteParts.isNotEmpty
        ? '${contexteParts.join(', ')}.\n\n'
        : '';

    // ══════════════════════════════════════════════════════════════════════
    // BUILD EMOTIONAL CONTEXT
    // ══════════════════════════════════════════════════════════════════════

    final contexteEmotionnel = (emotionsActuelles != null && emotionsActuelles.isNotEmpty)
        ? '''

────────────────────────────────────────────────────────────────────────────────
USER'S CURRENT EMOTIONAL STATE
────────────────────────────────────────────────────────────────────────────────

Emotions felt: $emotionsActuelles
Overall intensity: ${intensiteEmotionnelle ?? 5}/10

The user's emotional state must influence your response:
1. FIGURE CHOICE: favor a figure who went through an experience that resonates
   with this emotional state. The figure must be able to "speak" to someone
   who feels these emotions.
2. ILLUMINATION TONE: adapt the depth and sensitivity to the emotional
   intensity level. The higher the intensity, the more welcoming and
   non-intrusive the tone should be. NEVER minimize the emotion.

'''
        : '';
    
    // ══════════════════════════════════════════════════════════════════════
    // BUILD ACTIVE SOURCES LIST
    // ══════════════════════════════════════════════════════════════════════
    
    final sourcesList = <String>[];
    if (religions != 'Aucune' && religions != 'Aucune selectionnee' && religions != 'None' && religions.isNotEmpty) {
      sourcesList.add(religions);
    }
    if (litteratures != 'Aucun' && litteratures != 'Aucun selectionne' && litteratures != 'None' && litteratures.isNotEmpty) {
      sourcesList.add(litteratures);
    }
    if (psychologies != 'Aucune' && psychologies != 'Aucune selectionnee' && psychologies != 'None' && psychologies.isNotEmpty) {
      sourcesList.add(psychologies);
    }
    if (philosophies != 'Aucun' && philosophies != 'Aucun selectionne' && philosophies != 'None' && philosophies.isNotEmpty) {
      sourcesList.add(philosophies);
    }
    if (philosophes != 'Aucun' && philosophes != 'Aucun selectionne' && philosophes != 'None' && philosophes.isNotEmpty) {
      sourcesList.add(philosophes);
    }
    
    final sourcesTexte = sourcesList.join(', ');
    
    // ══════════════════════════════════════════════════════════════════════
    // BUILD DYNAMIC CONSTRAINTS
    // ══════════════════════════════════════════════════════════════════════
    
    final contraintesPersonnages = personnagesInterdits != null && personnagesInterdits.isNotEmpty
        ? '\n• $personnagesInterdits'
        : '\n• None for now';
    
    final styleTutoiement = userPrenom != null && userPrenom.isNotEmpty 
        ? 'using informal address and the first name $userPrenom (once per section maximum)'
        : 'using informal address';
    
    final contexteHistorique = historique30Jours != null && historique30Jours.isNotEmpty
        ? '''

────────────────────────────────────────────────────────────────────────────────
CONTEXT: REFLECTIONS FROM THE LAST 30 DAYS
────────────────────────────────────────────────────────────────────────────────

$historique30Jours

────────────────────────────────────────────────────────────────────────────────
USE OF THIS HISTORY
────────────────────────────────────────────────────────────────────────────────

1. PATTERNS
   If you observe a thematic recurrence
   (e.g., loneliness returns in different forms,
   the question of control appears multiple times),
   you may note it SOBERLY in the REFORMULATION section.
   No psychologizing interpretation — just an observation.

2. EVOLUTION
   If you perceive a movement over time
   (e.g., transition from anger to sadness,
   or from external complaint to internal questioning),
   you may NAME it without judging or guiding.

3. COHERENCE
   Avoid proposing an illumination that ignores
   what the person has already explored.
   The history allows you not to start from zero.

4. RESONANCE
   If the current thought echoes a past thought,
   you may create a DISCRETE link between them,
   without forcing the connection.

You are NOT required to mention the history explicitly.
But it must INFORM your response silently,
like a memory of what this person is going through.

'''
        : '';
    
    // ══════════════════════════════════════════════════════════════════════
    // UNIFIED PROMPT
    // ══════════════════════════════════════════════════════════════════════
    
    return '''
════════════════════════════════════════════════════════════════════════════════
LENGTH CONSTRAINT — MANDATORY
════════════════════════════════════════════════════════════════════════════════

Respond in 200-260 words MAXIMUM (excluding FIGURE_META metadata).
Be concise and impactful. Every word must add value.
A response that is too long will be rejected.

════════════════════════════════════════════════════════════════════════════════
ABSOLUTE CONSTRAINTS — TO BE RESPECTED IMPERATIVELY DURING GENERATION
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
❌ STRICTLY FORBIDDEN FIGURES
────────────────────────────────────────────────────────────────────────────────

Founders/theorists can NEVER be used as "characters":

PSYCHOLOGY & THERAPY:
• Byron Katie (The Work) — use patient/case examples
• Carl Rogers (humanism) — use clinical cases
• Viktor Frankl (logotherapy) — use clinical cases, NOT his personal experience
• Sigmund Freud (psychoanalysis) — use clinical cases (Anna O., Dora, etc.)
• Carl Jung (analytical) — use archetypes or cases
• Aaron Beck (CBT) — use clinical cases
• Jeffrey Young (schemas) — use clinical cases

SPIRITUALITIES:
• Buddha (Buddhism) — use disciples, Jataka figures, monks
• Jesus (Christianity) — use apostles, saints, biblical figures
• Muhammad (Islam) — use companions, Sufi figures, Quranic stories
• Isaac Luria (Kabbalah) — use figures from Kabbalistic narratives
• Israel Salanter (Mussar) — use figures from ethical narratives

PHILOSOPHERS (do not use as character of their own school):
• A philosopher cannot illustrate their own philosophy
• Use conceptual figures, fictional situations, or representative characters

RECENTLY USED CHARACTERS (forbidden for 30 days):$contraintesPersonnages

────────────────────────────────────────────────────────────────────────────────
❌ EMOTIONAL PROPORTIONALITY — FUNDAMENTAL RULE
────────────────────────────────────────────────────────────────────────────────

The chosen figure and their experience must be PROPORTIONATE to the gravity
of the user's thought or situation.

PRINCIPLE: The intensity of the ordeal lived by the figure must correspond
to the intensity of the difficulty expressed by the user.

EXAMPLES OF DISPROPORTION TO AVOID:

Light/moderate thought:
• "I lost my iPhone"
  ❌ Job losing all his possessions, children, and health
  ✅ A character who lost an object they cherished

• "I'm leaving my job and I'm apprehensive"
  ❌ Frankl and the concentration camps
  ❌ An exile fleeing persecution
  ✅ A character facing a chosen life change

• "I feel a bit empty these days"
  ❌ Survivors of major traumas
  ❌ Tragic bereavements
  ✅ A character going through an ordinary period of questioning

ABSOLUTELY FORBIDDEN EXPERIENCES (unless equivalent explicit gravity):
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
• PROHIBITION of using Byron Katie as a character
• ALLOWED: description of the mechanism "believing the thought = suffering", without protocol

────────────────────────────────────────────────────────────────────────────────
✅ SOURCE ↔ FIGURE COHERENCE — MANDATORY
────────────────────────────────────────────────────────────────────────────────

Any cited figure MUST belong STRICTLY to the declared source.

Examples of INCONSISTENCIES to avoid:
• Job → Judaism only (not Stoicism, not Christianity as main figure)
• Buddha → Buddhism only (not generic "Eastern wisdom")
• Hamlet → literature/tragedy (not psychoanalysis, unless explicit Freudian analysis)
• Raskolnikov → Russian literature (not direct existentialist philosophy)
• Sisyphus → mythology/Camus (not Stoicism)

────────────────────────────────────────────────────────────────────────────────
✅ PRECISE TEXTUAL REFERENCE — MANDATORY
────────────────────────────────────────────────────────────────────────────────

Each figure MUST have AT LEAST ONE precise reference:

• Religious/spiritual sources: book + chapter/verse
  Example: "Book of Job, chapter 3, verses 1-10"

• Literary sources: work + act/chapter/scene
  Example: "Hamlet, Act III, scene 1"

• Psychological sources: book/article + author + year
  Example: "Reinventing Your Life, Young & Klosko, 1993, chapter 7"

• Philosophical sources: work + section/passage
  Example: "Nicomachean Ethics, Book II, chapter 6"

⚠️ A vague reference ("in the tradition", "according to texts") = INVALID

────────────────────────────────────────────────────────────────────────────────
✅ STYLE — MANDATORY
────────────────────────────────────────────────────────────────────────────────

• Systematic informal address, without excessive familiarity
• The first name (if provided): once per section maximum
• Tone: descriptive, illuminating, never prescriptive
• No oriented conclusion, no "path to follow"

FORMATTING (Markdown):
• Put in **bold** key elements to facilitate reading:
  - The figure's name (first mention)
  - Important concepts from the tradition
  - Textual references
  - Essential keywords of the final reformulation
• Use *italics* for direct quotations from texts
• Don't overload: 3-5 bold elements maximum per response

────────────────────────────────────────────────────────────────────────────────
✅ MINIMAL FORMAT — MANDATORY
────────────────────────────────────────────────────────────────────────────────

The response MUST obligatorily contain:
• At least 1 figure/character OR 1 clinical case OR 1 clearly identified scene
• At least 1 precise textual reference (see rule above)
• A comprehensible structure following the 3 requested sections

Without these elements, the response is unusable.

════════════════════════════════════════════════════════════════════════════════
USER REQUEST
════════════════════════════════════════════════════════════════════════════════
$contexteHistorique
${contexteUtilisateur}${contexteEmotionnel}My thought, situation or dilemma: "$contenu"

Source to use: $sourcesTexte

════════════════════════════════════════════════════════════════════════════════
GENERATION INSTRUCTIONS
════════════════════════════════════════════════════════════════════════════════

From the thought, situation, or question submitted,
mobilize ONE embodied figure belonging STRICTLY
to the tradition or source indicated above.

────────────────────────────────────────────────────────────────────────────────
PRELIMINARY STEP: IDENTIFICATION OF THE UNIVERSAL MOTIF
────────────────────────────────────────────────────────────────────────────────

BEFORE choosing a figure, identify the UNIVERSAL MOTIF underlying
the user's thought.

The universal motif is the fundamental and timeless human experience
hidden behind the concrete situation expressed.

Examples of transposition:
• "I lost my iPhone" → attachment to possessions / vulnerability to loss
• "My colleague got the promotion" → jealousy / sense of injustice
• "I can't decide" → paralysis facing choice / fear of error
• "Nobody understands me" → existential loneliness / quest for recognition
• "I lied to my friend" → guilt / tension between truth and protection
• "I don't know who I am anymore" → identity crisis / loss of bearings

This universal motif will help find a figure from the tradition
who lived an ANALOGOUS tension, even in a radically different context.

⚠️ ATTENTION TO PROPORTIONALITY:
The universal motif must also account for the INTENSITY of the thought.
The same family of motifs (e.g., "loss") can range from slight inconvenience
to deep grief. The chosen figure must match this intensity.

⚠️ ABSOLUTE REQUIREMENT:
The chosen figure MUST embody the identified universal motif.
If the figure is clearly off-motif → DO NOT use it, find another figure.
If no figure from the source matches the motif → indicate it explicitly.

────────────────────────────────────────────────────────────────────────────────
FIGURE SELECTION CRITERION
────────────────────────────────────────────────────────────────────────────────

The figure should NOT be chosen for:
• their historical importance
• their notoriety
• their general symbolic value

They must be chosen ONLY because they have:
• explicitly lived
• formulated
• or embodied

a thought, complaint, inability, or tension
ANALOGOUS to the one expressed by the user,
even symbolically.

It is not about explaining a doctrine,
but showing what this tradition makes VISIBLE
in a human situation like this one.

────────────────────────────────────────────────────────────────────────────────
TYPE OF FIGURE ACCORDING TO SOURCE
────────────────────────────────────────────────────────────────────────────────

SPIRITUAL OR RELIGIOUS SOURCES:
→ Character from sacred texts, traditional narratives, or classical religious literature
→ NEVER a theologian, commentator, or modern author

LITERARY SOURCES:
→ FICTIONAL character from the work
→ NEVER the author themselves

PHILOSOPHICAL SOURCES:
→ Conceptual figure, fictional situation, or imaginary representative character of a dilemma
→ NEVER the philosopher themselves (unless explicitly requested)

PSYCHOLOGICAL OR THERAPEUTIC SOURCES:
→ Fictional or anonymized clinical case
→ NEVER the founder, theorist, or creator of the method

If no compliant figure is possible for this source,
indicate it clearly rather than forcing an unsuitable figure.

════════════════════════════════════════════════════════════════════════════════
RESPONSE STRUCTURE — 5 SECTIONS (200-260 words total)
════════════════════════════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────────────────────────
1. UNIVERSAL MOTIF (15-25 words)
────────────────────────────────────────────────────────────────────────────────

Name in 1-2 sentences the universal and timeless human thread
hidden behind the submitted thought.

────────────────────────────────────────────────────────────────────────────────
2. THE FIGURE (30-40 words)
────────────────────────────────────────────────────────────────────────────────

Present the chosen figure. Describe their context: who, era, tension experienced.
Indicate WHY this figure is retained: what tension they lived or formulated
in DIRECT resonance with the universal motif.

SHARED VALUES (conditional):
If the user declared values AND the figure factually shares one or more
IN ITS TRADITION OF ORIGIN → mention it as a fact of the tradition, NOT flattery.
Format: "[Figure], for whom [value] meant [precise meaning in this tradition]..."
FORBIDDEN: "Like you, they believed in...", any mirror or validating formulation.
If NO value resonates factually → SAY NOTHING.

────────────────────────────────────────────────────────────────────────────────
3. PRECISE REFERENCE & CONTEXT (20-30 words)
────────────────────────────────────────────────────────────────────────────────

Give the PRECISE TEXTUAL REFERENCE (mandatory):
book + chapter + verse, or work + act/chapter, or clinical case + publication.

────────────────────────────────────────────────────────────────────────────────
4. ILLUMINATION & REFORMULATION (70-90 words)
────────────────────────────────────────────────────────────────────────────────

• What the tradition makes VISIBLE in this situation
• Key concepts, distinctions, or notions
• What the tradition does NOT seek to resolve

Stay DESCRIPTIVE. Adapt style to tradition.
End by reformulating the user's thought in the language SPECIFIC to this tradition,
$styleTutoiement. This reformulation SHIFTS the gaze without guiding the path.

────────────────────────────────────────────────────────────────────────────────
5. THE SOURCE'S GAZE (40-60 words)
────────────────────────────────────────────────────────────────────────────────

Formulate 1-2 questions that THIS illumination generates —
not this source in general.

VALIDITY TEST: if this question could appear in another illumination
of the same source on a different thought, it is too generic — reformulate.

FORBIDDEN: rhetorical questions with implicit positive answer,
questions presupposing growth or action, generic questions.
ALLOWED: conceptual tensions the tradition reveals in THIS CASE,
questions left open without expected answer.

────────────────────────────────────────────────────────────────────────────────
4. FIGURE METADATA (for historization) — MANDATORY
────────────────────────────────────────────────────────────────────────────────

At the very end of your response, OBLIGATORILY add a metadata line
in the following format (this line will be extracted automatically):

[FIGURE_META]
nom: <exact name of the figure>
source: <source used>
reference: <precise textual reference>
motif: <identified universal motif>
[/FIGURE_META]

Example:
[FIGURE_META]
nom: Martha of Bethany
source: Christianity
reference: Gospel of Luke, chapter 10, verses 38-42
motif: Inner agitation facing responsibilities
[/FIGURE_META]

This section is MANDATORY and helps avoid re-proposing
the same figure to the user for 30 days.
''';
  }
}

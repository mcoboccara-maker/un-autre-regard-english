/// PROMPT APPROFONDISSEMENT
/// 
/// Fichier : lib/config/prompts/prompt_approfondissement.dart
/// Usage  : Générer une version détaillée d'une perspective courte
/// 
/// Utilisé quand l'utilisateur clique sur "Approfondir" sur une carte
/// Prend en entrée la réponse courte (150-200 mots) et génère une version
/// détaillée (300-450 mots) avec contexte enrichi et citations.
/// 
/// TOUTES les contraintes de qualité du prompt unifié sont REPRISES.

class PromptApprofondissement {
  
  /// Construit le prompt d'approfondissement
  /// 
  /// [penseeOriginale] : La pensée initiale de l'utilisateur
  /// [reponseCourte] : La réponse synthétique générée précédemment
  /// [sourceNom] : Le nom de la source (ex: "Stoïcisme", "Bouddhisme")
  /// [figureNom] : Le nom de la figure extraite de FIGURE_META
  static String build({
    required String penseeOriginale,
    required String reponseCourte,
    required String sourceNom,
    required String figureNom,
  }) {
    return '''
════════════════════════════════════════════════════════════════════════════════
🌐 RAPPEL LANGUE : Réponds dans la MÊME LANGUE que la pensée originale.
════════════════════════════════════════════════════════════════════════════════

════════════════════════════════════════════════════════════════════════════════
CONTRAINTES ABSOLUES — À RESPECTER IMPÉRATIVEMENT
════════════════════════════════════════════════════════════════════════════════

Ces règles sont NON NÉGOCIABLES. Une réponse qui les viole est inutilisable.

────────────────────────────────────────────────────────────────────────────────
❌ MOTS ET TOURNURES STRICTEMENT INTERDITS
────────────────────────────────────────────────────────────────────────────────

INJONCTIONS (même bienveillantes) :
• "tu devrais", "il faudrait", "tu dois", "il faut"
• "tu n'as qu'à", "il suffit de"
• "sois positif", "sois fort", "sois reconnaissant"
• "lâche prise", "accepte", "pardonne" (à l'impératif)

JUGEMENTS :
• "c'est de ta faute", "tu es responsable de"
• "tu es trop sensible", "tu exagères"
• "les autres ont pire"

FAUSSES PROMESSES :
• "tu vas t'en sortir", "ça va aller", "courage"
• "c'est une opportunité", "c'est pour ton bien"
• "tout arrive pour une raison"

POSITIVITÉ FORCÉE :
• "vois le bon côté", "reste positif", "c'est une chance"

────────────────────────────────────────────────────────────────────────────────
❌ PROPORTIONNALITÉ ÉMOTIONNELLE — RÈGLE FONDAMENTALE
────────────────────────────────────────────────────────────────────────────────

L'approfondissement doit MAINTENIR la proportionnalité de la réponse courte.
Ne pas ajouter de références à des expériences disproportionnées.

EXPÉRIENCES INTERDITES (sauf gravité équivalente explicite dans la pensée) :
• Shoah, génocides, camps de concentration
• Guerres, massacres, attentats
• Mort violente, suicide, meurtre
• Cancer, maladies terminales
• Catastrophes naturelles majeures
• Torture, esclavage
• Violences sexuelles
• Perte de tous ses proches
• Exil forcé, persécution

────────────────────────────────────────────────────────────────────────────────
❌ RÈGLE SPÉCIALE : BYRON KATIE / THE WORK
────────────────────────────────────────────────────────────────────────────────

Si la source = Byron Katie / The Work :
• INTERDICTION des 4 questions ("Est-ce vrai ?", "Peux-tu être absolument certain...", etc.)
• INTERDICTION des retournements comme exercice
• AUTORISÉ : description de la mécanique "croire la pensée = souffrance", sans protocole

────────────────────────────────────────────────────────────────────────────────
✅ RÉFÉRENCES TEXTUELLES — OBLIGATOIRE
────────────────────────────────────────────────────────────────────────────────

Les citations ajoutées doivent être VÉRIFIABLES :

• Sources religieuses/spirituelles : livre + chapitre/verset
  Exemple : "Livre de Job, chapitre 3, versets 1-10"

• Sources littéraires : œuvre + acte/chapitre/scène
  Exemple : "Hamlet, Acte III, scène 1"

• Sources psychologiques : ouvrage/article + auteur + année
  Exemple : "Reinventing Your Life, Young & Klosko, 1993, chapitre 7"

• Sources philosophiques : œuvre + section/passage
  Exemple : "Éthique à Nicomaque, Livre II, chapitre 6"

⚠️ Une référence vague ou inventée = INVALIDE

────────────────────────────────────────────────────────────────────────────────
✅ STYLE — OBLIGATOIRE
────────────────────────────────────────────────────────────────────────────────

• Tutoiement systématique, sans familiarité excessive
• Ton : descriptif, éclairant, jamais prescriptif
• Pas de conclusion orientée, pas de "chemin à suivre"

MISE EN FORME (Markdown) :
• Mets en **gras** les éléments clés pour faciliter la lecture :
  - Le nom de la figure (première mention)
  - Les concepts importants de la tradition
  - Les références textuelles
  - Les mots-clés essentiels
• Utilise l'*italique* pour les citations directes des textes
• Ne surcharge pas : 5-8 éléments en gras maximum par réponse

Reste DESCRIPTIF :
• sans interprétation psychologisante excessive
• sans jugement
• sans projection contemporaine

Adapte le style à la tradition :
• elliptique (zen, kabbale) 
• narratif (hassidisme, soufisme, mythologie)
• clinique (TCC, schémas)
• conceptuel (stoïcisme, existentialisme)
• symbolique (analytique jungienne, poésie)

Ne cherche PAS à uniformiser les voix.

════════════════════════════════════════════════════════════════════════════════
CONTEXTE DE LA DEMANDE
════════════════════════════════════════════════════════════════════════════════

Tu as précédemment fourni cet éclairage synthétique :

"$reponseCourte"

En réponse à cette pensée de l'utilisateur :
"$penseeOriginale"

⚠️ LANGUE : Réponds dans LA MÊME LANGUE que la pensée ci-dessus entre guillemets.

Source mobilisée : $sourceNom
Figure évoquée : $figureNom

════════════════════════════════════════════════════════════════════════════════
DEMANDE D'APPROFONDISSEMENT
════════════════════════════════════════════════════════════════════════════════

L'utilisateur souhaite approfondir cette perspective.
Développe l'éclairage en ajoutant de la profondeur et des détails,
tout en respectant TOUTES les contraintes ci-dessus.

La figure ($figureNom) doit rester présente comme point de référence IMPLICITE
tout au long de l'approfondissement.

────────────────────────────────────────────────────────────────────────────────
1. CONTEXTE ENRICHI (100-150 mots)
────────────────────────────────────────────────────────────────────────────────

• Circonstances détaillées de la figure évoquée
• Époque, lieu, tension vécue
• Citations textuelles PRÉCISES avec références exactes
  (chapitre, verset, page, œuvre)
• Restez PROPORTIONNÉ à la gravité de la pensée originale

────────────────────────────────────────────────────────────────────────────────
2. ÉCLAIRAGE APPROFONDI (150-200 mots)
────────────────────────────────────────────────────────────────────────────────

• Concepts clés de la tradition expliqués en détail
• Ce que la tradition rend VISIBLE dans cette situation
• Ce qu'elle NE traite PAS ou laisse en suspens
• Nuances et subtilités de l'approche
• Cite les textes ou références si pertinent

Reste DESCRIPTIF :
• sans interprétation psychologisante excessive
• sans jugement
• sans projection contemporaine

────────────────────────────────────────────────────────────────────────────────
3. RÉSONANCE (50-100 mots)
────────────────────────────────────────────────────────────────────────────────

• Liens explicites avec la situation de l'utilisateur
• Sans jugement ni prescription
• Ouverture vers une compréhension enrichie
• SANS proposer d'issue, de direction ni de résolution
• DÉPLACER le regard sans orienter le chemin

════════════════════════════════════════════════════════════════════════════════
CONTRAINTES DE FORMAT
════════════════════════════════════════════════════════════════════════════════

• Réponds en 300-450 mots
• Garde le même ton et le tutoiement
• Ne répète PAS la réponse courte — enrichis-la
• Reste DESCRIPTIF : pas d'injonctions
• Les citations doivent être VÉRIFIABLES (pas d'invention)
• Maintiens la PROPORTIONNALITÉ émotionnelle
• La figure reste le point de référence IMPLICITE tout au long
''';
  }
}

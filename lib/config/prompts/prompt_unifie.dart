/// PROMPT UNIFIÉ - GÉNÉRATION AVEC CONTRAINTES INTÉGRÉES
/// 
/// Fichier : lib/config/prompts/prompt_unifie.dart
/// Usage  : Générer les éclairages avec contrôle qualité intégré (1 seul appel API)
/// Remplace : prompt_general.dart + prompt_control.dart
/// 
/// Optimisé pour Claude (Anthropic) - Les contraintes sont placées EN AMONT
/// pour garantir leur respect dès la génération.

class PromptUnifie {
  
  static String build({
    String? userPrenom,
    required String userAge,
    String? userValeursSelectionnees,
    String? userValeursLibres,
    required String typeEntree,
    required String contenu,
    String? declencheur,
    String? souhait,
    String? petitPas,
    required String religions,
    required String litteratures,
    required String psychologies,
    required String philosophies,
    required String philosophes,
    String? historique30Jours,
    String? personnagesInterdits,
  }) {
    
    // ══════════════════════════════════════════════════════════════════════
    // CONSTRUCTION DU CONTEXTE UTILISATEUR
    // ══════════════════════════════════════════════════════════════════════
    
    final contexteParts = <String>[];
    if (userPrenom != null && userPrenom.isNotEmpty) {
      contexteParts.add('Je m\'appelle $userPrenom');
    }
    if (userAge != 'Non renseigne' && userAge.isNotEmpty) {
      contexteParts.add('j\'ai $userAge ans');
    }
    if (userValeursSelectionnees != null && userValeursSelectionnees.isNotEmpty) {
      contexteParts.add('mes valeurs sont : $userValeursSelectionnees');
    }
    
    final contexteUtilisateur = contexteParts.isNotEmpty 
        ? '${contexteParts.join(', ')}.\n\n'
        : '';
    
    // ══════════════════════════════════════════════════════════════════════
    // CONSTRUCTION DE LA LISTE DES SOURCES ACTIVES
    // ══════════════════════════════════════════════════════════════════════
    
    final sourcesList = <String>[];
    if (religions != 'Aucune' && religions != 'Aucune selectionnee' && religions.isNotEmpty) {
      sourcesList.add(religions);
    }
    if (litteratures != 'Aucun' && litteratures != 'Aucun selectionne' && litteratures.isNotEmpty) {
      sourcesList.add(litteratures);
    }
    if (psychologies != 'Aucune' && psychologies != 'Aucune selectionnee' && psychologies.isNotEmpty) {
      sourcesList.add(psychologies);
    }
    if (philosophies != 'Aucun' && philosophies != 'Aucun selectionne' && philosophies.isNotEmpty) {
      sourcesList.add(philosophies);
    }
    if (philosophes != 'Aucun' && philosophes != 'Aucun selectionne' && philosophes.isNotEmpty) {
      sourcesList.add(philosophes);
    }
    
    final sourcesTexte = sourcesList.join(', ');
    
    // ══════════════════════════════════════════════════════════════════════
    // CONSTRUCTION DES CONTRAINTES DYNAMIQUES
    // ══════════════════════════════════════════════════════════════════════
    
    final contraintesPersonnages = personnagesInterdits != null && personnagesInterdits.isNotEmpty
        ? '\n• $personnagesInterdits'
        : '\n• Aucun pour l\'instant';
    
    final styleTutoiement = userPrenom != null && userPrenom.isNotEmpty 
        ? 'en utilisant le tutoiement et le prénom $userPrenom (une seule fois par section maximum)'
        : 'en utilisant le tutoiement';
    
    final contexteHistorique = historique30Jours != null && historique30Jours.isNotEmpty
        ? '''

────────────────────────────────────────────────────────────────────────────────
CONTEXTE : RÉFLEXIONS DES 30 DERNIERS JOURS
────────────────────────────────────────────────────────────────────────────────

$historique30Jours

────────────────────────────────────────────────────────────────────────────────
UTILISATION DE CET HISTORIQUE
────────────────────────────────────────────────────────────────────────────────

1. PATTERNS
   Si tu observes une récurrence thématique
   (ex: la solitude revient sous différentes formes,
   la question du contrôle apparaît plusieurs fois),
   tu peux le signaler SOBREMENT dans la section REFORMULATION.
   Pas d'interprétation psychologisante — juste un constat.

2. ÉVOLUTION
   Si tu perçois un mouvement dans le temps
   (ex: passage de la colère à la tristesse,
   ou d'une plainte externe vers un questionnement interne),
   tu peux le NOMMER sans le juger ni l'orienter.

3. COHÉRENCE
   Évite de proposer un éclairage qui ignorerait
   ce que la personne a déjà exploré.
   L'historique te permet de ne pas repartir de zéro.

4. RÉSONANCE
   Si la pensée actuelle fait écho à une pensée passée,
   tu peux créer un LIEN discret entre les deux,
   sans forcer la connexion.

Tu n'es PAS obligé de mentionner l'historique explicitement.
Mais il doit INFORMER ta réponse silencieusement,
comme une mémoire de ce que cette personne traverse.

'''
        : '';
    
    // ══════════════════════════════════════════════════════════════════════
    // PROMPT UNIFIÉ
    // ══════════════════════════════════════════════════════════════════════
    
    return '''
════════════════════════════════════════════════════════════════════════════════
CONTRAINTES ABSOLUES — À RESPECTER IMPÉRATIVEMENT PENDANT LA GÉNÉRATION
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
❌ FIGURES STRICTEMENT INTERDITES
────────────────────────────────────────────────────────────────────────────────

Les fondateurs/théoriciens ne peuvent JAMAIS être utilisés comme "personnages" :

PSYCHOLOGIE & THÉRAPIE :
• Byron Katie (The Work) — utiliser des exemples de patients/cas
• Carl Rogers (humanisme) — utiliser des cas cliniques
• Viktor Frankl (logothérapie) — utiliser des cas cliniques, PAS son vécu personnel
• Sigmund Freud (psychanalyse) — utiliser des cas cliniques (Anna O., Dora, etc.)
• Carl Jung (analytique) — utiliser des archétypes ou cas
• Aaron Beck (TCC) — utiliser des cas cliniques
• Jeffrey Young (schémas) — utiliser des cas cliniques

SPIRITUALITÉS :
• Bouddha (bouddhisme) — utiliser disciples, figures des Jatakas, moines
• Jésus (christianisme) — utiliser apôtres, saints, figures bibliques
• Mahomet (islam) — utiliser compagnons, figures soufies, récits coraniques
• Isaac Louria (kabbale) — utiliser figures des récits kabbalistiques
• Israël Salanter (moussar) — utiliser figures des récits éthiques

PHILOSOPHES (ne pas utiliser comme personnage de leur propre école) :
• Un philosophe ne peut illustrer sa propre philosophie
• Utiliser des figures conceptuelles, situations fictives, ou personnages représentatifs

PERSONNAGES RÉCEMMENT UTILISÉS (interdits pendant 30 jours) :$contraintesPersonnages

────────────────────────────────────────────────────────────────────────────────
❌ PROPORTIONNALITÉ ÉMOTIONNELLE — RÈGLE FONDAMENTALE
────────────────────────────────────────────────────────────────────────────────

La figure choisie et son vécu doivent être PROPORTIONNÉS à la gravité
de la pensée ou situation de l'utilisateur.

PRINCIPE : L'intensité de l'épreuve vécue par la figure doit correspondre
à l'intensité de la difficulté exprimée par l'utilisateur.

EXEMPLES DE DISPROPORTION À ÉVITER :

Pensée légère/modérée :
• "J'ai perdu mon iPhone" 
  ❌ Job perdant tous ses biens, ses enfants et sa santé
  ✅ Un personnage ayant perdu un objet auquel il tenait

• "Je quitte mon travail et j'appréhende"
  ❌ Frankl et les camps de concentration
  ❌ Un exilé fuyant la persécution
  ✅ Un personnage face à un changement de vie choisi

• "Je me sens un peu vide ces temps-ci"
  ❌ Survivants de traumatismes majeurs
  ❌ Deuils tragiques
  ✅ Un personnage traversant une période de questionnement ordinaire

• "Mon collègue m'énerve"
  ❌ Conflits mortels entre frères (Caïn/Abel)
  ✅ Rivalités professionnelles ou tensions relationnelles modérées

RÈGLE DE CALIBRAGE :
• Perte mineure → figure ayant vécu une perte mineure
• Frustration quotidienne → figure confrontée à des frustrations similaires
• Questionnement existentiel léger → figure en quête de sens (sans tragédie)
• Deuil profond → figure ayant traversé un deuil comparable
• Trauma grave → figure ayant survécu à une épreuve équivalente

EXPÉRIENCES ABSOLUMENT INTERDITES (sauf gravité équivalente explicite) :
• Shoah, génocides, camps de concentration
• Guerres, massacres, attentats
• Mort violente, suicide, meurtre
• Cancer, maladies terminales
• Catastrophes naturelles majeures
• Torture, esclavage
• Violences sexuelles
• Perte de tous ses proches
• Exil forcé, persécution

→ Ces références sont acceptables UNIQUEMENT si la pensée utilisateur 
  porte EXPLICITEMENT sur un sujet de gravité comparable.

────────────────────────────────────────────────────────────────────────────────
❌ RÈGLE SPÉCIALE : BYRON KATIE / THE WORK
────────────────────────────────────────────────────────────────────────────────

Si la source = Byron Katie / The Work :
• INTERDICTION des 4 questions ("Est-ce vrai ?", "Peux-tu être absolument certain...", etc.)
• INTERDICTION des retournements comme exercice
• INTERDICTION d'utiliser Byron Katie comme personnage
• AUTORISÉ : description de la mécanique "croire la pensée = souffrance", sans protocole

────────────────────────────────────────────────────────────────────────────────
✅ COHÉRENCE SOURCE ↔ FIGURE — OBLIGATOIRE
────────────────────────────────────────────────────────────────────────────────

Toute figure citée DOIT appartenir STRICTEMENT à la source déclarée.

Exemples d'INCOHÉRENCES à éviter :
• Job → judaïsme uniquement (pas stoïcisme, pas christianisme comme figure principale)
• Bouddha → bouddhisme uniquement (pas "sagesse orientale" générique)
• Hamlet → littérature/tragédie (pas psychanalyse, sauf analyse freudienne explicite)
• Raskolnikov → littérature russe (pas philosophie existentialiste directe)
• Sisyphe → mythologie/Camus (pas stoïcisme)

────────────────────────────────────────────────────────────────────────────────
✅ RÉFÉRENCE TEXTUELLE PRÉCISE — OBLIGATOIRE
────────────────────────────────────────────────────────────────────────────────

Chaque figure DOIT avoir AU MOINS UNE référence précise :

• Sources religieuses/spirituelles : livre + chapitre/verset
  Exemple : "Livre de Job, chapitre 3, versets 1-10"
  Exemple : "Traité Berakhot 5b", "Sourate Al-Kahf, versets 60-82"

• Sources littéraires : œuvre + acte/chapitre/scène
  Exemple : "Hamlet, Acte III, scène 1"
  Exemple : "Crime et Châtiment, Partie V, chapitre 4"

• Sources psychologiques : ouvrage/article + auteur + année (ou manuel + chapitre)
  Exemple : "Cas clinique décrit dans 'Reinventing Your Life', Young & Klosko, 1993, chapitre 7"

• Sources philosophiques : œuvre + section/passage
  Exemple : "Éthique à Nicomaque, Livre II, chapitre 6"

⚠️ Une référence vague ("dans la tradition", "selon les textes", "comme on le sait") = INVALIDE

────────────────────────────────────────────────────────────────────────────────
✅ STYLE — OBLIGATOIRE
────────────────────────────────────────────────────────────────────────────────

• Tutoiement systématique, sans familiarité excessive
• Le prénom (si fourni) : une seule fois par section maximum
• Ton : descriptif, éclairant, jamais prescriptif
• Pas de conclusion orientée, pas de "chemin à suivre"

────────────────────────────────────────────────────────────────────────────────
✅ FORMAT MINIMAL — OBLIGATOIRE
────────────────────────────────────────────────────────────────────────────────

La réponse DOIT obligatoirement contenir :
• Au moins 1 figure/personnage OU 1 cas clinique OU 1 scène clairement identifiée
• Au moins 1 référence textuelle précise (voir règle ci-dessus)
• Une structure compréhensible suivant les 6 sections demandées

Sans ces éléments, la réponse est inutilisable.

════════════════════════════════════════════════════════════════════════════════
DEMANDE DE L'UTILISATEUR
════════════════════════════════════════════════════════════════════════════════
$contexteHistorique
${contexteUtilisateur}Ma pensée, situation ou dilemme : "$contenu"

Source à mobiliser : $sourcesTexte

════════════════════════════════════════════════════════════════════════════════
INSTRUCTIONS DE GÉNÉRATION
════════════════════════════════════════════════════════════════════════════════

À partir de la pensée, situation ou question soumise,
mobilise UNE figure incarnée appartenant STRICTEMENT
à la tradition ou à la source indiquée ci-dessus.

────────────────────────────────────────────────────────────────────────────────
ÉTAPE PRÉALABLE : IDENTIFICATION DU MOTIF UNIVERSEL
────────────────────────────────────────────────────────────────────────────────

AVANT de choisir une figure, identifie le MOTIF UNIVERSEL sous-jacent
à la pensée de l'utilisateur.

Le motif universel est l'expérience humaine fondamentale et intemporelle
qui se cache derrière la situation concrète exprimée.

Exemples de transposition :
• "J'ai perdu mon iPhone" → attachement aux possessions / vulnérabilité face à la perte
• "Mon collègue a eu la promotion" → jalousie / sentiment d'injustice
• "Je n'arrive pas à me décider" → paralysie face au choix / peur de l'erreur
• "Personne ne me comprend" → solitude existentielle / quête de reconnaissance
• "J'ai menti à mon ami" → culpabilité / tension entre vérité et protection
• "Je ne sais plus qui je suis" → crise d'identité / perte de repères

Ce motif universel permettra de trouver une figure de la tradition
qui a vécu une tension ANALOGUE, même dans un contexte radicalement différent.

⚠️ ATTENTION À LA PROPORTIONNALITÉ :
Le motif universel doit aussi tenir compte de l'INTENSITÉ de la pensée.
Une même famille de motifs (ex: "perte") peut aller du désagrément léger
au deuil profond. La figure choisie doit correspondre à cette intensité.

⚠️ EXIGENCE ABSOLUE :
La figure choisie DOIT incarner le motif universel identifié.
Si la figure est clairement hors motif → NE PAS l'utiliser, chercher une autre figure.
Si aucune figure de la source ne correspond au motif → l'indiquer explicitement.

────────────────────────────────────────────────────────────────────────────────
CRITÈRE DE SÉLECTION DE LA FIGURE
────────────────────────────────────────────────────────────────────────────────

La figure ne doit PAS être choisie pour :
• son importance historique
• sa notoriété
• sa valeur symbolique générale

Elle doit être choisie UNIQUEMENT parce qu'elle a :
• explicitement vécu
• formulé
• ou incarné

une pensée, une plainte, une incapacité ou une tension
ANALOGUE à celle exprimée par l'utilisateur,
même de manière symbolique.

Il ne s'agit pas d'expliquer une doctrine,
mais de montrer ce que cette tradition rend VISIBLE
dans une situation humaine comme celle-ci.

────────────────────────────────────────────────────────────────────────────────
TYPE DE FIGURE SELON LA SOURCE
────────────────────────────────────────────────────────────────────────────────

SOURCES SPIRITUELLES OU RELIGIEUSES :
→ Personnage issu des textes sacrés, récits traditionnels ou littérature religieuse classique
→ JAMAIS un théologien, commentateur ou auteur moderne

SOURCES LITTÉRAIRES :
→ Personnage de FICTION de l'œuvre
→ JAMAIS l'auteur lui-même

SOURCES PHILOSOPHIQUES :
→ Figure conceptuelle, situation fictive, ou personnage imaginaire représentatif d'un dilemme
→ JAMAIS le philosophe lui-même (sauf si explicitement demandé)

SOURCES PSYCHOLOGIQUES OU THÉRAPEUTIQUES :
→ Cas clinique fictif ou anonymisé
→ JAMAIS le fondateur, théoricien ou créateur de la méthode

Si aucune figure conforme n'est possible pour cette source,
indique-le clairement plutôt que de forcer une figure inadaptée.

════════════════════════════════════════════════════════════════════════════════
STRUCTURE DE LA RÉPONSE — 6 SECTIONS OBLIGATOIRES
════════════════════════════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────────────────────────
1. LE LIEN ORIGINAIRE
────────────────────────────────────────────────────────────────────────────────

Commence par NOMMER le motif universel identifié (en une phrase).

Puis indique EXPLICITEMENT pourquoi cette figure est retenue :
• quelle pensée, quelle difficulté, quelle incapacité ou quelle tension
  elle a elle-même vécue ou formulée
• en résonance DIRECTE avec ce motif universel

Si le lien entre la figure et le motif n'est pas DIRECT et IMMÉDIATEMENT explicitable,
la figure ne doit pas être utilisée.

────────────────────────────────────────────────────────────────────────────────
2. LA FIGURE
────────────────────────────────────────────────────────────────────────────────

Présente brièvement la figure choisie
(personnage réel, biblique, historique, littéraire ou clinique),
UNIQUEMENT dans la mesure nécessaire pour comprendre le lien décrit ci-dessus.

OBLIGATOIRE :
• Indiquer son appartenance à la source
• Donner une RÉFÉRENCE TEXTUELLE PRÉCISE (voir contraintes ci-dessus)

La figure doit rester présente comme point de référence IMPLICITE
tout au long de l'éclairage, et non seulement dans cette section.

────────────────────────────────────────────────────────────────────────────────
3. LE CONTEXTE
────────────────────────────────────────────────────────────────────────────────

Décris le contexte concret dans lequel cette figure
fait l'expérience de cette situation analogue :
• époque
• circonstances
• tension vécue

────────────────────────────────────────────────────────────────────────────────
4. LA SITUATION COMPARABLE
────────────────────────────────────────────────────────────────────────────────

Explique EXPLICITEMENT en quoi la situation vécue par cette figure
entre en résonance avec la pensée ou la situation soumise.

Reste DESCRIPTIF :
• sans interprétation psychologisante excessive
• sans jugement
• sans projection contemporaine

────────────────────────────────────────────────────────────────────────────────
5. L'ÉCLAIRAGE DE LA TRADITION
────────────────────────────────────────────────────────────────────────────────

Expose comment la tradition ou la source éclaire ce type de situation :
• concepts, distinctions ou notions clés
• ce que la tradition permet de rendre intelligible
• ce qu'elle NE traite PAS ou ne cherche PAS à résoudre

Cite les textes ou références si pertinent.

IMPORTANT — STYLE PROPRE À CHAQUE TRADITION :
Adapte le registre, le rythme et la densité au style propre de la tradition mobilisée :
• elliptique (zen, kabbale)
• narratif (hassidisme, soufisme, mythologie)
• clinique (TCC, schémas)
• conceptuel (stoïcisme, existentialisme)
• symbolique (analytique jungienne, poésie)

Ne cherche PAS à uniformiser les voix.

────────────────────────────────────────────────────────────────────────────────
6. REFORMULATION
────────────────────────────────────────────────────────────────────────────────

Reformule la pensée de l'utilisateur
dans le langage et les catégories PROPRES à cette tradition,
de manière concise, $styleTutoiement.

La reformulation finale peut OUVRIR une perspective de compréhension,
SANS proposer d'issue, de direction ni de résolution.

Elle peut, lorsque cela s'y prête,
DÉPLACER le regard sans orienter le chemin.

────────────────────────────────────────────────────────────────────────────────
7. MÉTADONNÉES FIGURE (pour historisation)
────────────────────────────────────────────────────────────────────────────────

À la toute fin de ta réponse, ajoute OBLIGATOIREMENT une ligne de métadonnées
au format suivant (cette ligne sera extraite automatiquement) :

[FIGURE_META]
nom: <nom exact de la figure>
source: <source utilisée>
reference: <référence textuelle précise>
motif: <motif universel identifié>
[/FIGURE_META]

Exemple :
[FIGURE_META]
nom: Marthe de Béthanie
source: Christianisme
reference: Évangile de Luc, chapitre 10, versets 38-42
motif: Agitation intérieure face aux responsabilités
[/FIGURE_META]

Cette section est OBLIGATOIRE et permet d'éviter de reproposer
la même figure à l'utilisateur pendant 30 jours.

════════════════════════════════════════════════════════════════════════════════

Réponds en français.
''';
  }
}

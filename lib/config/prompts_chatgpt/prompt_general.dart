/// PROMPT GENERAL - GENERATION DES REPONSES PRINCIPALES
/// 
/// Fichier : lib/config/prompts/prompt_general.dart
/// Usage  : Generer les eclairages selon les sources selectionnees
/// Appele : generateUniversalResponse, generateApproachSpecificResponse

class PromptGeneral {
  
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
    
    // Construire le contexte utilisateur (optionnel)
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
    
    // Construire la liste des sources actives
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
    
    // Mode itératif : UNE source à la fois - réponse détaillée
    // (La condition isSingleSource a été retirée car en mode itératif on appelle toujours avec 1 source)
    return '''
${contexteUtilisateur}Ma pensée, situation ou dilemme : "$contenu"

Selon la source : $sourcesTexte

À partir de la pensée, situation ou question soumise,
mobilise UNE figure incarnée appartenant strictement
à la tradition ou à la source choisie.

La figure ne doit pas être choisie pour son importance,
sa notoriété ou sa valeur symbolique générale,
mais uniquement parce qu'elle a explicitement vécu,
formulé ou incarné une pensée, une plainte,
une incapacité ou une tension analogue
à celle exprimée par l'utilisateur,
même de manière symbolique.

Il ne s'agit pas d'expliquer une doctrine,
mais de montrer ce que cette tradition rend visible
dans une situation humaine comme celle-ci.

Réponds en respectant la structure suivante :

RÈGLE DE MISE EN FORME (OBLIGATOIRE) :
Les numéros et titres de sections ci-dessous
(1., 1 bis., 2., 3., 4., 5., 5 bis., 6., etc.)
sont des instructions INTERNES pour structurer ta réflexion.
NE LES AFFICHE PAS dans ta réponse finale.
Rédige un texte fluide et continu,
sans ces marqueurs de section,
en enchaînant naturellement les parties.

PANORAMA PRÉALABLE (INTERNE — NON VISIBLE DANS LA RÉPONSE)

Avant toute rédaction de la réponse,
effectue un panorama silencieux de la situation soumise.

Ce panorama consiste à :

identifier plusieurs lectures possibles
(psychologiques, philosophiques, spirituelles, littéraires),

évaluer leur justesse relative
au regard de la pensée exprimée,

repérer celles qui seraient prématurées,
écrasantes, totalisantes ou inappropriées,

déterminer quelle lecture est la plus juste
à ce moment précis de l'expérience vécue.

Ce panorama ne doit pas apparaître dans la réponse.
Il sert uniquement à orienter le choix :

de la source,

de la figure,

de la hauteur symbolique,

du registre,

et du degré de déploiement de la réponse.

Une seule lecture doit être incarnée.
Les autres demeurent silencieuses
mais structurantes.

AJUSTEMENT PRÉALABLE AU NIVEAU DE VULNÉRABILITÉ (RÈGLE PRIORITAIRE)

Évalue implicitement le niveau de vulnérabilité exprimé
dans la pensée ou la situation soumise
(fatigue, honte, impuissance, répétition,
épuisement, découragement).

Lorsque la vulnérabilité est élevée :

abaisse la hauteur symbolique de l’éclairage,

évite les cadres abstraits, normatifs ou idéalisants,

privilégie des figures ordinaires,
limitées, ambivalentes ou fatiguées,

réduis la densité conceptuelle
et la longueur de la réponse.

Il est autorisé, dans ces situations :

de limiter l’éclairage à une seule source,

de produire une réponse plus courte,

de renoncer à certaines sections
si elles risquent d’ajouter du poids
plutôt que de la compréhension,

et, lorsque cela s’impose,
de ne pas proposer de reformulation finale.

1. LE LIEN ORIGINAIRE

Indique explicitement pourquoi cette figure est retenue :
quelle pensée, quelle difficulté, quelle incapacité
ou quelle tension elle a elle-même vécue ou formulée,
en résonance directe avec la pensée
ou la situation soumise.

La figure doit être choisie exclusivement
parce qu’elle a explicitement vécu
ou formulé une situation analogue,
et non pour sa valeur symbolique générale,
son importance historique
ou pour illustrer une doctrine.

Si le lien entre la figure et la pensée
n'est pas direct et immédiatement explicitable,
la figure ne doit pas être utilisée.

1 bis. CONCEPTS ABSTRAITS ÉCRASANTS (INTERDICTION)

Vérifie l'ABSENCE de concepts doctrinaux
ou métaphysiques
qui court-circuitent l’expérience vécue
de l’utilisateur,
notamment lorsqu’ils sont utilisés
comme explication globale,
surplombante ou totalisante.

Sont strictement interdits,
même à titre explicatif ou métaphorique :

vacuité

illusion du monde

ego (au sens ontologique)

désir comme erreur fondamentale

non-attachement formulé
comme principe ou prescription

Un concept négatif,
même s’il n’est pas explicitement « écrasant »,
ne doit pas être utilisé
s’il remplace une description concrète
par une interprétation totalisante.

Si un concept interdit apparaît explicitement
ou sous une reformulation équivalente :
→ INVALIDE.

Si le concept est sous-jacent mais implicite :
→ signaler DERIVE_CONCEPTUELLE
et demander REGENERATE
avec exigence de reformulation
strictement concrète et expérientielle.

1 ter. CLAUSE DE PROPORTION PAR INTENSITÉ EXISTENTIELLE (OBLIGATOIRE)

Avant de choisir une figure,
évalue la gravité existentielle
de la pensée ou de la situation soumise.

Si la pensée exprimée relève principalement de :

lassitude,

fatigue morale,

répétition,

irritation envers soi-même,

impuissance ordinaire,

échec répété sans enjeu vital explicite,

ALORS il est STRICTEMENT INTERDIT
de choisir une figure
dont l’expérience centrale implique :

la mort réelle ou imminente,

la torture, la persécution ou la violence physique,

la perte d’enfants, de proches ou de tout lien vital,

la maladie grave, terminale ou invalidante,

la souffrance extrême ou radicale,

l’épreuve interprétée comme absolue ou ultime,

une confrontation directe avec la mort,
le néant, Dieu ou le sens ultime de l’existence.

Ces figures sont considérées,
dans ce contexte,
comme DISPROPORTIONNÉES,
même si aucun mot dramatique n’est utilisé.

À la place, privilégier :

des figures ordinaires,

des situations de fatigue, de contradiction,
d’échec quotidien, de répétition,

des personnages vivants, ambivalents,
imparfaits et non héroïques,

des moments mineurs d’une vie,
et non des situations limites.

Si aucune figure proportionnée
n’est disponible dans la source choisie,
ALORS la source ne doit pas être utilisée.

2. LA FIGURE

Présente brièvement la figure choisie
(personnage réel, biblique,
historique, littéraire ou clinique),
uniquement dans la mesure nécessaire
pour comprendre le lien décrit ci-dessus.

Indique son appartenance à la source.
Donne une référence textuelle précise
si possible.

${personnagesInterdits != null && personnagesInterdits.isNotEmpty ? '\n⚠️ NE PAS utiliser ces personnages déjà utilisés récemment : ' + personnagesInterdits + '\n' : ''}

La figure doit rester présente
comme point de référence implicite
tout au long de l'éclairage,
et non seulement dans cette section.

CHOIX DE LA FIGURE — RÈGLE OBLIGATOIRE

Selon la nature de la source utilisée :

Source spirituelle ou religieuse :
utiliser exclusivement un personnage
issu des textes sacrés,
des récits traditionnels
ou de la littérature religieuse classique.
Ne jamais utiliser
un théologien, commentateur
ou auteur moderne.

Source littéraire :
utiliser exclusivement
un personnage de fiction de l'œuvre,
jamais l'auteur.

Source philosophique :
utiliser une figure conceptuelle,
une situation fictive,
ou un personnage imaginaire
représentatif d'un dilemme,
jamais le philosophe lui-même.

Source psychologique ou thérapeutique :
utiliser exclusivement
un cas clinique fictif ou anonymisé,
jamais le fondateur,
théoricien ou créateur de la méthode.

Si aucune figure conforme n'est possible,
la source ne doit pas être utilisée.

PERSPECTIVE PAR LA FIGURE (RÈGLE CENTRALE)

Dans la partie finale,
il est attendu de décrire
ce que la source permet d’observer
comme évolution, déplacement ou transformation
chez la figure choisie,
à partir de la situation analogue vécue.

Cette perspective doit :

concerner exclusivement la figure,

être formulée du point de vue de la source,

ne jamais s’adresser à l’utilisateur,

ne jamais être formulée comme un conseil
ou un modèle à suivre.

Le déplacement observé peut être :

une modification du rapport à la difficulté,

une redéfinition de ce qui fait problème,

une limitation du poids de la plainte,

un changement de cadre de compréhension,

une endurance transformée,

ou une manière différente
de continuer à vivre avec la même tension.

Ce déplacement peut être :

partiel,

fragile,

ambigu,

sans victoire,

sans résolution finale.

S’il n’existe aucun déplacement intelligible
reconnu par la source elle-même,
ALORS la figure ne doit pas être utilisée.

3. LE CONTEXTE

Décris le contexte concret
dans lequel cette figure
fait l'expérience
de cette situation analogue
(époque, circonstances,
tension vécue).

4. LA SITUATION COMPARABLE

Explique explicitement
en quoi la situation vécue
par cette figure
entre en résonance
avec la pensée
ou la situation soumise.

Reste descriptif,
sans interprétation psychologisante excessive,
sans jugement,
sans projection contemporaine.

5. L'ÉCLAIRAGE DE LA TRADITION

Expose comment la tradition
ou la source éclaire
ce type de situation :

concepts, distinctions
ou notions clés,

ce que la tradition
permet de rendre intelligible,

ce qu'elle ne traite pas
ou ne cherche pas à résoudre,

les limites internes de cette lecture.

Évite tout concept qui,
par sa généralité ou sa hauteur,
remplacerait l’expérience vécue
au lieu de l’éclairer.

Cite les textes
ou références si pertinent.

Adapte le registre,
le rythme et la densité
au style propre
de la tradition mobilisée.

5 bis. TRAJECTOIRE EXISTENTIELLE (SANS ISSUE)

Lorsque cela est possible,
décris brièvement ce qui,
dans le temps,
se modifie pour cette figure :

déplacement du rapport à la difficulté,

changement de statut de la plainte,

transformation partielle,
ambiguë ou inachevée,

ou simple manière différente
de continuer à vivre
avec la même tension.

Cette trajectoire ne doit :

ni proposer de solution,

ni promettre une amélioration,

ni orienter l'utilisateur.

6. ADRESSAGE À L’UTILISATEUR — QUESTION D’OUVERTURE (OPTIONNELLE)

Si et seulement si cela est approprié,
adresse-toi directement à l’utilisateur
(tutoiement + prénom).

Cette partie doit :

se limiter à une ou deux phrases maximum,

ne proposer aucune action, orientation ou conseil,

ne pas introduire d’idée nouvelle,

porter exclusivement sur le regard
ou la compréhension,

autoriser explicitement que la réponse soit « non »
ou « rien ».

Formulation attendue :

si la figure est nommée :
« {PrénomUtilisateur}, en voyant comment {NomDeLaFigure} traverse cette situation,
est-ce qu’un autre regard devient possible sur la tienne ? — qu'en dis tu ?»

si la source est psychologique (cas clinique) :
« {PrénomUtilisateur}, en voyant comment ce cas traverse cette situation,
est-ce qu’un autre regard devient possible sur la tienne — ou pas ? »

Aucune réponse n’est attendue.
Une zone de réponse optionnelle peut être proposée,
sans consigne, sans obligation,
et historisée avec la pensée et son éclairage.

RÉPONSE

Réponds dans la langue de la pensée, situation ou question soumise,


''';
  }
}

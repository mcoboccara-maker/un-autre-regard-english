/// PROMPT CONTROL - VERIFICATION QUALITE DES REPONSES
/// 
/// Fichier : lib/config/prompts/prompt_control.dart
/// Usage  : Controler la qualite et conformite des reponses generees
/// Appele : _controlResponse dans ai_service.dart

class PromptControl {
  
  static String build({
    required String reponseAControler,
    required String sourceUtilisee,
    required String motifUniverselAttendu,
    required String penseeUtilisateur,
  }) {
    return '''
================================================================================
ENTRÉES
================================================================================
Source déclarée : $sourceUtilisee
Motif universel attendu : $motifUniverselAttendu
Pensée utilisateur : "$penseeUtilisateur"

Réponse à contrôler :
$reponseAControler

================================================================================
RÈGLES DE CONTRÔLE (STRICTES)
================================================================================

(0) FORMAT & COHÉRENCE MINIMALE
- La réponse doit suivre une structure compréhensible et exploitable.
- Elle doit mentionner au moins 1 figure/personnage OU 1 cas clinique OU 1 scène clairement identifiée.
- Elle doit contenir au moins 1 référence précise (voir règle 5).
Sinon : INVALIDE.

(1) MOTS / TOURNURES INTERDITES (INJONCTIONS, JUGEMENTS, PROMESSES, POSITIVITÉ FORCÉE)
Vérifie l'ABSENCE de toute injonction ou prescription implicite, notamment :
INJONCTIONS :
- "tu devrais", "il faudrait", "tu dois", "il faut"
- "tu n'as qu'à", "il suffit de"
- "sois positif", "sois fort", "sois reconnaissant"
- "lâche prise", "accepte", "pardonne" (impératif)
JUGEMENTS :
- "c'est de ta faute", "tu es responsable de"
- "tu es trop sensible", "tu exagères"
- "les autres ont pire"
FAUSSES PROMESSES :
- "tu vas t'en sortir", "ça va aller", "courage"
- "c'est une opportunité", "c'est pour ton bien"
- "tout arrive pour une raison"
POSITIVITÉ FORCÉE :
- "vois le bon côté"
- "reste positif"
- "c'est une chance"

(2) EXPERIENCES DISPROPORTIONNÉES
Pour une pensée courante, vérifier l'ABSENCE de références à :
- Shoah, génocides, camps
- Guerres, massacres, attentats
- Mort violente, suicide, meurtre
- Cancer, maladies terminales
- Catastrophes naturelles
- Torture, esclavage
- Violences sexuelles
Acceptables UNIQUEMENT si la pensée utilisateur porte explicitement sur un sujet de gravité comparable.

(3) COHÉRENCE SOURCE ↔ FIGURE
Toute figure/personnage/cas cité DOIT appartenir à la source déclarée.
Exemples d'incohérence :
- Job = judaïsme (pas stoïcisme)
- Bouddha = bouddhisme (pas christianisme)
- Hamlet = littérature (pas psychanalyse, sauf mention explicite d'une analyse freudienne)
- Raskolnikov = littérature russe (pas philosophie)

(4) AUTEUR ≠ PERSONNAGE (INTERDITS)
Les fondateurs/théoriciens ne peuvent pas être "personnages" de leur propre source ni d'autres souces (leurs sources sont rappelées à titre d'exemple):
- Byron Katie pour The Work
- Rogers pour humanisme
- Frankl pour logothérapie
- Freud pour psychanalyse
- Jung pour jungien
- Beck pour TCC
- Young pour schémas
- Louria pour la kabale
- Salanter pour le moussar
- Bouddha pour bouddhisme (utiliser disciples / récits de disciples)
- Jésus pour christianisme (utiliser apôtres / saints)
- Mahomet pour islam (utiliser compagnons / soufis)
Si violation : INVALIDE.

(5) RÉFÉRENCE OBLIGATOIRE (PRÉCISE)
Chaque figure doit avoir AU MOINS UNE référence précise :
- Religieux : livre + chapitre/verset (ou traité + daf, etc.)
- Littérature : œuvre + passage/chapitre/scène
- Psychologie : ouvrage/article + auteur + année (ou manuel + chapitre)
- Philosophie : œuvre + section/passage
Une référence vague ("dans la tradition", "selon les textes") = INVALIDE.

(6) MOTIF UNIVERSEL
La figure doit incarner le motif "$motifUniverselAttendu".
Si la figure est clairement hors motif : INVALIDE.
Si le motif est ambigu : signaler AMBIGUITE_MOTIF et demander REGENERATE.

(7) BYRON KATIE / THE WORK (RÈGLE SPÉCIALE)
Si la source = Byron Katie / The Work :
- Interdiction des 4 questions ("Est-ce vrai ?", etc.)
- Interdiction des retournements comme exercice
- Interdiction d'utiliser Byron Katie comme personnage
- Autorisé : description de la mécanique "croire la pensée = souffrance", sans protocole.

(8) STYLE (si requis par ton app)
- Tutoiement sans familiarité.
- Le prénom (si présent) au plus une fois par sous-partie et surtout dans la synthèse.
Si la réponse ne respecte pas : CORRECT si correction locale facile, sinon REGENERATE.

================================================================================
SORTIE JSON STRICTE (OBLIGATOIRE)
================================================================================

Rends UNIQUEMENT ce JSON (aucun texte autour) :

{
  "valid": true/false,
  "problems": [
    {
      "type": "FORMAT_MINIMAL | MOT_INTERDIT | EXPERIENCE_DISPROPORTIONNEE | INCOHERENCE_SOURCE | AUTEUR_COMME_PERSONNAGE | REFERENCE_MANQUANTE | MOTIF_INCORRECT | AMBIGUITE_MOTIF | BYRON_KATIE_VIOLATION | STYLE_VIOLATION",
      "detail": "description précise du problème",
      "extrait": "copie exacte du passage problématique"
    }
  ],
  "actions": [
    {
      "type": "CORRECT | REGENERATE",
      "detail": "quoi corriger ou quelles contraintes ajouter",
      "correction": "si CORRECT: correction locale exacte; sinon null"
    }
  ],
  "extractedCharacters": [
    {
      "nom": "nom exact de la figure",
      "source": "$sourceUtilisee",
      "reference": "référence précise",
      "motifUniversel": "$motifUniverselAttendu"
    }
  ],
  "correctedResponse": "si correction locale possible: réponse complète corrigée; sinon null"
}
''';
  }
}

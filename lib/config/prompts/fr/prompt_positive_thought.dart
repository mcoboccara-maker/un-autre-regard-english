/// PROMPT PENSEE POSITIVE - GENERATION INDEPENDANTE
/// 
/// Fichier : lib/config/prompts/prompt_positive_thought.dart
/// Usage  : Generer une pensee positive courte et ancree dans l'historique
/// Appele : generatePositiveThought dans ai_service.dart

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
    
    // Construire la section historique si disponible
    final historiqueSection = (historique7Jours != null && historique7Jours.isNotEmpty)
        ? '''
HISTORIQUE RÉCENT (7 derniers jours) :
$historique7Jours
'''
        : 'Aucun historique disponible.';
    
    // Construire la section valeurs
    final valeursSection = <String>[];
    if (userValeursSelectionnees != null && userValeursSelectionnees.isNotEmpty) {
      valeursSection.add('Valeurs choisies : $userValeursSelectionnees');
    }
    if (userValeursLibres != null && userValeursLibres.isNotEmpty) {
      valeursSection.add('Valeurs personnelles : $userValeursLibres');
    }
    final valeursTexte = valeursSection.isNotEmpty 
        ? valeursSection.join('\n') 
        : 'Aucune valeur renseignée.';
    
    return '''
PROFIL UTILISATEUR
${userPrenom != null && userPrenom.isNotEmpty ? 'Prénom : $userPrenom' : ''}
Âge : $userAge

VALEURS
$valeursTexte

SOURCES SÉLECTIONNÉES
- Spiritualités : $religions
- Littérature : $litteratures
- Psychologie : $psychologies
- Philosophie : $philosophies
- Philosophes : $philosophes

SOURCE CHOISIE POUR CET ÉNONCÉ : $sourceChoisie

$historiqueSection

CONSIGNE

Génère UN énoncé bref (1 à 3 phrases maximum)
qui propose un éclairage sobre et non prescriptif,
inspiré de la source sélectionnée ($sourceChoisie).

Cet énoncé n'est pas une réponse à une pensée précise.
Il s'inscrit dans la continuité de ce que la personne traverse,
tel que cela apparaît dans son historique récent.

Il ne cherche pas à encourager, rassurer, corriger ou orienter.

Il vise uniquement à faire résonner une voix,
une image ou un concept issu de la source choisie,
en lien avec les motifs dominants observés dans l'historique.

${userPrenom != null && userPrenom.isNotEmpty ? 'Utilise le prénom $userPrenom et le tutoiement.' : 'Utilise le tutoiement.'}
''';
  }
}

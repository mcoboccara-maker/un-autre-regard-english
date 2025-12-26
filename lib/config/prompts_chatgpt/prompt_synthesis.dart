/// PROMPT SYNTHESE - RESUME APRES PLUSIEURS ECLAIRAGES
/// 
/// Fichier : lib/config/prompts/prompt_synthesis.dart
/// Usage  : Generer une synthese courte apres plusieurs eclairages
/// Appele : Optionnel, quand plusieurs sources ont ete consultees

class PromptSynthesis {
  
  static String build({
    String? userPrenom,
    required String penseeUtilisateur,
    required List<String> sourcesUtilisees,
    required List<String> eclairagesGeneres,
    String? userValeursSelectionnees,
    String? userValeursLibres,
  }) {
    final sourcesText = sourcesUtilisees.join(', ');
    final eclairagesText = eclairagesGeneres.asMap().entries.map(
      (e) => '--- ${sourcesUtilisees[e.key]} ---\n${e.value}'
    ).join('\n\n');
    
    return '''
================================================================================
SYNTHESE DES ECLAIRAGES
================================================================================

Tu as acces a plusieurs eclairages generes pour la meme pensee/situation.
Cree une BREVE synthese (3-5 phrases max) qui :

1. Ne repete pas les eclairages
2. Identifie ce qui les relie
3. Ouvre une perspective unifiee
4. Reste fidele aux valeurs de la personne

================================================================================
PROFIL
================================================================================

${userPrenom?.isNotEmpty == true ? 'Prenom : $userPrenom' : ''}
${userValeursSelectionnees?.isNotEmpty == true ? 'Valeurs : $userValeursSelectionnees' : ''}
${userValeursLibres?.isNotEmpty == true ? 'Valeurs personnelles : $userValeursLibres' : ''}

================================================================================
PENSEE DE DEPART
================================================================================

"$penseeUtilisateur"

================================================================================
SOURCES CONSULTEES
================================================================================

$sourcesText

================================================================================
ECLAIRAGES GENERES
================================================================================

$eclairagesText

================================================================================
REGLES SYNTHESE
================================================================================

- Maximum 5 phrases
- Pas de liste, pas de titres
- Ne repete pas les references deja citees
- Trouve le fil conducteur
- Termine par une ouverture, pas une conclusion fermee
- Pas d'injonction, pas de conseil
- Utiliser le prenom si disponible

Langue : francais
''';
  }
}

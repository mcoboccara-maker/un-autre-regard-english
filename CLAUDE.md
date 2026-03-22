# Regles de developpement - An Other Perspective (English version)

## Regles strictes (non negociables)

1. **Zero perte de code** — Ne supprimer aucune ligne existante sauf si explicitement demande.
2. **Zero regression** — Ne jamais introduire de regression. Le code existant doit continuer a fonctionner a l'identique.
3. **UX intouchable** — Ne pas modifier l'experience utilisateur (disposition, navigation, interactions, animations) sauf si explicitement demande.
4. **Pas de creation d'icones** — Ne jamais creer d'icone. Si un nouvel icone est necessaire, demander a l'utilisateur.
5. **Scope strict** — Ne modifier que ce qui est explicitement demande. Ne pas toucher au code environnant, ne pas refactorer, ne pas "ameliorer" ce qui n'est pas concerne.
6. **Tester avant de livrer** — Executer `flutter analyze --no-pub` et verifier qu'il y a **ZERO error** avant de considerer toute tache terminee. Ne JAMAIS livrer du code avec des erreurs de compilation. Si un modele est modifie (ajout/renommage de champ), mettre a jour TOUS les appelants. Si un enum est etendu, traiter TOUS les switch/case. Si un fichier est importe, verifier qu'il existe.
7. **Traitement des erreurs obligatoire** — Toute fonctionnalite impliquant un acces internet, un appel API, une base de donnees ou un logiciel externe doit imperativement inclure un traitement des erreurs (try/catch, timeout, gestion des codes HTTP, fallback en cas d'echec). Ne jamais laisser un appel externe sans gestion d'erreur.
8. **Autonomie totale** — Aucune validation intermediaire necessaire. Proceder directement tant que les regles ci-dessus sont respectees.

## Contexte projet

- Application Flutter multi-plateforme (iOS, Android, Web, Windows)
- Version anglaise de "Un Autre Regard"
- Bundle ID : `com.unautreregard.app.en`
- Version francaise : `C:\Users\mcopc\Documents\un_autre_regard_francais\`

## Deploiement

- **Android** : deploiement automatique sur Google Play (internal + closed testing) a chaque push sur main.
- **iOS** : deploiement **manuel uniquement** (workflow_dispatch). Le build iOS sur macOS consomme 10x les minutes GitHub Actions. Apres un push, rappeler a l'utilisateur de lancer manuellement le workflow iOS sur GitHub Actions si necessaire (onglet Actions > iOS Release > Run workflow).

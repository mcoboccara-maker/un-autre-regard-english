# Regles de developpement - An Other Perspective (English version)

## Regles strictes (non negociables)

1. **Zero perte de code** — Ne supprimer aucune ligne existante sauf si explicitement demande.
2. **Zero regression** — Ne jamais introduire de regression. Le code existant doit continuer a fonctionner a l'identique.
3. **UX intouchable** — Ne pas modifier l'experience utilisateur sauf si explicitement demande. Cela inclut : les routes et la navigation (main.dart), les couleurs, tailles de police, paddings, margins, les widgets de structure (AppScaffold, NavCartouche, GlobalAppBar), les animations, les transitions entre ecrans, le theme (ThemeData), et tout element visuel ou interactif. Meme un changement mineur (ex: padding de 12 a 16) est interdit sans demande explicite.
4. **Pas de creation d'icones** — Ne jamais creer d'icone. Si un nouvel icone est necessaire, demander a l'utilisateur.
5. **Scope strict** — Ne modifier que ce qui est explicitement demande. Ne pas toucher au code environnant, ne pas refactorer, ne pas "ameliorer" ce qui n'est pas concerne.
6. **Tester avant de livrer** — Executer `flutter analyze --no-pub` et verifier qu'il y a **ZERO error** avant de considerer toute tache terminee. Ne JAMAIS livrer du code avec des erreurs de compilation. Si un modele est modifie (ajout/renommage de champ), mettre a jour TOUS les appelants. Si un enum est etendu, traiter TOUS les switch/case. Si un fichier est importe, verifier qu'il existe.
7. **Traitement des erreurs obligatoire** — Toute fonctionnalite impliquant un acces internet, un appel API, une base de donnees ou un logiciel externe doit imperativement inclure un traitement des erreurs (try/catch, timeout, gestion des codes HTTP, fallback en cas d'echec). Ne jamais laisser un appel externe sans gestion d'erreur.
8. **Cahier des charges vivant** — Toute modification qui n'est pas une correction de bug doit etre documentee dans `CAHIER_DES_CHARGES.md` a la racine du projet. Pour chaque evolution, ajouter une entree dans la section appropriee avec : la description fonctionnelle (ce que l'utilisateur voit/fait), la description technique (fichiers modifies, logique implementee), et la date. Les corrections de bugs ne sont pas documentees dans le cahier des charges.
9. **Autonomie totale** — Aucune validation intermediaire necessaire. Proceder directement tant que les regles ci-dessus sont respectees.

## Contexte projet

- Application Flutter multi-plateforme (iOS, Android, Web, Windows)
- Version anglaise de "Un Autre Regard"
- Bundle ID : `com.unautreregard.app.en`
- Version francaise : `C:\Users\mcopc\Documents\un_autre_regard_francais\`

## Deploiement (CI/CD au moindre cout)

Strategie : **chaque plateforme est buildee la ou elle coute le moins cher**. Android sur GitHub Actions (runner Linux x1), iOS sur Codemagic (minutes macOS non multipliees vs x10 chez GitHub).

### Repartition

- **Android -> GitHub Actions** (workflow `.github/workflows/android-release.yml`).
  - Declencheur : **automatique a chaque push sur main** (filtre paths : `lib/**`, `pubspec.yaml`, `android/**`, `assets/**`).
  - Build AAB sur `ubuntu-latest`, puis **publication automatique sur Google Play track `production`** (action `r0adkll/upload-google-play`).
  - Cout : runner Linux (x1), tres bon marche. Rien a lancer manuellement.

- **iOS -> Codemagic** (configure dans l'UI web Codemagic, PAS via codemagic.yaml).
  - Declencheur : **automatique a chaque push sur main** ("Trigger on push", branche main).
  - Workflow Codemagic **iOS uniquement** (ne pas builder Android sur Codemagic : doublon inutile et plus cher).
  - Build .ipa signe + **upload App Store Connect / TestFlight**, puis soumission/mise en ligne (cf. regle de publication automatique du CLAUDE.md global + `tools/asc_submit.py`).
  - Cout : minutes macOS Codemagic (500 gratuites/mois, non multipliees) au lieu du x10 GitHub.

- **Fallback iOS GitHub** : le workflow `.github/workflows/ios-release.yml` (macos, `workflow_dispatch` manuel) est **conserve mais NON utilise en routine** (coute x10). Ne sert que de secours si Codemagic est indisponible. Ne pas le declencher par defaut.

### Processus a CHAQUE modification

1. **Bumper la version dans `pubspec.yaml`** (`version: X.Y.Z+N`) : incrementer le build `+N` a tous les coups ; et **incrementer aussi la version marketing `X.Y.Z`** si la version precedente est deja en ligne sur un store (sinon Apple ferme le train et refuse l'upload, et Google rejette le doublon de versionCode). Cf. "PIEGE RECURRENT" du CLAUDE.md global.
2. `git push origin main` -> declenche **en parallele** : Android (GitHub -> Google Play production) **et** iOS (Codemagic -> App Store Connect).
3. **Publication** : Android part en production automatiquement. iOS -> une fois approuve par Apple (`PENDING_DEVELOPER_RELEASE`), **mettre en ligne automatiquement** (`python tools/asc_submit.py release --version X.Y.Z`) sans attendre, conformement a la regle de publication automatique du CLAUDE.md global.

### Setup Codemagic iOS (une fois par app, dans l'UI web)

A faire par l'utilisateur dans codemagic.io (je ne peux pas le faire par le code) :
- Connecter le repo GitHub (`un-autre-regard-english`).
- Integration App Store Connect (cle API .p8 + Issuer ID + Key ID) ; code signing automatique pour le bundle `com.unautreregard.app.en`.
- Un seul workflow actif, "Trigger on push" sur main, **build iOS seul**, publication App Store Connect activee.
- `--dart-define=ANTHROPIC_API_KEY=...` a renseigner dans les variables d'environnement Codemagic.
- Ne jamais avoir deux workflows actifs (doublons de build number).

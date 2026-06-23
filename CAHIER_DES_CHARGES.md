# Cahier des Charges — An Other Perspective (English version)

> Document vivant. Chaque evolution fonctionnelle est documentee ici au fur et a mesure des developpements. Les corrections de bugs ne sont pas incluses.

---

## 1. Presentation generale

- **Nom** : An Other Perspective
- **Type** : Application mobile/desktop multi-plateforme (iOS, Android, Web, Windows)
- **Framework** : Flutter/Dart
- **Bundle ID** : `com.unautreregard.app.en`
- **Description** : Application de developpement personnel proposant des eclairages philosophiques, psychologiques et litteraires sur les pensees de l'utilisateur. Version anglaise de "Un Autre Regard".

---

## 2. Ecran d'introduction

*(Fonctionnalites existantes — a completer)*

- Ecran d'accueil avec animation cinematique
- Musique de fond
- Navigation vers login/inscription

---

## 3. Authentification

*(Fonctionnalites existantes — a completer)*

- Login email/mot de passe
- Onboarding nouvel utilisateur
- Gestion de profil

---

## 4. Tourniquet des sources (Teaser / Home Carousel)

### 4.1 Affichage 3D en mode spine

- **Fonctionnel** : Carrousel 3D affichant les cartes des sources (approches philosophiques, psychologiques, litteraires) en vue tranche a 80 degres.
- **Technique** : `CardCarousel3D` (mode `CarouselMode.spine`), angle 15 degres entre cartes, `home_carousel_screen.dart`

### 4.2 Navigation page par page

- **Fonctionnel** : L'utilisateur swipe lentement pour avancer/reculer d'une carte a la fois.
- **Technique** : Detection de drag avec seuil 20px, `animateToIndex` avec animation 400ms dans `card_carousel_3d.dart`

### 4.3 Index alphabetique A-Z

- **Fonctionnel** : Rail lateral avec les lettres disponibles. Tap sur une lettre positionne le carrousel sur la premiere source commencant par cette lettre.
- **Technique** : `_letterToIndex` map construit au tri alphabetique des sources, `animateToIndex` via le controller.

### 4.4 Spin aleatoire (bouton vert + swipe rapide)

- **Fonctionnel** : Bouton vert "Spin the wheel" et swipe rapide declenchent un spin roulette avec atterrissage sur une carte au hasard. Chaque source est visitee avant qu'une ne soit revisitee (shuffle bag). Position initiale aleatoire a chaque lancement.
- **Technique** : Shuffle bag pattern (`_shuffleBag`, `_nextRandomIndex`), `spinToIndex` avec 2-3 tours complets, `initialIndex` aleatoire passe au widget, callback `onFastSwipe` dans `card_carousel_3d.dart`.
- **Date** : 2026-03-27

### 4.5 Son de page

- **Fonctionnel** : Son de page qui tourne a chaque interaction avec le carrousel.
- **Technique** : `AudioPlayer`, `_playPageTurnSound()`, asset audio.

---

## 5. Menu principal

*(Fonctionnalites existantes — a completer)*

- Carrousel de 4 cartes animees (Express, Feel, Journey, Sources)
- Navigation vers les sections correspondantes

---

## 6. Saisie de pensee

*(Fonctionnalites existantes — a completer)*

- Ecran de saisie de texte libre
- Validation et envoi vers le moteur d'eclairage

---

## 7. Roue des emotions

*(Fonctionnalites existantes — a completer)*

- Selection d'emotions via roue interactive
- Association emotion + pensee

---

## 8. Generation d'eclairages

*(Fonctionnalites existantes — a completer)*

- Appel API IA pour generer un eclairage
- Streaming de la reponse
- Affichage dans un carrousel dedie

---

## 9. Historique

*(Fonctionnalites existantes — a completer)*

- Carrousel vertical des eclairages passes
- Navigation chronologique

---

## 10. Mandala

*(Fonctionnalites existantes — a completer)*

- Visualisation mandala
- Gestion des couleurs et aureoles

---

## 11. Profil utilisateur

*(Fonctionnalites existantes — a completer)*

- Edition du profil
- Preferences

---

## 12. Services transversaux

### 12.1 Musique de fond

- **Fonctionnel** : Musique d'ambiance jouee en continu, adaptee selon l'ecran.
- **Technique** : `BackgroundMusicService` implementant `NavigatorObserver`.

### 12.2 Theme visuel

- **Fonctionnel** : Theme coherent indigo/blanc avec police Inter, boutons roses "Positive Thought", cartouches cyan pour la navigation.
- **Technique** : `ThemeData` dans `main.dart`, `NavCartouche` cyan `0xFF00E5FF`, `AppScaffold` avec gradient.

---

## 13. Deploiement

- **Android** : Deploiement automatique Google Play a chaque push sur main.
- **iOS** : Deploiement manuel via GitHub Actions (workflow_dispatch) pour economiser les minutes macOS.

---

## 14. Agent Guide (Amy)

### 14.1 Bouton flottant permanent

- **Fonctionnel** : Un bouton circulaire flottant (avatar pastel "Amy") est present en bas a gauche sur tous les ecrans de l'application, y compris l'ecran d'accueil/introduction, a l'exception des ecrans de connexion, d'onboarding et de l'ecran de l'agent lui-meme. Un tap ouvre l'ecran de l'agent guide.
- **Technique** : `AgentGuideFab` (widget `lib/widgets/agent_guide_fab.dart`) injecte via le `builder` de `MaterialApp` dans `main.dart`. Suivi de la route active via `AgentGuideRouteTracker` (NavigatorObserver + ValueNotifier). Navigation vers `/agent-guide` via `GlobalKey<NavigatorState>` passee a `MaterialApp.navigatorKey`. Aucun ecran existant n'est modifie.
- **Date** : 2026-04-21

### 14.2 Ecran conversationnel avec voix

- **Fonctionnel** : L'ecran a un fond bleu nuit et presente Amy (avatar pastel en grand format) avec un message d'accueil. L'utilisateur peut poser des questions en texte libre ou choisir une des 8 suggestions (pastilles vertes) : "The principle of the app", "How does it work", "What are the sources?", "How to find a thought?", "What is the quiz for?", "And the wheel of chance?", "Why fill in my profile?", "Privacy of my exchanges". Chaque reponse d'Amy dispose d'un bouton "Listen / Stop" qui declenche la synthese vocale native via TTS. Un indicateur de frappe anime s'affiche pendant que l'agent reflechit. Un bouton "Back" (cartouche retour) en bas permet de revenir a l'ecran precedent.
- **Technique** : `AgentGuideScreen` (`lib/screens/agent_guide_screen.dart`). Scaffold custom (palette bleu nuit `#0A1628` / surface `#152840` / vert `#2E8B7B` reprise du `home_carousel_screen.dart`). Appel Claude via la nouvelle methode `AIService.generateAgentReply` qui gere un historique de messages multi-tour (role user/assistant), avec retry, timeout et gestion d'erreurs. Historique plafonne aux 20 derniers messages envoyes a l'API. Base de connaissances dans `lib/config/agent_guide_knowledge.dart` (description fonctionnelle de l'app + consignes de style injectees comme `system prompt`). Lecture vocale via `TtsService` existant.
- **Date** : 2026-04-21

### 14.3 Perimetre de l'agent

- **Fonctionnel** : Amy peut (1) expliquer le fonctionnement de chaque ecran et fonctionnalite, (2) accompagner un utilisateur qui bloque, (3) suggerer une premiere action concrete. Elle ne donne pas de conseils therapeutiques et ramene toujours vers l'usage de l'application. **Regle critique** : interdiction absolue de dire que l'application est "inspired by" quelqu'un. Elle peut en revanche dire que l'app "resembles" / "echoes" des demarches connues d'introspection (4 questions de Byron Katie, TCC, stoicisme, pleine conscience) a titre d'exemple.
- **Technique** : Le system prompt (`AgentGuideKnowledge.systemPrompt`) encadre le ton (chaleureux, simple, court), la longueur (3 a 6 phrases par defaut), la langue (anglais par defaut) et exclut la mention des technologies sous-jacentes ainsi que toute notion d'inspiration.
- **Date** : 2026-04-21

---

## 15. Suppression de compte (conformite App Store Guideline 5.1.1(v))

- **Fonctionnel** : Sur l'ecran de connexion, un lien discret "Delete my account" est affiche en bas (sous les boutons de connexion sociale). Un tap ouvre une feuille listant les comptes enregistres sur cet appareil (un email par ligne), chacun accompagne d'un bouton "Delete" rouge. Le tap sur "Delete" affiche un dialogue de confirmation ("Delete your account?" avec boutons Cancel / Delete) precisant que la suppression est definitive et efface profil, valeurs et reflexions. Apres confirmation, le compte est supprime, la liste se met a jour et un message "Account deleted" s'affiche. Si aucun compte n'est enregistre, la feuille indique "No account is registered on this device." Le compte invite (mode Guest) est exclu de la liste.
- **Technique** : `lib/screens/auth/login_screen.dart`. Lien ajoute dans `build()` apres `_buildSocialLoginSection()`. Methodes `_showDeleteAccountSheet()` (chargement via `CompleteAuthService.getAllUsers()`, filtrage de `guestEmail`, `showModalBottomSheet` + `StatefulBuilder` pour rafraichir apres suppression) et `_confirmDeleteAccount(email)` (dialogue retournant un `bool`). La suppression appelle `CompleteAuthService.clearUserData(email)` (efface mot de passe, profil, reflexions, parametres et retire l'utilisateur de `all_users`), puis `SocialAuthService.signOutGoogle()` / `signOutFacebook()` par hygiene de session. Les donnees de compte sont uniquement locales (SharedPreferences) : aucun compte serveur a supprimer. Contexte : retour App Review du 11/05/2026 (submission afd23919) — la creation de compte email/password avait deja ete retiree de l'UI ; cette evolution ajoute le flux de suppression exige des lors que la connexion sociale cree un compte.
- **Date** : 2026-04-21

---

## 16. Enrichissement du rapport d'erreur API par email

- **Fonctionnel** : Lorsqu'un appel a l'API Claude echoue (apres retries), un email de diagnostic est envoye a l'equipe support. Cet email contient desormais, en plus des informations existantes (date, plateforme, utilisateur, code erreur, details) : la **version exacte de l'app** (numero de version + build), la **source IA concernee** (ex. "aristote", "judaisme", "agent") et le **Request ID Anthropic**. Le Request ID permet de distinguer une vraie panne plateforme Claude (Request ID present = la requete a atteint Claude) d'un probleme reseau cote utilisateur (Request ID absent = la requete n'a jamais atteint Claude). Aucune donnee personnelle supplementaire (pensee de l'utilisateur, telephone, ville) n'est ajoutee.
- **Technique** : `lib/services/ai_service.dart` et `lib/services/email_service.dart`. Ajout de la dependance `package_info_plus` (lecture de la version au runtime, mise en cache via `_getAppVersion()`). `_callClaude()` et `generateAgentReply()` capturent l'en-tete HTTP `request-id` (fallback `x-request-id`) de la reponse et propagent `sourceKey` + `requestId` a `_reportApiError()`, qui les transmet a `EmailService.sendApiErrorReport()` (nouveau parametre `requestId`, nouvelle ligne dans le template HTML). La `sourceKey` est passee depuis les appelants disposant d'une source unique (`generateSpecificApproach`, `generateDeepening`, `generatePositiveThought`, agent). Pour les erreurs sans reponse HTTP (timeout, reseau), le Request ID est absent, ce qui est interprete dans le mail comme "requete jamais arrivee — probablement reseau".
- **Date** : 2026-06-24

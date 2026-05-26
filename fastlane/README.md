fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios upload_meta

```sh
[bundle exec] fastlane ios upload_meta
```

Uploade les metadonnees seulement (textes FR/EN sans vocabulaire therapeutique)

### ios upload_all

```sh
[bundle exec] fastlane ios upload_all
```

Uploade tout (textes + captures), sans soumettre

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Soumet la version a la review Apple

### ios remove_locale

```sh
[bundle exec] fastlane ios remove_locale
```

Supprime une localisation de la fiche (texte version + texte app info)

### ios cm_list_apps

```sh
[bundle exec] fastlane ios cm_list_apps
```

Liste les apps Codemagic accessibles via l'API token

### ios cm_build

```sh
[bundle exec] fastlane ios cm_build
```

Declenche un build Codemagic via API (auto-merge metadata sans saisie UI)

### ios cancel_pending

```sh
[bundle exec] fastlane ios cancel_pending
```

Annule la submission en cours (state non terminal)

### ios list_builds

```sh
[bundle exec] fastlane ios list_builds
```

Liste les builds TestFlight disponibles

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

# menubar-kit

Shared CI/release workflows, packaging scripts and config templates for my macOS menubar apps.

## Contents
- `.github/workflows/ci.yml`, `release.yml`: reusable (`workflow_call`) workflows.
- `scripts/package-app.sh <App> <version>`, `make-icon.sh <emoji>`, `rebuild.sh <App>`: run from an app repo root.
- `templates/`: files to copy into a new app (`swiftlint.yml`, `dependabot.yml`, `dependabot-automerge.yml`, `gitignore`, `Info.plist` with `__APP__`, `LICENSE`).

## Swift package: MenuBarKit
```swift
dependencies: [.package(url: "https://github.com/PhilRoli/menubar-kit", from: "1.1.0")],
// target dependencies: [.product(name: "MenuBarKit", package: "menubar-kit")]
```
Provides `LoginItemController`, `MainMenu.make(appName:)`, `runMenuBarApp(_:)`, `SecurityCLIKeychain`, `JSONDefaultsStore`, `NotificationScheduler` and `BannerNotificationPresenter`.

## Adding an app
1. Copy the templates in; replace `__APP__` in `Info.plist`.
2. `../menubar-kit/scripts/make-icon.sh 🚆`
3. Add `.github/workflows/ci.yml`:
   ```yaml
   name: CI
   on:
     push:
       branches: [main, develop]
     pull_request:
   jobs:
     ci:
       uses: PhilRoli/menubar-kit/.github/workflows/ci.yml@v1
       with:
         app: MyApp
   ```
   and `release.yml`:
   ```yaml
   name: Release
   on:
     push:
       tags: ['v[0-9]*']
     workflow_dispatch:   # manual run = dry run (no release, no tap update)
   permissions:
     contents: write
   jobs:
     release:
       uses: PhilRoli/menubar-kit/.github/workflows/release.yml@v1
       with:
         app: MyApp
         dry_run: ${{ github.event_name == 'workflow_dispatch' }}
       secrets: inherit
   ```
4. Add `Casks/<app>.rb` to `homebrew-tap`.

## Local development
Clone this repo next to the app repos (`../menubar-kit`) or set `MENUBAR_KIT`. App `rebuild.sh` shims call `scripts/rebuild.sh`.

## Releasing the kit
Tag `v1.x.y`, then move the floating tag: `git tag -f v1 && git push -f origin v1`.

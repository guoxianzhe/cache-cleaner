<p align="center">
  <img src="docs/mascot.png" width="100" alt="Cache-Chan, an original pink-haired chibi desktop companion">
</p>

<h1 align="center">Cache-Chan</h1>
<p align="center"><strong>A little companion. A little more space.</strong></p>
<p align="center">An anime-inspired macOS desktop buddy that helps you reclaim development cache space.</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-f4a7b7?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-macOS_11%2B-24212c?style=flat-square" alt="macOS 11 and newer">
  <img src="https://img.shields.io/badge/built_with-Swift_%2B_AppKit-f4a7b7?style=flat-square" alt="Swift and AppKit">
  <img src="https://img.shields.io/badge/runtime_dependencies-zero-24212c?style=flat-square" alt="Zero third-party runtime dependencies">
</p>

![Cache-Chan project showcase: the original mascot beside the real native cleaner panel](docs/showcase.png)

## Meet your new desktop buddy

Leave Cache-Chan on your desktop, drag her wherever you like, and click her avatar when you want to make room. Pick your own character image to make the companion yours.

- **Avatar first.** A small floating companion, with the cleaner tucked away until you need it.
- **Your character, your desk.** Choose a local image, center-crop it into a round avatar and keep it across restarts.
- **Know before you clean.** Scan fixed development cache locations and review their measured sizes before confirming.
- **See the result.** The cleaner reports removed cache size, remaining space and the actual available-space change.
- **Native and local.** Swift + AppKit. No account, administrator access, telemetry, network calls or automatic cleaning.

The showcase uses the actual native view in a presentation state. Cache sizes are measured from your machine when you scan; no reclaimed-space claim is fabricated.

## Run it

Requires macOS 11 or newer and Xcode or Xcode Command Line Tools with a Swift compiler that supports `@main`.

```sh
git clone https://github.com/guoxianzhe/cache-cleaner.git
cd cache-cleaner
bash build.sh --run
```

The build creates `build/Cache-Chan.app`, runs an isolated self-test and applies an ad-hoc local signature. Double-click the app later or copy it into Applications. This is a source-built app, not a Developer ID signed or notarized download.

## The tiny controls

| Action | What happens |
| --- | --- |
| Click avatar | Open or hide the cleaner; first opening scans caches |
| Drag avatar | Move it; placement is saved and clamped to a visible screen |
| Right-click avatar | Change/reset avatar, open cleaner, About or Quit |
| Menu bar sparkle | The same controls, even if the cleaner is closed |
| Scan again | Refresh the per-directory estimate without deleting anything |
| Clean caches… | Review the confirmation, then remove only measured cache targets |

Your image is copied as a cropped PNG to `~/Library/Application Support/Cache-Chan/avatar.png`. The original stays untouched. The default mascot can be restored with **Reset avatar**. Custom images are never uploaded; their rights remain with their respective owners.

## What's on the menu?

Only these fixed paths under the current user's home are eligible:

| Tool | Cache paths |
| --- | --- |
| Codex | `Library/Application Support/Codex/Crashpad/pending` |
| uv | `.cache/uv` |
| VS Code C++ | `Library/Caches/vscode-cpptools` |
| Gradle | `.gradle/caches`, `.gradle/.tmp`, `.gradle/daemon` |
| npm / npx | `.npm/_cacache`, `.npm/_npx` |
| CocoaPods / Yarn | `Library/Caches/CocoaPods`, `Library/Caches/Yarn` |
| Electron / Playwright / TypeScript | `Library/Caches/electron`, `Library/Caches/ms-playwright`, `Library/Caches/typescript` |

**Deletion is permanent, not a move to Trash.** Quit active builds and affected tools first. Packages, browsers and indexes may need to download or rebuild afterwards. Source code, Git worktrees, chat files, Codex conversations and Docker data are outside this scope.

Symbolic links in a target or its parent path are rejected before measurement and again before cleanup. Inaccessible locations are reported and skipped. Do not replace target paths while cleaning: this small utility does not lock the filesystem against concurrent directory changes.

Disk estimates use `du -sk`. APFS shared blocks and other apps' activity mean removed cache size and available disk space can differ. Scanning/cleanup runs in the background and disables action buttons until completion.

## Build, check, hack

```sh
bash build.sh
build/Cache-Chan.app/Contents/MacOS/CacheCleaner --self-test
```

The self-test covers path boundaries, symbolic-link rejection, capacity formatting, mascot PNG rendering and deletion in a disposable test directory. It never deletes real development caches. Also test clicking, dragging, avatar selection and the confirmation's **Cancel** path after UI changes.

To regenerate the repository artwork:

```sh
mkdir -p docs
build/Cache-Chan.app/Contents/MacOS/CacheCleaner --export-avatar docs/mascot.png
build/Cache-Chan.app/Contents/MacOS/CacheCleaner --preview docs/showcase.png
```

Contributions welcome: see [CONTRIBUTING.md](CONTRIBUTING.md). Have an idea for a companion or a new cache target? [Open an issue](https://github.com/guoxianzhe/cache-cleaner/issues). If Cache-Chan makes your desk a little happier, a star helps others find her.

## License

Copyright © 2026 [guoxianzhe](https://github.com/guoxianzhe). Code and the original default mascot are released under the [MIT License](LICENSE). No third-party anime characters are bundled. See [CHANGELOG.md](CHANGELOG.md) for release notes.

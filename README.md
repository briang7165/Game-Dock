# Game Dock

A local-first Windows desktop game library and launcher built with **Tauri 2, Rust, React and TypeScript**. Games remain separate, runnable executables: the launcher does not depend on a particular game engine.

**Current phase: v0.1 development launcher.** GitHub Windows build passed and the Tauri development application was launched successfully on Windows on 2026-10-22. Standalone Harbor Test/installed launcher integration still needs hands-on verification. No store, updater, or completed pirate game is claimed.

## Start on Windows

1. Follow [Windows setup](docs/WINDOWS_SETUP.md) to install free prerequisites.
2. Clone this repository to `C:\Dev\Game-Dock` (or any local folder outside OneDrive).
3. Run `START_GAME_DOCK_DEV.bat`.
4. Optionally run `INSTALL_HARBOR_TEST.bat` to compile and register the bundled benign native launch-test executable.
5. In Game Dock, open **My Library**, select **Refresh**, and press **Play** on Harbor Test.

No additional account or subscription is needed to run the installed application. GitHub is used for source control and optional CI builds.

## Projects

- **Game Dock:** Tauri 2 native shell; Rust file/process backend; React/TypeScript interface.
- **Harbor Test:** a tiny separate Windows executable to check launches; not a game.
- **Broadside:** approved pirate naval combat design; standalone Godot project to be built in stages, with first Codex PR limited to working combat.

## Broadside design and Codex task

- [Approved Broadside game specification](docs/BROADSIDE_DESIGN_DRAFT.md) — painterly top-down arcade-tactical pirate combat; WASD/arrows, Space broadside firing, automatic reload, Esc pause, mouse only in menus; rocky islands; sloop-to-galleon purchase progression.
- [Codex implementation task book](docs/CODEX_BROADSIDE_BUILD.md) — PR1 playable combat, PR2 shipyard/progression, PR3 art and release.
- [GitHub Issue #3](https://github.com/briang7165/Game-Dock/issues/3) — implementation tracker.
- [Endless Odyssey campaign design](docs/BROADSIDE_ENDLESS_ODYSSEY.md) — shorter early battles, captain/ship names, skippable voyage chart, endless adventure chapters, tactical shipyard and varied upgrades.
- [GitHub Issue #5](https://github.com/briang7165/Game-Dock/issues/5) — staged M2 campaign/shipyard build, separate from current combat PR #4.
- [Install Broadside in Game Dock](docs/BROADSIDE_INSTALL_IN_GAME_DOCK.md) — export/copy the complete Windows game into the library and click Play.
- [GitHub Issue #6](https://github.com/briang7165/Game-Dock/issues/6) — publish a dedicated playable Broadside Windows ZIP artifact and easy install method.

- [AGENTS.md](AGENTS.md) — repository instructions for coding agents.

## Releasing

Run `BUILD_WINDOWS_INSTALLER.bat` on Windows or download the installer artifact from the GitHub Actions build once it has passed. The CI workflow builds a **launcher-only** NSIS installer; it does not publish a release or bundle Broadside. Game Dock does not currently download or install games.

## Game package convention

Installed games live in the app-specific roaming data folder returned in **Settings**, under `games/<game-id>`. Each folder includes an executable and a `game.json` manifest:

```json
{
  "schema_version": 1,
  "id": "harbor-test",
  "name": "Harbor Test",
  "version": "0.1.0",
  "genre": "Utility",
  "description": "Local executable launch test",
  "executable": "HarborTest.exe"
}
```

A stand-alone game must work without Game Dock. Saves belong in their own user-data directory, **not** beside executables.

See [Architecture](docs/ARCHITECTURE.md), [Roadmap](docs/ROADMAP.md), and [Game manifest schema](specs/game-manifest.schema.json).

## Security

The Rust backend rejects unsafe game IDs and path traversal, resolves executable paths and does not use a shell to execute game commands. This is not a malware scanner: only register executables you trust.

License: Not yet selected. Public repository visibility does **not** automatically grant an open-source license.

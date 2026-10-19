# Architecture

## Principles
1. Game Dock is a local-only launcher by default; installed games launch without an online connection.
2. Games remain independently installable, with their own executables and saves.
3. Game packages are engine-agnostic, defined by a simple versioned JSON manifest.
4. React/TypeScript renders the interface; Rust manages filesystem and process operations through registered Tauri commands.
5. Never call a command shell with game manifest content. Reject traversal and symlink escapes.
6. Treat remote downloads, installers, updates and uninstall as separate milestones requiring verification and rollback.

## Flow

React UI -> Tauri invoke -> Rust commands -> per-user app data / games -> separate game process.

## V0.1 game manifest
Required keys: schema_version=1, id, name, version, executable. Optional: genre, description.
- Lowercase game ID and directory name must match; only digits and hyphens accepted in addition to letters.
- Executable is one Windows .exe filename in the same directory; no shell args or nested paths.
- Native executable path must resolve inside the canonical game directory.
- No network fetch, remote execution, telemetry, or online account.
- Saved games live outside the installed game binaries.

See specs/game-manifest.schema.json.

## Testing
The supplied Harbor Test standalone program is a benign executable that opens a message box. Run its builder locally and launch it using Game Dock to test the entire path. GitHub Actions validates frontend compilation, Rust tests, Harbor Test compilation, and launcher packaging, but **does not** run the graphical desktop app.

## Portability
Windows 11 x64 first. The frontend is OS-independent, while executable filename policy and installation scripts intentionally target Windows for v0.1. macOS/Linux support requires separate package rules and native testing.

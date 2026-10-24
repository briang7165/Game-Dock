# Broadside — Export, Install and Play in Game Dock (Windows)
**User-facing guide, 2026-10-23.** Game Dock is the launcher. Broadside is a separate standalone Godot application. Game Dock does not yet automatically download or install games.

## Current status
- The Broadside M1.4 source is on [PR #4](https://github.com/briang7165/Game-Dock/pull/4) and passes the reported Godot/Windows checks.
- PR #4 is not yet merged into main.
- Current GitHub Actions for this repo publish **a Game Dock launcher installer**, not a Broadside game ZIP. Do not mistake the `game-dock-windows-setup` artifact for a playable Broadside export.
- The Broadside game export (Broadside.exe + Broadside.pck) must be obtained from the Godot export performed locally/Codex, or from a future dedicated release-artifact workflow. The `packaging/game.json` file is in the Broadside project. Downloading only source files from GitHub does **not** produce a double-clickable game.

## Quick method: If you already have Broadside.exe, Broadside.pck and game.json
1. Run Broadside.exe once outside Game Dock to confirm the standalone game works. Keep its matching .pck beside the .exe.
2. Open Game Dock from Start/taskbar (or launch `START_GAME_DOCK_DEV.bat` for the development version).
3. In Game Dock, open **My Library** and click **Open games folder** (or go to Settings -> **Open games folder**). Use the actual folder opened by the app, **not** your GitHub repository or OneDrive project folder.
4. Inside the opened `games` folder, create a subfolder named exactly **broadside** (lowercase).
5. Copy **all three files** into it:
   
   ```text
   ...\games\broadside\
       Broadside.exe
       Broadside.pck
       game.json
   ```
   
   This project deliberately exports an **external .pck**. The EXE alone will not work without it.
6. In Game Dock open **My Library**, click the top-right **Refresh games** icon, and select **Installed** if needed.
7. Broadside should appear as an installed game with **Play game** enabled. Click it. Game Dock starts a separate normal Windows game process.
8. Leave Game Dock installed if desired; Broadside can also be launched directly by double-clicking `Broadside.exe`.

## What game.json must say
The game manifest is already in `games/broadside/packaging/game.json` in the Broadside project. Do not invent or rename its keys. Simplest valid example:

```json
{
  "schema_version": 1,
  "id": "broadside",
  "name": "Broadside",
  "version": "0.1.4",
  "genre": "Naval combat",
  "description": "An offline pirate naval-combat adventure.",
  "executable": "Broadside.exe"
}
```

Game Dock checks that folder name matches id (both `broadside`), manifest is valid, and executable exists directly inside that same subfolder. Version string changes as new builds ship.

## If you only have the source project and not a playable .exe yet
1. Obtain the latest M1.4 source from PR #4 (after merge, GitHub Desktop **Fetch origin / Pull origin** gives it in the main branch; before merge, check out the feature branch `feature/broadside-m1-combat` in GitHub Desktop or use the PR's source ZIP). Avoid checking out a feature branch while you have uncommitted local changes.
2. Install/open **Godot 4.5.2 stable** and its **matching Windows Export Templates**. From Godot's Project Manager, **Import** the file `games/broadside/project.godot`.
3. Open project and test with F5 (not required for export but useful).
4. **Project → Export…**; select **Windows Desktop**. Export Project to `games/broadside/build/Broadside.exe` or another simple local folder. Leave **Embed PCK** off, matching the versioned `export_presets.cfg`, so Godot creates `Broadside.exe` and `Broadside.pck`.
5. Copy `games/broadside/packaging/game.json` into the same export folder and follow Quick method above.
6. Alternative from the repository root if the Godot console executable is on PATH or you've substituted its full path:

   ```powershell
   New-Item -ItemType Directory games/broadside/build -Force
   godot --headless --path games/broadside --editor --quit
   godot --headless --path games/broadside --export-release "Windows Desktop" build/Broadside.exe
   Copy-Item games/broadside/packaging/game.json games/broadside/build/game.json
   ```

   The export path is relative to the **Godot project**; verify files are actually in `games/broadside/build` before copying. Windows export templates are required. If a .pck is embedded by different presets, follow that preset's output requirements instead.

## Updating the installed Broadside
1. Preserve saves in Godot's separate `user://` location (Broadside's customized app user-data folder), not inside `games/broadside`.
2. Close the running game.
3. Replace `Broadside.exe`, `Broadside.pck`, and `game.json` in Game Dock's actual `games/broadside` folder with **files from one matching version**.
4. Reopen / refresh Game Dock. Do not mix a new EXE with an old PCK.
5. When M2 adds persistent campaign saves, ensure Codex provides backward-compatible migrations and a backup strategy before upgrading.

## Troubleshooting
- **No Broadside card:** verify the exact folder is `games/broadside`, with `game.json` directly inside and `id` = `broadside`; refresh the library.
- **"Executable missing":** ensure `Broadside.exe` exists at `games/broadside/Broadside.exe`, not hidden in a nested `build` folder; filename must match manifest.
- **Godot game won't start:** `Broadside.pck` may be missing or mismatched with the EXE; test `Broadside.exe` directly and inspect any visible error. Windows security prompts may appear for unsigned personal development builds; confirm the file came from your trusted own source/build before allowing.
- **Can't find games directory:** In Game Dock click **My Library → Open games folder**; this opens the exact native app data directory. Never guess the full `AppData` path.
- **ZIP contains only an installer for Game Dock:** This is the launcher bundle, not Broadside. Ask Codex for a dedicated **Broadside Windows playable ZIP** with EXE/PCK/manifest.
- **Can't see new version:** close running game, ensure both EXE and PCK are from the newest build, and refresh in Game Dock.
- **Save appears missing:** check that Broadside's `user://` application data folder is unchanged; don't copy save files into installation binaries folder.

## Future packaging improvement (Codex)
Build a dedicated **Broadside Windows export workflow** that installs pinned Godot matching export templates, validates the manifest, generates a versioned `Broadside-windows-x64.zip` containing exactly the correct standalone game payload (EXE + PCK + game.json), and uploads it as an artifact on the Broadside workflow. It is distinct from `game-dock-windows-setup`. Include a small optional Windows helper to locate the actual Game Dock games directory and safely install/upgrade these three files (prompt/preview, avoid deleting saves). Never silently run untrusted external downloaded executables. Record build verification and perform a real Game Dock Refresh/Play test on Windows when possible.

# M2-A verification — 2026-10-23

Dependent on PR #7 and approved combat PR #4; no branches merged into main.

Implemented captain/ship papers and pennants, versioned atomic JSON saves with safe backup recovery, illustrated seeded voyage chart, four-second skippable sailing, five-stop chapters with a flagship, endless progression and free defeat recovery. Practice remains available. Economy and encounter variety follow in M2-B/C.

Godot 4.5.2 stable official, Windows x64; Python 3.12 with jsonschema 4.26.0.

- `tests/run.ps1 -Godot <Godot_v4.5.2-stable_win64_console.exe>`: import, boot, manifest validation and 207 assertions passed (39 combat, 7 AI, 50 refinement, 31 impacts, 20 balance, 43 viewport, 17 campaign).
- Actual Windows release export via `packaging/build-windows.ps1`: boot smoke test passed; ZIP has exactly Broadside.exe, Broadside.pck, game.json at root.
- Exported executable running campaign_test.gd with native rendering: 17 assertions passed, exit 0. Isolated APPDATA protects player saves.
- Native 1280x720 chart screenshot inspected: complete parchment route and keyboard controls visible. Previous M1.4 resolution/fullscreen regression suite retained.
- Campaign tests exercise backup recovery, unsupported versions, duplicate settlement, twelve victories across chapters, defeat recovery, identity typing, skipped and automatic travel, actual battle victory/defeat.

Failure history: initial menu assertions expected old labels; updated for explicit practice/new-voyage menu. Expected corrupt-save fixture initially logged a JSON engine error; parser now returns a handled error. GitHub Windows headless shutdown intermittently reports signal 11, including once immediately after editor import; do not ignore failed exit codes. Packaging PR #7 run 40055253119 passed all steps and published artifact 12544948376, while its separate M1 regression workflow hit the intermittent import shutdown crash.

Human playtesting remains necessary for long-session pacing and subjective balance. M2-A local ZIP: Broadside-windows-x64-0.2.0-m2a.zip. Follow BROADSIDE_INSTALL_IN_GAME_DOCK.md; saves live in Godot user://, outside installation folders.

# M2-C Endless Odyssey verification — 2026-10-24

Depends on M2-B PR #9, M2-A PR #8, packaging PR #7 and approved combat PR #4. No automatic merge. Windows package version **0.2.2-m2c**.

## Implemented

Three risk/reward routes; deterministic safe reef templates; tropical, ash, mist and storm palettes; raider/hunter/heavy tactics; groups capped at three ships; three rotating chapter flagships with capped health and longer warnings. Campaign enemies cannot start firing while offscreen. Victory requires every hostile to sink, while mutual destruction remains defeat.

One earned specialist berth (gunner/navigator/carpenter/quartermaster), chain shot with an expiring rigging penalty, actual hull icons on the voyage chart, earned captain titles and a bounded eight-entry journal with lifetime counters. Persistent gold/salvage/repairs, nine upgrades and four ship classes are inherited from M2-B. Defeat preserves identity/equipment, grants emergency refit/salvage and permits a safer route.

The approved starter remains 60 HP, 16 damage and one cannon per side. Practice controls, physics, collision safeguards, audio, separate HUD and camera remain covered by regression tests.

## Tests and real Windows execution

Environment: Windows x64, official Godot 4.5.2 stable (6ce3de25a), Python 3.12 / jsonschema 4.26.0, Node 22.14.0 / npm 10.9.2 / Vite 6.4.5, Cargo 1.99.1. Native renderer: OpenGL 3.3, NVIDIA GeForce GTX 1660 Ti. APPDATA redirected to isolated test folders.

- `games/broadside/tests/run.ps1 -Godot <console.exe> -Python <venv/python.exe>`: import, boot, schema and **262 assertions passed**: combat 39, AI 7, refinement 50, impacts 31, balance 20, viewport 43, campaign 17, shipyard 27, odyssey 28.
- Odyssey tests cover **15,000 generated encounters across 1,000 chapters** for clear spawns, bounded counts/difficulty and deterministic layout. One hundred settled victories cross twenty chapters; rollover, bounded journal, active-route locking, duplicate settlement and older save defaults are exercised.
- Real battle tests verify first-versus-last fleet sinking, Escape skip, boss retreat/recovery, offscreen firing prevention, actual swept chain-shot hit/expiry and keyboard scroll-to-crew.
- `packaging/build-windows.ps1`: actual Windows release export, exported EXE boot smoke and exact ZIP root entries passed: Broadside.exe, Broadside.pck, game.json.
- **Exported EXE, native rendering**, `--script <absolute odyssey_test.gd>`: **28/28 passed**, normal exit.
- Native `viewport_test.gd`: **45/45 passed**, including real fullscreen/window restoration and 800x450, 1280x720, 1920x1080, ultrawide layout checks.
- Native `audio_playback_test.gd`: loop wrapped once; peak 0.3592, RMS 0.0316 over 2,617,344 samples; nonzero unclipped mix passed.
- `npm run build` in launcher: TypeScript/Vite production build passed. `cargo test --offline` in launcher/src-tauri: **2/2 safety tests passed**. Launcher source unchanged; generated test files removed.
- `git diff --check`: clean.

## Screenshots

Actual exported runtime captures inspected at chart 1280x720, shipyard 800x450, fleet battle 1920x1080 and fullscreen boss 2560x1440. The footer remains outside the ocean, route controls fit, and inventory scrolls. Captures are supplied with the task's deliverables, not committed as generated build files. Reproduce with `tests/campaign_capture.gd`, output path and chart/harbor/fleet/boss mode; append fullscreen for native fullscreen capture.

## Corrections and limits

Testing caught an untyped array assignment in the director, a zero-size first-frame viewport guard, the old single-enemy status label, and an inherited 12-damage generic cannon resource. All were corrected before this package. The cannon fix is also backported to PR #9 as **0.2.1-m2b.1**; do not use its original superseded 0.2.1-m2b artifact. Save writes are read back and validated before replacing the previous file.

Earlier packaging attempts experienced intermittent Godot Windows headless shutdown signal 11 (including editor import); no exit codes or engine errors are ignored. Later M2-A and M2-B source/export workflows passed. The M2-C PR's Actions checks remain the source of truth for remote build status.

These tests establish functional behavior, not average human battle duration or subjective final balance. Long-session human playtesting, code signing, and a manual launch through the installed Game Dock UI remain unverified. Manifest compatibility, standalone execution and launcher build/safety checks are verified. Optional merchant-defense/chase missions and a complex captain skill tree are not included; implemented variety is route/terrain/role/fleet/boss based.

CI follow-up: the first M2-C regression job reproduced the import-only shutdown access violation before any gameplay suite ran (run 40112082375). The import check now allows 120 editor frames at at most 60 FPS before quitting, rather than immediate --quit. All errors/nonzero exits remain fatal; no automatic retry or suppression is added. This mitigates the observed startup/shutdown race without changing game code; monitor subsequent CI runs rather than claiming an established engine root cause.

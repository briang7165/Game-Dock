# Broadside M2-F — validation and save compatibility

Version 0.2.5-m2f; dependent on PR #13 / feature/broadside-m2e-polish (6e45f2e). No merge performed.

## Changes

Unpaid estimates now cancel on tab/category/ship/chart navigation. Gold (30px base) and salvage stay pinned above repairs. Cards show exact next prices, tier circles, textual levels/remaining count, MAXED and weapon ownership. Maximum remaining tier steps account for category slots, not just theoretical item caps. Salvage sales use explicit revision-checked confirmation and cannot grant an inspected unowned ship. Desktop scaling increases text up to 1.5x, while 800x450 uses compact category controls and scrolling content.

A dedicated chart expands through the page with a winding route, original illustrated islands, completed stops, ship marker, next highlight and boss destination. One Set Sail action previews enemies/reward/preparation. Four-second sailing and keyboard skipping remain. New encounters use deterministic chapter/stop templates, with hunters/heavies introduced in chapter one and escorts later. Difficulty caps at chapter-six parameters: at most three enemies, boss HP at most 160, bounded reload/speed improvements. Chapter-one prizes total 700 gold before bonuses (enough for a brig and extra cannon with a 150-gold repair allowance).

Repeated defeats preserve ships/upgrades/progress, return a seaworthy ship and salvage for confirmed trade, weaken retries by up to 24%, and remove one escort after two setbacks. Victory clears that assistance. No new difficulty selector or automatic purchases.

## Save contract

Version-2 saves keep their existing format, fleet, names, currency, purchases, journal and progress. Optional validated progression/setbacks fields are added when needed. An active pre-M2-F save without the progression marker retains its old route, enemies and reward until settlement. The next new battle adopts automatic progression; merely loading does not reset or reroll it. Legacy v1 migration/backups are unchanged. Failed writes leave progress untouched and show a chart error.

## Actual local verification

Godot 4.5.2 official and matching Windows export templates; Windows OpenGL compatibility on NVIDIA GTX 1660 Ti. Python 3.12/jsonschema 4.26.0; Node 22.14/npm 10.9.2/Vite 6.4.5; Cargo 1.99.1. All saves run in isolated test APPDATA, never player data.

Commands: tests/run.ps1; individual Godot --headless --fixed-fps 60 --script suites; packaging/build-windows.ps1; exported Broadside.exe --script absolute-harness (without --headless); npm run build; cargo test --offline --manifest-path launcher/src-tauri/Cargo.toml.

Source assertions: combat39, AI7, refinement53, impacts31, balance20, viewport43, campaign17, shipyard27, odyssey28, fleet27, GUI19, M2-E44, M2-F harbor14, M2-F voyage24: 393 total. New checks cover real mouse/keyboard navigation, zero-charge cancellation, explicit one-time salvage sale, legacy active battles, 5000 bounded deterministic stages, zero-gold recovery, map geometry, sailing/skip, actual boss setup and failed-save handling.

One local combined run hit the previously observed Godot signal-11 shutdown crash after passing refinement assertions; a separate M2-E suite also passed assertions but exited with native access violation. These are failed processes, not passing runs. Other individual suites exited cleanly. Final independent CI status is linked in the pull request; do not infer it from assertion counts.

Exported native Windows tests passed: fleet27, GUI19, viewport45 including fullscreen, odyssey28, bosses44, harbor14, voyage24 (201 assertions), across initial and focused final runs. Exported boot and exact EXE/PCK/game.json ZIP packaging passed. Native audio loop/crossfade/SFX test: peak0.3814, RMS0.0404, 2,632,704 channel samples, one loop, clean exit. Launcher production build and Rust2/2 passed.

Screenshots/capture layout checks: 800x450, 1280x720, 1920x1080, requested2560x1440 (Windows clamps windowed client to2560x1415), 2560x1080 ultrawide, and exact2560x1440 fullscreen. Chart covers over65% at standard/large logical heights; small-window layout prioritizes readable preview/buttons with a smaller map share. Captures include completed-route chart, checkout, fleet and sailing. No binary build artifacts committed.

## Human verification remaining

Click through your own existing fleet; judge readability/scroll comfort at your Windows DPI; play several chapters and defeat/retry sequences to assess economy and difficulty. Scripted gold budgets and bounded stats do not establish human win rates. Music/boss controls are preserved; subjective audio/gameplay review still matters.
